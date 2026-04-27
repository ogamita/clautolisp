;;;; tests/file/open-close.lsp -- OPEN / CLOSE
;;;; Use a temporary file in the harness output area to avoid
;;;; depending on a writable test-fixtures directory.

(setq *aut-tmp-file*
      (strcat *autolisp-test-root* "results/.tmp-open-close.txt"))

(deftest-pred "open-write-returns-file"
  '((operator . "OPEN") (area . "file") (profile . strict))
  '(progn (setq oct-fp (open *aut-tmp-file* "w"))
          (close oct-fp)
          oct-fp)
  '(eq (type *result*) 'file))

(deftest-pred "open-write-then-read-roundtrips"
  '((operator . "OPEN") (area . "file") (profile . strict))
  '(progn (setq fp (open *aut-tmp-file* "w"))
          (write-line "abc" fp)
          (close fp)
          (setq fp (open *aut-tmp-file* "r"))
          (setq line (read-line fp))
          (close fp)
          line)
  '(equal *result* "abc"))

(deftest "close-returns-nil-on-success"
  '((operator . "CLOSE") (area . "file") (profile . strict))
  '(progn (setq fp (open *aut-tmp-file* "w")) (close fp))
  nil)
