(in-package #:clautolisp.cador)

;;;; Command-dispatch HAL methods on MockHost
;;;; (deferred-command-special-form issue).
;;;;
;;;; The mock semantics of an AutoLISP (command ...) call:
;;;;
;;;;   * the normalized token-string list the runtime routed here is
;;;;     recorded on the host's COMMAND-LOG (newest first, matching
;;;;     the DISPLAY-LOG convention),
;;;;   * a human-readable one-line echo is written to PROMPT-OUTPUT,
;;;;     so an interactive REPL shows that the command was "typed",
;;;;   * and — since the SCHMS corpus DRAWS through the command
;;;;     channel (its block factories run ._LINE / ._TEXT / ._DONUT /
;;;;     ._SOLID and then clone entlast..entnext into a block pair) —
;;;;     a small COMMAND ENGINE executes the model-only drawing and
;;;;     editing commands the corpus uses: LINE, CIRCLE, TEXT, DONUT,
;;;;     SOLID, ERASE, MOVE, COPY (see %EXECUTE-COMMAND-TOKENS
;;;;     below). Anything else stays record-only, and malformed input
;;;;     degrades to record-only — the engine never signals.
;;;;
;;;; The call returns nil — the documented COMMAND return-value rule.
;;;; Tests and the CLAL-COMMAND-LOG extension read the log back
;;;; oldest-first through HOST-COMMAND-LOG.

(defun render-command-token (token)
  "Echo spelling for TOKEN: the RETURN token \"\" prints as <RETURN>,
the PAUSE token \"\\\\\" as <PAUSE>, a non-string token (a live
selection set) as its printed form, anything else verbatim."
  (cond
    ((not (stringp token)) (princ-to-string token))
    ((string= token "")   "<RETURN>")
    ((string= token "\\") "<PAUSE>")
    (t token)))

(defun %cador-cmdecho-on-p (host)
  "True unless CMDECHO is 0. CMDECHO governs whether (command ...) echoes
the command line to the prompt output — its documented coupling (spec
§CMDECHO, whose Read/Written-By list names the command engine). An
absent or non-integer cell is treated as ON (the vendor default of 1),
so a host that never sets CMDECHO keeps echoing. system-variables.issue
'Coupling'."
  (let ((cell (ignore-errors (cador-sysvar host "CMDECHO"))))
    (or (null cell)
        (not (eql (sysvar-cell-value cell) 0)))))

