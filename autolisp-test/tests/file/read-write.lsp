;;;; tests/file/read-write.lsp -- READ-LINE / WRITE-LINE / READ-CHAR / WRITE-CHAR

(setq *aut-rw-file*
      (strcat *autolisp-test-root* "results/.tmp-read-write.txt"))

(deftest "write-line-returns-line"
  '((operator . "WRITE-LINE") (area . "file") (profile . strict))
  '(progn (setq fp (open *aut-rw-file* "w"))
          (setq r (write-line "alpha" fp))
          (close fp)
          r)
  "alpha")

(deftest "read-line-returns-written-line"
  '((operator . "READ-LINE") (area . "file") (profile . strict))
  '(progn (setq fp (open *aut-rw-file* "w"))
          (write-line "first" fp)
          (write-line "second" fp)
          (close fp)
          (setq fp (open *aut-rw-file* "r"))
          (setq r (read-line fp))
          (close fp)
          r)
  "first")

(deftest "read-line-eof-returns-nil"
  '((operator . "READ-LINE") (area . "file") (profile . strict))
  '(progn (setq fp (open *aut-rw-file* "w"))
          (close fp)
          (setq fp (open *aut-rw-file* "r"))
          (setq r (read-line fp))
          (close fp)
          r)
  nil)

(deftest "write-char-then-read-char"
  '((operator . "WRITE-CHAR") (area . "file") (profile . strict))
  '(progn (setq fp (open *aut-rw-file* "w"))
          (write-char 65 fp)
          (write-char 66 fp)
          (close fp)
          (setq fp (open *aut-rw-file* "r"))
          (setq c (read-char fp))
          (close fp)
          c)
  65)
