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
    ;; --strict means "the intersection of all dialects" (a program that
    ;; runs clean under --strict runs on any implementation), NOT
    ;; "maximally locked down". So strict warns (1) rather than blocks
    ;; (2): an untrusted load is a portability signal, not a hard stop.
    ;; A program that needs blocking sets SECURELOAD=2 itself.
    (:strict 1)
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

(defun trusted-spec-directories (&rest specs)
  "Return the list of directory strings named by the TRUSTEDPATHS-syntax
SPECS (each a string or NIL), in order, de-duplicated. The recursion
marker is irrelevant to a per-folder file search, so only the directory
component of each entry is kept. Used to build the findfile (support u
trusted) and findtrustedfile (trusted-only) search lists."
  (let ((dirs '()))
    (dolist (spec specs)
      (dolist (entry (parse-trusted-path-spec (or spec "")))
        ;; Return directory-form namestrings (trailing separator) so a
        ;; search via merge-pathnames treats them as folders, not files.
        (let ((dir (namestring (uiop:ensure-directory-pathname (car entry)))))
          (unless (member dir dirs :test #'string=)
            (push dir dirs)))))
    (nreverse dirs)))

(defun %same-file-p (a b)
  "True when namestrings A and B denote the same file (string match, or
equal truenames when both resolve)."
  (and a b
       (or (string= a b)
           (let ((ta (ignore-errors (truename a)))
                 (tb (ignore-errors (truename b))))
             (and ta tb (equal ta tb))))))

(defun secureload-path-trusted-p (abs-file-path trustedpaths-string
                                  implicit-string init-files)
  "True when ABS-FILE-PATH (an absolute file namestring) is trusted:
either an exact match of one of INIT-FILES (the trusted user init
files), or inside a directory trusted by TRUSTEDPATHS-STRING or
IMPLICIT-STRING (each a TRUSTEDPATHS-syntax spec; NIL/empty allowed).
This is the trust test the load / open gate uses."
  (and (or (some (lambda (f) (%same-file-p abs-file-path f)) init-files)
           (path-trusted-p abs-file-path
                           (append (parse-trusted-path-spec (or trustedpaths-string ""))
                                   (parse-trusted-path-spec (or implicit-string "")))))
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

;;; --- clautolisp-only trust sysvars (Phase 2) -----------------------
;;;
;;; CLAUTOLISPSUPPORTFILESEARCHPATH and CLAUTOLISPIMPLICITLYTRUSTEDFOLDER-
;;; PATHS exist only under the clautolisp dialect. The mock host's
;;; generated catalogue is dialect-neutral and has neither, so the launch
;;; overlay (APPLY-DIALECT-TRUST-SYSVAR-DEFAULTS below) registers them
;;; via HOST-DEFINE-SYSVAR when the dialect is :clautolisp.

(defparameter *clautolisp-support-search-path-default* "./"
  "Default CLAUTOLISPSUPPORTFILESEARCHPATH: relative load/open/findfile
names are searched in the current directory only; absolute names are
used directly. spec § 'New clautolisp system variables'.")

(defun %env (getenv name)
  "Look NAME up via the GETENV function, returning NIL for unset and a
trimmed string otherwise (uiop:getenv returns \"\" for set-empty)."
  (let ((v (funcall getenv name)))
    (and v (stringp v) v)))

(defun %nonempty (s)
  (and s (stringp s) (plusp (length (string-trim '(#\Space #\Tab) s))) s))

(defun %cwd-namestring (getcwd)
  "The current working directory as a namestring without a trailing
separator, or NIL when it cannot be determined."
  (let ((dir (ignore-errors (funcall getcwd))))
    (and dir
         (let ((s (namestring dir)))
           (%nonempty (string-right-trim "/\\" s))))))

(defun default-implicitly-trusted-paths (&key (getenv #'uiop:getenv)
                                              (getcwd #'uiop:getcwd))
  "Compute the launch-time default for CLAUTOLISPIMPLICITLYTRUSTEDFOLDER-
PATHS under the clautolisp dialect (spec § 'New clautolisp system
variables'):

  \"$(pwd)/...;$XDG_DATA_HOME/autolisp/...;$PREFIX/share/autolisp/...\"

with the variables substituted to absolute paths. The current working
directory subtree is prepended as a clautolisp convenience (AutoCAD /
BricsCAD do NOT implicitly trust the cwd, so this is clautolisp-only);
$XDG_DATA_HOME (falling back to $HOME/.local/share) comes next, then
$PREFIX from CLAUTOLISP_PREFIX (omitted when unset, since the install
root is not otherwise knowable headless). Each segment keeps the
cross-platform \"/...\" recursion marker so all subfolders are trusted.
The whole value is overridable by the CLAUTOLISPIMPLICITLYTRUSTEDFOLDER-
PATHS environment variable (applied by the caller, higher precedence)."
  (let* ((cwd    (%cwd-namestring getcwd))
         (prefix (%nonempty (%env getenv "CLAUTOLISP_PREFIX")))
         (xdg    (%nonempty (%env getenv "XDG_DATA_HOME")))
         (home   (%nonempty (%env getenv "HOME")))
         (data   (or xdg (and home (concatenate 'string home "/.local/share"))))
         (segs '()))
    ;; cwd subtree first (clautolisp convenience), then $XDG_DATA_HOME
    ;; (the user's own data dir), then $PREFIX (the install tree).
    (when cwd
      (push (concatenate 'string cwd "/...") segs))
    (when data
      (push (concatenate 'string data "/autolisp/...") segs))
    (when prefix
      (push (concatenate 'string prefix "/share/autolisp/...") segs))
    (format nil "~{~A~^;~}" (nreverse segs))))

(defparameter *clautolisp-trust-env-sysvars*
  '(("SECURELOAD" . :integer)
    ("TRUSTEDPATHS" . :string)
    ("CLAUTOLISPSUPPORTFILESEARCHPATH" . :string)
    ("CLAUTOLISPIMPLICITLYTRUSTEDFOLDERPATHS" . :string))
  "Trust-model sysvars seedable from an identically-named environment
variable. Precedence is setvar > env var > dialect default (spec
§ 'Environment-variable initialisation'). SECURELOAD parses as an
integer; the rest are strings. The CLAUTOLISP* pair is seeded only
under the clautolisp dialect, where the cells exist.")

(defun %coerce-env-sysvar-value (kind raw)
  "Coerce a raw environment string RAW to the sysvar KIND, or NIL when
it does not parse (an unparsable integer is ignored rather than set)."
  (ecase kind
    (:integer (parse-integer raw :junk-allowed t))
    (:string raw)))

(defun apply-dialect-trust-sysvar-defaults (host dialect-keyword
                                            &key (getenv #'uiop:getenv)
                                                 (getcwd #'uiop:getcwd))
  "Launch-time overlay: stamp the dialect-dependent SECURELOAD /
TRUSTEDPATHS defaults and read-only-ness onto HOST, register the two
clautolisp-only trust sysvars under the clautolisp dialect, then apply
environment-variable overrides (env > dialect default). DIALECT-KEYWORD
is one of :strict / :autocad-2026 / :bricscad-v26 / :lax / :clautolisp.
Mock-host only; no-ops on hosts without a sysvar table. Returns HOST.
spec §§ 'Dialect-dependent defaults', 'New clautolisp system variables',
'Environment-variable initialisation'."
  (when host
    (let* ((dk dialect-keyword)
           (ro (secureload-read-only-for-dialect-p dk))
           (clautolisp-p (eq dk :clautolisp)))
      (flet ((define (name kind value read-only-p)
               (clautolisp.autolisp-host:host-define-sysvar
                host name kind value read-only-p))
             (read-only-for (name)
               ;; SECURELOAD / TRUSTEDPATHS follow the dialect; the
               ;; clautolisp-only pair is always settable.
               (if (member name '("SECURELOAD" "TRUSTEDPATHS") :test #'string=)
                   ro
                   nil)))
        ;; 1. dialect defaults for the two product sysvars.
        (define "SECURELOAD"   :integer (secureload-dialect-default dk)   ro)
        (define "TRUSTEDPATHS" :string  (trustedpaths-dialect-default dk) ro)
        ;; 2. the clautolisp-only sysvars (only where they exist).
        (when clautolisp-p
          (define "CLAUTOLISPSUPPORTFILESEARCHPATH" :string
                  *clautolisp-support-search-path-default* nil)
          (define "CLAUTOLISPIMPLICITLYTRUSTEDFOLDERPATHS" :string
                  (default-implicitly-trusted-paths :getenv getenv :getcwd getcwd)
                  nil))
        ;; 3. environment-variable overrides (env > dialect default).
        (dolist (entry *clautolisp-trust-env-sysvars*)
          (let ((name (car entry)) (kind (cdr entry)))
            (when (or clautolisp-p
                      (member name '("SECURELOAD" "TRUSTEDPATHS")
                              :test #'string=))
              (let ((raw (%env getenv name)))
                (when raw
                  (let ((value (%coerce-env-sysvar-value kind raw)))
                    (when value
                      (define name kind value (read-only-for name))))))))))
    host)))
