(in-package #:clautolisp.debug)

;;;; FILE:LINE breakpoints (aldo-command-from-repl.issue).
;;;;
;;;; `,break FILE:LINE[:COL]' records a PERSISTENT breakpoint keyed by the raw
;;;; file position — NOT by an enclosing (defun NAME …) like the vbN virtual
;;;; breakpoints (virtual-breakpoints.lisp). It is (re)resolved on every load,
;;;; because the file may be edited and reloaded before the breakpoint is
;;;; reached, so the poll point it maps to can move.
;;;;
;;;; Resolution — the SAME rule whether arming now (the file is already loaded)
;;;; or materialising it at (re)load: the FIRST poll point at or after
;;;; FILE:LINE[:COL] (in file order). Reported as its exact file position, and
;;;; in which function + subform index (or a top-level form) it landed.
;;;;
;;;; Two arming paths:
;;;;   - SET TIME (file already loaded): RESOLVE-LINE-BREAKPOINT scans the file's
;;;;     current DEFUN metadata (a top-level form's metadata is transient — it
;;;;     only exists while that form is being evaluated during a load — so a
;;;;     FILE:LINE on a top-level form set AFTER the load stays pending and arms
;;;;     on the next load).
;;;;   - LOAD TIME (incremental): MATERIALIZE-LINE-BREAKPOINTS runs from
;;;;     INSTRUMENT-USUBR as each function AND each `<toplevel>' form is
;;;;     instrumented — in file order — so a breakpoint on a top-level form is
;;;;     armed just before that form executes and BREAKS DURING THE LOAD.
;;;;
;;;; A "load generation" (bumped by the before-load hook) makes a reload
;;;; re-resolve: a line-breakpoint armed in an older generation is eligible to
;;;; re-arm, and the first metadata of the new generation (file order) to offer
;;;; a candidate wins. When a reload moves a breakpoint, its FILE:LINE ref is
;;;; collected and the after-load hook warns.

(defstruct line-breakpoint
  (id 0 :type fixnum)              ; the lbN id the listings/removal use
  (file "" :type string)           ; file as designated (matched truename-tolerant)
  (line 0 :type fixnum)            ; target line (1-based)
  (col 1 :type fixnum)             ; target column (1-based); 1 = "at/after the line"
  ti                               ; thread-debug-info the real breakpoint arms on
  (bp nil)                         ; the real breakpoint currently arming it, or NIL
  (resolved-line nil)              ; line of the poll point it resolved to (for the diff)
  (armed-generation -1 :type fixnum)) ; load generation it was armed in (-1 = pending)

(defvar *line-breakpoints* '()
  "The FILE:LINE breakpoints, newest first (aldo-command-from-repl.issue).")
(defvar *line-breakpoint-id-counter* 0)

(defvar *load-generation* 0
  "Bumped on each file (re)load (BEGIN-FILE-LOAD). A line-breakpoint armed in an
older generation is re-resolved when its file is loaded again.")

(defvar *line-breakpoints-changed* '()
  "FILE:LINE refs (strings) whose resolved position moved during the current
load, collected for the after-load warning.")

;;; --- position helpers ---------------------------------------------------

(defun %position>= (pline pcol line col)
  "True when source position (PLINE,PCOL) is at or after (LINE,COL)."
  (or (> pline line) (and (= pline line) (>= pcol col))))

(defun %position< (aline acol bline bcol)
  "True when (ALINE,ACOL) is strictly before (BLINE,BCOL)."
  (or (< aline bline) (and (= aline bline) (< acol bcol))))

(defun earliest-poll-point-at/after (metadata line col)
  "The earliest poll point of METADATA at or after (LINE,COL): (values FORM-ID
PLINE PCOL), or NIL when METADATA has no poll point there."
  (let ((positions (function-debug-metadata-form-id->position metadata))
        (best-id nil) (best-line 0) (best-col 0))
    (dotimes (form-id (length positions))
      (let ((position (aref positions form-id)))
        (when (and (source-position-p position)
                   (%position>= (source-position-start-line position)
                                (source-position-start-column position)
                                line col)
                   (or (null best-id)
                       (%position< (source-position-start-line position)
                                   (source-position-start-column position)
                                   best-line best-col)))
          (setf best-id form-id
                best-line (source-position-start-line position)
                best-col (source-position-start-column position)))))
    (when best-id (values best-id best-line best-col))))

(defun resolve-line-breakpoint (file line col)
  "The first poll point at/after (LINE,COL) of FILE among its currently-loaded
DEFUN metadata (latest redefinition per name; the transient `<toplevel>'
metadata is skipped — see the file header). Returns (values METADATA FORM-ID
PLINE PCOL) or NIL. Used to arm a FILE:LINE breakpoint set while the file is
already loaded."
  (let ((by-name (make-hash-table :test 'equal)))
    ;; latest redefinition per name (mirror METADATA-FOR-NAME's highest-fid rule)
    (dolist (metadata (all-function-metadata))
      (let ((name (function-debug-metadata-name metadata))
            (position (function-debug-metadata-source-position metadata)))
        (when (and (source-position-p position)
                   (not (string-equal name "<toplevel>"))
                   (same-source-file-p file (source-position-file position)))
          (let ((prior (gethash name by-name)))
            (when (or (null prior)
                      (> (function-debug-metadata-function-id metadata)
                         (function-debug-metadata-function-id prior)))
              (setf (gethash name by-name) metadata))))))
    (let ((best-md nil) (best-id nil) (best-line 0) (best-col 0))
      (maphash (lambda (name metadata)
                 (declare (ignore name))
                 (multiple-value-bind (form-id pline pcol)
                     (earliest-poll-point-at/after metadata line col)
                   (when (and form-id
                              (or (null best-md)
                                  (%position< pline pcol best-line best-col)))
                     (setf best-md metadata best-id form-id
                           best-line pline best-col pcol))))
               by-name)
      (when best-md (values best-md best-id best-line best-col)))))

;;; --- records ------------------------------------------------------------

(defun add-line-breakpoint (ti file line col)
  "Record a FILE:LINE breakpoint (deduplicated on file+line+col). Returns
(values LINE-BREAKPOINT NEW-P)."
  (let ((existing (find-if (lambda (lbp)
                             (and (same-source-file-p (line-breakpoint-file lbp) file)
                                  (eql (line-breakpoint-line lbp) line)
                                  (eql (line-breakpoint-col lbp) col)))
                           *line-breakpoints*)))
    (if existing
        (values existing nil)
        (let ((lbp (make-line-breakpoint :id (incf *line-breakpoint-id-counter*)
                                         :file file :line line :col col :ti ti)))
          (push lbp *line-breakpoints*)
          (values lbp t)))))

(defun list-line-breakpoints ()
  "Every FILE:LINE breakpoint, oldest first."
  (reverse *line-breakpoints*))

(defun find-line-breakpoint (id)
  "The FILE:LINE breakpoint numbered ID, or NIL."
  (find id *line-breakpoints* :key #'line-breakpoint-id))

(defun remove-line-breakpoint (lbp)
  "Drop the FILE:LINE breakpoint LBP, disarming its real breakpoint if armed."
  (when (and (line-breakpoint-bp lbp)
             (thread-debug-info-p (line-breakpoint-ti lbp)))
    (ignore-errors (remove-breakpoint (line-breakpoint-ti lbp) (line-breakpoint-bp lbp))))
  (setf *line-breakpoints* (remove lbp *line-breakpoints*))
  lbp)

(defun line-breakpoints-for-file (file)
  "The FILE:LINE breakpoints recorded on FILE, oldest first."
  (remove-if-not (lambda (lbp) (same-source-file-p (line-breakpoint-file lbp) file))
                 (list-line-breakpoints)))

;;; --- arming -------------------------------------------------------------

(defun %arm-line-breakpoint (lbp metadata form-id pline)
  "Arm LBP on (METADATA, FORM-ID), replacing any breakpoint it previously armed;
record the resolved line and the current load generation, and note a moved
position for the reload warning."
  (let ((ti (line-breakpoint-ti lbp))
        (old-bp (line-breakpoint-bp lbp))
        (old-line (line-breakpoint-resolved-line lbp)))
    (when (and old-bp (thread-debug-info-p ti))
      (ignore-errors (remove-breakpoint ti old-bp)))
    (let ((bp (add-breakpoint ti (function-debug-metadata-function-id metadata) form-id)))
      (setf (line-breakpoint-bp lbp) bp
            (line-breakpoint-resolved-line lbp) pline
            (line-breakpoint-armed-generation lbp) *load-generation*)
      (when (and old-line (/= old-line pline))
        (pushnew (format nil "~A:~A" (file-namestring (line-breakpoint-file lbp))
                         (line-breakpoint-line lbp))
                 *line-breakpoints-changed* :test #'equal))
      bp)))

(defun set-line-breakpoint (ti file line col)
  "The `,break FILE:LINE[:COL]' engine entry: record a FILE:LINE breakpoint and,
when the file is already loaded, arm it now against the current defuns. Returns
(values LINE-BREAKPOINT NEW-P ARMED-P)."
  (multiple-value-bind (lbp new-p) (add-line-breakpoint ti file line col)
    (let ((armed-p (and (line-breakpoint-bp lbp) t)))
      (when (not armed-p)
        (multiple-value-bind (metadata form-id pline)
            (resolve-line-breakpoint file line col)
          (when form-id
            (%arm-line-breakpoint lbp metadata form-id pline)
            (setf armed-p t))))
      (values lbp new-p armed-p))))

(defun materialize-line-breakpoints (metadata)
  "Arm the FILE:LINE breakpoints of METADATA's file that resolve into METADATA,
called from INSTRUMENT-USUBR as each function/`<toplevel>' form is instrumented
(in file order). A line-breakpoint is eligible when it has not been armed in the
CURRENT load generation; the first metadata of the generation (file order) to
offer a poll point at/after its target arms it — so a top-level breakpoint is
armed just before that form runs, breaking during the load."
  (let ((position (function-debug-metadata-source-position metadata)))
    (when (source-position-p position)
      (let ((file (source-position-file position)))
        (dolist (lbp *line-breakpoints*)
          (when (and (same-source-file-p (line-breakpoint-file lbp) file)
                     (< (line-breakpoint-armed-generation lbp) *load-generation*))
            (multiple-value-bind (form-id pline pcol)
                (earliest-poll-point-at/after metadata
                                              (line-breakpoint-line lbp)
                                              (line-breakpoint-col lbp))
              (declare (ignore pcol))
              (when form-id
                (%arm-line-breakpoint lbp metadata form-id pline)))))))))

;;; --- load-generation hooks (wired into the runtime load path) -----------

(defun begin-file-load (file)
  "BEFORE a file loads: open a new load generation so its FILE:LINE breakpoints
re-resolve, and reset the moved-breakpoint list."
  (declare (ignore file))
  (incf *load-generation*)
  (setf *line-breakpoints-changed* '()))

(defun end-file-load (file)
  "AFTER a file loads: warn when the load moved any FILE:LINE breakpoint."
  (declare (ignore file))
  (when *line-breakpoints-changed*
    (format *standard-output* "~&;; breakpoints changed ~{~A~^, ~}~%"
            (reverse *line-breakpoints-changed*))
    (setf *line-breakpoints-changed* '())))

;; Dependency inversion: the runtime calls these around each load without
;; depending on this layer (like *INSTRUMENT-USUBR-HOOK*).
(setf clautolisp.autolisp-runtime:*before-load-file-hook* #'begin-file-load
      clautolisp.autolisp-runtime:*after-load-file-hook*  #'end-file-load)
