;;;; autolisp-builtins-core/source/secureload.lisp
;;;;
;;;; SECURELOAD / TRUSTEDPATHS trust-model primitives — Phase 1.
;;;;
;;;; Pure functions only: gated-extension classification, trusted-path
;;;; parsing (TRUSTEDPATHS syntax: semicolon-separated, optional quotes,
;;;; "" / "." special cases, trailing "\..." / "/..." subfolder
;;;; recursion), the absolute-path TRUST-P predicate, the dialect
;;;; default tables, and the SECURELOAD action resolver. No I/O, no host
;;;; access, no behavioural change to load / open here — the builtins
;;;; wire these in Phase 3. See
;;;; documentation/clautolisp-secureload-trust-model-spec.org and
;;;; issues/open/note-secureload.txt.

(in-package #:clautolisp.autolisp-builtins-core)

;;; --- gated "executable" file extensions ----------------------------

(defparameter *secureload-gated-extensions*
  '("lsp" "fas" "vlx" "mnl" "scr" "arx" "crx" "dbx" "hdi" "dvb")
  "Lower-case file extensions whose loading/opening SECURELOAD gates.
The AutoLISP-relevant, headless-meaningful subset of AutoCAD's
\"executable file\" set (dll / .net / js / bundle are outside
clautolisp's execution surface today and are intentionally omitted).
spec § 'Gated executable file extensions'.")

(defun secureload-gated-extension-p (path-designator)
  "True when PATH-DESIGNATOR (a namestring or pathname) names a file
whose extension is in *SECURELOAD-GATED-EXTENSIONS* (case-insensitive).
A file with no extension is not gated."
  (let ((type (pathname-type (pathname path-designator))))
    (and (stringp type)
         (member (string-downcase type) *secureload-gated-extensions*
                 :test #'string=)
         t)))

;;; --- dialect defaults ----------------------------------------------

(defun secureload-dialect-default (dialect-name)
  "The default SECURELOAD value for DIALECT-NAME (a keyword such as
:autocad-2026 / :bricscad-v26 / :strict / :lax / :clautolisp). spec
§ 'Dialect-dependent defaults'."
  (case dialect-name
    (:autocad-2026 1)
    (:bricscad-v26 0)
    (:strict 2)
    (:lax 0)
    (:clautolisp 1)
    (t 1)))                              ; conservative AutoCAD-like default

(defun trustedpaths-dialect-default (dialect-name)
  "The default TRUSTEDPATHS value for DIALECT-NAME. Empty everywhere
clautolisp controls it; real hosts derive it from the registry. spec
§ 'Dialect-dependent defaults'."
  (declare (ignore dialect-name))
  "")

(defun secureload-read-only-for-dialect-p (dialect-name)
  "True when SECURELOAD / TRUSTEDPATHS are read-only under DIALECT-NAME.
BricsCAD makes both read-only (admin-configured); AutoCAD and the
clautolisp dialects leave them settable so users / tests can opt in or
out. spec § 'Dialect-dependent defaults'."
  (eq dialect-name :bricscad-v26))

;;; --- trusted-path parsing ------------------------------------------

(defun %strip-surrounding-quotes (s)
  "Remove one layer of surrounding double quotes from S, if present."
  (let ((len (length s)))
    (if (and (>= len 2)
             (char= (char s 0) #\")
             (char= (char s (1- len)) #\"))
        (subseq s 1 (1- len))
        s)))

(defun %split-trusted-path-spec-recursion (s)
  "If S ends in the subfolder-recursion marker \"\\...\" or \"/...\",
return (values BASE-DIRECTORY T) with the marker (and its leading
separator) stripped; otherwise (values S NIL). clautolisp accepts the
forward-slash form as a cross-platform extension of AutoCAD's
backslash-only \"\\...\"."
  (flet ((ends-with (suffix)
           (let ((ls (length s)) (lz (length suffix)))
             (and (>= ls lz) (string= s suffix :start1 (- ls lz))))))
    (cond
      ((ends-with "\\...") (values (subseq s 0 (- (length s) 4)) t))
      ((ends-with "/...")  (values (subseq s 0 (- (length s) 4)) t))
      (t (values s nil)))))

(defun parse-trusted-path-spec (spec-string)
  "Parse a TRUSTEDPATHS-style SPEC-STRING into a list of
(DIRECTORY . RECURSIVE-P) entries:

- segments are separated by `;';
- each segment may be wrapped in double quotes and have surrounding
  whitespace;
- an empty segment or a lone `.' contributes nothing (the \"\" / \".\"
  special case: no trusted folders beyond the implicit ones);
- a segment ending in `\\...' or `/...' is RECURSIVE-P t with the
  marker stripped.

DIRECTORY is the raw (un-normalised) folder string; TRUST-P normalises
it against the path being tested. Returns NIL for an empty / all-blank
spec. spec § 'TRUSTEDPATHS syntax'."
  (let ((result '()))
    (dolist (raw (uiop:split-string (or spec-string "") :separator ";"))
      (let* ((trimmed (string-trim '(#\Space #\Tab) raw))
             (unquoted (string-trim '(#\Space #\Tab)
                                    (%strip-surrounding-quotes trimmed))))
        (unless (or (zerop (length unquoted))
                    (string= unquoted "."))
          (multiple-value-bind (dir recursive-p)
              (%split-trusted-path-spec-recursion unquoted)
            (let ((dir (string-trim '(#\Space #\Tab) dir)))
              (unless (zerop (length dir))
                (push (cons dir recursive-p) result)))))))
    (nreverse result)))

;;; --- the TRUST-P predicate -----------------------------------------

(defun %directory-component-list (namestring-or-pathname &key as-directory)
  "Return the :ABSOLUTE directory component list of a path. When
AS-DIRECTORY, the whole path is treated as a folder (its last segment
is a directory); otherwise the path is a file and the list is its
CONTAINING directory. Returns NIL when the path is not absolute."
  (let* ((p (pathname namestring-or-pathname))
         (dir (pathname-directory
               (if as-directory
                   (uiop:ensure-directory-pathname p)
                   p))))
    (and (consp dir) (eq (first dir) :absolute) dir)))

(defun %directory-prefix-p (prefix dir)
  "True when the directory component list PREFIX is a prefix of (or
equal to) DIR. Both are :ABSOLUTE component lists."
  (and prefix dir
       (<= (length prefix) (length dir))
       (every #'equal prefix (subseq dir 0 (length prefix)))))

(defun path-within-trusted-entry-p (abs-file-path entry)
  "True when ABS-FILE-PATH (an absolute file namestring/pathname) is
trusted by ENTRY, a (DIRECTORY . RECURSIVE-P) cons from
PARSE-TRUSTED-PATH-SPEC. Non-recursive: the file's containing directory
must equal the trusted folder. Recursive: the trusted folder must be
the containing directory or an ancestor of it."
  (let ((file-dir (%directory-component-list abs-file-path))
        (trust-dir (%directory-component-list (car entry) :as-directory t)))
    (and file-dir trust-dir
         (if (cdr entry)
             (%directory-prefix-p trust-dir file-dir)
             (equal trust-dir file-dir)))))

(defun path-trusted-p (abs-file-path trusted-entries)
  "True when ABS-FILE-PATH is trusted by any entry in TRUSTED-ENTRIES
(a list of (DIRECTORY . RECURSIVE-P) conses). An empty list is never
trusted."
  (and trusted-entries
       (some (lambda (e) (path-within-trusted-entry-p abs-file-path e))
             trusted-entries)
       t))

;;; --- SECURELOAD action resolver ------------------------------------

(defun secureload-action (secureload-value trusted-p)
  "Resolve the headless SECURELOAD action for a gated file:

  :allow  — proceed silently;
  :warn   — emit a warning, then proceed (headless analogue of
            AutoCAD's value-1 prompt: warn-and-proceed);
  :block  — refuse (set ERRNO + signal).

A trusted file is always :allow. An untrusted file is :allow at 0,
:warn at 1, and :block at 2 (or any value >= 2). spec § 'Headless
interpretation of the SECURELOAD values'."
  (cond
    (trusted-p :allow)
    ((null secureload-value) :allow)
    ((<= secureload-value 0) :allow)
    ((= secureload-value 1) :warn)
    (t :block)))
