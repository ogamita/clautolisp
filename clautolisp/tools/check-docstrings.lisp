;;;; check-docstrings.lisp — catch docstrings that end where they did not mean to.
;;;;
;;;; THE DEFECT THIS EXISTS FOR. An unescaped double quote inside a
;;;; docstring closes it early. What follows is no longer prose: it is
;;;; read as FORMS, and they land in the function's body.
;;;;
;;;; It has happened twice, and only one of the two was caught by running
;;;; the tests:
;;;;
;;;;   2.0.9  CALL-IN-FILE-COMPILATION-UNIT's docstring left
;;;;          `SPEED 3 compiles the whole file at once' as bare symbols in
;;;;          the body. SBCL DELETES the dead variable read; CCL evaluates
;;;;          it and signals `Unbound variable: SPEED'. Every LOAD failed
;;;;          on CCL, and nothing failed on SBCL.
;;;;
;;;;   2.0.13 (SETF FRAME-BINDING)'s docstring was truncated and the rest
;;;;          of the explanation became a dead STRING constant at the head
;;;;          of the body. A dead constant upsets neither host, so all 31
;;;;          suites passed on both — and the defect shipped. One
;;;;          character further left and it would have been 2.0.9 again.
;;;;
;;;; So a test run is not a detector for this: whether it is caught
;;;; depends on what the prose happens to say. This is, though — the
;;;; symptom is structural, not textual. A definition's body should not
;;;; contain dead constants or bare variable reads BEFORE its last form.
;;;; Real code does not do that; a broken docstring always does.
;;;;
;;;; Run: sbcl --load tools/check-docstrings.lisp   (from clautolisp/)
;;;; Exit status 1 and a report if anything is flagged.

(require :asdf)
(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname))))
  (when (probe-file ql) (load ql)))

;;; The system has to be LOADED before the sources can be read: a form
;;; like `internal::dynamic-frame-bindings' is unreadable until the
;;; package exists. Reading is all that happens afterwards.
(asdf:load-asd (merge-pathnames "clautolisp.asd" (uiop:getcwd)))
(handler-bind ((warning #'muffle-warning))
  (asdf:load-system "clautolisp/clautolisp-tool" :verbose nil)
  (asdf:load-system "clautolisp/autolisp-compiler" :verbose nil))

(defpackage #:clautolisp.check-docstrings (:use #:cl))
(in-package #:clautolisp.check-docstrings)

(defparameter *definition-heads*
  '(defun defmacro defmethod define-compiler-macro)
  "The forms whose body this check walks. All of them take an optional
docstring in the same position, which is what makes the symptom uniform.")

(defun dead-form-p (form)
  "True when FORM cannot have an effect and cannot be the value of the
body, i.e. it is dead where it stands.

A string, a number, a keyword or a QUOTE form in non-final position is
dead. So is a bare symbol: reading a variable and discarding it does
nothing — and it is exactly what a broken docstring leaves behind, since
prose reads as a run of symbols."
  (or (stringp form)
      (numberp form)
      (keywordp form)
      (characterp form)
      (and (symbolp form) (not (null form)) (not (eq form t)))
      (and (consp form) (eq (first form) 'quote))))

(defun definition-body (form)
  "The body forms of FORM, past the name and lambda list, with a leading
docstring dropped. NIL when FORM is not a definition this check walks."
  (when (and (consp form)
             (member (first form) *definition-heads*)
             (>= (length form) 3))
    (let ((tail (if (eq (first form) 'defmethod)
                    ;; (defmethod name [qualifier]* lambda-list . body)
                    (let ((rest (cddr form)))
                      (loop while (and rest (not (listp (first rest))))
                            do (pop rest))
                      (rest rest))
                    (cdddr form))))
      ;; A docstring is only a docstring when something follows it;
      ;; a lone string is the function's return value.
      (if (and (stringp (first tail)) (rest tail))
          (rest tail)
          tail))))

(defun permissive-readtable ()
  "A readtable that reads `#.FORM' as a placeholder instead of evaluating
it. *READ-EVAL* NIL would make such a file unreadable, and running the
repository's own read-time evaluation just to lint a docstring is a
trade nobody should make: this check reads, it does not run."
  (let ((readtable (copy-readtable nil)))
    (set-dispatch-macro-character
     #\# #\.
     (lambda (stream character argument)
       (declare (ignore character argument))
       (read stream t nil t)
       :read-time-evaluation)
     readtable)
    readtable))

