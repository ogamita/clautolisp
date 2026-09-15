(in-package #:clautolisp.cador.tests)

(in-suite cador-suite)

;;; --- Command dispatch (deferred-command-special-form issue) -------
;;;
;;; MockHost has no command engine: HOST-COMMAND records the routed
;;; token sequence on the per-session command log, echoes one line to
;;; PROMPT-OUTPUT, and returns nil. HOST-COMMAND-LOG reads the log
;;; back oldest-first.

(test host-command-records-tokens-and-returns-nil
  (let ((mock (make-cador)))
    (is (null (clautolisp.autolisp-host:host-command
               mock '("._LINE" "0.0,0.0,0.0" "10.0,10.0,0.0" ""))))
    (is (equal '(("._LINE" "0.0,0.0,0.0" "10.0,10.0,0.0" ""))
               (clautolisp.autolisp-host:host-command-log mock)))))

(test host-command-log-is-oldest-first
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command mock '("._LINE"))
    (clautolisp.autolisp-host:host-command mock '("._CIRCLE" "1,2" "5.5"))
    (is (equal '(("._LINE") ("._CIRCLE" "1,2" "5.5"))
               (clautolisp.autolisp-host:host-command-log mock)))))

(test host-command-echoes-to-prompt-output
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command mock '("._LINE" "" "\\"))
    (let ((echo (get-output-stream-string (cador-prompt-output mock))))
      (is (search "Command: ._LINE <RETURN> <PAUSE>" echo)))))

(test host-command-empty-sequence-is-a-cancel
  (let ((mock (make-cador)))
    (is (null (clautolisp.autolisp-host:host-command mock '())))
    (is (equal '(()) (clautolisp.autolisp-host:host-command-log mock)))
    (is (search "Command: *Cancel*"
                (get-output-stream-string (cador-prompt-output mock))))))

;;; --- The drawing-command engine ----------------------------------
;;; (Regression for the SCHMS sigfic fixtures, whose block factories
;;; DRAW through the command channel — ._donut/._line/._text/._solid —
;;; then clone the drawn entities into an entmake BLOCK/ENDBLK pair.)

(defun %ct-types (mock)
  "The group-0 kinds of MOCK's live main-space entities, oldest first."
  (let ((types '()) (e (host-entnext mock nil)))
    (loop while e
          do (push (autolisp-string-value
                    (cdr (assoc 0 (host-entget mock e))))
                   types)
             (setq e (host-entnext mock e)))
    (nreverse types)))

(test command-line-draws-line-entities
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command
     mock '("._line" "0.0,0.0,0.0" "10.0,10.0,0.0" ""))
    (is (equal '("LINE") (%ct-types mock)))
    ;; Chained points make consecutive segments; Close appends one.
    (clautolisp.autolisp-host:host-command
     mock '("._line" "0,0" "1,0" "1,1" "_c"))
    (is (equal '("LINE" "LINE" "LINE" "LINE") (%ct-types mock)))))

(test command-text-justified-draws-a-text-entity
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command
     mock '("._text" "_j" "_tl" "5.0,6.0,0.0" "3.5" "0.0" "NOM DU SIGNAL"))
    (let* ((e (host-entnext mock nil))
           (data (host-entget mock e)))
      (is (string= "TEXT" (autolisp-string-value (cdr (assoc 0 data)))))
      (is (string= "NOM DU SIGNAL"
                   (autolisp-string-value (cdr (assoc 1 data)))))
      (is (= 3.5d0 (cdr (assoc 40 data))))
      ;; _TL -> horizontal left (72=0), vertical top (73=3), aligned
      ;; on group 11.
      (is (eql 0 (cdr (assoc 72 data))))
      (is (eql 3 (cdr (assoc 73 data))))
      (is (consp (cdr (assoc 11 data)))))))

(test command-donut-and-solid-draw-their-entities
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command
     mock '("._donut" "0" "2" "1.0,1.0,0.0" ""))
    (clautolisp.autolisp-host:host-command
     mock '("._solid" "0,0" "1,0" "0,1" "0,1" ""))
    (is (equal '("LWPOLYLINE" "SOLID") (%ct-types mock)))
    ;; The donut is a closed constant-width two-arc polyline.
    (let* ((e (host-entnext mock nil))
           (data (host-entget mock e)))
      (is (eql 1 (cdr (assoc 70 data))))
      (is (= 1.0d0 (cdr (assoc 43 data)))))))

(test command-unknown-commands-stay-record-only
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command
     mock '("._regen"))
    (clautolisp.autolisp-host:host-command
     mock '("._zoom" "_e"))
    (is (null (%ct-types mock)))
    (is (= 2 (length (clautolisp.autolisp-host:host-command-log mock))))))

(test command-drawn-entities-clone-into-a-block-pair
  ;; The schms_creer_bloc shape: draw via commands, walk the new
  ;; entities, entmake BLOCK, clone each with (entmake (entget e)),
  ;; entdel the originals, entmake ENDBLK — then the block holds the
  ;; drawn shapes and model space is clean.
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command
     mock '("._donut" "0" "2" "0.0,0.0,0.0" ""))
    (clautolisp.autolisp-host:host-command
     mock '("._line" "0.0,0.0,0.0" "0.0,6.0,0.0" ""))
    (clautolisp.autolisp-host:host-command
     mock '("._text" "_j" "_tl" "1.0,9.0,0.0" "3.5" "0.0" "S1"))
    (clautolisp.autolisp-host:host-command
     mock '("._line" "0.0,6.0,0.0" "8.0,6.0,0.0" ""))
    (clautolisp.autolisp-host:host-command
     mock '("._solid" "8,6" "6,7" "6,5" "6,5" ""))
    (let ((drawn '()) (e (host-entnext mock nil)))
      (loop while e do (push e drawn) (setq e (host-entnext mock e)))
      (setq drawn (nreverse drawn))
      (is (= 5 (length drawn)))
      (host-entmake mock (list (cons 0 "BLOCK") (cons 2 "SIGFIC_CMD")
                               (cons 70 2) (list 10 0.0d0 0.0d0 0.0d0)))
      (dolist (old drawn)
        (host-entmake mock (host-entget mock old)))
      (dolist (old drawn)
        (host-entdel mock old))
      (host-entmake mock (list (cons 0 "ENDBLK")))
      ;; Model space is empty again; the block holds the five clones,
      ;; two of them LINEs — the SCHMS fixture check.
      (is (null (host-entnext mock nil)))
      (let* ((data (host-tblsearch mock "BLOCK" "SIGFIC_CMD"))
             (entry (cdr (assoc -2 data)))
             (types '()))
        (let ((e entry))
          (loop while e
                do (push (autolisp-string-value
                          (cdr (assoc 0 (host-entget mock e))))
                         types)
                   (setq e (host-entnext mock e))))
        (setq types (nreverse types))
        (is (= 5 (length types)))
        (is (= 2 (count "LINE" types :test #'string=)))))))

;;; --- Selection sets through the command channel ------------------
;;; (Regression for the SCHMS "(command \"._erase\" ss \"\")" idiom:
;;; a live selection set is a valid COMMAND argument and the engine
;;; consumes it as object selection.)

(test command-erase-consumes-a-selection-set
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command
     mock '("._line" "0,0" "1,1" ""))
    (clautolisp.autolisp-host:host-command
     mock '("._line" "2,2" "3,3" ""))
    (let ((ss (host-ssget mock nil :mode "X")))
      (is (not (null ss)))
      (clautolisp.autolisp-host:host-command
       mock (list "._erase" ss ""))
      ;; Both lines gone; the database walk is empty.
      (is (null (host-entnext mock nil)))
      (is (null (host-entlast mock))))))

(test command-erase-accepts-the-last-option-and-handles
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command
     mock '("._line" "0,0" "1,1" ""))
    (clautolisp.autolisp-host:host-command
     mock (list "._erase" "_l" ""))
    (is (null (host-entnext mock nil)))))

(test command-move-translates-the-selection
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command
     mock '("._line" "0,0" "1,0" ""))
    (let ((ss (host-ssget mock nil :mode "X")))
      (clautolisp.autolisp-host:host-command
       mock (list "._move" ss "" "0,0" "10.0,5.0"))
      (let* ((e (host-entnext mock nil))
             (data (host-entget mock e))
             (p10 (cdr (assoc 10 data))))
        (is (= 10.0d0 (first p10)))
        (is (= 5.0d0 (second p10)))))))

(test command-copy-clones-the-selection-displaced
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command
     mock '("._line" "0,0" "1,0" ""))
    (let ((ss (host-ssget mock nil :mode "X")))
      (clautolisp.autolisp-host:host-command
       mock (list "._copy" ss "" "0,0" "5.0,0.0"))
      ;; Two lines now: the original at x=0, the clone at x=5.
      (let ((firsts '()) (e (host-entnext mock nil)))
        (loop while e
              do (push (first (cdr (assoc 10 (host-entget mock e)))) firsts)
                 (setq e (host-entnext mock e)))
        (is (equal '(0.0d0 5.0d0) (sort firsts #'<)))))))

;;; --- The -BLOCK / ROTATE commands (the SCHMS block factory path) --
;;; (schms_creer_bloc: draw via commands, optionally ROTATE the
;;; selection, then "-block" NAME BASE SELECTION "" — the dash form is
;;; the same command with its UI projected on the console TUI.)

(test command-block-registers-and-absorbs-the-selection
  (let ((mock (make-cador)))
    ;; Two lines drawn around (100 50).
    (clautolisp.autolisp-host:host-command
     mock '("._line" "100,50" "100,56" ""))
    (clautolisp.autolisp-host:host-command
     mock '("._line" "100,56" "108,56" ""))
    (let ((ss (host-ssget mock nil :mode "X")))
      (clautolisp.autolisp-host:host-command
       mock (list "_.-block" "sigfic_1" "100,50" ss ""))
      ;; The definition exists; model space is empty (the entities
      ;; were absorbed); the block holds the two lines translated so
      ;; the base point is the origin.
      (is (not (null (cador-find-table-record mock :block-record "sigfic_1"))))
      (is (null (host-entnext mock nil)))
      (let* ((data (host-tblsearch mock "BLOCK" "sigfic_1"))
             (entry (cdr (assoc -2 data)))
             (first-data (host-entget mock entry))
             (p10 (cdr (assoc 10 first-data))))
        (is (typep entry 'autolisp-ename))
        (is (= 0.0d0 (first p10)))
        (is (= 0.0d0 (second p10)))
        (let ((second-entity (host-entnext mock entry)))
          (is (typep second-entity 'autolisp-ename))
          (is (null (host-entnext mock second-entity))))))))

(test command-rotate-rotates-the-selection-about-the-base
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command
     mock '("._line" "0,0" "1,0" ""))
    (let ((ss (host-ssget mock nil :mode "X")))
      ;; Rotate a quarter turn (command input in decimal degrees).
      (clautolisp.autolisp-host:host-command
       mock (list "_.rotate" ss "" "0,0" "90.0"))
      (let* ((e (host-entnext mock nil))
             (data (host-entget mock e))
             (p11 (cdr (assoc 11 data))))
        (is (< (abs (first p11)) 1d-9))
        (is (< (abs (- 1.0d0 (second p11))) 1d-9))))))

(test block-absorption-translates-every-polyline-vertex
  ;; The donut LWPOLYLINE has one 10 group per vertex: -BLOCK's
  ;; translation to the base point must transform them ALL (1.8.19
  ;; regression: only the first was translated, corrupting the
  ;; geometry and the bas/haut discrimination).
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command
     mock '("._donut" "0" "2" "100.0,50.0,0.0" ""))
    (let ((ss (host-ssget mock nil :mode "X")))
      (clautolisp.autolisp-host:host-command
       mock (list "_.-block" "sigfic_d" "100,50" ss "")))
    (let* ((data (host-tblsearch mock "BLOCK" "sigfic_d"))
           (entry (cdr (assoc -2 data)))
           (view (host-entget mock entry))
           (vertices (loop for pair in view
                           when (and (consp pair) (eql 10 (car pair)))
                             collect (cdr pair))))
      (is (= 2 (length vertices)))
      ;; Both vertices are local now: x = ±0.5, y = 0.
      (is (every (lambda (v) (< (abs (second v)) 1d-9)) vertices))
      (is (< (abs (+ 0.5d0 (first (first vertices)))) 1d-9))
      (is (< (abs (- 0.5d0 (first (second vertices)))) 1d-9)))))

(test insert-boundingbox-covers-every-vertex-and-discriminates-side
  ;; A bas-drawn shape (all geometry at or below the insertion point)
  ;; must yield a bounding box that stays below it — the SCHMS côté
  ;; BAS check.
  (let ((mock (make-cador)))
    ;; Donut at the insertion, vertical line going DOWN (côté bas).
    (clautolisp.autolisp-host:host-command
     mock '("._donut" "0" "2" "100.0,50.0,0.0" ""))
    (clautolisp.autolisp-host:host-command
     mock '("._line" "100,50" "100,44" ""))
    (let ((ss (host-ssget mock nil :mode "X")))
      (clautolisp.autolisp-host:host-command
       mock (list "_.-block" "sigfic_b" "100,50" ss "")))
    (let* ((doc (%tv-active-document mock))
           (modelspace (host-vlax-get-property mock doc "ModelSpace"))
           (ref (host-vlax-invoke-method
                 mock modelspace "InsertBlock"
                 (list (list 100.0d0 50.0d0 0.0d0) "sigfic_b"
                       1.0d0 1.0d0 1.0d0 0.0d0)))
           (box (host-vlax-invoke-method mock ref "GetBoundingBox" '()))
           (min-corner (first box))
           (max-corner (second box)))
      ;; max-y == insertion y (nothing above), min-y == 44 (the line).
      (is (< (abs (- 50.0d0 (second max-corner))) 1d-9))
      (is (< (abs (- 44.0d0 (second min-corner))) 1d-9))
      ;; x spread is the donut's, centred on the insertion.
      (is (< (abs (- 99.5d0 (first min-corner))) 1d-9))
      (is (< (abs (- 100.5d0 (first max-corner))) 1d-9)))))

;;; --- The 14 SCHMS-driven commands (schms-call-inventory §9) -------
;;; ARC / PLINE / MTEXT / WIPEOUT / MIRROR / INSERT / LAYER / LINETYPE
;;; mutate the model; ZOOM / UCS / PEDIT / BREAK / BROWSER / SHELL are
;;; recognised so a driven sequence keeps flowing past them.

(defun %ct-last-data (mock)
  "The entget data of MOCK's most recently created entity."
  (host-entget mock (host-entlast mock)))

(defun %ct-group (data code)
  (cdr (assoc code data)))

(test command-arc-draws-an-arc-through-three-points
  (let ((mock (make-cador)))
    ;; (1,0) (0,1) (-1,0): the unit circle centred at the origin.
    (clautolisp.autolisp-host:host-command
     mock '("._arc" "1,0" "0,1" "-1,0" ""))
    (let ((data (%ct-last-data mock)))
      (is (string= "ARC" (autolisp-string-value (%ct-group data 0))))
      (is (< (abs (- 1.0d0 (%ct-group data 40))) 1d-6))       ; radius
      (let ((center (%ct-group data 10)))
        (is (< (abs (first center)) 1d-6))
        (is (< (abs (second center)) 1d-6)))
      (is (< (abs (- 0.0d0 (%ct-group data 50))) 1d-6))        ; start angle
      (is (< (abs (- pi (%ct-group data 51))) 1d-6)))))        ; end angle

(test command-pline-draws-a-closed-lwpolyline
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command
     mock '("._pline" "0,0" "1,0" "1,1" "_c"))
    (let ((data (%ct-last-data mock)))
      (is (string= "LWPOLYLINE" (autolisp-string-value (%ct-group data 0))))
      (is (= 3 (%ct-group data 90)))                           ; vertex count
      (is (= 1 (%ct-group data 70)))                           ; closed
      (is (= 3 (count 10 data :key #'car))))))                 ; one 10 per vertex

(test command-mtext-draws-an-mtext
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command
     mock '("._mtext" "0,0" "10,5" "Hello" ""))
    (let ((data (%ct-last-data mock)))
      (is (string= "MTEXT" (autolisp-string-value (%ct-group data 0))))
      (is (string= "Hello" (autolisp-string-value (%ct-group data 1))))
      (is (< (abs (- 10.0d0 (%ct-group data 41))) 1d-9)))))    ; reference width

(test command-wipeout-draws-a-wipeout
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command
     mock '("._wipeout" "0,0" "2,0" "2,2" "0,2" ""))
    (let ((data (%ct-last-data mock)))
      (is (string= "WIPEOUT" (autolisp-string-value (%ct-group data 0))))
      (is (= 4 (%ct-group data 90))))))

(test command-mirror-reflects-and-keeps-the-source
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command mock '("._line" "1,0" "1,2" ""))
    ;; Mirror the last entity across the Y axis, keeping the original.
    (clautolisp.autolisp-host:host-command
     mock '("._mirror" "_l" "" "0,0" "0,1" "_n"))
    (is (equal '("LINE" "LINE") (%ct-types mock)))
    ;; The clone (entlast) sits at x = -1.
    (let ((data (%ct-last-data mock)))
      (is (< (abs (- -1.0d0 (first (%ct-group data 10)))) 1d-6))
      (is (< (abs (- -1.0d0 (first (%ct-group data 11)))) 1d-6)))))

(test command-mirror-yes-erases-the-source
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command mock '("._line" "1,0" "1,2" ""))
    (clautolisp.autolisp-host:host-command
     mock '("._mirror" "_l" "" "0,0" "0,1" "_y"))
    ;; Original erased, only the reflected clone remains.
    (is (equal '("LINE") (%ct-types mock)))
    (is (< (abs (- -1.0d0 (first (%ct-group (%ct-last-data mock) 10)))) 1d-6))))

(test command-insert-creates-a-block-reference
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command
     mock '("._insert" "MYBLK" "5,5" "2" "3" "0" ""))
    (let ((data (%ct-last-data mock)))
      (is (string= "INSERT" (autolisp-string-value (%ct-group data 0))))
      (is (string= "MYBLK" (autolisp-string-value (%ct-group data 2))))
      (let ((p (%ct-group data 10)))
        (is (and (< (abs (- 5.0d0 (first p))) 1d-9)
                 (< (abs (- 5.0d0 (second p))) 1d-9))))
      (is (< (abs (- 2.0d0 (%ct-group data 41))) 1d-9))        ; xscale
      (is (< (abs (- 3.0d0 (%ct-group data 42))) 1d-9))        ; yscale
      (is (= 0 (%ct-group data 66))))))                        ; no attributes

(test command-insert-consumes-attribute-values-and-keeps-flowing
  ;; Attribute values are swallowed (not modelled — schms §9), and a command
  ;; that follows them still runs.
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command
     mock '("._insert" "BLK" "0,0" "1" "1" "0" "V1" "V2" "" "._circle" "9,9" "1"))
    (is (equal '("INSERT" "CIRCLE") (%ct-types mock)))))

(test command-layer-make-creates-and-sets-current
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command mock '("._layer" "_m" "MURS" ""))
    (is (not (null (cador-find-table-record mock :layer "MURS"))))
    (is (string= "MURS" (sysvar-cell-value (cador-sysvar mock "CLAYER"))))
    ;; A subsequent LINE lands on the new current layer.
    (clautolisp.autolisp-host:host-command mock '("._line" "0,0" "1,1" ""))
    (is (string= "MURS" (autolisp-string-value
                         (%ct-group (%ct-last-data mock) 8))))))

(test command-layer-new-accepts-a-comma-list
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command mock '("._layer" "_n" "A,B,C" ""))
    (is (not (null (cador-find-table-record mock :layer "A"))))
    (is (not (null (cador-find-table-record mock :layer "B"))))
    (is (not (null (cador-find-table-record mock :layer "C"))))))

(test command-linetype-load-registers-an-ltype
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command
     mock '("._linetype" "_l" "DASHED" "acad.lin" ""))
    (is (not (null (cador-find-table-record mock :ltype "DASHED"))))))

(test command-recognised-noop-keeps-the-sequence-flowing
  ;; The key dispatch fix: a recognised no-op in the MIDDLE of a driven
  ;; sequence must not stop the commands that follow it.
  (let ((mock (make-cador)))
    (clautolisp.autolisp-host:host-command
     mock '("._zoom" "_e" "._line" "0,0" "1,1" "" "._ucs" "_w" "._circle" "5,5" "2"))
    (is (equal '("LINE" "CIRCLE") (%ct-types mock)))))
