(in-package #:clautolisp.autolisp-cli)

;;;; Generic spec-driven argv parser. Both clautolisp and alfe build
;;;; a list of option-spec records (common + tool-specific) and feed
;;;; argv through PARSE-ARGUMENTS-WITH-SPEC, which returns a fully-
;;;; populated CLI-OPTIONS struct.
;;;;
;;;; Long options accept both `--opt VALUE` and `--opt=VALUE`. Short
;;;; options are matched as exact strings (so `-norc` is a long-form
;;;; written with a single dash, matching the existing CLI surface).
;;;;
;;;; Unknown options signal CLI-USAGE-ERROR. Positional arguments
;;;; (anything that doesn't start with `-` AND isn't recognised as an
;;;; option) are pushed onto cli-options-positional in order, and
;;;; additionally queued as a (:file . PATH) action so a bare
;;;; `clautolisp foo.lsp` invocation works like `-l foo.lsp`.

(defun %starts-with-dash-p (string)
  (and (plusp (length string))
       (char= (char string 0) #\-)))

(defun %split-equals (argument)
  "Split `--opt=VALUE` into (values OPT VALUE). Returns (values
ARGUMENT nil) when there is no `=`."
  (let ((eq (position #\= argument)))
    (if eq
        (values (subseq argument 0 eq) (subseq argument (1+ eq)))
        (values argument nil))))

(defun %find-spec (name specs)
  "Return the first option-spec in SPECS that matches NAME on either
its long or short alias list, or nil."
  (find-if (lambda (spec)
             (or (member name (option-spec-longs spec) :test #'string=)
                 (member name (option-spec-shorts spec) :test #'string=)))
           specs))

(defun %pop-arg-value (option remaining-cell)
  "Pop the head of the live argv tail held by REMAINING-CELL (a cons
whose CAR is the tail). Signals CLI-USAGE-ERROR when the tail is
empty — every option that takes a value must have one."
  (let ((rest (car remaining-cell)))
    (unless rest
      (error 'cli-usage-error
             :option option
             :message (format nil "Missing argument after ~A" option)))
    (setf (car remaining-cell) (rest rest))
    (first rest)))

(defun parse-arguments-with-spec (specs argv
                                  &key (initial-options (make-cli-options)))
  "Walk ARGV against SPECS, returning the populated CLI-OPTIONS.
INITIAL-OPTIONS lets the caller pre-seed defaults (env-var folding,
test-only knobs); the default is a fresh struct."
  (let* ((options initial-options)
         (remaining (cons argv nil))
         (long-only-actions nil))
    (loop
      (let ((arg (when (car remaining) (pop (car remaining)))))
        (unless arg (return))
        (multiple-value-bind (head embedded-value) (%split-equals arg)
          (cond
            ;; Try a spec match (long or short, by exact head).
            ((let ((spec (%find-spec head specs)))
               (cond
                 ((null spec) nil)
                 ((option-spec-takes-arg-p spec)
                  (let ((value
                          (or embedded-value
                              (%pop-arg-value head remaining))))
                    (funcall (option-spec-handler spec) options value head))
                  t)
                 (t
                  (when embedded-value
                    (error 'cli-usage-error
                           :option head
                           :message
                           (format nil "Option ~A does not take a value (got ~S)"
                                   head embedded-value)))
                  (funcall (option-spec-handler spec) options nil head)
                  t))))
            ;; Unknown -…
            ((%starts-with-dash-p arg)
             (error 'cli-usage-error
                    :option arg
                    :message (format nil "Unknown option ~A" arg)))
            ;; Positional: file argument.
            (t
             (push arg (cli-options-positional options))
             (push (cons :file arg) long-only-actions))))))
    (setf (cli-options-positional options)
          (nreverse (cli-options-positional options)))
    (setf (cli-options-actions options)
          (append (cli-options-actions options)
                  (nreverse long-only-actions)))
    options))