(defun %token-char-p (character)
  (or (alphanumericp character)
      (find character "-+*/%.<>=&!?_$")))

(defun ensure-packages-named-in (text)
  "Create, empty, every package TEXT names as a prefix that does not exist.

Reading a source file needs its packages to EXIST -- `internal::foo' is
unreadable otherwise -- and not every package can be had by loading a
system: some come from optional dependencies (CFFI, charms) that a given
build may not have. Rather than skip those files, which would make this
check silently blind exactly where nobody is looking, the missing
packages are conjured empty. Nothing is evaluated, so an empty package
is enough to read a form; a stray package invented from a colon inside a
comment is harmless in a process that exits a moment later."
  (let ((length (length text)))
    (loop with start = 0
          for colon = (position #\: text :start start)
          while colon
          do (setf start (1+ colon))
             (let ((end colon))
               (loop while (and (plusp end) (%token-char-p (char text (1- end))))
                     do (decf end))
               (when (< end colon)
                 (let ((name (string-upcase (subseq text end colon))))
                   (when (and (plusp (length name))
                              (not (find-package name))
                              ;; A prefix, not the tail of something else:
                              ;; the character before must not be one that
                              ;; would make this a keyword or a comment word.
                              (or (zerop end) (not (char= (char text (1- end)) #\:))))
                     (ignore-errors (make-package name :use nil))))))
             (when (and (< start length) (char= (char text start) #\:))
               (incf start)))))

(defun check-file (path)
  "Report every dead non-final body form in PATH. Returns the count."
  (let ((problems 0))
    (ensure-packages-named-in (uiop:read-file-string path :external-format :utf-8))
    (with-open-file (stream path :external-format :utf-8)
      (let ((*read-eval* nil)
            (*readtable* (permissive-readtable))
            (*package* (find-package :cl-user)))
        (loop
          (let ((form (handler-case
                          ;; `PKG:SYM' where SYM is not external -- which a
                          ;; test file may legitimately write against a
                          ;; version of a library this image does not have --
                          ;; offers a CONTINUE restart that interns it. Taking
                          ;; it keeps the file READABLE, which is the whole
                          ;; point: a file this check cannot read is a file it
                          ;; cannot check, and that is where a defect would
                          ;; sit unseen.
                          (handler-bind
                              ((error (lambda (condition)
                                        (let ((restart (find-restart 'continue condition)))
                                          (when restart (invoke-restart restart))))))
                            (read stream nil :eof))
                        (error (condition)
                          ;; A file this check cannot read is worth
                          ;; saying so about rather than passing over:
                          ;; silence here would be the same failure this
                          ;; whole file exists to prevent.
                          (format t "~&~A: cannot read: ~A~%" path condition)
                          (incf problems)
                          :eof))))
            (when (eq form :eof) (return))
            (let ((body (definition-body form)))
              (loop for rest on body
                    while (rest rest)          ; every form but the last
                    for dead = (dead-form-p (first rest))
                    when dead
                      do (incf problems)
                         (format t "~&~A: ~S: dead form in body: ~S~%"
                                 (file-namestring path)
                                 (second form)
                                 (let ((text (format nil "~S" (first rest))))
                                   (subseq text 0 (min 70 (length text)))))))))))
    problems))

(let* ((root (uiop:getcwd))
       (files (sort (remove-if (lambda (p) (search "third-party" (namestring p)))
                               (directory (merge-pathnames "**/*.lisp" root)))
                    #'string< :key #'namestring))
       (total 0))
  (format t "~&check-docstrings: reading ~D files~%" (length files))
  (dolist (file files)
    (incf total (check-file file)))
  (cond
    ((zerop total)
     (format t "~&check-docstrings: OK (no dead body forms)~%")
     (uiop:quit 0))
    (t
     (format t "~&check-docstrings: ~D problem(s).~%~
Each is a form that cannot have an effect and is not the body's value.~%~
The usual cause is an unescaped double quote ending a docstring early,~%~
which turns the rest of the prose into forms. Use `like this' for~%~
quoting inside a docstring.~%" total)
     (uiop:quit 1))))
