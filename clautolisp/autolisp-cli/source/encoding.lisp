(in-package #:clautolisp.autolisp-cli)

;;;; Encoding alias registry + resolver shared by clautolisp and alfe.
;;;;
;;;; The CLI parsers run every -e / -E value through RESOLVE-ENCODING-NAME
;;;; at parse time so a typo (e.g. `-e uft-8') surfaces as a clean
;;;; cli-usage-error rather than later as a cryptic "Undefined
;;;; external-format" from CL OPEN when a file finally gets touched.
;;;;
;;;; The mandatory set is US-ASCII, ISO-8859-1, WINDOWS-1252 and
;;;; UTF-8 (encoding.issue). Common spellings are aliased to the
;;;; canonical keyword the CL implementation accepts. Other encodings
;;;; the running implementation recognises are passed through case-
;;;; folded but only after a sanity-check pass: a string that doesn't
;;;; match any alias and contains no slashes / spaces / digit-leading
;;;; characters is treated as plausibly an encoding name and forwarded
;;;; to the impl, which can still signal at OPEN time. To opt out of
;;;; the validator entirely, use the canonical keyword directly via a
;;;; Lisp init file rather than the CLI option.

(defparameter *encoding-aliases*
  '(("US-ASCII"     :us-ascii   "us-ascii" "ascii" "iso-646-us" "iso-ir-6"
                                 "ansi-x3.4-1968" "ansi-x3.4-1986" "csascii")
    ("ISO-8859-1"   :iso-8859-1 "iso-8859-1" "latin-1" "latin1"
                                 "iso8859-1" "iso_8859-1" "iso-ir-100"
                                 "csisolatin1")
    ("WINDOWS-1252" :windows-1252 "windows-1252" "cp1252" "cp-1252"
                                 "wcp1252")
    ("UTF-8"        :utf-8      "utf-8" "utf8" "utf_8" "csutf8"))
  "Alist of (CANONICAL KEYWORD ALIAS …) for the mandatory encodings.
CANONICAL is the spec-spelled string published as the value of the
*AUTOLISP-{FILE,TERMINAL}-ENCODING* globals; KEYWORD is what CL OPEN
accepts as :EXTERNAL-FORMAT; the trailing strings are the case-
folded aliases RESOLVE-ENCODING-NAME accepts on the command line.
Encoding names not on this list are still accepted — see
RESOLVE-ENCODING-NAME — but get no spelling-error protection.")

(defun %encoding-alias-match-p (name aliases)
  "True when NAME (a string) matches any alias in ALIASES case-
insensitively. ALIASES is the tail of an *ENCODING-ALIASES* row."
  (some (lambda (alias) (string-equal name alias)) aliases))

(defun %plausible-encoding-name-syntactically-p (name)
  "Cheap syntactic gate: reject digit-leading or punctuation-laden
strings before they even reach the implementation's encoding
registry. Used as the gate of last resort on Lisp implementations
that don't expose an introspectable list of external formats."
  (and (stringp name)
       (plusp (length name))
       (alpha-char-p (char name 0))
       (every (lambda (ch)
                (or (alphanumericp ch)
                    (member ch '(#\- #\_ #\.) :test #'char=)))
              name)))

(defun %implementation-knows-encoding-p (keyword)
  "True when the running Common Lisp implementation recognises
KEYWORD as an external-format. Catches typos like :UFT-8 that
would otherwise survive the syntactic gate and only fail later
at OPEN time.

SBCL and CCL expose introspection APIs (sb-impl::get-external-format
and ccl:character-encoding); on other implementations the function
returns T to fall through to the syntactic gate."
  #+sbcl
  (not (null (ignore-errors (sb-impl::get-external-format keyword))))
  #+ccl
  (not (null (ignore-errors (ccl:lookup-character-encoding keyword))))
  #-(or sbcl ccl)
  t)

(defun %plausible-encoding-name-p (name)
  "Plausibility check used by RESOLVE-ENCODING-NAME for encoding
names not on the alias table. Combines the syntactic gate with
the implementation's external-format registry — the latter is
what rejects typos like `uft-8' that pass syntax but aren't real."
  (and (%plausible-encoding-name-syntactically-p name)
       (%implementation-knows-encoding-p
        (intern (string-upcase name) :keyword))))

(defun resolve-encoding-name (name &optional option)
  "Map NAME (the user-typed -e / -E value, a string) to the canonical
encoding spelling (a string published in *AUTOLISP-…-ENCODING* and
returned as the first value) and the CL external-format keyword
(returned as the second value).

Mandatory encodings (US-ASCII / ISO-8859-1 / WINDOWS-1252 / UTF-8)
match through *ENCODING-ALIASES*. An encoding name not on that
list, but whose syntax passes %PLAUSIBLE-ENCODING-NAME-P, is
forwarded to the underlying CL implementation by upcasing it and
returning both the upper-cased string and its KEYWORD twin —
implementations that don't recognise it surface their own error
at OPEN time. Implausible spellings (typos, garbage) signal
CLI-USAGE-ERROR mentioning OPTION."
  ;; SOME drops secondary values, so locate the row first then call
  ;; VALUES from the outer scope.
  (let ((row (find-if (lambda (r) (%encoding-alias-match-p name (cddr r)))
                      *encoding-aliases*)))
    (cond
      (row
       (values (first row) (second row)))
      ((%plausible-encoding-name-p name)
       (let ((up (string-upcase name)))
         (values up (intern up :keyword))))
      (t
       (error 'cli-usage-error
              :option option
              :message
              (format nil "Unknown encoding ~S. Expected one of: ~
~{~A~^, ~} (with the usual aliases)."
                      name
                      (mapcar #'first *encoding-aliases*)))))))

(defun encoding-keyword (name &optional option)
  "Return the CL external-format keyword for NAME — the second value
of RESOLVE-ENCODING-NAME. Convenience for callers that don't need
the canonical spelling. Signals CLI-USAGE-ERROR on a typo."
  (nth-value 1 (resolve-encoding-name name option)))

(defun canonical-encoding-name (name &optional option)
  "Return the canonical encoding spelling (e.g. \"UTF-8\") for NAME
— the first value of RESOLVE-ENCODING-NAME. Used by the transmit-
options installer so *AUTOLISP-FILE-ENCODING* always shows the
canonical spelling regardless of which alias the user typed."
  (nth-value 0 (resolve-encoding-name name option)))

(defun resolve-locale-encoding-name ()
  "Return the canonical encoding spelling derived from the host's
locale environment, or NIL when no recognised encoding shows up.
Used by both the in-process and remote install paths to fill the
default value of *AUTOLISP-{FILE,TERMINAL}-ENCODING* when the CLI
options are absent.

Walks the locale chain via CLAUTOLISP.AUTOLISP-RUNTIME:LOCALE-
DEFAULT-SOURCE-ENCODING (LC_ALL > LANG > LC_CTYPE), then renders
the resulting keyword as the canonical spelling — :UTF-8 → \"UTF-8\"
etc."
  (let ((keyword (clautolisp.autolisp-runtime:locale-default-source-encoding)))
    (and keyword
         (or (some (lambda (row)
                     (and (eq keyword (second row)) (first row)))
                   *encoding-aliases*)
             ;; Unknown-but-present locale keyword: surface its
             ;; symbol-name as-is so the user sees what the host
             ;; carried.
             (symbol-name keyword)))))

;;; --- catalogue + --list-encodings printer ------------------------

#+sbcl
(defparameter *sbcl-common-encoding-probes*
  '(:us-ascii :iso-8859-1 :iso-8859-2 :iso-8859-3 :iso-8859-4
    :iso-8859-5 :iso-8859-6 :iso-8859-7 :iso-8859-8 :iso-8859-9
    :iso-8859-10 :iso-8859-13 :iso-8859-14 :iso-8859-15 :iso-8859-16
    :cp437 :cp850 :cp852 :cp855 :cp857 :cp860 :cp861 :cp862 :cp863
    :cp864 :cp865 :cp866 :cp869 :cp874
    :cp1250 :cp1251 :cp1252 :cp1253 :cp1254 :cp1255 :cp1256 :cp1257 :cp1258
    :mac-roman :mac-cyrillic :mac-greek :mac-iceland
    :koi8-r :koi8-u :ebcdic-us :ebcdic-international
    :utf-8 :utf-16 :utf-16be :utf-16le :utf-32 :utf-32be :utf-32le
    :ucs-2 :ucs-2be :ucs-2le :ucs-4 :ucs-4be :ucs-4le
    :euc-jp :shift_jis :gbk :gb2312 :big5 :euc-kr)
  "Names probed at --list-encodings time so SBCL's on-demand
loader pulls them into *external-formats*. The catalogue then
shows every encoding the running SBCL can handle, not just the
ones some earlier user code already triggered.")

(defun enumerate-implementation-encodings ()
  "Return the list of canonical encoding names the running CL
implementation accepts as :EXTERNAL-FORMAT, sorted alphabetically.
Each entry is a (CANONICAL-NAME . ALIASES) cons, with CANONICAL-NAME
the impl-preferred spelling (its first registered alias) and
ALIASES the rest of the names it answers to. On implementations
without an introspectable registry, returns NIL — the --list-
encodings printer falls back to the mandatory four with a note.

SBCL stores its built-in formats in *external-formats* but resolves
lazy-loaded ones (the ISO-8859-* family, KOI8-*, CP*, etc.) through
a separate path that doesn't register them in the same vector.
We probe each name in *SBCL-COMMON-ENCODING-PROBES* via
GET-EXTERNAL-FORMAT to surface them; the returned struct's
EF-NAMES list gives the canonical spelling and aliases. Built-in
formats are read straight from the vector."
  #+sbcl
  (let ((rows '()))
    ;; (1) Built-in formats from the static vector. Filter to struct
    ;; entries — the ((:newline-variant) . struct) conses are the
    ;; per-line-ending duplicates we'd otherwise double-count.
    (loop for fmt across sb-impl::*external-formats*
          when (typep fmt 'sb-impl::external-format)
          do (let* ((names (sb-impl::ef-names fmt))
                    (canonical (string (first names)))
                    (aliases (mapcar #'string (rest names))))
               (pushnew (cons canonical aliases) rows
                        :test #'equal :key #'car)))
    ;; (2) Lazy-loaded formats — probe each, extract its EF-NAMES.
    ;; Unknown probe entries return nil; we silently skip them so
    ;; the catalogue stays accurate to what this SBCL build can
    ;; actually handle, even when the probe table optimistically
    ;; lists more.
    (dolist (name *sbcl-common-encoding-probes*)
      (let ((fmt (ignore-errors (sb-impl::get-external-format name))))
        (when (typep fmt 'sb-impl::external-format)
          (let* ((names (sb-impl::ef-names fmt))
                 (canonical (string (first names)))
                 (aliases (mapcar #'string (rest names))))
            (pushnew (cons canonical aliases) rows
                     :test #'equal :key #'car)))))
    (sort rows #'string< :key #'car))
  #+ccl
  (let ((rows '()))
    (ccl::map-character-encodings
     (lambda (name encoding)
       (declare (ignore encoding))
       (let ((s (string name)))
         (pushnew (cons s '()) rows :test #'equal :key #'car))))
    (sort rows #'string< :key #'car))
  #-(or sbcl ccl)
  nil)

(defun print-encodings (&optional (stream *standard-output*))
  "Print the catalogue of supported encoding names to STREAM. Used
by the --list-encodings CLI action. The output has two sections:
the mandatory four with their hand-curated aliases, and the
remaining encodings the running CL implementation accepts."
  (format stream "~&clautolisp / alfe — supported encoding names.~%~%")
  (format stream "Encoding names are case-insensitive on the CLI: ~
utf-8 = UTF-8 = Utf-8.~%~%")
  (format stream "Mandatory (always supported; CLI also accepts ~
these aliases):~%")
  (dolist (row *encoding-aliases*)
    (format stream "  ~14A ~{~A~^, ~}~%"
            (first row) (cddr row)))
  (let* ((impl (enumerate-implementation-encodings))
         (canonicals (mapcar #'first *encoding-aliases*))
         (extra (remove-if (lambda (r)
                             (or (member (car r) canonicals
                                         :test #'string-equal)
                                 (some (lambda (alias)
                                         (member alias canonicals
                                                 :test #'string-equal))
                                       (cdr r))))
                           impl)))
    (cond
      ((null impl)
       (format stream "~%Implementation-supported: unknown — this CL ~
implementation does not expose an introspectable external-format ~
registry. Pass any name; if the runtime rejects it the CLI will ~
report a clean usage error.~%"))
      ((null extra)
       (format stream "~%(No additional impl-supported encodings ~
beyond the mandatory set.)~%"))
      (t
       (format stream "~%Additional impl-supported (~A; CLI accepts ~
any case):~%"
               #+sbcl "SBCL" #+ccl "CCL" #-(or sbcl ccl) "this Common Lisp")
       (dolist (row extra)
         (cond
           ((cdr row)
            (format stream "  ~14A ~{~A~^, ~}~%" (car row) (cdr row)))
           (t
            (format stream "  ~A~%" (car row))))))))
  (force-output stream))

(defun resolve-effective-encoding (cli-value)
  "Three-tier resolution for the *AUTOLISP-FILE-ENCODING* and
*AUTOLISP-TERMINAL-ENCODING* publication contract from
encoding.issue:

  1. Explicit -e / -E CLI value (CLI-VALUE, a string) — already
     validated by RESOLVE-ENCODING-NAME at parse time, so a
     simple alias-map lookup here.
  2. Otherwise, host locale (LC_ALL > LANG > LC_CTYPE).
  3. Otherwise, the issue-mandated fallback \"US-ASCII\".

Returns the canonical encoding spelling string. The publication
contract guarantees the result is never NIL — user code can rely
on *AUTOLISP-FILE-ENCODING* being a string at all times."
  (cond
    (cli-value (canonical-encoding-name cli-value))
    (t         (or (resolve-locale-encoding-name)
                   "US-ASCII"))))
