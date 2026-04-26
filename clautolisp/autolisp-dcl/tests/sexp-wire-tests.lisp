(in-package #:clautolisp.autolisp-dcl.tests)

(in-suite autolisp-dcl-suite)

(defun roundtrip (form)
  "Serialise FORM, then read it back; return the parsed value."
  (let ((text (with-output-to-string (out)
                (clautolisp.autolisp-dcl::write-sexp-form form out))))
    (with-input-from-string (in text)
      (clautolisp.autolisp-dcl:read-sexp-message in))))

(test sexp-wire-roundtrip-primitives
  (is (eql 42 (roundtrip 42)))
  (is (eql -7 (roundtrip -7)))
  (is (equal "hi" (roundtrip "hi")))
  (is (equal :open-dialog (roundtrip :open-dialog)))
  (is (null (roundtrip nil)))
  (is (eq t (roundtrip t))))

(test sexp-wire-roundtrip-string-escapes
  (let ((s (roundtrip (format nil "a~Cb~Cc\"\\d" #\Newline #\Tab))))
    (is (string= (format nil "a~Cb~Cc\"\\d" #\Newline #\Tab) s))))

(test sexp-wire-roundtrip-list
  (let ((parsed (roundtrip '(:set-tile 7 "key" "value"))))
    (is (equal '(:set-tile 7 "key" "value") parsed))))

(test sexp-wire-roundtrip-nested
  (let ((parsed (roundtrip '(:open-dialog 0 "hi"
                             (:tile :dialog :nokey
                              (:attr ("label" "Hello"))
                              (:children
                               (:tile :button "ok"
                                (:attr ("label" "OK"))
                                (:children))))))))
    (is (equal :open-dialog (first parsed)))
    (is (eql 0 (second parsed)))
    (is (equal "hi" (third parsed)))))

(test sexp-wire-reads-multiple-messages-per-stream
  (with-input-from-string (in "(:hello 1)
(:done 0 1)
")
    (let ((m1 (clautolisp.autolisp-dcl:read-sexp-message in))
          (m2 (clautolisp.autolisp-dcl:read-sexp-message in))
          (m3 (clautolisp.autolisp-dcl:read-sexp-message in)))
      (is (equal '(:hello 1) m1))
      (is (equal '(:done 0 1) m2))
      (is (eq :eof m3)))))

(test sexp-wire-rejects-unterminated-string
  (signals clautolisp.autolisp-dcl:sexp-wire-error
    (with-input-from-string (in "(:set-tile 0 \"key")
      (clautolisp.autolisp-dcl:read-sexp-message in))))

(test sexp-wire-tile-encoding-shape
  (let* ((tile (clautolisp.autolisp-dcl:make-dcl-tile
                :type :button
                :key "ok"
                :attributes '(("label" . "OK"))))
         (form (clautolisp.autolisp-dcl:tile->sexp tile)))
    (is (eq :tile (first form)))
    (is (eq :button (second form)))
    (is (equal "ok" (third form)))
    (is (eq :attr (first (fourth form))))
    (is (eq :children (first (fifth form))))))

(test sexp-wire-tile-encoding-falls-back-to-attribute-key
  "Anonymous DCL tiles like `: edit_box { key = \"name\"; }` have
nil dcl-tile-key but their identifying key lives in the
attributes alist. tile->sexp must surface that as the third
slot so the GUI driver can address the widget by name."
  (let* ((tile (clautolisp.autolisp-dcl:make-dcl-tile
                :type :edit-box
                :key nil
                :attributes '(("key" . "name") ("label" . "Name"))))
         (form (clautolisp.autolisp-dcl:tile->sexp tile)))
    (is (equal "name" (third form)))))

(test sexp-wire-tile-encoding-falls-back-to-nokey
  "When neither slot nor attribute provides a key, the encoder
must emit :nokey so the receiver can decode reliably."
  (let* ((tile (clautolisp.autolisp-dcl:make-dcl-tile
                :type :spacer
                :key nil
                :attributes nil))
         (form (clautolisp.autolisp-dcl:tile->sexp tile)))
    (is (eq :nokey (third form)))))
