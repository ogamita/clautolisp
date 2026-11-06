;;;; bricscad-extensions-probe.lsp — harvest what BricsCAD's undocumented
;;;; Common-Lisp constructs actually DO (bricscad-undocumented-clisms.issue).
;;;;
;;;; Background: BricsCAD V26 silently accepts several CL constructs absent
;;;; from Autodesk's public AutoLISP reference — setf, let, let*, and the
;;;; &rest lambda-list keyword. Bricsys support confirmed &rest; the other
;;;; three were only OBSERVED (notably `(setf *sym* nil)' echoing `2' in an
;;;; alfe REPL — deferred-bricscad-setq-nil-returns-2.issue). This probe
;;;; captures the RAW RETURN VALUE of each construct directly (each result
;;;; wrapped in its own princ, so the value seen is the form's own return
;;;; value, not any REPL/print-wrap echo), decoding the `2' mystery and
;;;; recording let/let*/&rest behaviour.
;;;;
;;;; This is a HARVEST probe, not a conformance probe: BricsCAD's behaviour
;;;; is exactly the unknown. Every construct is evaluated through
;;;; vl-catch-all-apply, so an unsupported construct reports its error
;;;; instead of aborting the run — the probe therefore runs to completion on
;;;; ANY backend (under clautolisp it documents clautolisp's current
;;;; behaviour; under BricsCAD it records the vendor's).
;;;;
;;;; Every result line is machine-readable: "EXTPROBE <KEY>=<VALUE>", so a
;;;; diff of the report across backends shows each divergence. Ends with
;;;; "EXTPROBE DONE".

(defun ep (key val) (princ (strcat "EXTPROBE " key "=" val "\n")) (princ))

;;; Evaluate FORM (a quoted list) via vl-catch-all-apply, returning a string:
;;; either the printed return value, or "ERROR:<message>" when the construct
;;; is unsupported / signals. FORM is applied as (apply (car FORM) (cdr FORM))
;;; — but most constructs here are special forms, so instead we wrap each in a
;;; zero-argument lambda and funcall it through the catch-all.
(defun probe-value (thunk / r)
  (setq r (vl-catch-all-apply thunk nil))
  (if (vl-catch-all-error-p r)
      (strcat "ERROR:" (vl-catch-all-error-message r))
      (vl-princ-to-string r)))

(defun probe-extensions ( / )
  ;; --- setq baseline (documented; must return its value) -------------
  (ep "SETQ-99"      (probe-value '(lambda () (setq foo 99))))
  (ep "SETQ-NIL"     (probe-value '(lambda () (setq foo nil))))

  ;; --- setf: decode the "2". Vary the value; if the echo is always the
  ;;     same regardless of value, it is an internal sentinel, not the
  ;;     assigned value. If it tracks the value, setf behaves like setq. --
  (ep "SETF-NIL"     (probe-value '(lambda () (setf foo nil))))
  (ep "SETF-1"       (probe-value '(lambda () (setf foo 1))))
  (ep "SETF-2"       (probe-value '(lambda () (setf foo 2))))
  (ep "SETF-99"      (probe-value '(lambda () (setf foo 99))))
  (ep "SETF-STRING"  (probe-value '(lambda () (setf foo "hello"))))
  (ep "SETF-LIST"    (probe-value '(lambda () (setf foo '(a b)))))
  ;; and confirm what the variable actually holds after a setf, to tell
  ;; "returns a sentinel but assigns correctly" from "does not assign".
  (probe-value '(lambda () (setf foo 42)))
  (ep "SETF-THEN-FOO" (probe-value '(lambda () foo)))

  ;; --- let / let*: value + binding discipline ------------------------
  (ep "LET-SUM"      (probe-value '(lambda () (let ((x 1) (y 2)) (+ x y)))))
  ;; parallel binding: y must NOT see x's new value (classic let vs let*).
  (ep "LET-PARALLEL" (probe-value '(lambda () (setq x 10)
                                            (let ((x 1) (y x)) (list x y)))))
  (ep "LETSTAR-SEQ"  (probe-value '(lambda () (let* ((x 1) (y (+ x 1))) y))))

  ;; --- &rest and the bare & separator in lambda lists ----------------
  (ep "REST-BINDS"   (probe-value '(lambda () ((lambda (a &rest r) r) 1 2 3 4))))
  (ep "AMP-BINDS"    (probe-value '(lambda () ((lambda (a & r) r) 1 2 3 4))))

  (ep "DONE" "1"))

(vl-catch-all-apply 'probe-extensions nil)
(princ "EXTPROBE DONE\n")
(princ)
