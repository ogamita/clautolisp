;;;; probes/sources/probe-cond.lsp
;;;;
;;;; COND / AND / OR at their edges (issues/open/autolisp-spec-questions):
;;;; a clause with no body, an empty clause, no clause at all, and whether
;;;; AND / OR return T or the last value evaluated. Each form is READ from
;;;; its text and EVALuated, so the case name is exactly what ran; the
;;;; value is recorded as VL-PRIN1-TO-STRING prints it, an error as an
;;;; error.

(defun cad-probe-run-cond-probes ()
  (foreach text '("(cond ((= 1 1)))"
                  "(cond (42))"
                  "(cond (nil) ('ok))"
                  "(cond (\"a\"))"
                  "(cond ((setq cad-probe--x 5)))"
                  "(cond (nil))"
                  "(cond)"
                  "(cond () (33))"
                  "(and)"
                  "(or)"
                  "(and 1 2)"
                  "(and 1 nil)"
                  "(and 'a \"b\")"
                  "(or nil 3)"
                  "(or nil nil)"
                  "(or nil 'a)")
    (cad-probe-capture "cond" text
      (function (lambda () (vl-prin1-to-string (eval (read text)))))))
  (princ))
