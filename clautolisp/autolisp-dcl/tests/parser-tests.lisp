(in-package #:clautolisp.autolisp-dcl.tests)

(in-suite autolisp-dcl-suite)

(test parse-empty-source
  "An empty DCL source parses to an empty alist."
  (is (null (parse-dcl ""))))

(test parse-single-empty-dialog
  "A bare dialog declaration produces one tile with type :dialog."
  (let* ((alist (parse-dcl "hello : dialog { }"))
         (entry (first alist)))
    (is (= 1 (length alist)))
    (is (string= "hello" (car entry)))
    (is (eq :dialog (dcl-tile-type (cdr entry))))))

(test parse-attributes-string-and-number
  "label = \"...\" stores the string verbatim and width = 40 stores
the integer."
  (let* ((alist (parse-dcl
                 "g : dialog { label = \"Greeting\"; width = 40; }"))
         (tile (cdr (first alist))))
    (is (equal "Greeting" (tile-attribute tile "label")))
    (is (equal 40 (tile-attribute tile "width")))))

(test parse-nested-children-named
  "A named child tile is added to the parent's CHILDREN, with its
key set from the leading name."
  (let* ((alist (parse-dcl
                 "g : dialog { ok : button { label = \"OK\"; } }"))
         (parent (cdr (first alist)))
         (child (first (dcl-tile-children parent))))
    (is (eq :button (dcl-tile-type child)))
    (is (equal "ok" (dcl-tile-key child)))
    (is (equal "OK" (tile-attribute child "label")))))

(test parse-predefined-instantiation-keeps-type
  "`row : ok_cancel ;` produces a child tile whose type is the
predefined keyword (so it can later be expanded by the runtime)."
  (let* ((alist (parse-dcl
                 "g : dialog { : ok_cancel; }"))
         (parent (cdr (first alist)))
         (child (first (dcl-tile-children parent))))
    (is (eq :ok-cancel (dcl-tile-type child)))))

(test parse-line-comment-and-block-comment
  "// line comments and /* block comments */ are skipped."
  (let* ((alist (parse-dcl
                 "// header
g : dialog { /* inline */ label = \"Hi\"; }"))
         (tile (cdr (first alist))))
    (is (equal "Hi" (tile-attribute tile "label")))))

(test parse-error-on-unterminated-string
  "An unterminated string literal signals dcl-parse-error."
  (signals dcl-parse-error
    (parse-dcl "g : dialog { label = \"oops; }")))

(test parse-multiple-top-level-tiles
  "Multiple top-level tile-class definitions are collected."
  (let ((alist (parse-dcl "a : dialog { }
b : dialog { }
c : dialog { }")))
    (is (= 3 (length alist)))
    (is (equal '("a" "b" "c") (mapcar #'car alist)))))

(test predefined-tiles-registered
  "The ok_button / cancel_button / ok_cancel templates are registered."
  (is (functionp (gethash "ok_button" *predefined-tiles*)))
  (is (functionp (gethash "cancel_button" *predefined-tiles*)))
  (is (functionp (gethash "ok_cancel" *predefined-tiles*))))
