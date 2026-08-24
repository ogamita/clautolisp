;;;; Interactive smoke test for the no-grovel CFFI ncurses backend.
;;;;
;;;; Run on a REAL terminal (macOS/Linux) from the clautolisp/ directory:
;;;;
;;;;   sbcl --script autolisp-debug-ui-tui-curses/test/smoke.lisp
;;;;
;;;; It opens libncurses on demand and brings up the four-pane ncurses
;;;; debugger UI stopped inside a tiny AutoLISP function. Keys:
;;;;   d u > <   navigate the source form (the >> gutter follows the selection)
;;;;   b         toggle a breakpoint at the selected form's line
;;;;   up/down   select a stack frame
;;;;   e         eval an expression in the frame (into the repl pane)
;;;;   c         continue — ends the demo
;;;;   q         abort
;;;; The terminal is restored (endwin) on exit.

(require :asdf)
(let ((ql (merge-pathnames #p"quicklisp/setup.lisp" (user-homedir-pathname))))
  (when (probe-file ql) (load ql)))
(dolist (s '("cffi" "babel" "trivial-gray-streams" "bordeaux-threads" "cl-ppcre"))
  (when (find-package :ql) (funcall (read-from-string "ql:quickload") s :silent t)))

(let* ((here (or *load-truename* *default-pathname-defaults*))
       ;; here = .../clautolisp/autolisp-debug-ui-tui-curses/test/smoke.lisp
       (clroot (merge-pathnames
                #p"../../" (make-pathname :directory (pathname-directory here)))))
  (asdf:load-asd (merge-pathnames "clautolisp.asd" clroot))
  (asdf:load-system "clautolisp/autolisp-debug-ui-ncurses")
  (asdf:load-asd (merge-pathnames
                  "autolisp-debug-ui-tui-curses/clautolisp-tui-curses.asd" clroot))
  (asdf:load-system "clautolisp-tui-curses"))

(defpackage #:curses-smoke (:use #:cl))
(in-package #:curses-smoke)

(defun rt-sym (n) (clautolisp.autolisp-runtime:intern-autolisp-symbol n))

(defparameter *src*
  (format nil "(defun id (a) a)~%(defun two (x / z)~%  (setq z (id x))~%  (id z))"))

(let ((ctx (progn (clautolisp.debug:reset-function-id-registry)
                  (clautolisp.source:clear-source-positions)
                  (clautolisp.autolisp-runtime:make-default-runtime-context))))
  (clautolisp.source:with-source-tracking ()
    (dolist (form (clautolisp.autolisp-runtime:read-runtime-from-string
                   *src* :source-name "two.lsp"))
      (clautolisp.autolisp-runtime:autolisp-eval form ctx)))
  (with-open-file (o "two.lsp" :direction :output
                               :if-exists :supersede :if-does-not-exist :create)
    (write-string *src* o))
  (let* ((meta (clautolisp.debug:instrument-usubr
                (clautolisp.autolisp-runtime:lookup-function (rt-sym "TWO") ctx)))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t))
         (screen (clautolisp.ui.tui.curses:make-curses-screen))
         (ui (clautolisp.debug.ui:make-ui :ncurses :screen screen)))
    (clautolisp.debug:instrument-usubr
     (clautolisp.autolisp-runtime:lookup-function (rt-sym "ID") ctx))
    (clautolisp.debug:add-breakpoint
     ti (clautolisp.debug:function-debug-metadata-function-id meta)
     (clautolisp.debug:find-form-id-at-line meta 3) :when :before)
    (clautolisp.debug.ui:call-with-session
     ui (lambda ()
          (clautolisp.autolisp-runtime:autolisp-eval (list (rt-sym "TWO") 7) ctx))
     :thread-info ti :context ctx)
    (format t "~&Smoke test finished — TWO returned; terminal restored.~%")))
