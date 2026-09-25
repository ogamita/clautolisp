;;;; comparison-operators-probe.lsp — PROBE of = /= < <= > >=
;;;;
;;;; A probe EXERCISES a feature and reports the EXHIBITED behaviour to be
;;;; compared against the specification (autolisp-spec ch.25 probe model);
;;;; it does not itself judge pass/fail. This one drives the six comparison
;;;; operators over the argument-type domain questioned by the spec
;;;; (ch.5, "The Comparison Operators =, /=, <, <=, >, >="):
;;;;   - numbers and strings (the documented domain);
;;;;   - a number against a string, e.g. (= 1 "1"), (< 1 "a");
;;;;   - symbols and lists, e.g. (= 'a 'a) -- used by alfe's own bootstrap
;;;;     on AutoCAD and BricsCAD, so presumably accepted by =;
;;;;   - nil, and which wins between nil and an incompatible pair;
;;;;   - arity 0 / 1 / 3 and the pairwise-vs-adjacent meaning of /=.
;;;; It uses only functions every target provides, so it runs UNCHANGED on
;;;; AutoCAD, BricsCAD and clautolisp.
;;;;
;;;; Run it:
;;;;   clautolisp:            clautolisp -norc -l comparison-operators-probe.lsp
;;;;   via alfe on BricsCAD:  alfe --bricscad -l comparison-operators-probe.lsp
;;;;   via alfe on AutoCAD:   alfe --autocad  -l comparison-operators-probe.lsp
;;;;   or (load "comparison-operators-probe.lsp") at the CAD command line.
;;;;
;;;; Output: one machine-readable line per observation
;;;;   OBSERVE <name> <token>
;;;; where <token> is T, nil, or error (the call signalled). For an error,
;;;; a following human line "  message: ..." gives the vendor's text. The
;;;; last line is "OBSERVATIONS <n>". Send the whole output back.

(vl-load-com)

(setq *obs-count* 0)

;; Emit one observation: NAME is a stable dotted key, TOKEN a single
;; whitespace-free word encoding the exhibited outcome. Returns TOKEN.
(defun obs (name token / )
  (setq *obs-count* (1+ *obs-count*))
  (princ (strcat "OBSERVE " name " " token "\n"))
  token)

;; Apply operator FN (a symbol) to ARGS, trapping any error, and record
;; the outcome under OPNAME.CASE.
(defun try (opname fn case args / r)
  (setq r (vl-catch-all-apply fn args))
  (cond
    ((vl-catch-all-error-p r)
     (obs (strcat opname "." case) "error")
     (princ (strcat "  message: " (vl-catch-all-error-message r) "\n")))
    ((null r) (obs (strcat opname "." case) "nil"))
    ((eq r T) (obs (strcat opname "." case) "T"))
    (T (obs (strcat opname "." case) "other"))))

;; The argument lists, as (CASE-NAME ARGS). The same list object is used
;; for the "same-list" case so an identity comparison can succeed.
(setq *shared-list* (list 1 2))

(setq *cases*
  (list
    ;; numbers -- the documented domain
    (list "int-int-lt"        (list 1 2))
    (list "int-int-eq"        (list 2 2))
    (list "int-real-eq"       (list 1 1.0))
    (list "real-int-gt"       (list 2.5 1))
    ;; strings -- the documented domain
    (list "str-lt"            (list "a" "b"))
    (list "str-eq"            (list "b" "b"))
    (list "str-gt"            (list "c" "b"))
    (list "str-case"          (list "B" "a"))
    (list "str-prefix"        (list "ab" "abc"))
    (list "str-empty"         (list "" "a"))
    (list "str-case-eq"       (list "a" "A"))
    ;; number against string
    (list "int-str-digit"     (list 1 "1"))
    (list "str-int-digit"     (list "1" 1))
    (list "int-str-alpha"     (list 1 "a"))
    (list "real-str"          (list 1.0 "1.0"))
    ;; symbols
    (list "sym-same"          (list 'a 'a))
    (list "sym-diff"          (list 'a 'b))
    (list "sym-int"           (list 'a 1))
    (list "int-sym"           (list 1 'a))
    (list "sym-str"           (list 'a "A"))
    (list "t-t"               (list T T))
    ;; lists
    (list "list-equal"        (list (list 1 2) (list 1 2)))
    (list "list-same"         (list *shared-list* *shared-list*))
    (list "list-int"          (list (list 1) 1))
    ;; nil (bottom)
    (list "nil-nil"           (list nil nil))
    (list "int-nil"           (list 1 nil))
    (list "nil-int"           (list nil 1))
    (list "str-nil"           (list "a" nil))
    (list "sym-nil"           (list 'a nil))
    ;; nil against an incompatible pair in the same chain: which wins?
    (list "int-str-nil"       (list 1 "a" nil))
    (list "nil-int-str"       (list nil 1 "a"))
    ;; arity
    (list "arity0"            nil)
    (list "arity1-int"        (list 5))
    (list "arity1-str"        (list "a"))
    (list "arity1-sym"        (list 'a))
    (list "arity1-nil"        (list nil))
    ;; chains
    (list "chain-asc"         (list 1 2 3))
    (list "chain-mixed"       (list 1 3 2))
    (list "chain-repeat"      (list 1 2 1))
    (list "chain-str"         (list "a" "b" "c"))))

(defun run-comparison-probe (/ ops op c)
  (setq ops (list (list "eq" '=) (list "ne" '/=)
                  (list "lt" '<) (list "le" '<=)
                  (list "gt" '>) (list "ge" '>=)))
  (foreach op ops
    (princ (strcat "operator " (vl-symbol-name (cadr op)) ":\n"))
    (foreach c *cases*
      (try (car op) (cadr op) (car c) (cadr c))))
  (princ (strcat "OBSERVATIONS " (itoa *obs-count*) "\n"))
  (princ))

(run-comparison-probe)
