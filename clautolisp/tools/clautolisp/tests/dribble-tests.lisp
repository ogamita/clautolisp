;;;; clautolisp/tools/clautolisp/tests/dribble-tests.lisp
;;;;
;;;; FiveAM tests for the dribble feature (dribble.issue): start/stop,
;;;; the O/E tee prefixing and line-interleaving rule, the raw input
;;;; echo (with prompt suppression), interactor filtering, and the
;;;; toggle semantics of CLAL-DRIBBLE.

(in-package #:clautolisp.tools.clautolisp.tests)

(in-suite clautolisp-tool-suite)

;;; The dribble internals are deliberately unexported — these tests are
;;; the only outside reader, hence the `::' references throughout.

(defun call-with-dribble-to-string (names thunk)
  "Run THUNK with a dribble active on a string stream (no file) and the
captured interactor set NAMES; returns everything written to the
dribble. The interactor stack is empty, which counts as AUTOLISP."
  (with-output-to-string (dribble)
    (let ((clautolisp.tools.clautolisp::*dribble-stream* dribble)
          (clautolisp.tools.clautolisp::*dribble-names*
            (clautolisp.tools.clautolisp::%resolve-dribble-names names))
          (clautolisp.tools.clautolisp::*dribble-open-tee* nil)
          (clautolisp.interactor:*interactor-stack* '()))
      (funcall thunk)
      ;; Flush a pending partial line, as dribble-stop would.
      (clautolisp.tools.clautolisp::%dribble-terminate-open-line))))

(test dribble-tee-prefixes-output-lines
  "Complete lines through the O tee land as `;; O: ' lines; the real
stream sees the text verbatim."
  (let* ((real (make-string-output-stream))
         (dribbled
           (call-with-dribble-to-string
            nil
            (lambda ()
              (let ((tee (clautolisp.tools.clautolisp::make-dribble-output-tee real "O")))
                (write-string "6" tee)
                (terpri tee)
                (write-string "hello world" tee)
                (terpri tee))))))
    (is (string= (format nil "6~%hello world~%")
                 (get-output-stream-string real)))
    (is (string= (format nil ";; O: 6~%;; O: hello world~%") dribbled))))

(test dribble-tee-interleaving-terminates-open-line
  "When the E tee writes while the O tee owns an open (partial) line,
the O partial is terminated as a complete prefixed line first."
  (let* ((real-o (make-string-output-stream))
         (real-e (make-string-output-stream))
         (dribbled
           (call-with-dribble-to-string
            nil
            (lambda ()
              (let ((o (clautolisp.tools.clautolisp::make-dribble-output-tee real-o "O"))
                    (e (clautolisp.tools.clautolisp::make-dribble-output-tee real-e "E")))
                (write-string "partial" o)          ; no newline yet
                (write-string "boom" e)
                (terpri e)
                (write-string "rest" o)
                (terpri o))))))
    (is (string= (format nil ";; O: partial~%;; E: boom~%;; O: rest~%")
                 dribbled))))

(test dribble-tee-passes-through-when-off
  "With no dribble active the tee is a pure pass-through."
  (let* ((real (make-string-output-stream))
         (clautolisp.tools.clautolisp::*dribble-stream* nil)
         (tee (clautolisp.tools.clautolisp::make-dribble-output-tee real "O")))
    (format tee "plain~%")
    (is (string= (format nil "plain~%") (get-output-stream-string real)))))

(test dribble-tee-fresh-line-tracking
  "The tee tracks its column so FRESH-LINE / ~& behave: no spurious
newline at line start, a newline (closing the dribble line) mid-line."
  (let* ((real (make-string-output-stream))
         (dribbled
           (call-with-dribble-to-string
            nil
            (lambda ()
              (let ((tee (clautolisp.tools.clautolisp::make-dribble-output-tee real "O")))
                (fresh-line tee)                     ; at column 0: no-op
                (write-string "abc" tee)
                (fresh-line tee)                     ; mid-line: newline
                (fresh-line tee))))))                ; column 0 again: no-op
    (is (string= (format nil "abc~%") (get-output-stream-string real)))
    (is (string= (format nil ";; O: abc~%") dribbled))))

