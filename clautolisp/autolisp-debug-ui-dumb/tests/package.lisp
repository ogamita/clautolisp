;;;; clautolisp/autolisp-debug-ui-dumb/tests/package.lisp

(defpackage #:clautolisp.ui.dumb.tests
  (:use #:cl)
  (:import-from #:fiveam
                #:def-suite #:in-suite #:test #:is #:run #:explain! #:results-status)
  (:export #:run-all-tests))

(in-package #:clautolisp.ui.dumb.tests)

(def-suite dumb-ui-suite
  :description "UI protocol + dumb-terminal debugger UI (spec §17, §18).")

(defun run-all-tests ()
  (let ((results (run 'dumb-ui-suite)))
    (explain! results)
    (unless (results-status results)
      (error "clautolisp.ui.dumb tests failed."))))

;;; --- fixtures ------------------------------------------------------

(defun rt-sym (name) (clautolisp.autolisp-runtime:intern-autolisp-symbol name))

(defparameter +frob-source+
  ;; 1: (defun id (a) a)
  ;; 2: (defun frob (x / z)
  ;; 3:   (setq z (id x))
  ;; 4:   z)
  (format nil "(defun id (a) a)~%(defun frob (x / z)~%  (setq z (id x))~%  z)"))

(defun fresh-context ()
  (clautolisp.debug:reset-function-id-registry)
  (clautolisp.debug:clear-virtual-breakpoints)
  (clautolisp.source:clear-source-positions)
  (clautolisp.autolisp-runtime:make-default-runtime-context))

(defun load-and-instrument (context source &rest names)
  (clautolisp.source:with-source-tracking ()
    (dolist (form (clautolisp.autolisp-runtime:read-runtime-from-string source :source-name "frob.lsp"))
      (clautolisp.autolisp-runtime:autolisp-eval form context)))
  (mapcar (lambda (name)
            (clautolisp.debug:instrument-usubr
             (clautolisp.autolisp-runtime:lookup-function (rt-sym name) context)))
          names))

(defun fid-of (metadata) (clautolisp.debug:function-debug-metadata-function-id metadata))

(defun run-ui (commands &key context thread-info thunk)
  "Run THUNK under a dumb-UI session whose input is COMMANDS (a string)
and output is captured. Returns (values result output-string)."
  (let* ((output (make-string-output-stream))
         (input (make-string-input-stream commands))
         (ui (clautolisp.ui.dumb:make-dumb-ui :input input :output output))
         (result (clautolisp.debug.ui:call-with-session
                  ui thunk :thread-info thread-info :context context)))
    (values result (get-output-stream-string output))))

(defun contains (haystack needle)
  (and (search needle haystack) t))

(defmacro with-fresh-user-dictionary (&body body)
  "Swap a fresh user dictionary onto the singleton *ALDO* interactor — the
live dictionary the stop loop dispatches through and the registration API
targets — for BODY's extent (interactor-design-revision.issue T5/D6: there
is no global user table; ALDO's slot IS the dictionary)."
  (let ((dict (gensym "DICT")) (saved (gensym "SAVED")))
    `(let ((,dict (clautolisp.debug.ui:make-command-dictionary "test"))
           (,saved (clautolisp.interactor:interactor-user-commands
                    clautolisp.ui.dumb::*aldo*)))
       (setf (clautolisp.interactor:interactor-user-commands
              clautolisp.ui.dumb::*aldo*)
             ,dict)
       (unwind-protect (progn ,@body)
         (setf (clautolisp.interactor:interactor-user-commands
                clautolisp.ui.dumb::*aldo*)
               ,saved)))))
