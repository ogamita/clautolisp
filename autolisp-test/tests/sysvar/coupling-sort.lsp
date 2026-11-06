;;;; tests/sysvar/coupling-sort.lsp
;;;;
;;;; MAXSORT caps acad_strlsort: the Express Tools string-list sort
;;;; returns nil when the list is longer than MAXSORT, otherwise the
;;;; ascending-ordinal sorted copy. (spec MAXSORT Read/Written-By names
;;;; acad_strlsort.)

(deftest "sysvar-maxsort-caps-acad-strlsort"
  '((operator . "MAXSORT") (area . "sysvar") (profile . strict))
  '(progn (setvar "MAXSORT" 2)
          (acad_strlsort (list "c" "b" "a")))
  nil)

(deftest "sysvar-maxsort-allows-within-limit"
  '((operator . "MAXSORT") (area . "sysvar") (profile . strict))
  '(progn (setvar "MAXSORT" 1000)
          (acad_strlsort (list "c" "a" "b")))
  '("a" "b" "c"))

;; Reset MAXSORT so a lowered value does not leak into later tests.
(deftest "sysvar-maxsort-reset"
  '((operator . "MAXSORT") (area . "sysvar") (profile . strict))
  '(progn (setvar "MAXSORT" 1000) (getvar "MAXSORT"))
  1000)