(test dribble-input-echo-raw-line-and-prompt-suppression
  "A consumed input line is dribbled RAW; a pending partial output line
(the prompt) is discarded, not emitted."
  (let* ((real-o (make-string-output-stream))
         (dribbled
           (call-with-dribble-to-string
            nil
            (lambda ()
              (let ((o (clautolisp.tools.clautolisp::make-dribble-output-tee real-o "O"))
                    (in (clautolisp.tools.clautolisp::make-dribble-input-echo
                         (make-string-input-stream
                          (format nil "(+ 1 2 3)~%")))))
                (write-string "_$ " o)               ; the prompt: partial line
                (is (string= "(+ 1 2 3)" (read-line in)))
                (format o "6~%"))))))
    (is (string= (format nil "(+ 1 2 3)~%;; O: 6~%") dribbled))))

(test dribble-input-echo-eof-flushes-last-line
  "A final input line not terminated by a newline is still dribbled."
  (let ((dribbled
          (call-with-dribble-to-string
           nil
           (lambda ()
             (let ((in (clautolisp.tools.clautolisp::make-dribble-input-echo
                        (make-string-input-stream "(quit)"))))
               (is (string= "(quit)" (read-line in nil nil))))))))
    (is (string= (format nil "(quit)~%") dribbled))))

(test dribble-filtering-empty-stack-counts-as-autolisp
  "The default captured set is (\"AUTOLISP\"); an empty interactor
stack counts as AUTOLISP, so recording happens."
  (let ((dribbled
          (call-with-dribble-to-string
           nil
           (lambda ()
             (let ((tee (clautolisp.tools.clautolisp::make-dribble-output-tee
                         (make-broadcast-stream) "O")))
               (format tee "yes~%"))))))
    (is (string= (format nil ";; O: yes~%") dribbled))))

(test dribble-filtering-excludes-unlisted-interactor
  "With a captured set not containing the current top interactor,
nothing is recorded (the real stream still sees everything)."
  (let* ((real (make-string-output-stream))
         (dribbled
           (call-with-dribble-to-string
            '("ALDO")
            (lambda ()
              (let ((tee (clautolisp.tools.clautolisp::make-dribble-output-tee real "O")))
                ;; empty stack = AUTOLISP, which is not in ("ALDO").
                (format tee "hidden~%"))))))
    (is (string= (format nil "hidden~%") (get-output-stream-string real)))
    (is (string= "" dribbled))))

(test dribble-filtering-all-records-everything
  "The :ALL set records regardless of the top interactor."
  (let ((dribbled
          (call-with-dribble-to-string
           :all
           (lambda ()
             (let ((tee (clautolisp.tools.clautolisp::make-dribble-output-tee
                         (make-broadcast-stream) "O")))
               (format tee "everything~%"))))))
    (is (string= (format nil ";; O: everything~%") dribbled))))

