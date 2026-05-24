;;;; clautolisp/autolisp-init-files/source/api.lisp
;;;;
;;;; Init-file discovery API. The full contract is in
;;;; ../../../issues/open/init-files.issue; the highlights:
;;;;
;;;;   - Each program (clautolisp + alfe) carries a *list* of stems.
;;;;     EVERY existing init file in that list is loaded, in order —
;;;;     not first-match-wins. Later files override earlier ones.
;;;;
;;;;   - For one stem, the resolved file is picked from:
;;;;       1. The bare stem itself (e.g. ~/.clautolisp), when
;;;;          REQUIRE-EXTENSION-P is NIL.
;;;;       2. Among compiled forms <stem>.{fas,des,vlx}, the newest
;;;;          that is newer than <stem>.lsp (if any).
;;;;       3. <stem>.lsp if it exists.
;;;;     The .lsp source is preferred over a stale compiled form,
;;;;     so editing the source automatically retires the cached
;;;;     compile until rebuilt.
;;;;
;;;;   - XDG `init` slots (~/.config/<program>/init) have no
;;;;     bare-stem variant — REQUIRE-EXTENSION-P is T there, so
;;;;     a bare file at that path is ignored.
;;;;
;;;;   - Gating: NO-INIT-REQUESTED-P is the consolidated check for
;;;;     a CLI flag OR $AUTOLISP_NO_INIT OR a per-program env var
;;;;     ($CLAUTOLISP_NO_INIT / $ALFE_NO_INIT).

(in-package #:clautolisp.autolisp-init-files)

;;; --- default stem lists per program -------------------------------

(defparameter *default-clautolisp-stems*
  '(("~/.autolisp"                     nil)
    ("~/.config/autolisp/init"         t)
    ("~/.clautolisp"                   nil)
    ("~/.config/clautolisp/init"       t))
  "Four-slot lookup list for the clautolisp binary, per
issues/closed/init-files.issue. Order is significant: earlier files
load first, later files override. The shared ~/.autolisp pair runs
first so a defun in the program-specific ~/.clautolisp /
~/.config/clautolisp/init pair can override it — that matches the
conventional Unix layering (more-specific overrides less-specific).
Within each scope, the legacy HOME slot loads before the modern
XDG slot so the XDG path is the higher-priority override.")

(defparameter *default-alfe-stems*
  '(("~/.autolisp"                     nil)
    ("~/.config/autolisp/init"         t)
    ("~/.alfe"                         nil)
    ("~/.config/alfe/init"             t))
  "Four-slot lookup list for the alfe binary. Mirrors
*DEFAULT-CLAUTOLISP-STEMS* with the program-specific stems swapped
in; the shared autolisp stems are identical so a user maintaining
a single ~/.autolisp file sees it loaded by both binaries with the
same priority — both binaries' program-specific files override
it.")

;;; --- home-relative path expansion ---------------------------------

(defun expand-home-relative (path)
  "Replace a leading ~/ in PATH with the user's home directory.
Returns the resulting string. Falls through unchanged when PATH
does not begin with ~/ — callers may pass absolute paths in tests
to bypass the real $HOME without monkeying with environment
variables."
  (cond
    ((and (>= (length path) 2)
          (string= path "~/" :end1 2))
     (let ((home (namestring (user-homedir-pathname))))
       (concatenate 'string
                    (if (and (plusp (length home))
                             (char= (char home (1- (length home))) #\/))
                        home
                        (concatenate 'string home "/"))
                    (subseq path 2))))
    (t path)))

;;; --- per-stem discovery -------------------------------------------

(defparameter *compiled-extensions* '("fas" "des" "vlx")
  "Extensions the legacy bash wrapper recognises as compiled
AutoLISP. Order in the list is not significant for selection —
the picker uses mtime — but listing them here makes the supported
set discoverable.")

(defun file-newer-p (a b)
  "True iff PROBE-FILE result A's write date is strictly greater
than B's. Both arguments must be pathnames or NIL; NIL collates
older than any present file."
  (cond
    ((null b) t)
    ((null a) nil)
    (t (> (file-write-date a) (file-write-date b)))))

(defun newest-qualifying-compiled (stem lsp-path)
  "Walk *COMPILED-EXTENSIONS* under STEM, keep only the variants
that are strictly newer than LSP-PATH (or all of them when LSP-PATH
is NIL), and return the newest. Returns NIL when no compiled form
qualifies."
  (let ((candidates
         (loop for ext in *compiled-extensions*
               for candidate = (probe-file
                                (concatenate 'string stem "." ext))
               when (and candidate
                         (or (null lsp-path)
                             (file-newer-p candidate lsp-path)))
                 collect candidate)))
    (when candidates
      (first (sort (copy-list candidates) #'file-newer-p)))))

(defun find-init-file (stem &key require-extension-p)
  "Resolve one stem (a string, possibly with a leading ~/ that
EXPAND-HOME-RELATIVE replaces with the user's home dir) to a
pathname or NIL.

When REQUIRE-EXTENSION-P is NIL, the bare stem itself wins outright
if it exists. Otherwise the picker considers .lsp + the compiled
extensions per the contract documented at the top of this file."
  (let* ((expanded   (expand-home-relative stem))
         (bare       (and (not require-extension-p) (probe-file expanded)))
         (lsp        (probe-file (concatenate 'string expanded ".lsp"))))
    (cond
      (bare
       bare)
      (t
       (or (newest-qualifying-compiled expanded lsp)
           lsp)))))

(defun find-init-files (stems)
  "Walk STEMS in order and return the list of resolved pathnames
(NILs filtered). STEMS is a list of (STEM-PATH REQUIRE-EXTENSION-P)
pairs — typically *DEFAULT-CLAUTOLISP-STEMS* or
*DEFAULT-ALFE-STEMS*. The returned list preserves walking order,
so callers can prepend it to their action plan with confidence
that earlier files load first."
  (loop for entry in stems
        for stem = (first entry)
        for require-ext-p = (second entry)
        for resolved = (find-init-file stem :require-extension-p require-ext-p)
        when resolved collect resolved))

;;; --- gating --------------------------------------------------------

(defun env-true-p (value)
  "Lenient interpretation of an env-var value as a boolean. T iff
VALUE is one of \"1\" / \"y\" / \"yes\" / \"true\" / \"on\"
(case-insensitive). Empty string and NIL are false. Anything else
is also false, matching the legacy bash wrapper's permissive read
of $AUTOLISP_NO_INIT."
  (and value
       (stringp value)
       (member value '("1" "y" "Y" "yes" "YES" "true" "TRUE" "on" "ON")
               :test #'string=)))

(defun env-flag-set-p (name)
  "True iff env var NAME is set to a recognised truthy value. NIL
when unset or set to an empty / falsy value."
  (env-true-p (uiop:getenv name)))

(defun no-init-requested-p (cli-flag-value &rest program-env-vars)
  "True iff the caller's CLI flag was set, OR $AUTOLISP_NO_INIT is
truthy, OR any of PROGRAM-ENV-VARS is. Used by both the clautolisp
and alfe CLI plumbing as the single gate before walking the
init-file list.

The CLI flag wins outright — if the user passed --no-init we
short-circuit without touching the environment. The env-var rung
exists for non-interactive shells (CI, daemons, the autolisp-test
harness) that can't pass flags."
  (cond
    (cli-flag-value t)
    ((env-flag-set-p "AUTOLISP_NO_INIT") t)
    (t (some #'env-flag-set-p program-env-vars))))
