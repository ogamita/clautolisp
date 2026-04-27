;;;; tests/file/vl-filename.lsp -- VL-FILENAME-* family

(deftest "vl-filename-base-with-dir-and-ext"
  '((operator . "VL-FILENAME-BASE") (area . "file") (profile . strict))
  '(vl-filename-base "/some/dir/foo.lsp") "foo")

(deftest "vl-filename-base-no-ext"
  '((operator . "VL-FILENAME-BASE") (area . "file") (profile . strict))
  '(vl-filename-base "foo") "foo")

(deftest "vl-filename-extension-lsp"
  '((operator . "VL-FILENAME-EXTENSION") (area . "file") (profile . strict))
  '(vl-filename-extension "foo.lsp") ".lsp")

(deftest "vl-filename-extension-none-returns-nil"
  '((operator . "VL-FILENAME-EXTENSION") (area . "file") (profile . strict))
  '(vl-filename-extension "foo") nil)

(deftest-pred "vl-filename-directory-extracts-dir"
  '((operator . "VL-FILENAME-DIRECTORY") (area . "file") (profile . strict))
  '(vl-filename-directory "/a/b/c.lsp")
  '(or (equal *result* "/a/b") (equal *result* "/a/b/")))
