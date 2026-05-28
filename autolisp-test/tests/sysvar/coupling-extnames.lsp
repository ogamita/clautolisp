;;;; tests/sysvar/coupling-extnames.lsp
;;;;
;;;; EXTNAMES controls strict (R14, 31-char) vs relaxed (255-char +
;;;; extra characters) symbol-table name validation. snvalid honours
;;;; the current value.

(deftest "sysvar-extnames-relaxed-accepts-long-name"
  '((operator . "EXTNAMES") (area . "sysvar") (profile . strict))
  '(progn (setvar "EXTNAMES" 1)
          (snvalid "Layer With Spaces"))
  T)

(deftest "sysvar-extnames-relaxed-default"
  '((operator . "EXTNAMES") (area . "sysvar") (profile . strict))
  '(getvar "EXTNAMES")
  1)

(deftest "sysvar-extnames-strict-rejects-spaces"
  '((operator . "EXTNAMES") (area . "sysvar") (profile . strict))
  '(progn (setvar "EXTNAMES" 0)
          (let ((result (snvalid "Has Space")))
            (setvar "EXTNAMES" 1)        ;; restore
            result))
  nil)

(deftest "sysvar-extnames-toggle-survives-restore"
  '((operator . "EXTNAMES") (area . "sysvar") (profile . strict))
  '(progn (setvar "EXTNAMES" 0)
          (setvar "EXTNAMES" 1)
          (getvar "EXTNAMES"))
  1)
