;;;; tests/deferred/express-tools.lsp -- ACET-* (AutoCAD Express Tools)
;;;;
;;;; Express Tools is a sizable extension library (258 functions in
;;;; the inventory). The portable subset (file/string/calc) will be
;;;; promoted to executable tests as clautolisp implements them.

(deftest-skip "acet-file-copy-deferred"
  '((operator . "ACET-FILE-COPY") (area . "express-tools") (profile . strict)
    (runtime-tags . (express-tools)))
  '(acet-file-copy "a" "b")
  "deferred: requires express-tools runtime")

(deftest-skip "acet-str-format-deferred"
  '((operator . "ACET-STR-FORMAT") (area . "express-tools") (profile . strict)
    (runtime-tags . (express-tools)))
  '(acet-str-format "%d" 1)
  "deferred: requires express-tools runtime")

(deftest-skip "acet-list-flatten-deferred"
  '((operator . "ACET-LIST-FLATTEN") (area . "express-tools") (profile . strict)
    (runtime-tags . (express-tools)))
  '(acet-list-flatten '((1 2) (3 4)))
  "deferred: requires express-tools runtime")

(deftest-skip "acet-dtor-deferred"
  '((operator . "ACET-DTOR") (area . "express-tools") (profile . strict)
    (runtime-tags . (express-tools)))
  '(acet-dtor 90)
  "deferred: requires express-tools runtime")
