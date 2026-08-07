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
  "The upcased command name of TOKEN with the \".\" (English), \"_\"
\(non-localized) and \"-\" (command-line form) prefixes stripped; NIL
for tokens that read as data (numbers, points, RETURN, PAUSE)."
  (and (stringp token)
       (plusp (length token))
       (not (string= token "\\"))
       (not (%command-token-point token))
       (not (%command-token-number token))
       (let ((name (string-left-trim "._-" token)))
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
                         (t (return))))))
    (error () nil))
  nil)

(defmethod host-command-log ((host cador))
  (reverse (cador-command-log host)))
