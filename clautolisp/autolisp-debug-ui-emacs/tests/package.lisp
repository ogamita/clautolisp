;;;; clautolisp/autolisp-debug-ui-emacs/tests/package.lisp

(defpackage #:clautolisp.ui.emacs.tests
  (:use #:cl)
  (:import-from #:fiveam
                #:def-suite #:in-suite #:test #:is #:run #:explain! #:results-status)
  (:export #:run-all-tests))

(in-package #:clautolisp.ui.emacs.tests)

(def-suite emacs-suite
  :description "Emacs (aldb) RPC shim: protocol messages + command dispatch over string streams (§20).")

(defun run-all-tests ()
  (let ((results (run 'emacs-suite)))
    (explain! results)
    (unless (results-status results)
      (error "clautolisp.ui.emacs tests failed."))))

;;; --- fixtures ------------------------------------------------------

(defun rt-sym (name) (clautolisp.autolisp-runtime:intern-autolisp-symbol name))

(defparameter +two-source+
  ;; 1: (defun id (a) a)
  ;; 2: (defun two (x / z)
  ;; 3:   (setq z (id x))
  ;; 4:   (id z))
  (format nil "(defun id (a) a)~%(defun two (x / z)~%  (setq z (id x))~%  (id z))"))

(defun fresh-context ()
  (clautolisp.debug:reset-function-id-registry)
  (clautolisp.source:clear-source-positions)
  (clautolisp.autolisp-runtime:make-default-runtime-context))

(defun load-and-instrument (context source &rest names)
  (clautolisp.source:with-source-tracking ()
    (dolist (form (clautolisp.autolisp-runtime:read-runtime-from-string source :source-name "two.lsp"))
      (clautolisp.autolisp-runtime:autolisp-eval form context)))
  (mapcar (lambda (name)
            (clautolisp.debug:instrument-usubr
             (clautolisp.autolisp-runtime:lookup-function (rt-sym name) context)))
          names))

(defun fid-of (metadata) (clautolisp.debug:function-debug-metadata-function-id metadata))

(defun break-at (metas line)
  (let ((ti (clautolisp.debug:make-thread-debug-info :debug-flag t))
        (meta (first metas)))
    (clautolisp.debug:add-breakpoint
     ti (fid-of meta) (clautolisp.debug:find-form-id-at-line meta line) :when :before)
    ti))

(defun call-two (context)
  (clautolisp.autolisp-runtime:autolisp-eval (list (rt-sym "TWO") 7) context))

(defun run-emacs (command-forms &key context thread-info thunk)
  "Run THUNK under an Emacs-UI session whose INPUT is COMMAND-FORMS
rendered as text and whose OUTPUT is captured. Returns (values result
output-string messages) where MESSAGES is the list of read-back wire forms."
  (let* ((input (with-output-to-string (s)
                  (let ((*package* (find-package :keyword)) (*print-pretty* nil))
                    (dolist (form command-forms) (prin1 form s) (terpri s)))))
         (out (make-string-output-stream))
         (ui (clautolisp.ui.emacs:make-emacs-ui
              :input (make-string-input-stream input) :output out)))
    (let ((result (clautolisp.debug.ui:call-with-session
                   ui thunk :thread-info thread-info :context context)))
      (let ((text (get-output-stream-string out)))
        (values result text (parse-messages text))))))

(defun parse-messages (text)
  "Read every wire form the shim wrote (keyword package, like Emacs)."
  (with-input-from-string (s text)
    (let ((*package* (find-package :keyword)))
      (loop for form = (read s nil :eof)
            until (eq form :eof)
            collect form))))

(defun message-of (messages tag)
  "First wire message with car TAG, or NIL."
  (find tag messages :key (lambda (m) (and (consp m) (car m)))))

(defun message-tags (messages)
  (mapcar (lambda (m) (and (consp m) (car m))) messages))
