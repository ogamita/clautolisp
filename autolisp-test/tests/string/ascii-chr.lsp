;;;; tests/string/ascii-chr.lsp -- ASCII / CHR

(deftest "ascii-of-A"
  '((operator . "ASCII") (area . "string") (profile . strict))
  '(ascii "A") 65)

(deftest "ascii-of-zero-char"
  '((operator . "ASCII") (area . "string") (profile . strict))
  '(ascii "0") 48)

(deftest "ascii-of-multichar-uses-first"
  '((operator . "ASCII") (area . "string") (profile . strict))
  '(ascii "ABC") 65)

(deftest "chr-of-65"
  '((operator . "CHR") (area . "string") (profile . strict))
  '(chr 65) "A")

(deftest "chr-of-48"
  '((operator . "CHR") (area . "string") (profile . strict))
  '(chr 48) "0")

(deftest "ascii-chr-roundtrip"
  '((operator . "CHR") (area . "string") (profile . strict))
  '(ascii (chr 90)) 90)
