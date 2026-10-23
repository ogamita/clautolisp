;;;; tests/error/vl-exit.lsp -- VL-EXIT-WITH-ERROR / VL-EXIT-WITH-VALUE
;;;;
;;;; Outside a separate-namespace VLX -- always, in clautolisp, which loads
;;;; no VLX -- BOTH are an error without a message, measured on AutoCAD 2022
;;;; (GUI + accoreconsole) and BricsCAD V25 / V26 (control-flow probe, MR
;;;; !471; vl-exit-outside-vlx-caught-diverges): vl-catch-all-apply returns
;;;; a catch-all error object, even for vl-exit-with-value, whose message is
;;;; nil on AutoCAD (and under the strict profile, which follows it) and ""
;;;; on BricsCAD.

(deftest-pred "vl-exit-with-error-is-caught"
  '((operator . "VL-EXIT-WITH-ERROR") (area . "error") (profile . strict))
  '(vl-catch-all-apply
    '(lambda () (vl-exit-with-error "custom-error"))
    nil)
  '(vl-catch-all-error-p *result*))

(deftest "vl-exit-with-error-outside-a-vlx-has-no-message"
  '((operator . "VL-EXIT-WITH-ERROR") (area . "error") (profile . strict))
  '(vl-catch-all-error-message
    (vl-catch-all-apply
     '(lambda () (vl-exit-with-error "custom-error"))
     nil))
  nil)

(deftest-pred "vl-exit-with-value-outside-a-vlx-is-an-error"
  '((operator . "VL-EXIT-WITH-VALUE") (area . "error") (profile . strict))
  '(vl-catch-all-apply
    '(lambda () (vl-exit-with-value 99))
    nil)
  '(vl-catch-all-error-p *result*))
