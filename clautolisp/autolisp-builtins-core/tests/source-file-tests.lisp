(in-package #:clautolisp.autolisp-builtins-core.tests)

(in-suite autolisp-builtins-core-suite)

;;;; The source-file editing module (sedit-bugs-and-design.issue): reading and
;;;; line-level editing of a source file while keeping the source-position map
;;;; consistent, so a save never invalidates the positions of the forms below
;;;; the first edit.

(defmacro with-sf-temp ((var text) &body body)
  "Bind VAR to a fresh temp .lsp file initialised with TEXT (removed after)."
  `(uiop:with-temporary-file (:pathname %p :type "lsp" :keep t)
     (let ((,var (namestring %p)))
       (unwind-protect
            (progn (with-open-file (out ,var :direction :output :if-exists :supersede)
                     (write-string ,text out))
                   ,@body)
         (ignore-errors (delete-file ,var))))))

(defun %sf (name) (find-symbol (string name) "CLAUTOLISP.SOURCE-FILE"))
(defun %rd (text) (funcall (find-symbol "AUTOLISP-READ-FROM-STRING"
                                        "CLAUTOLISP.AUTOLISP-RUNTIME")
                           text))
(defun %startline (cons)
  (let ((pos (funcall (find-symbol "POSITION-OF" "CLAUTOLISP.SOURCE") cons)))
    (and pos (funcall (find-symbol "SOURCE-POSITION-START-LINE" "CLAUTOLISP.SOURCE") pos))))

(defun %line-of (needle text)
  "1-based number of the first line of TEXT containing NEEDLE, or NIL."
  (let ((at (search needle text)))
    (and at (1+ (count #\Newline text :end at)))))

(test source-file-read-yields-forms-with-positions
  (with-sf-temp (path (format nil "(defun a (x) x)~%~%(defun b (y) y)~%"))
    (let* ((sf (funcall (%sf 'source-file-open) path 'read))
           (a (funcall (%sf 'source-file-read) sf))
           (b (funcall (%sf 'source-file-read) sf))
           (eof (funcall (%sf 'source-file-read) sf :eof)))
      (is (consp a))
      (is (consp b))
      (is (eql 1 (%startline a)))
      (is (eql 3 (%startline b)))
      (is (eq :eof eof)))))

(test source-file-insert-shifts-positions-below
  (with-sf-temp (path (format nil "(defun a (x) x)~%~%(defun b (y) y)~%~%(defun c (z) z)~%"))
    (let* ((sf (funcall (%sf 'source-file-open) path 'update))
           (a (funcall (%sf 'source-file-read) sf))
           (b (funcall (%sf 'source-file-read) sf))
           (c (funcall (%sf 'source-file-read) sf)))
      (declare (ignore a))
      (is (eql 3 (%startline b)))
      (is (eql 5 (%startline c)))
      ;; insert one form (+ a trailing blank) at the top: below shifts by 2
      (funcall (%sf 'source-file-insert-toplevel-form) sf 1 (%rd "(defun z () 0)"))
      (is (eql 5 (%startline b)))
      (is (eql 7 (%startline c))))))

(test source-file-delete-shifts-positions-up-and-drops-lines
  (with-sf-temp (path (format nil "(defun a (x) x)~%~%(defun b (y) y)~%~%(defun c (z) z)~%"))
    (let* ((sf (funcall (%sf 'source-file-open) path 'update))
           (a (funcall (%sf 'source-file-read) sf))
           (b (funcall (%sf 'source-file-read) sf))
           (c (funcall (%sf 'source-file-read) sf)))
      (declare (ignore a b))
      (funcall (%sf 'source-file-delete-toplevel-form) sf 1) ; delete A + its blank
      (funcall (%sf 'source-file-save-and-close) sf)
      (let ((text (uiop:read-file-string path)))
        (is (null (search "defun a" text)))
        (is (search "defun b" text))
        (is (search "defun c" text))
        ;; C's recorded position stayed consistent with where it now is
        (is (eql (%startline c) (%line-of "defun c" text)))))))

(test source-file-replace-shifts-by-delta
  (with-sf-temp (path (format nil "(defun a (x) x)~%~%(defun b (y) y)~%"))
    (let* ((sf (funcall (%sf 'source-file-open) path 'update))
           (a (funcall (%sf 'source-file-read) sf))
           (b (funcall (%sf 'source-file-read) sf)))
      (declare (ignore a))
      ;; replace A with a bigger form; B's recorded position must stay consistent
      ;; with where B actually ends up in the file, whatever the reflow height.
      (funcall (%sf 'source-file-replace-toplevel-form)
               sf 1 (%rd "(defun a (x) (+ x 1) (* x 2) (- x 3))"))
      (funcall (%sf 'source-file-save-and-close) sf)
      (let ((text (uiop:read-file-string path)))
        (is (eql (%startline b) (%line-of "defun b" text)))))))

(test source-file-save-file-text-keeps-positions-consistent
  ;; a whole-file save (as sedit does) where form A grew must leave B and C
  ;; with positions matching where they actually end up.
  (with-sf-temp (path (format nil "(defun a (x) x)~%~%(defun b (y) y)~%~%(defun c (z) z)~%"))
    (let* ((sf (funcall (%sf 'source-file-open) path 'read))
           (a (funcall (%sf 'source-file-read) sf))
           (b (funcall (%sf 'source-file-read) sf))
           (c (funcall (%sf 'source-file-read) sf)))
      (declare (ignore a))
      (funcall (%sf 'save-file-text) path
               (format nil "(defun a (x)~%  (+ x 1)~%  x)~%~%(defun b (y) y)~%~%(defun c (z) z)~%"))
      (let ((text (uiop:read-file-string path)))
        (is (eql (%startline b) (%line-of "defun b" text)))
        (is (eql (%startline c) (%line-of "defun c" text)))))))

(test source-file-insert-inside-a-form-is-an-error
  (with-sf-temp (path (format nil "(defun a (x)~%  (+ x 1))~%"))
    (let ((sf (funcall (%sf 'source-file-open) path 'update)))
      (funcall (%sf 'source-file-read) sf)
      (is (eq :caught
              (handler-case
                  (progn (funcall (%sf 'source-file-insert-toplevel-form)
                                  sf 2 (%rd "(defun q () 1)"))
                         :no-error)
                (error () :caught)))))))
