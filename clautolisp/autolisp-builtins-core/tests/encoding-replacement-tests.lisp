(in-package #:clautolisp.autolisp-builtins-core.tests)

(in-suite autolisp-builtins-core-suite)

;;;; encoding-replacement-character-option.issue: what a write does with a
;;;; character the target encoding cannot hold.
;;;;
;;;; Measured (error-processing catalogue, cases 535-545, 2026-11-03): no
;;;; vendor signals. AutoCAD 2022 keeps the low byte (U+012C -> ",", U+4E2D
;;;; -> "-"); BricsCAD V25 Windows best-fits ("I", "?"); BricsCAD V26 macOS
;;;; writes \U+XXXX. clautolisp used to let the host signal (SBCL) or
;;;; substitute silently (CCL). pjb's rule (error-processing-per-dialect.issue,
;;;; section 7): each vendor dialect does as its product; clautolisp, strict
;;;; and lax write the V26 escape; every dialect but lax warns, once per
;;;; calling function. Every test writes through a windows-1252 file, the
;;;; vendors' default write encoding, so the case is the probe's.

(defparameter *er-chr-300* (string (code-char 300))
  "LATIN CAPITAL LETTER I WITH BREVE, absent from windows-1252.")

(defparameter *er-a-zhong-b* (coerce (list #\a (code-char #x4E2D) #\b) 'string)
  "a, CJK U+4E2D, b -- the catalogue's case 538.")

(defun %er-octets (path)
  (with-open-file (in path :element-type '(unsigned-byte 8))
    (loop :for b := (read-byte in nil) :while b :collect b)))

(defun %er-text (path)
  "The file's octets as a string of Latin-1 characters, line ends stripped."
  (string-right-trim '(#\Newline #\Return)
                     (map 'string #'code-char (%er-octets path))))

(defun %er-write (dialect text &key (prelude "") (open-arguments "\"w\"")
                                    (writer "write-line"))
  "Write TEXT with WRITER through (open PATH OPEN-ARGUMENTS) under DIALECT,
the file encoding forced to windows-1252, after PRELUDE. Returns (values
FILE-TEXT RESULT WARNINGS): the file as Latin-1 text, the AutoLISP result of
the evaluation, and what went to *ERROR-OUTPUT*."
  (let ((path (namestring (merge-pathnames (format nil "clautolisp-er-~D.txt" (random 1000000))
                                           (uiop:temporary-directory))))
        (errors (make-string-output-stream)))
    (unwind-protect
         (let ((clautolisp.autolisp-runtime:*enc-diagnostic-stream* (make-broadcast-stream))
               (clautolisp.autolisp-runtime:*encoding-replacement-warnings-seen*
                (make-hash-table :test 'equal))
               (*error-output* errors))
           (reset-autolisp-symbol-table)
           (let ((result
                   (%al (format nil "(progn (setq *AUTOLISP-DIALECT* '~A)
                                       (setq *AUTOLISP-FILE-WRITE-ENCODING* \"windows-1252\")
                                       ~A
                                       (setq f (open ~S ~A))
                                       (setq r (vl-catch-all-apply '~A (list ~S f)))
                                       (close f)
                                       (if (vl-catch-all-error-p r)
                                           (strcat \"ERROR: \" (vl-catch-all-error-message r))
                                           \"OK\"))"
                                dialect prelude path open-arguments writer text))))
             (values (%er-text path)
                     (if (typep result 'clautolisp.autolisp-runtime:autolisp-string)
                         (clautolisp.autolisp-runtime:autolisp-string-value result)
                         result)
                     (get-output-stream-string errors))))
      (ignore-errors (delete-file path)))))

;;; --- the codec part ------------------------------------------------

(test encoding-replacement-text-policies
  (let ((i-breve (code-char 300))
        (zhong (code-char #x4E2D)))
    (is (clautolisp.autolisp-reader:character-encodable-p #\e :cp1252))
    (is (clautolisp.autolisp-reader:character-encodable-p (code-char 233) :cp1252))
    (is (clautolisp.autolisp-reader:character-encodable-p (code-char 8364) :cp1252)
        "the euro sign is in windows-1252 (0x80)")
    (is (not (clautolisp.autolisp-reader:character-encodable-p i-breve :cp1252)))
    (is (clautolisp.autolisp-reader:character-encodable-p i-breve :utf-8))
    (is (not (clautolisp.autolisp-reader:character-encodable-p i-breve :iso-8859-1)))
    (is (string= "," (clautolisp.autolisp-reader:encoding-replacement-text i-breve :cp1252 :low-byte)))
    (is (string= "-" (clautolisp.autolisp-reader:encoding-replacement-text zhong :cp1252 :low-byte)))
    (is (string= "I" (clautolisp.autolisp-reader:encoding-replacement-text i-breve :cp1252 :best-fit)))
    (is (string= "?" (clautolisp.autolisp-reader:encoding-replacement-text zhong :cp1252 :best-fit)))
    (is (string= "\\U+012C" (clautolisp.autolisp-reader:encoding-replacement-text i-breve :cp1252 :escape)))
    (is (string= "\\U+4E2D" (clautolisp.autolisp-reader:encoding-replacement-text zhong :cp1252 :escape)))
    (is (string= "#" (clautolisp.autolisp-reader:encoding-replacement-text i-breve :cp1252 #\#)))
    (is (null (clautolisp.autolisp-reader:encoding-replacement-text i-breve :cp1252 zhong))
        "a replacement the encoding cannot hold either is NIL, for the caller to signal")))

(test encoding-replacement-dialect-defaults
  (flet ((default (name)
           (clautolisp.autolisp-runtime:dialect-encoding-replacement-default
            (clautolisp.autolisp-reader:find-autolisp-dialect name))))
    (is (eq :escape (default :strict)))
    (is (eq :escape (default :clautolisp)))
    (is (eq :escape (default :lax)))
    (is (eq :low-byte (default :autocad-2022)))
    (is (eq :low-byte (default :autocad)))
    (is (eq :best-fit (default :bricscad-v25)))
    (is (eq :best-fit (default :bricscad)))
    (is (eq :escape (default :bricscad-mac)))))

(test encoding-replacement-parse
  (is (eql #\? (clautolisp.autolisp-runtime:parse-encoding-replacement "?")))
  (is (eq :error (clautolisp.autolisp-runtime:parse-encoding-replacement "ERROR")))
  (is (eq :low-byte (clautolisp.autolisp-runtime:parse-encoding-replacement "low-byte")))
  (is (eq :best-fit (clautolisp.autolisp-runtime:parse-encoding-replacement "best-fit")))
  (is (eq :escape (clautolisp.autolisp-runtime:parse-encoding-replacement "escape")))
  (is (null (clautolisp.autolisp-runtime:parse-encoding-replacement "")))
  (is (eq :invalid (clautolisp.autolisp-runtime:parse-encoding-replacement "question"))))

;;; --- the per-dialect defaults, through WRITE-LINE --------------------

(test encoding-replacement-clautolisp-and-strict-escape-and-warn
  ;; Section 7: the clautolisp behaviour is BricsCAD V26 macOS's, and --strict
  ;; returns what --dialect clautolisp returns -- warning, both.
  (dolist (dialect '("strict" "clautolisp"))
    (multiple-value-bind (file result warnings) (%er-write dialect *er-a-zhong-b*)
      (is (equal "OK" result) "~A: ~S" dialect result)
      (is (string= "a\\U+4E2Db" file) "~A: ~S" dialect file)
      (is (search "[encoding-replacement]" warnings) "~A: ~S" dialect warnings))))

(test encoding-replacement-error-policy-is-a-catchable-autolisp-error
  ;; The issue's "Also": the failure is an ordinary AutoLISP error that
  ;; vl-catch-all-apply catches -- and nothing of the line was written.
  (dolist (dialect '("strict" "autocad-2022" "lax"))
    (multiple-value-bind (file result)
        (%er-write dialect *er-chr-300* :prelude "(setq *AUTOLISP-ENCODING-REPLACEMENT* \"error\")")
      (is (and (stringp result) (search "ERROR:" result) (search "U+012C" result))
          "~A: expected a caught AutoLISP error naming U+012C, got ~S" dialect result)
      (is (string= "" file) "~A: nothing may be written, got ~S" dialect file))))

(test encoding-replacement-autocad-keeps-the-low-byte
  (multiple-value-bind (file result warnings) (%er-write "autocad-2022" *er-chr-300*)
    (is (equal "OK" result))
    (is (string= "," file))
    (is (search "[encoding-replacement]" warnings)
        "the substitution is a divergence: warned, got ~S" warnings))
  (is (string= "a-b" (%er-write "autocad-2022" *er-a-zhong-b*))))

(test encoding-replacement-bricscad-best-fit-and-escape
  (is (string= "I" (%er-write "bricscad-v25" *er-chr-300*)))
  (is (string= "a?b" (%er-write "bricscad-v25" *er-a-zhong-b*)))
  (is (string= "\\U+012C" (%er-write "bricscad-mac" *er-chr-300*)))
  (is (string= "a\\U+4E2Db" (%er-write "bricscad-mac" *er-a-zhong-b*))))

(test encoding-replacement-lax-is-silent
  (multiple-value-bind (file result warnings) (%er-write "lax" *er-a-zhong-b*)
    (is (equal "OK" result))
    (is (string= "a\\U+4E2Db" file))
    (is (not (search "[encoding-replacement]" warnings)))))

(test encoding-replacement-warns-once-per-caller
  ;; "the first time the caller called the function in question": two
  ;; substitutions from one caller give one notice, from two callers two.
  (multiple-value-bind (file result warnings)
      (%er-write "autocad-2022" *er-a-zhong-b*
                 :writer "(lambda (s f) (write-line s f) (write-line s f))")
    (declare (ignore file))
    (is (equal "OK" result))
    (is (= 1 (count-substrings "[encoding-replacement]" warnings))
        "one caller, one notice: ~S" warnings))
  (multiple-value-bind (file result warnings)
      (%er-write "autocad-2022" *er-a-zhong-b*
                 :prelude "(defun er-one (s f) (write-line s f)) (defun er-two (s f) (write-line s f))"
                 :writer "(lambda (s f) (er-one s f) (er-two s f) (er-one s f))")
    (declare (ignore file))
    (is (equal "OK" result))
    (is (= 2 (count-substrings "[encoding-replacement]" warnings))
        "two callers, two notices: ~S" warnings)))

(defun count-substrings (needle haystack)
  (loop with start = 0
        for hit = (search needle haystack :start2 start)
        while hit
        count t
        do (setf start (1+ hit))))

;;; --- the globals the option seeds ---------------------------------------

(test encoding-replacement-global-overrides-the-dialect
  (is (string= "a#b" (%er-write "strict" *er-a-zhong-b*
                                :prelude "(setq *AUTOLISP-ENCODING-REPLACEMENT* \"#\")")))
  (is (string= "a\\U+4E2Db" (%er-write "autocad-2022" *er-a-zhong-b*
                                       :prelude "(setq *AUTOLISP-ENCODING-REPLACEMENT* \"escape\")")))
  ;; A symbol works as well as a string.
  (is (string= "aIb" (%er-write "strict" (coerce (list #\a (code-char 300) #\b) 'string)
                                :prelude "(setq *AUTOLISP-ENCODING-REPLACEMENT* 'best-fit)")))
  ;; "error" makes a vendor dialect signal.
  (multiple-value-bind (file result)
      (%er-write "autocad-2022" *er-chr-300*
                 :prelude "(setq *AUTOLISP-ENCODING-REPLACEMENT* \"error\")")
    (is (string= "" file))
    (is (search "ERROR:" result))))

(test encoding-replacement-per-situation-global-wins
  (is (string= "a*b" (%er-write "strict" *er-a-zhong-b*
                                :prelude "(setq *AUTOLISP-ENCODING-REPLACEMENT* \"#\"
                                                *AUTOLISP-FILE-WRITE-ENCODING-REPLACEMENT* \"*\")")))
  ;; The terminal one does not reach a file.
  (is (string= "a#b" (%er-write "strict" *er-a-zhong-b*
                                :prelude "(setq *AUTOLISP-ENCODING-REPLACEMENT* \"#\"
                                                *AUTOLISP-TERMINAL-ENCODING-REPLACEMENT* \"*\")"))))

(test encoding-replacement-invalid-global-is-an-autolisp-error
  (multiple-value-bind (file result)
      (%er-write "lax" *er-chr-300* :prelude "(setq *AUTOLISP-ENCODING-REPLACEMENT* \"question\")")
    (is (string= "" file))
    (is (and (stringp result) (search "*AUTOLISP-ENCODING-REPLACEMENT*" result))
        "got ~S" result)))

(test encoding-replacement-applies-to-every-writer
  (dolist (writer '("princ" "prin1" "print"))
    (is (search "a-b" (%er-write "autocad-2022" *er-a-zhong-b* :writer writer))
        "~A" writer))
  (is (string= "-" (%er-write "autocad-2022" (string (code-char #x4E2D))
                               :writer "(lambda (s f) (write-char (ascii s) f))"))))

(test encoding-replacement-explicit-encoding-argument
  ;; A named encoding without a :REPLACEMENT says nothing about replacement:
  ;; the policy applies to it too.
  (is (string= "," (%er-write "autocad-2022" *er-chr-300* :open-arguments "\"w\" \"cp1252\"")))
  ;; A UTF-8 file holds everything: nothing to replace.
  (is (equal '(#xC4 #xAC)
             (let ((path (namestring (merge-pathnames "clautolisp-er-utf8.txt"
                                                      (uiop:temporary-directory)))))
               (unwind-protect
                    (let ((clautolisp.autolisp-runtime:*enc-diagnostic-stream* (make-broadcast-stream)))
                      (reset-autolisp-symbol-table)
                      (%al (format nil "(progn (setq f (open ~S \"w\" \":utf-8\")) (princ ~S f) (close f))"
                                   path *er-chr-300*))
                      (%er-octets path))
                 (ignore-errors (delete-file path)))))))

#+sbcl
(test encoding-replacement-explicit-replacement-keeps-its-precedence
  ;; (open f "w" "(:cp1252 :replacement #\?)") is left to the designator,
  ;; whatever the policy says -- even "error" under --strict.
  (is (string= "?" (%er-write "strict" *er-chr-300*
                              :prelude "(setq *AUTOLISP-ENCODING-REPLACEMENT* \"error\")"
                              :open-arguments "\"w\" \"(:cp1252 :replacement #\\\\?)\""))))

(test encoding-replacement-terminal
  ;; The terminal path: *STANDARD-OUTPUT* a windows-1252 stream.
  (let ((path (namestring (merge-pathnames (format nil "clautolisp-er-term-~D.txt" (random 1000000))
                                           (uiop:temporary-directory)))))
    (unwind-protect
         (let ((clautolisp.autolisp-runtime:*enc-diagnostic-stream* (make-broadcast-stream))
               (clautolisp.autolisp-runtime:*encoding-replacement-warnings-seen*
                (make-hash-table :test 'equal))
               (*error-output* (make-broadcast-stream)))
           (with-open-stream (out (clautolisp.autolisp-reader:open-with-external-format
                                   path :direction :output :if-exists :supersede
                                        :external-format :cp1252))
             (let ((*standard-output* out))
               (reset-autolisp-symbol-table)
               (%al (format nil "(progn (setq *AUTOLISP-DIALECT* 'autocad-2022) (princ ~S) (prompt ~S) nil)"
                            *er-a-zhong-b* *er-chr-300*))))
           (is (string= "a-b," (%er-text path)))
           ;; and the terminal-only global
           (with-open-stream (out (clautolisp.autolisp-reader:open-with-external-format
                                   path :direction :output :if-exists :supersede
                                        :external-format :cp1252))
             (let ((*standard-output* out))
               (reset-autolisp-symbol-table)
               (%al (format nil "(progn (setq *AUTOLISP-TERMINAL-ENCODING-REPLACEMENT* \"~~\") (princ ~S) nil)"
                            *er-a-zhong-b*))))
           (is (string= "a~b" (%er-text path))))
      (ignore-errors (delete-file path)))))

;;; --- the clautolisp system variable / environment variable ----------------

(test encoding-replacement-sysvar
  ;; CLAUTOLISPENCODINGREPLACEMENT decides when no global does ...
  (is (string= "a+b" (%er-write "strict" *er-a-zhong-b*
                                :prelude "(setvar \"CLAUTOLISPENCODINGREPLACEMENT\" \"+\")")))
  (is (string= "aIb" (%er-write "clautolisp" (coerce (list #\a (code-char 300) #\b) 'string)
                                :prelude "(setvar \"CLAUTOLISPENCODINGREPLACEMENT\" \"best-fit\")")))
  ;; ... the -Ereplacement global wins over it ...
  (is (string= "a#b" (%er-write "strict" *er-a-zhong-b*
                                :prelude "(setvar \"CLAUTOLISPENCODINGREPLACEMENT\" \"+\")
                                          (setq *AUTOLISP-ENCODING-REPLACEMENT* \"#\")")))
  ;; ... a value naming no policy is an AutoLISP error at the write ...
  (multiple-value-bind (file result)
      (%er-write "lax" *er-chr-300* :prelude "(setvar \"CLAUTOLISPENCODINGREPLACEMENT\" \"question\")")
    (is (string= "" file))
    (is (and (stringp result) (search "CLAUTOLISPENCODINGREPLACEMENT" result)) "got ~S" result))
  ;; ... and reading it for the write is not the program's use of it: no
  ;; [clautolisp-sysvar] notice under a vendor dialect.
  (multiple-value-bind (file result warnings)
      (let ((clautolisp.autolisp-runtime:*clautolisp-sysvar-warnings-seen*
              (make-hash-table :test 'equal)))
        (%er-write "autocad-2022" *er-chr-300*))
    (declare (ignore result))
    (is (string= "," file))
    (is (not (search "[clautolisp-sysvar]" warnings)) "got ~S" warnings)))

(test encoding-replacement-sysvar-seeded-from-environment
  (flet ((seeded (value)
           (let ((name clautolisp.autolisp-runtime:+encoding-replacement-sysvar+)
                 (old (uiop:getenv clautolisp.autolisp-runtime:+encoding-replacement-sysvar+)))
             (unwind-protect
                  (progn
                    (setf (uiop:getenv name) value)
                    (clautolisp.cador::%encoding-replacement-initial-value))
               ;; "" reads as unset, so restoring to it is harmless.
               (setf (uiop:getenv name) (or old ""))))))
    (is (string= "?" (seeded "?")))
    (is (string= "escape" (seeded " ESCAPE ")))
    (is (string= "" (seeded "question")))
    (is (string= "" (seeded "")))))
