;;;; tests/variables/pause.lsp -- PAUSE
;;;; PAUSE is documented in both vendors as a string literal "\\\\"
;;;; used inside (command ...) to suspend the command for user input.

(deftest "pause-is-bound"
  '((operator . "PAUSE") (area . "variable") (profile . strict))
  '(boundp 'pause) T)

(deftest-pred "pause-is-string"
  '((operator . "PAUSE") (area . "variable") (profile . strict))
  'pause
  '(eq (type *result*) 'str))
