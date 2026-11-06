(in-package #:clautolisp.interactor.tests)

(in-suite interactor-suite)

;;;; The shell escape (bang.issue): a line whose FIRST character is the
;;;; shell-escape character sends its remainder to $SHELL with
;;;; stdin/stdout/stderr inherited.
;;;;
;;;; Both halves are hooks, so these tests install a recording runner
;;;; instead of spawning anything: what is under test is the RULES —
;;;; which lines escape, what command text comes out — not the process.

(defmacro with-shell-escape ((recorder &key (character #\!)) &body body)
  "Run BODY with the escape enabled on CHARACTER, RECORDER bound to a list
that collects every command handed to the runner."
  `(let ((,recorder '()))
     (let ((clautolisp.interactor::*shell-escape-character-hook*
             (constantly ,character))
           (clautolisp.interactor::*shell-escape-runner*
             (lambda (command) (push command ,recorder))))
       ,@body)
     (setf ,recorder (nreverse ,recorder))
     ,recorder))

(defun %escape-commands (script &key (character #\!))
  "The commands the runner receives while reading SCRIPT."
  (let ((collected '()))
    (let ((clautolisp.interactor::*shell-escape-character-hook*
            (constantly character))
          (clautolisp.interactor::*shell-escape-runner*
            (lambda (command) (push command collected))))
      (read-all #'comma-command-read script))
    (nreverse collected)))

;;; --- the & rule -----------------------------------------------------------

(test shell-escape-appends-echo-for-a-backgrounded-command
  "A command ending in `&' is backgrounded, and a NON-INTERACTIVE bash
prints neither the PID nor a job-control notice — so `echo $!' is appended
to print it (the ticket's `!pwd &' → `bash -c 'pwd & echo $!'')."
  (is (string= "pwd & echo $!"
               (clautolisp.interactor::%shell-escape-command-to-run "pwd &")))
  ;; "There may be spaces before or after the shell command, so the test
  ;; for & must take into account this possibility."
  (is (string= "pwd & echo $!"
               (clautolisp.interactor::%shell-escape-command-to-run "  pwd &   ")))
  (is (string= "pwd"
               (clautolisp.interactor::%shell-escape-command-to-run "  pwd  "))))

(test shell-escape-leaves-a-conjunction-alone
  "`a && b' does not END in `&' — appending `echo $!' there would print the
PID of nothing and is not what the ticket asks for."
  (is (string= "a && b"
               (clautolisp.interactor::%shell-escape-command-to-run "a && b")))
  (is (string= "a & b & echo $!"
               (clautolisp.interactor::%shell-escape-command-to-run "a & b &"))))

;;; --- continuation lines ---------------------------------------------------

(test shell-escape-joins-continuation-lines
  "A trailing backslash continues onto the next line: the ticket's
`!echo hello \\' then `world.' runs as one command."
  (is (equal '("echo hello world.")
             (%escape-commands (format nil "!echo hello \\~%world.~%"))))
  ;; several continuations in a row
  (is (equal '("abc")
             (%escape-commands (format nil "!a\\~%b\\~%c~%")))))

(test shell-escape-continuation-at-eof-does-not-hang
  "A trailing backslash on the LAST line has nothing to continue onto; it
must terminate rather than read forever."
  (is (equal '("echo hi")
             (%escape-commands (format nil "!echo hi\\~%")))))

;;; --- what does and does not escape ----------------------------------------

(test shell-escape-requires-the-character-first
  "\"There may not be any space or other character input before the
shell-escape-character.\" The reader left-trims lines, so this is exactly
the case a naive implementation gets wrong."
  (is (null (%escape-commands (format nil " !pwd~%"))))
  (is (null (%escape-commands (format nil "x!pwd~%"))))
  (is (equal '("pwd") (%escape-commands (format nil "!pwd~%")))))

(test shell-escape-is-off-until-both-hooks-are-installed
  "The interactor system is dependency-free and cannot run a shell by
itself: with no runner installed the escape does not fire, and the line is
read as ordinary input rather than silently swallowed."
  (let ((clautolisp.interactor::*shell-escape-character-hook* (constantly #\!))
        (clautolisp.interactor::*shell-escape-runner* nil))
    (is (null (shell-escape-character)))
    (let ((inputs (read-all #'command-read (format nil "!pwd~%"))))
      (is (= 1 (length inputs)))
      (is (input-command-p (first inputs)))))
  (let ((clautolisp.interactor::*shell-escape-character-hook* (constantly nil))
        (clautolisp.interactor::*shell-escape-runner* (lambda (c) (declare (ignore c)))))
    (is (null (shell-escape-character)))))

(test shell-escape-honours-a-configured-character
  "The character is configurable (setting shell-escape-character); it is
read through a HOOK so a change takes effect at once rather than at the
next launch."
  (is (equal '("pwd") (%escape-commands (format nil "@pwd~%") :character #\@)))
  (is (null (%escape-commands (format nil "!pwd~%") :character #\@))))

;;; --- the escape does not disturb the other readers ------------------------

(test shell-escape-leaves-commands-and-forms-alone
  "A comma command is still a command, a form is still a form, and a blank
line is still blank — the escape only claims lines that start with its own
character."
  (let ((collected '()))
    (let ((clautolisp.interactor::*shell-escape-character-hook* (constantly #\!))
          (clautolisp.interactor::*shell-escape-runner*
            (lambda (c) (push c collected))))
      (let ((inputs (read-all #'comma-command-read
                              (format nil ",date~%(+ 1 2)~%!pwd~%~%"))))
        ;; ,date -> command, (+ 1 2) -> form, !pwd -> handled (:blank),
        ;; empty line -> :blank
        (is (input-command-p (first inputs)))
        (is (equal '(+ 1 2) (second inputs)))
        (is (eq :blank (third inputs)))
        (is (eq :blank (fourth inputs)))))
    (is (equal '("pwd") (nreverse collected)))))
