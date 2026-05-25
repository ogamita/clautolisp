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
