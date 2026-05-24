;;;; autolisp-front-end/scripts/check-spec-coverage.lisp
;;;;
;;;; Spec-coverage check, per alfe-conformance.issue section 4.
;;;;
;;;; Walks documentation/alfe--specifications.org for CLI option
;;;; names (the =--foo= / =-x= shorthand notation the spec uses) and
;;;; asserts each appears in at least one scenario's :covers-options
;;;; or :argv list. Run with:
;;;;
;;;;   make -C autolisp-front-end check-spec-coverage
;;;;
;;;; or directly:
;;;;
;;;;   sbcl --script scripts/check-spec-coverage.lisp
;;;;
;;;; Exit codes: 0 = every option covered; 1 = at least one
;;;; uncovered (the offending options print to stderr); 2 = setup
;;;; error (spec file missing, etc.).
;;;;
;;;; The check is intentionally lossy: it greps the spec for
;;;; ``=--foo=`` and ``=-X=`` patterns rather than parsing the org
;;;; tables. Option names invented elsewhere (e.g. inside a
;;;; lengthy prose section) still get caught.

(require :asdf)

(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname))))
  (when (probe-file ql) (load ql)))
(when (find-package :ql)
  (funcall (find-symbol "QUICKLOAD" :ql) "fiveam" :silent t)
  (funcall (find-symbol "QUICKLOAD" :ql) "bordeaux-threads" :silent t)
  (funcall (find-symbol "QUICKLOAD" :ql) "trivial-gray-streams" :silent t))

(defun resolve-relative (relative)
  (let ((self (or *load-pathname* *load-truename*)))
    (when self
      (merge-pathnames relative
                       (make-pathname :name nil :type nil :version nil
                                      :defaults self)))))

(asdf:load-asd (namestring (resolve-relative "../../clautolisp/clautolisp.asd")))
(asdf:load-asd (namestring (resolve-relative "../autolisp-front-end.asd")))
(asdf:load-system "autolisp-front-end/conformance")

;;; --- option extraction ---------------------------------------------

(defparameter *spec-path*
  (namestring (resolve-relative "../documentation/alfe--specifications.org")))

(defparameter *scenarios-dir*
  (alfe.conformance:scenarios-directory))

(defparameter *exempt-options*
  '("-B"   ; BricsCAD's own batch flag passed in argv; not an alfe option.
    "-P"   ; BricsCAD's profile flag passed through to the engine.
    "/i"   ; accoreconsole.exe input flag (Windows).
    "/s")  ; accoreconsole.exe script flag (Windows).
  "Option-shaped tokens the spec mentions because they appear in the
emitted *engine-side* command line — not alfe's own CLI. The
spec-coverage check skips these so they don't show up as
'uncovered'.")

(defun option-token-p (token)
  "True iff TOKEN looks like a CLI option name: --foo, --foo-bar, or
single-letter -X. We also accept --opt=VALUE form, but only the
prefix up to = counts."
  (and (stringp token)
       (>= (length token) 2)
       (char= (char token 0) #\-)
       (or (and (char= (char token 1) #\-)
                (>= (length token) 3)
                (alpha-char-p (char token 2)))
           (and (not (char= (char token 1) #\-))
                (alpha-char-p (char token 1))))))

(defun strip-trailing (string chars)
  "Trim CHARS from the right end of STRING."
  (let ((end (length string)))
    (loop while (and (plusp end)
                     (find (char string (1- end)) chars))
          do (decf end))
    (subseq string 0 end)))

(defun normalise-option-token (token)
  "Strip = / whitespace / trailing punctuation so the spec's
verbatim spans like `=--opt=VAL=` and `=-B <run.scr>=` reduce to the
option name (`--opt`, `-B`). Returns NIL when TOKEN doesn't begin
with an option-shaped prefix."
  (let* ((first-segment
           ;; Take everything up to the first whitespace — drops the
           ;; argument placeholder in `-B <run.scr>` / `-l FILE` spans.
           (subseq token 0 (or (position-if
                                (lambda (c) (find c '(#\Space #\Tab)))
                                token)
                               (length token))))
         (trimmed (strip-trailing
                   first-segment
                   '(#\= #\, #\. #\; #\) #\> #\: #\? #\!)))
         (eq-pos (position #\= trimmed)))
    (cond
      ((not (option-token-p trimmed)) nil)
      (eq-pos (subseq trimmed 0 eq-pos))
      (t trimmed))))

(defun extract-options-from-spec (path)
  "Return the set (an alist of (option . T)) of every CLI option
mentioned in the spec. We scan for tokens between org-mode `=`
verbatim markers — every option in the spec is documented that way."
  (let ((options (make-hash-table :test #'equal)))
    (with-open-file (in path :external-format :utf-8)
      (loop for line = (read-line in nil :eof)
            until (eq line :eof)
            do (let ((position 0))
                 (loop while (< position (length line))
                       for start = (position #\= line :start position)
                       while start
                       for end = (position #\= line :start (1+ start))
                       while end
                       do (let ((token (subseq line (1+ start) end)))
                            (let ((opt (normalise-option-token token)))
                              (when opt
                                (setf (gethash opt options) t))))
                          (setf position (1+ end))))))
    (sort (loop for k being the hash-keys of options collect k)
          #'string<)))

(defun collect-scenario-options (scenarios)
  "Collect the union of every option referenced in any scenario's
:argv or :covers-options. Returns a hash table whose keys are the
option strings."
  (let ((seen (make-hash-table :test #'equal)))
    (dolist (scenario scenarios)
      (dolist (token (alfe.conformance:scenario-argv scenario))
        (let ((opt (normalise-option-token token)))
          (when opt (setf (gethash opt seen) t))))
      (dolist (opt (getf scenario :covers-options))
        (setf (gethash opt seen) t)))
    seen))

;;; --- main ---------------------------------------------------------

(handler-case
    (let* ((spec-options (extract-options-from-spec *spec-path*))
           (scenarios (alfe.conformance:read-scenarios-from *scenarios-dir*))
           (covered (collect-scenario-options scenarios))
           (uncovered (remove-if (lambda (opt)
                                   (or (gethash opt covered)
                                       (member opt *exempt-options*
                                               :test #'string=)))
                                 spec-options)))
      (format t "~&alfe spec-coverage:~%")
      (format t "  spec options:     ~D~%" (length spec-options))
      (format t "  covered options:  ~D~%"
              (- (length spec-options) (length uncovered)))
      (format t "  uncovered:        ~D~%" (length uncovered))
      (when uncovered
        (format *error-output* "~&Uncovered CLI options:~%")
        (dolist (opt uncovered)
          (format *error-output* "  ~A~%" opt))
        (uiop:quit 1))
      (uiop:quit 0))
  (error (probe)
    (format *error-output* "~&spec-coverage check failed: ~A~%" probe)
    (uiop:quit 2)))