(defmethod host-command ((host cador) arguments)
  ;; NB (slice 3f): host-command never reads cador-prompt-stream -- every %cmd-*
  ;; consumes only its token arguments and degrades to record-only on missing
  ;; data, so no "prompting host-command" park point exists yet. D1 §13.5 lists
  ;; it as a FUTURE park point; when a command is made to prompt for missing
  ;; input it must route through read-prompt-line / %cador-maybe-park-read, so
  ;; the parking seam is already in place and no work is owed here now.
  (push arguments (cador-command-log host))
  ;; The command log is always recorded (so CLAL-COMMAND-LOG and tests
  ;; can see what was "typed"); only the human-readable echo obeys
  ;; CMDECHO, matching AutoCAD where CMDECHO=0 silences the prompt echo
  ;; without disabling the command itself.
  (let ((sink (cador-prompt-output host)))
    (when (and sink (%cador-cmdecho-on-p host))
      (if arguments
          (format sink "~&Command:~{ ~A~}~%"
                  (mapcar #'render-command-token arguments))
          ;; (command) with no arguments — the vendor-documented
          ;; "cancel the current command" call.
          (format sink "~&Command: *Cancel*~%"))
      (finish-output sink)))
  (%execute-command-tokens host arguments)
  nil)

;;; --- The drawing-command engine ----------------------------------
;;;
;;; Executes the model-only drawing commands the SCHMS corpus routes
;;; through (command ...): LINE, CIRCLE, TEXT (with the _Justify
;;; option), DONUT and SOLID. Entities land in model space on the
;;; current layer, through the same %HOST-ADD-ENTITY path as entmake,
;;; so entlast / entnext / reactors see them. Unknown commands and
;;; malformed input degrade to record-only — never a signal.

(defun %split-string-on (character string)
  (loop with start = 0
        for pos = (position character string :start start)
        collect (subseq string start (or pos (length string)))
        while pos
        do (setf start (1+ pos))))

(defun %numeric-token-p (token)
  (and (stringp token)
       (plusp (length token))
       (every (lambda (c) (find c "0123456789.+-eE")) token)
       (some #'digit-char-p token)))

(defun %command-token-number (token)
  "The double-float value of a numeric command TOKEN, or NIL."
  (when (%numeric-token-p token)
    (let ((value (ignore-errors
                   (let ((*read-default-float-format* 'double-float))
                     (with-input-from-string (stream token)
                       (read stream))))))
      (and (realp value) (coerce value 'double-float)))))

(defun %command-token-point (token)
  "The 3D doubles list of an \"x,y[,z]\" command TOKEN, or NIL."
  (when (and (stringp token) (find #\, token))
    (let ((numbers (mapcar #'%command-token-number
                           (%split-string-on #\, token))))
      (when (and (<= 2 (length numbers) 3)
                 (every #'identity numbers))
        (list (first numbers) (second numbers)
              (or (third numbers) 0.0d0))))))

(defun %command-name (token)
  "The upcased command name of TOKEN with the \".\" (English) and \"_\"
\(non-localized) prefix modifiers stripped; NIL for tokens that read as
data (numbers, points, RETURN, PAUSE). A leading \"-\" is NOT a
modifier — \"-FOO\" is a distinct, explicitly-defined command whose
user interface is projected on the console TUI — so it stays part of
the name and each dash form is registered explicitly in the dispatch."
  (and (stringp token)
       (plusp (length token))
       (not (string= token "\\"))
       (not (%command-token-point token))
       (not (%command-token-number token))
       (let ((name (string-left-trim "._" token)))
         (and (plusp (length name)) (string-upcase name)))))

(defun %command-option-p (token &rest spellings)
  "True when TOKEN spells one of the command-option SPELLINGS,
tolerating the \"_\" non-localized prefix."
  (and (stringp token)
       (member (string-left-trim "_" token) spellings
               :test #'string-equal)
       t))

(defun %current-layer-name (host)
  (let ((cell (ignore-errors (cador-sysvar host "CLAYER"))))
    (or (and cell (stringp (sysvar-cell-value cell))
             (sysvar-cell-value cell))
        "0")))

(defun %current-text-style-name (host)
  (let ((cell (ignore-errors (cador-sysvar host "TEXTSTYLE"))))
    (or (and cell (stringp (sysvar-cell-value cell))
             (sysvar-cell-value cell))
        "Standard")))

(defun %command-entity (host data)
  (%host-add-entity host data 'command))

(defun %cmd-line (host tokens)
  "LINE: points until RETURN (or Close). Consecutive points become
LINE entities; Close appends the closing segment."
  (let ((points '()) (closed nil))
    (loop
      (let ((token (first tokens)))
        (cond
          ((null tokens) (return))
          ((equal token "") (pop tokens) (return))
          ((%command-token-point token)
           (push (%command-token-point token) points)
           (pop tokens))
          ((%command-option-p token "c" "close")
           (setf closed t)
           (pop tokens)
           (return))
          (t (return)))))
    (let ((points (nreverse points))
          (layer (%current-layer-name host)))
      (loop for (a b) on points
            while b
            do (%command-entity host
                                (list (cons 0 "LINE") (cons 8 layer)
                                      (cons 10 (copy-list a))
                                      (cons 11 (copy-list b)))))
      (when (and closed (<= 3 (length points)))
        (%command-entity host
                         (list (cons 0 "LINE") (cons 8 layer)
                               (cons 10 (copy-list (first (last points))))
                               (cons 11 (copy-list (first points)))))))
    tokens))

(defun %cmd-circle (host tokens)
  "CIRCLE: center point, then radius."
  (let ((center (%command-token-point (first tokens))))
    (when center
      (pop tokens)
      (let ((radius (%command-token-number (first tokens))))
        (when radius
          (pop tokens)
          (%command-entity host
                           (list (cons 0 "CIRCLE")
                                 (cons 8 (%current-layer-name host))
                                 (cons 10 center) (cons 40 radius)))))))
  tokens)

(defparameter *text-justifications*
  ;; option -> (72-horizontal . 73-vertical)
  '(("L" . (0 . 0)) ("C" . (1 . 0)) ("R" . (2 . 0))
    ("A" . (3 . 0)) ("M" . (4 . 0)) ("F" . (5 . 0))
    ("TL" . (0 . 3)) ("TC" . (1 . 3)) ("TR" . (2 . 3))
    ("ML" . (0 . 2)) ("MC" . (1 . 2)) ("MR" . (2 . 2))
    ("BL" . (0 . 1)) ("BC" . (1 . 1)) ("BR" . (2 . 1)))
  "The TEXT command's justification options mapped onto the DXF
72 (horizontal) and 73 (vertical) group values.")

(defun %cmd-text (host tokens)
  "TEXT [_Justify OPT | _Style NAME]… POINT HEIGHT ROTATION STRING.
ROTATION is command input, read in decimal degrees (AUNITS 0, the
factory default) and stored in radians per the entget convention.
SPEC-UNCERTAIN: AUNITS/ANGDIR-sensitive angular input is not modelled
\(deferred-spec-research.issue)."
  (let ((justification '(0 . 0)) (style nil) (point nil))
    (loop
      (let ((token (first tokens)))
        (cond
          ((null tokens) (return-from %cmd-text tokens))
          ((%command-option-p token "j" "justify")
           (pop tokens)
           (let ((option (and (stringp (first tokens))
                              (string-upcase
                               (string-left-trim "_" (pop tokens))))))
             (setf justification
                   (or (cdr (assoc option *text-justifications*
                                   :test #'string-equal))
                       '(0 . 0)))))
          ((%command-option-p token "s" "style")
           (pop tokens)
           (when (stringp (first tokens))
             (setf style (pop tokens))))
          ((%command-token-point token)
           (setf point (%command-token-point token))
           (pop tokens)
           (return))
          (t (return-from %cmd-text tokens)))))
    (let ((height (%command-token-number (first tokens))))
      (unless height (return-from %cmd-text tokens))
      (pop tokens)
      (let ((rotation (%command-token-number (first tokens))))
        (unless rotation (return-from %cmd-text tokens))
        (pop tokens)
        (let ((text (first tokens)))
          (unless (stringp text) (return-from %cmd-text tokens))
          (pop tokens)
          (let ((h (car justification))
                (v (cdr justification)))
            (%command-entity
             host
             (append (list (cons 0 "TEXT")
                           (cons 8 (%current-layer-name host))
                           (cons 10 (copy-list point))
                           (cons 40 height)
                           (cons 50 (* rotation (/ pi 180.0d0)))
                           (cons 1 text)
                           (cons 7 (or style (%current-text-style-name host)))
                           (cons 72 h) (cons 73 v))
                     ;; A non-default justification aligns on group 11.
                     (unless (and (zerop h) (zerop v))
                       (list (cons 11 (copy-list point)))))))))))
  tokens)

(defun %cmd-donut (host tokens)
  "DONUT: inside diameter, outside diameter, then center points until
RETURN. Each donut is the vendors' closed two-arc LWPOLYLINE with
constant width."
  (let ((inside (%command-token-number (first tokens))))
    (unless inside (return-from %cmd-donut tokens))
    (pop tokens)
    (let ((outside (%command-token-number (first tokens))))
      (unless outside (return-from %cmd-donut tokens))
      (pop tokens)
      (let ((radius (/ (+ inside outside) 4.0d0))
            (width (/ (- outside inside) 2.0d0))
            (layer (%current-layer-name host)))
        (loop
          (let ((token (first tokens)))
            (cond
              ((null tokens) (return))
              ((equal token "") (pop tokens) (return))
              ((%command-token-point token)
               (let ((center (%command-token-point token)))
                 (pop tokens)
                 (%command-entity
                  host
                  (list (cons 0 "LWPOLYLINE")
                        (cons 100 "AcDbEntity") (cons 100 "AcDbPolyline")
                        (cons 8 layer)
                        (cons 90 2) (cons 70 1) (cons 43 width)
                        (cons 10 (list (- (first center) radius)
                                       (second center)))
                        (cons 42 1.0d0)
                        (cons 10 (list (+ (first center) radius)
                                       (second center)))
                        (cons 42 1.0d0)))))
              (t (return))))))))
  tokens)

(defun %cmd-solid (host tokens)
  "SOLID: three or four corner points, then RETURN. A three-point
solid repeats the third corner, as the vendors do."
  (let ((points '()))
    (loop
      (let ((token (first tokens)))
        (cond
          ((null tokens) (return))
          ((equal token "") (pop tokens) (return))
          ((%command-token-point token)
           (push (%command-token-point token) points)
           (pop tokens))
          (t (return)))))
    (let ((points (nreverse points)))
      (when (<= 3 (length points))
        (let ((p1 (first points)) (p2 (second points))
              (p3 (third points)) (p4 (or (fourth points) (third points))))
          (%command-entity host
                           (list (cons 0 "SOLID")
                                 (cons 8 (%current-layer-name host))
                                 (cons 10 p1) (cons 11 p2)
                                 (cons 12 p3) (cons 13 p4)))))))
  tokens)

(defun %command-selection (host tokens)
  "Consume object-selection input: live selection sets, entity-handle
tokens and the _Last option, up to the closing RETURN. Returns
\(values ENTITY-HANDLES REMAINING-TOKENS)."
  (let ((entities '()))
    (loop
      (let ((token (first tokens)))
        (cond
          ((null tokens) (return))
          ((typep token 'clautolisp.autolisp-runtime:autolisp-pickset)
           (let ((set (ignore-errors (ap->pickset host token 'command))))
             (when set
               (dolist (entity (pickset-members set))
                 (when (and entity (not (entity-handle-deleted-p entity)))
                   (push entity entities)))))
           (pop tokens))
          ((not (stringp token)) (return))
          ((equal token "") (pop tokens) (return))
          ((%command-option-p token "l" "last")
           (let* ((ename (host-entlast host))
                  (entity
                    (and ename
                         (cador-find-entity-by-handle
                          host
                          (clautolisp.autolisp-runtime:autolisp-ename-value
                           ename)))))
             (when entity (push entity entities)))
           (pop tokens))
          ((let ((entity (safe-find-entity (cador-active-drawing host)
                                           token)))
             (when entity (push entity entities) t))
           (pop tokens))
          (t (return)))))
    (values (nreverse entities) tokens)))

(defun %erase-entity-and-run (host entity)
  "Mark ENTITY and its subentity run (330-owned ATTRIBs / VERTEXes /
SEQEND) deleted."
  (dolist (handle (%entity-subentity-handles host entity))
    (let ((sub (cador-find-entity-by-handle host handle)))
      (when sub (setf (entity-handle-deleted-p sub) t))))
  (setf (entity-handle-deleted-p entity) t))

(defun %cmd-erase (host tokens)
  "ERASE: object selection, then RETURN."
  (multiple-value-bind (entities tokens) (%command-selection host tokens)
    (dolist (entity entities)
      (%erase-entity-and-run host entity))
    tokens))

(defun %cmd-move (host tokens)
  "MOVE: object selection, RETURN, base point, second point."
  (multiple-value-bind (entities tokens) (%command-selection host tokens)
    (let ((from (%command-token-point (first tokens))))
      (when from
        (pop tokens)
        (let ((to (%command-token-point (first tokens))))
          (when to
            (pop tokens)
            (let ((dx (- (first to) (first from)))
                  (dy (- (second to) (second from)))
                  (dz (- (third to) (third from))))
              (dolist (entity entities)
                (%entity-translate entity dx dy dz)
                (dolist (handle (%entity-subentity-handles host entity))
                  (let ((sub (cador-find-entity-by-handle host handle)))
                    (when sub (%entity-translate sub dx dy dz))))))))))
    tokens))

(defun %cmd-copy (host tokens)
  "COPY: object selection, RETURN, base point, second point — clones
the selection (subentity runs included) displaced by the two points."
  (multiple-value-bind (entities tokens) (%command-selection host tokens)
    (let ((from (%command-token-point (first tokens))))
      (when from
        (pop tokens)
        (let ((to (%command-token-point (first tokens))))
          (when to
            (pop tokens)
            (let ((dx (- (first to) (first from)))
                  (dy (- (second to) (second from)))
                  (dz (- (third to) (third from))))
              (dolist (entity entities)
                (let ((clone (%clone-entity-with-run host entity)))
                  (%entity-translate clone dx dy dz)
                  (dolist (handle (%entity-subentity-handles host clone))
                    (let ((sub (cador-find-entity-by-handle host handle)))
                      (when sub (%entity-translate sub dx dy dz)))))))))))
    tokens))

(defun %cmd-rotate (host tokens)
  "ROTATE: object selection, RETURN, base point, rotation angle —
command angular input, read in decimal degrees (the TEXT note on
AUNITS applies) and applied in radians."
  (multiple-value-bind (entities tokens) (%command-selection host tokens)
    (let ((base (%command-token-point (first tokens))))
      (when base
        (pop tokens)
        (let ((angle (%command-token-number (first tokens))))
          (when angle
            (pop tokens)
            (let ((radians (* angle (/ pi 180.0d0)))
                  (bx (first base))
                  (by (second base)))
              (dolist (entity entities)
                (%entity-rotate-one entity bx by radians)
                (dolist (handle (%entity-subentity-handles host entity))
                  (let ((sub (cador-find-entity-by-handle host handle)))
                    (when sub
                      (%entity-rotate-one sub bx by radians))))))))))
    tokens))

(defun %cmd-block (host tokens)
  "-BLOCK: block name, base point, object selection, RETURN. Registers
the definition and ABSORBS the selected entities into it — translated
so the base point becomes the definition origin, leaving model space —
the vendor command contract. A same-name definition is redefined (its
previous contents erased), which the SCHMS factory guarantees never
happens (it purges beforehand)."
  (let ((name (first tokens)))
    (unless (and (stringp name)
                 (plusp (length name))
                 (not (%command-token-point name))
                 (not (%command-token-number name))
                 (not (equal name "?")))
      (return-from %cmd-block tokens))
    (pop tokens)
    (let ((base (%command-token-point (first tokens))))
      (unless base (return-from %cmd-block tokens))
      (pop tokens)
      (multiple-value-bind (entities tokens) (%command-selection host tokens)
        ;; Redefinition: the previous contents are erased.
        (when (cador-find-table-record host :block-record name)
          (loop for handle in (cador-creation-order host)
                for entity = (gethash handle (cador-entities host))
                when (and entity
                          (entity-handle-block entity)
                          (string-equal (entity-handle-block entity) name))
                  do (setf (entity-handle-deleted-p entity) t)))
        (let ((header (list (cons 0 "BLOCK") (cons 2 name) (cons 70 0)
                            (cons 10 (list 0.0d0 0.0d0 0.0d0)))))
          (cador-add-table-record
           host (make-symbol-table-record :kind :block-record
                                          :name name :data header))
          (clautolisp.drawing:add-block (cador-active-drawing host)
                                        name header))
        (let ((dx (- (first base)))
              (dy (- (second base)))
              (dz (- (third base))))
          (dolist (entity entities)
            (setf (entity-handle-block entity) name)
            (%entity-translate entity dx dy dz)
            (dolist (handle (%entity-subentity-handles host entity))
              (let ((sub (cador-find-entity-by-handle host handle)))
                (when sub
                  (setf (entity-handle-block sub) name)
                  (%entity-translate sub dx dy dz))))))
        tokens))))

;;; --- The 14 SCHMS-driven commands (schms-call-inventory §7/§9) ----
;;;
;;; The SCHMS+ corpus drives 21 vendor commands through (command ...); the 10
;;; above cover LINE/CIRCLE/TEXT/DONUT/SOLID/ERASE/MOVE/COPY/ROTATE/BLOCK. The
;;; handlers below add the remaining ones so a driven sequence keeps flowing
;;; (%EXECUTE-COMMAND-TOKENS stops at the first UNKNOWN name — a recognised
;;; no-op still consumes its tokens and lets the next command run). Geometry and
;;; table commands mutate the model; ZOOM/UCS/BROWSER/SHELL and the deferred
;;; edit paths (BREAK/PEDIT) are recognised token-consumers with no model effect
;;; (correct for the viewport/OS commands; a documented approximation for the
;;; edit ones). Malformed input still degrades to record-only — never a signal.

(defun %plain-string-token (token)
  "TOKEN as a name/value string: a non-empty string that is not the PAUSE
token and does not read as a coordinate point. Numbers pass (they are strings
here); callers that need a number use %COMMAND-TOKEN-NUMBER."
  (and (stringp token)
       (plusp (length token))
       (not (string= token "\\"))
       (not (%command-token-point token))
       token))

(defun %explicit-command-token-p (token)
  "True when TOKEN is an explicit command invocation — the SCHMS idiom drives
commands DOT-prefixed (`._LINE', `.LINE'), and the console dash forms
(`-INSERT', `-LAYER') are dash+letter. An option like `_e' (underscore only)
is NOT one. Used to find where a following command begins amid free-text input
(a no-op's tail, INSERT attribute values), which a bare word cannot be told
apart from otherwise."
  (and (stringp token)
       (>= (length token) 2)
       (or (char= (char token 0) #\.)                     ; ._CMD / .CMD
           (and (char= (char token 0) #\-)                ; -CMD dash form
                (alpha-char-p (char token 1))))))

(defun %consume-through-return (tokens)
  "Drop a no-op command's remaining input: tokens up to and including the first
RETURN (\"\"), stopping early at the next EXPLICIT (dot/dash-prefixed) command
so a following `._LINE'/`-INSERT' still runs. Options like `_e' are consumed."
  (loop
    (cond ((null tokens) (return tokens))
          ((equal (first tokens) "") (return (rest tokens)))
          ((%explicit-command-token-p (first tokens)) (return tokens))
          (t (pop tokens)))))

(defun %collect-points (tokens)
  "Collect leading coordinate points; returns (values POINTS REMAINING). A
Close/RETURN or any non-point ends collection (RETURN is consumed)."
  (let ((points '()) (closed nil))
    (loop
      (let ((token (first tokens)))
        (cond
          ((null tokens) (return))
          ((equal token "") (pop tokens) (return))
          ((%command-token-point token)
           (push (%command-token-point token) points) (pop tokens))
          ((%command-option-p token "c" "close") (setf closed t) (pop tokens) (return))
          (t (return)))))
    (values (nreverse points) tokens closed)))

;;; ARC — 3-point (start, second-on-arc, end) circumscription.

(defun %circumscribe (p1 p2 p3)
  "Center (x y) and radius of the circle through three 2D points, or NIL when
they are collinear."
  (let* ((ax (first p1)) (ay (second p1))
         (bx (first p2)) (by (second p2))
         (cx (first p3)) (cy (second p3))
         (d (* 2.0d0 (+ (* ax (- by cy)) (* bx (- cy ay)) (* cx (- ay by))))))
    (when (> (abs d) 1d-9)
      (let* ((a2 (+ (* ax ax) (* ay ay)))
             (b2 (+ (* bx bx) (* by by)))
             (c2 (+ (* cx cx) (* cy cy)))
             (ux (/ (+ (* a2 (- by cy)) (* b2 (- cy ay)) (* c2 (- ay by))) d))
             (uy (/ (+ (* a2 (- cx bx)) (* b2 (- ax cx)) (* c2 (- bx ax))) d)))
        (values (list ux uy)
                (sqrt (+ (expt (- ax ux) 2) (expt (- ay uy) 2))))))))

(defun %ccw-between-p (a b x)
  "True when angle X lies on the CCW sweep from A to B (all radians)."
  (flet ((norm (v) (mod v (* 2.0d0 pi))))
    (<= (norm (- x a)) (norm (- b a)))))

(defun %cmd-arc (host tokens)
  "ARC: three points (start, a point on the arc, end) -> an ARC entity with
CCW start/end angles (group 50/51) oriented so the middle point lies on it.
The Center/Angle keyword forms degrade to record-only."
  (multiple-value-bind (points tokens) (%collect-points tokens)
    (when (= (length points) 3)
      (destructuring-bind (p1 p2 p3) points
        (multiple-value-bind (center radius) (%circumscribe p1 p2 p3)
          (when center
            (let* ((cx (first center)) (cy (second center))
                   (a1 (atan (- (second p1) cy) (- (first p1) cx)))
                   (a2 (atan (- (second p2) cy) (- (first p2) cx)))
                   (a3 (atan (- (second p3) cy) (- (first p3) cx))))
              (multiple-value-bind (start end)
                  (if (%ccw-between-p a1 a3 a2) (values a1 a3) (values a3 a1))
                (%command-entity
                 host
                 (list (cons 0 "ARC") (cons 8 (%current-layer-name host))
                       (cons 10 (list cx cy 0.0d0)) (cons 40 radius)
                       (cons 50 start) (cons 51 end)))))))))
    tokens))

(defun %cmd-pline (host tokens)
  "PLINE: vertex points until Close/RETURN -> one LWPOLYLINE. The Arc/Width/
Halfwidth/Length/Undo sub-keywords are consumed (their parameters skipped) so
the polyline still forms through the entered vertices; arc bulges are not
modelled (a straight-segment approximation)."
  (let ((points '()) (closed nil))
    (loop
      (let ((token (first tokens)))
        (cond
          ((null tokens) (return))
          ((equal token "") (pop tokens) (return))
          ((%command-token-point token)
           (push (%command-token-point token) points) (pop tokens))
          ((%command-option-p token "c" "close") (setf closed t) (pop tokens) (return))
          ((%command-option-p token "a" "arc" "l" "line" "u" "undo") (pop tokens))
          ((%command-option-p token "w" "width" "h" "halfwidth")
           (pop tokens)
           (when (%command-token-number (first tokens)) (pop tokens))  ; start
           (when (%command-token-number (first tokens)) (pop tokens))) ; end
          (t (return)))))
    (let ((points (nreverse points)))
      (when (<= 2 (length points))
        (%command-entity
         host
         (append (list (cons 0 "LWPOLYLINE")
                       (cons 100 "AcDbEntity") (cons 100 "AcDbPolyline")
                       (cons 8 (%current-layer-name host))
                       (cons 90 (length points))
                       (cons 70 (if closed 1 0)))
                 (mapcar (lambda (p) (cons 10 (list (first p) (second p)))) points)))))
    tokens))

(defun %cmd-mtext (host tokens)
  "MTEXT: first corner point, an optional opposite corner (its width goes to
group 41), then the text line(s) until RETURN -> an MTEXT entity. The
interactive Height/Justify/Rotation sub-prompts are consumed; height defaults
to the current TEXTSIZE (or 2.5)."
  (let ((point (%command-token-point (first tokens))))
    (unless point (return-from %cmd-mtext tokens))
    (pop tokens)
    (let ((width nil))
      (when (%command-token-point (first tokens))
        (let ((corner (%command-token-point (pop tokens))))
          (setf width (abs (- (first corner) (first point))))))
      ;; consume any sub-keyword + its argument until we reach the text/RETURN
      (loop while (and (stringp (first tokens))
                       (%command-option-p (first tokens)
                                          "h" "height" "j" "justify" "r" "rotation"
                                          "l" "linespacing" "s" "style" "w" "width" "c" "columns")
                       (rest tokens))
            do (pop tokens) (pop tokens))
      (let ((lines '()))
        (loop
          (let ((token (first tokens)))
            (cond ((null tokens) (return))
                  ((equal token "") (pop tokens) (return))
                  ((%plain-string-token token) (push (pop tokens) lines))
                  (t (return)))))
        (let ((height (or (let ((c (ignore-errors (cador-sysvar host "TEXTSIZE"))))
                            (and c (numberp (sysvar-cell-value c))
                                 (plusp (sysvar-cell-value c))
                                 (coerce (sysvar-cell-value c) 'double-float)))
                          2.5d0)))
          (%command-entity
           host
           (append (list (cons 0 "MTEXT")
                         (cons 100 "AcDbEntity") (cons 100 "AcDbMText")
                         (cons 8 (%current-layer-name host))
                         (cons 10 (copy-list point)) (cons 40 height)
                         (cons 71 1)
                         (cons 7 (%current-text-style-name host))
                         (cons 1 (format nil "~{~A~^\\P~}" (nreverse lines))))
                   (when (and width (plusp width)) (list (cons 41 width)))))))))
  tokens)

(defun %cmd-wipeout (host tokens)
  "WIPEOUT: boundary points until RETURN -> a WIPEOUT entity carrying the
boundary vertices (group 10 per vertex). The Frames/Polyline keyword forms are
consumed (Polyline additionally swallows its selection)."
  (let ((token (first tokens)))
    (cond
      ((%command-option-p token "f" "frames")
       (pop tokens)
       (when (stringp (first tokens)) (pop tokens))  ; ON/OFF
       (return-from %cmd-wipeout tokens))
      ((%command-option-p token "p" "polyline")
       (pop tokens)
       (return-from %cmd-wipeout (nth-value 1 (%command-selection host tokens))))))
  (multiple-value-bind (points tokens) (%collect-points tokens)
    (when (<= 3 (length points))
      (%command-entity
       host
       (append (list (cons 0 "WIPEOUT")
                     (cons 100 "AcDbEntity") (cons 100 "AcDbWipeout")
                     (cons 8 (%current-layer-name host))
                     (cons 90 (length points)))
               (mapcar (lambda (p) (cons 10 (list (first p) (second p)))) points))))
    tokens))

;;; MIRROR — reflect a selection across a line; optionally erase the source.

(defun %entity-mirror (entity x1 y1 x2 y2)
  "Reflect ENTITY's point groups across the line (x1 y1)-(x2 y2), and flip the
rotation (group 50) of angle-bearing kinds about the line's bearing."
  (let* ((a (- x2 x1)) (b (- y2 y1)) (den (+ (* a a) (* b b))))
    (when (> den 1d-12)
      (%entity-map-point-groups
       entity
       (lambda (p)
         (let* ((px (coerce (first p) 'double-float))
                (py (coerce (second p) 'double-float))
                (vx (- px x1)) (vy (- py y1))
                (factor (/ (+ (* a vx) (* b vy)) den))
                (rx (+ x1 (- (* 2.0d0 a factor) vx)))
                (ry (+ y1 (- (* 2.0d0 b factor) vy))))
           (if (cddr p) (list rx ry (coerce (third p) 'double-float)) (list rx ry)))))
      (when (member (entity-handle-kind entity)
                    '(:text :mtext :attrib :attdef :insert))
        (let ((line-angle (atan b a)))
          (%entity-set-group entity 50
                             (- (* 2.0d0 line-angle)
                                (coerce (or (%entity-group-value entity 50) 0.0d0)
                                        'double-float))))))))

(defun %cmd-mirror (host tokens)
  "MIRROR: object selection, RETURN, two mirror-line points, then the
Delete-source answer (Yes/No; default No). Clones the selection reflected
across the line, erasing the originals when the source is deleted."
  (multiple-value-bind (entities tokens) (%command-selection host tokens)
    (let ((p1 (%command-token-point (first tokens))))
      (when p1
        (pop tokens)
        (let ((p2 (%command-token-point (first tokens))))
          (when p2
            (pop tokens)
            (let* ((delete-source
                     (and (%command-option-p (first tokens) "y" "yes")
                          (progn (pop tokens) t)))
                   (x1 (first p1)) (y1 (second p1))
                   (x2 (first p2)) (y2 (second p2)))
              (when (%command-option-p (first tokens) "n" "no") (pop tokens))
              (dolist (entity entities)
                (let ((clone (%clone-entity-with-run host entity)))
                  (%entity-mirror clone x1 y1 x2 y2)
                  (dolist (handle (%entity-subentity-handles host clone))
                    (let ((sub (cador-find-entity-by-handle host handle)))
                      (when sub (%entity-mirror sub x1 y1 x2 y2)))))
                (when delete-source (%erase-entity-and-run host entity))))))))
    tokens))

;;; INSERT — a block reference.

(defun %cmd-insert (host tokens)
  "INSERT / -INSERT: block name, insertion point, then optional X/Y/Z scale and
rotation numbers (RETURN-defaults skipped) -> an INSERT entity (group
2/10/41/42/43/50, 66=0). Any attribute-value tokens (present when ATTREQ is on)
are consumed so the driven sequence keeps flowing, but are not modelled as
ATTRIB subentities in this slice — that needs the block's attdef tags, which
the (command …) token stream does not carry (deferred, schms-call-inventory §9)."
  (let ((name (%plain-string-token (first tokens))))
    (unless (and name (%command-name (first tokens))
                 (not (%command-option-p name "?")))
      (return-from %cmd-insert tokens))
    (pop tokens)
    (let ((point (%command-token-point (first tokens))))
      (unless point (return-from %cmd-insert tokens))
      (pop tokens)
      ;; optional scales + rotation: consume up to three leading numbers,
      ;; skipping RETURN defaults; stop at the first attribute value / command.
      (flet ((next-number (default)
               (cond ((and (stringp (first tokens)) (equal (first tokens) ""))
                      (pop tokens) default)
                     ((%command-token-number (first tokens))
                      (%command-token-number (pop tokens)))
                     (t default))))
        (let* ((xscale (next-number 1.0d0))
               (yscale (next-number xscale))
               (rotation (next-number 0.0d0))
               (attreq (let ((c (ignore-errors (cador-sysvar host "ATTREQ"))))
                         (or (null c) (not (eql (sysvar-cell-value c) 0))))))
          (%command-entity
           host
           (list (cons 0 "INSERT")
                 (cons 100 "AcDbEntity") (cons 100 "AcDbBlockReference")
                 (cons 8 (%current-layer-name host))
                 (cons 2 name) (cons 10 (copy-list point))
                 (cons 41 (coerce xscale 'double-float))
                 (cons 42 (coerce yscale 'double-float))
                 (cons 43 1.0d0)
                 (cons 50 (* (coerce rotation 'double-float) (/ pi 180.0d0)))
                 (cons 66 0)))
          ;; consume trailing attribute values (up to RETURN / the next command)
          (when attreq
            (loop
              (let ((token (first tokens)))
                (cond ((null tokens) (return))
                      ((equal token "") (pop tokens) (return))
                      ((%explicit-command-token-p token) (return))
                      ((%command-token-point token) (return))
                      ((%plain-string-token token) (pop tokens))
                      (t (return))))))))))
  tokens)

;;; LAYER / LINETYPE — symbol-table maintenance.

(defun %ensure-layer (host name)
  (unless (cador-find-table-record host :layer name)
    (cador-add-table-record
     host (make-symbol-table-record
           :kind :layer :name name
           :data (list (cons 0 "LAYER") (cons 2 name) (cons 70 0)
                       (cons 62 7) (cons 6 "Continuous")))))
  name)

(defun %cmd-layer (host tokens)
  "LAYER / -LAYER: an option loop until RETURN. New/Make create layer records
(Make also sets CLAYER, Set sets CLAYER creating the layer if needed); Color
and Ltype are applied to the named layer; the state keywords
(On/Off/Freeze/Thaw/Lock/Unlock/Plot) are consumed. Comma-separated name lists
are honoured (New/Off/... accept them)."
  (flet ((names (token) (%split-string-on #\, token)))
    (loop
      (let ((token (first tokens)))
        (cond
          ((null tokens) (return))
          ((equal token "") (pop tokens) (return))
          ((%command-option-p token "n" "new")
           (pop tokens)
           (when (%plain-string-token (first tokens))
             (mapc (lambda (n) (%ensure-layer host n)) (names (pop tokens)))))
          ((%command-option-p token "m" "make")
           (pop tokens)
           (when (%plain-string-token (first tokens))
             (let ((n (pop tokens))) (%ensure-layer host n)
               (cador-set-sysvar host "CLAYER" n))))
          ((%command-option-p token "s" "set")
           (pop tokens)
           (when (%plain-string-token (first tokens))
             (let ((n (pop tokens))) (%ensure-layer host n)
               (cador-set-sysvar host "CLAYER" n))))
          ((%command-option-p token "c" "color" "colour")
           (pop tokens)
           (let ((color (and (%plain-string-token (first tokens)) (pop tokens)))
                 (who (and (%plain-string-token (first tokens)) (pop tokens))))
             (declare (ignore color))
             (when who (mapc (lambda (n) (%ensure-layer host n)) (names who)))))
          ((%command-option-p token "l" "ltype" "linetype")
           (pop tokens)
           (let ((lt (and (%plain-string-token (first tokens)) (pop tokens)))
                 (who (and (%plain-string-token (first tokens)) (pop tokens))))
             (declare (ignore lt))
             (when who (mapc (lambda (n) (%ensure-layer host n)) (names who)))))
          ((%command-option-p token "on" "off" "f" "freeze" "t" "thaw"
                                    "lo" "lock" "u" "unlock" "p" "plot" "a" "?")
           (pop tokens)
           (when (%plain-string-token (first tokens)) (pop tokens)))
          (t (return)))))
    tokens))

(defun %cmd-linetype (host tokens)
  "LINETYPE / -LINETYPE: Load creates an :ltype record (its definition file is
ignored — the mock has none); Set sets CELTYPE; Create is consumed. The loop
ends at RETURN."
  (loop
    (let ((token (first tokens)))
      (cond
        ((null tokens) (return))
        ((equal token "") (pop tokens) (return))
        ((%command-option-p token "l" "load")
         (pop tokens)
         (when (%plain-string-token (first tokens))
           (let ((n (pop tokens)))
             (unless (cador-find-table-record host :ltype n)
               (cador-add-table-record
                host (make-symbol-table-record
                      :kind :ltype :name n
                      :data (list (cons 0 "LTYPE") (cons 2 n) (cons 70 0)
                                  (cons 3 "") (cons 72 65) (cons 73 0)
                                  (cons 40 0.0d0)))))
             (when (%plain-string-token (first tokens)) (pop tokens))))) ; file
        ((%command-option-p token "s" "set")
         (pop tokens)
         (when (%plain-string-token (first tokens))
           (cador-set-sysvar host "CELTYPE" (pop tokens))))
        ((%command-option-p token "c" "create")
         (pop tokens)
         (when (%plain-string-token (first tokens)) (pop tokens)))
        (t (return)))))
  tokens)

(defun %cmd-recognised-noop (host tokens)
  "ZOOM / UCS / PEDIT / BREAK / BROWSER / SHELL: recognised so the dispatch
keeps flowing, but with no model-space effect. ZOOM/UCS are viewport/coordinate
context (cador is model-only, WCS); BROWSER/SHELL launch external processes
(no-ops headless); PEDIT/BREAK are edit paths whose geometry is deferred
(schms-call-inventory §9). Swallows the command's remaining input line."
  (declare (ignore host))
  (%consume-through-return tokens))

(defun %execute-command-tokens (host tokens)
  "Interpret TOKENS — one HOST-COMMAND call's normalized sequence —
executing the drawing commands the engine knows; the first unknown
command name stops interpretation (the sequence stays recorded on the
command log either way). Never signals."
  (handler-case
      (loop while tokens
            do (let ((name (%command-name (first tokens))))
                 (unless name (return))
                 (setf tokens (rest tokens))
                 (setf tokens
                       (cond
                         ((string= name "LINE")   (%cmd-line host tokens))
                         ((string= name "CIRCLE") (%cmd-circle host tokens))
                         ((string= name "TEXT")   (%cmd-text host tokens))
                         ((string= name "DONUT")  (%cmd-donut host tokens))
                         ((string= name "SOLID")  (%cmd-solid host tokens))
                         ((string= name "ERASE")  (%cmd-erase host tokens))
                         ((string= name "MOVE")   (%cmd-move host tokens))
                         ((string= name "COPY")   (%cmd-copy host tokens))
                         ((string= name "ROTATE") (%cmd-rotate host tokens))
                         ;; -BLOCK is the explicitly-defined console
                         ;; form of BLOCK; on this TUI-only host the
                         ;; dialog form projects onto the same console
                         ;; grammar, so both spellings run it.
                         ((or (string= name "-BLOCK")
                              (string= name "BLOCK"))
                          (%cmd-block host tokens))
                         ;; The 14 SCHMS-driven commands (schms-call-inventory §9).
                         ((string= name "ARC")      (%cmd-arc host tokens))
                         ((string= name "PLINE")    (%cmd-pline host tokens))
                         ((string= name "MTEXT")    (%cmd-mtext host tokens))
                         ((string= name "WIPEOUT")  (%cmd-wipeout host tokens))
                         ((string= name "MIRROR")   (%cmd-mirror host tokens))
                         ((or (string= name "INSERT")
                              (string= name "-INSERT"))
                          (%cmd-insert host tokens))
                         ((or (string= name "LAYER")
                              (string= name "-LAYER"))
                          (%cmd-layer host tokens))
                         ((or (string= name "LINETYPE")
                              (string= name "-LINETYPE"))
                          (%cmd-linetype host tokens))
                         ;; Recognised, but model-only no-ops (viewport /
                         ;; coordinate context / external process / deferred
                         ;; edit): consume the input line and keep flowing.
                         ((member name '("ZOOM" "UCS" "PEDIT" "BREAK"
                                         "BROWSER" "SHELL")
                                  :test #'string=)
                          (%cmd-recognised-noop host tokens))
                         (t (return))))))
    (error () nil))
  nil)

(defmethod host-command-log ((host cador))
  (reverse (cador-command-log host)))