(test dribble-resolve-names
  "NIL -> AUTOLISP only; T / :ALL -> :ALL; a list resolves aliases to
canonical interactor names and keeps unregistered names (upcased)."
  (is (equal '("AUTOLISP")
             (clautolisp.tools.clautolisp::%resolve-dribble-names nil)))
  (is (eq :all (clautolisp.tools.clautolisp::%resolve-dribble-names t)))
  (is (eq :all (clautolisp.tools.clautolisp::%resolve-dribble-names :all)))
  ;; "LISP" is the AUTOLISP interactor's alias.
  (is (equal '("AUTOLISP")
             (clautolisp.tools.clautolisp::%resolve-dribble-names '("lisp"))))
  (is (equal '("NOSUCH")
             (clautolisp.tools.clautolisp::%resolve-dribble-names '("nosuch")))))

(test dribble-condition-lines
  "DRIBBLE-CONDITION writes each line of the condition report prefixed
`;; C: ', terminating any open output line first."
  (let* ((real (make-string-output-stream))
         (dribbled
           (call-with-dribble-to-string
            nil
            (lambda ()
              (let ((tee (clautolisp.tools.clautolisp::make-dribble-output-tee real "O")))
                (write-string "part" tee)
                (clautolisp.tools.clautolisp::dribble-condition
                 (make-condition 'simple-error
                                 :format-control "line one~%line two")))))))
    (is (string= (format nil ";; O: part~%;; C: line one~%;; C: line two~%")
                 dribbled))))

(test dribble-start-stop-file-and-header
  "DRIBBLE-START opens (appends), writes the header with the version,
returns the absolute namestring; DRIBBLE-STOP closes and returns NIL;
CLAL-DRIBBLE toggles."
  (let* ((path (merge-pathnames
                (format nil "clautolisp-dribble-test-~D.log" (get-universal-time))
                (uiop:temporary-directory)))
         (clautolisp.tools.clautolisp::*dribble-stream* nil)
         (clautolisp.tools.clautolisp::*dribble-names* nil)
         (clautolisp.tools.clautolisp::*dribble-path* nil)
         (clautolisp.tools.clautolisp::*dribble-open-tee* nil))
    (unwind-protect
         (progn
           ;; explicit path: starts, returns absolute namestring
           (let ((result (clautolisp.tools.clautolisp::clal-dribble
                          (namestring path))))
             (is (stringp result))
             (is (uiop:absolute-pathname-p (pathname result)))
             (is (streamp clautolisp.tools.clautolisp::*dribble-stream*))
             (is (equal '("AUTOLISP") clautolisp.tools.clautolisp::*dribble-names*)))
           ;; toggle off: returns NIL, closes the stream
           (is (null (clautolisp.tools.clautolisp::clal-dribble)))
           (is (null clautolisp.tools.clautolisp::*dribble-stream*))
           (let ((first-contents (uiop:read-file-string path)))
             (is (string= (format nil ";; H: clautolisp ~A~%"
                                  clautolisp.tools.clautolisp:*version*)
                          first-contents))
             ;; restarting on the same path APPENDS (a second header)
             (clautolisp.tools.clautolisp::clal-dribble (namestring path) :all)
             (is (eq :all clautolisp.tools.clautolisp::*dribble-names*))
             (clautolisp.tools.clautolisp::clal-dribble)
             (is (string= (concatenate 'string first-contents first-contents)
                          (uiop:read-file-string path)))))
      (when (streamp clautolisp.tools.clautolisp::*dribble-stream*)
        (close clautolisp.tools.clautolisp::*dribble-stream*))
      (ignore-errors (delete-file path)))))

(test dribble-cli-parse-interactors
  "--dribble-interactors=t -> :ALL; a comma-separated list -> names;
an empty value is a usage error."
  (is (eq :all (clautolisp.autolisp-cli:parse-dribble-interactors
                "t" "--dribble-interactors")))
  (is (eq :all (clautolisp.autolisp-cli:parse-dribble-interactors
                "T" "--dribble-interactors")))
  (is (equal '("AUTOLISP" "ALDO")
             (clautolisp.autolisp-cli:parse-dribble-interactors
              "AUTOLISP,ALDO" "--dribble-interactors")))
  (is (equal '("navi")
             (clautolisp.autolisp-cli:parse-dribble-interactors
              " navi " "--dribble-interactors")))
  (signals clautolisp.autolisp-cli:cli-usage-error
    (clautolisp.autolisp-cli:parse-dribble-interactors
     "" "--dribble-interactors")))

(test dribble-cli-optional-argument
  "--dribble is optional-argument: bare form records T, --dribble=FILE
records the file, and the following argv element is NOT consumed."
  (let ((options (clautolisp.tools.clautolisp::parse-arguments
                  '("--dribble" "-x" "(+ 1 2)"))))
    (is (eq t (clautolisp.autolisp-cli:cli-options-dribble options)))
    (is (equal '((:expression . "(+ 1 2)"))
               (clautolisp.autolisp-cli:cli-options-actions options))))
  (let ((options (clautolisp.tools.clautolisp::parse-arguments
                  '("--dribble=/tmp/trace.sexp"
                    "--dribble-interactors=t"))))
    (is (equal "/tmp/trace.sexp"
               (clautolisp.autolisp-cli:cli-options-dribble options)))
    (is (eq :all (clautolisp.autolisp-cli:cli-options-dribble-interactors
                  options)))))
