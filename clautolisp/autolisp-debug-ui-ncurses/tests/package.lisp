;;;; clautolisp/autolisp-debug-ui-ncurses/tests/package.lisp

(defpackage #:clautolisp.ui.ncurses.tests
  (:use #:cl)
  (:import-from #:fiveam
                #:def-suite #:in-suite #:test #:is #:run #:explain! #:results-status)
  (:export #:run-all-tests))

(in-package #:clautolisp.ui.ncurses.tests)

(def-suite ncurses-suite
  :description "TUI abstraction + four-pane ncurses debugger UI (spec §19).")

(defun run-all-tests ()
  (let ((results (run 'ncurses-suite)))
    (explain! results)
    (unless (results-status results)
      (error "clautolisp.ui.ncurses tests failed."))))

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

(defun run-ncurses (keys &key context thread-info thunk (rows 24) (cols 80))
  "Run THUNK under an ncurses session whose screen is a mock fed KEYS.
Returns (values result ui screen)."
  (let* ((screen (clautolisp.ui.tui:make-mock-screen :rows rows :cols cols :keys keys))
         (ui (clautolisp.ui.ncurses:make-ncurses-ui :screen screen))
         (result (clautolisp.debug.ui:call-with-session
                  ui thunk :thread-info thread-info :context context)))
    (values result ui screen)))

(defun grid-contains (screen substring)
  (and (clautolisp.ui.tui:mock-find-line screen substring) t))
