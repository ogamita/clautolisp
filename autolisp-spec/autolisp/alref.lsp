;;;; alref.lsp -- AutoLISP Spec reference library, loadable into any
;;;; conforming implementation (AutoCAD, BricsCAD, clautolisp).
;;;;
;;;; Companion to autolisp-spec/emacs/alref.el. Reads the paged spec
;;;; artefacts produced by autolisp-spec/scripts/build-paged-spec.el
;;;; off disk — symbols.txt for the symbol -> page map, index.txt
;;;; for the chapter walk, and the per-section .txt files under
;;;; pages/ for the symbol description bodies — and exposes six
;;;; interactive entry points:
;;;;
;;;;   (alref-lookup "pattern")        -- print every documented
;;;;                                      symbol whose name contains
;;;;                                      PATTERN (case-insensitive)
;;;;   (alref-apropos-list "pattern")  -- the underlying list-returning
;;;;                                      variant (no printing)
;;;;   (alref-apropos "pattern")       -- print one symbol per line
;;;;                                      with its current live state:
;;;;                                        NAME<TAB>Function
;;;;                                        NAME<TAB>Sysvar<TAB>VALUE
;;;;                                        NAME<TAB>Variable<TAB>VALUE
;;;;                                        NAME<TAB>Variable<TAB>NIL
;;;;                                      (matching the user-spec
;;;;                                      table in alref's docs)
;;;;   (alref-describe SYMBOL-OR-STRING)
;;;;                                   -- print the spec page for the
;;;;                                      symbol (or chapter title /
;;;;                                      chapter number)
;;;;   (alref-documentation SYMBOL-OR-STRING)
;;;;                                   -- like alref-describe but
;;;;                                      returns the page text as a
;;;;                                      string instead of printing
;;;;   (alref-help "string")           -- search the body of every
;;;;                                      page for STRING and return
;;;;                                      a list of matching page
;;;;                                      basenames
;;;;
;;;; Configuration:
;;;;
;;;;   (alref-set-root "/path/to/share/doc/autolisp-spec/")
;;;;
;;;; Defaults to "/opt/local/share/doc/autolisp-spec/"; load-time autodetection
;;;; isn't possible in stock AutoLISP (no file-system-aware autoload
;;;; primitive), so set the root explicitly in your init file or
;;;; pass it on the first call.
;;;;
;;;; Portable across AutoCAD / BricsCAD / clautolisp: uses only the
;;;; strict-subset primitives (open, read-line, close, strcat, substr,
;;;; strlen, strcase, princ, terpri, basic list ops). No vl-string-*,
;;;; no host-specific extensions.

;; Library version. Bump the DEVELOP counter (third component) on
;; every change that touches alref.lsp's behaviour. (alref-version)
;; returns this string — useful when a user reports a bug, so we
;; know which revision of the library they're running against.
(setq *alref-version* "1.5.0")

;|Return the alref.lsp library version as a string (e.g. "1.0.0").
Format is MAJOR.MINOR.DEVELOP, matching the clautolisp convention.|;
(defun alref-version ( )
  *alref-version*)

;; Default install root. Matches the repo-wide PREFIX=/opt/local
;; convention documented in the root Makefile's install target. The
;; paged spec data ships under share/doc/autolisp-spec/ alongside the
;; html and the org/pdf docs. Override at load time via:
;;   (alref-set-root "/usr/local/share/doc/autolisp-spec/")
(setq *alref-root* "/opt/local/share/doc/autolisp-spec/")

;|Point the library at the install directory. The directory must
contain the documented layout (pages/, html/, info/ subdirs +
symbols.txt + index.txt under pages/).|;
(defun alref-set-root (path)
  (setq *alref-root* path)
  path)

;;; --- low-level helpers --------------------------------------------

;|Read PATH (a file) into a list of its lines, in order. Returns
nil when the file is missing or unreadable.|;
(defun alref-slurp-lines (path / f acc line)
  (setq f (open path "r"))
  (if (null f)
    nil
    (progn
      (setq acc nil)
      (while (setq line (read-line f))
        (setq acc (cons line acc)))
      (close f)
      (reverse acc))))

;|ASCII 9 — the TAB character we use as the index/symbols field
separator. (chr 9) is portable across AutoLISP implementations
where #\Tab isn't a reader form.|;
(defun alref-tab-char ( )
  (chr 9))

;|1-indexed position of NEEDLE in HAYSTACK starting at column
START (1 = beginning), or nil when not found. Plain naive scan;
avoids vl-string-search for portability.|;
(defun alref-string-position (needle haystack start / len-h len-n i)
  (setq len-h (strlen haystack))
  (setq len-n (strlen needle))
  (if (= len-n 0)
    start
    (progn
      (setq i start)
      (while (and (<= (+ i len-n -1) len-h)
                  (/= (substr haystack i len-n) needle))
        (setq i (1+ i)))
      (if (> (+ i len-n -1) len-h) nil i))))

;|T iff NEEDLE appears anywhere in HAYSTACK (case-insensitive).|;
(defun alref-string-contains-p (needle haystack)
  (not (null (alref-string-position
              (strcase needle)
              (strcase haystack)
              1))))

;|Parse a tab-separated symbols.txt line into (SYMBOL KIND BASENAME
FLAGS). The FLAGS field carries the ABC availability letters —
'A' AutoCAD, 'B' BricsCAD, 'C' clautolisp (the runtime library adds
'C' live, so on-disk lines hold only A/B). FLAGS is optional: lines
emitted before the flags column was added parse with FLAGS = "", and
any extra trailing tab-separated fields are folded into FLAGS rather
than leaking into BASENAME. Returns nil when the line lacks the two
mandatory tabs (SYMBOL / KIND / BASENAME).|;
(defun alref-split-tab (line / tab1 tab2 tab3)
  (setq tab1 (alref-string-position (alref-tab-char) line 1))
  (if (null tab1)
    nil
    (progn
      (setq tab2 (alref-string-position (alref-tab-char) line (1+ tab1)))
      (if (null tab2)
        nil
        (progn
          ;; Optional 3rd tab separates BASENAME from the FLAGS column.
          ;; Without it (pre-flags files) BASENAME runs to end-of-line.
          (setq tab3 (alref-string-position (alref-tab-char) line (1+ tab2)))
          (list (substr line 1 (1- tab1))
                (substr line (1+ tab1) (- tab2 tab1 1))
                (if tab3
                  (substr line (1+ tab2) (- tab3 tab2 1))
                  (substr line (1+ tab2)))
                (if tab3 (substr line (1+ tab3)) "")))))))

;|Compose the absolute pathname of pages/BASENAME.txt under the
configured root.|;
(defun alref-page-path (basename / )
  (strcat *alref-root* "pages/" basename ".txt"))

;;; --- index loaders (cached after first read) ---------------------

(setq *alref-symbols-cache* nil)
(setq *alref-symbols-root* nil)

;|Return the parsed contents of pages/symbols.txt as a list of
(SYMBOL KIND BASENAME FLAGS) tuples. Re-reads the file on the first
call after `alref-set-root' moves the root.|;
(defun alref-load-symbols ( / path lines acc parsed)
  (if (and *alref-symbols-cache*
           (= *alref-symbols-root* *alref-root*))
    *alref-symbols-cache*
    (progn
      (setq path (strcat *alref-root* "pages/symbols.txt"))
      (setq lines (alref-slurp-lines path))
      (setq acc nil)
      (foreach line lines
        (setq parsed (alref-split-tab line))
        (if parsed (setq acc (cons parsed acc))))
      (setq *alref-symbols-cache* (reverse acc))
      (setq *alref-symbols-root* *alref-root*)
      *alref-symbols-cache*)))

(setq *alref-index-cache* nil)
(setq *alref-index-root* nil)

;|Return the parsed contents of pages/index.txt as a list of
(BASENAME TITLE) pairs. Cached after the first read.|;
(defun alref-load-index ( / path lines acc tab basename title)
  (if (and *alref-index-cache*
           (= *alref-index-root* *alref-root*))
    *alref-index-cache*
    (progn
      (setq path (strcat *alref-root* "pages/index.txt"))
      (setq lines (alref-slurp-lines path))
      (setq acc nil)
      (foreach line lines
        (setq tab (alref-string-position (alref-tab-char) line 1))
        (if tab
          (progn
            (setq basename (substr line 1 (1- tab)))
            (setq title (substr line (1+ tab)))
            (setq acc (cons (list basename title) acc)))))
      (setq *alref-index-cache* (reverse acc))
      (setq *alref-index-root* *alref-root*)
      *alref-index-cache*)))

;;; --- runtime-symbol helpers --------------------------------------
;;;
;;; The alref-* lookup functions union the documented spec catalog
;;; with the live AutoLISP image's bound symbols, so user-defun'd /
;;; user-setq'd names show up alongside specified ones. The runtime
;;; list isn't cached — `atoms-family' changes whenever the user
;;; defuns or setqs anything, and the cost is low (the image's
;;; symbol table is in memory).
;;;
;;; Caveat documented in the issue: AutoLISP's `atoms-family' only
;;; returns symbols that have a binding (defun'd or setq'd). A bare
;;; '(WONT-QUIT) read at the REPL interns WONT-QUIT but doesn't bind
;;; it, so it stays invisible to atoms-family and therefore to the
;;; union. This is a strict-spec property, not an alref limitation.

;|Return the list of uppercased symbol-name strings for every
currently-bound symbol in the image — what (atoms-family 1)
exposes. Used to widen alref-apropos-list / alref-resolve-key
beyond the documented spec catalog. Re-queried each call (the
runtime symbol table changes with each defun / setq).|;
(defun alref-runtime-symbol-names ( / raw acc s)
  (setq raw (atoms-family 1))
  (setq acc nil)
  (foreach s raw
    ;; atoms-family 1 returns NAMES (strings); fold to uppercase
    ;; for the case-insensitive substring scan downstream.
    (if s (setq acc (cons (strcase s) acc))))
  (reverse acc))

;|Return the uppercased names of the host's system variables whose
name contains PATTERN (case-insensitive substring), or nil when the
host cannot enumerate them. Uses the clautolisp extension
CLAL-SYSVAR-APROPOS when present (probed with boundp, the CLAL-
convention — autolisp-spec ch.16); AutoCAD / BricsCAD expose no
sysvar enumeration, so there the sysvar pass contributes nothing
(issues/open/alref-sysvars.issue).|;
(defun alref-sysvar-names-matching (pattern / acc name)
  (setq acc nil)
  (if (boundp 'clal-sysvar-apropos)
    (foreach name (clal-sysvar-apropos pattern)
      (setq acc (cons (strcase name) acc))))
  (reverse acc))

;|T iff UPPERCASED-NAME is present in the documented spec catalog
(`pages/symbols.txt').|;
(defun alref-spec-symbol-p (uppercased-name / )
  (not (null (assoc uppercased-name (alref-load-symbols)))))

;;; --- public API ----------------------------------------------------

;|T iff VAL is a callable function value: a SUBR (built-in),
USUBR (user-defined via DEFUN), or one of the external-subroutine
flavours AutoLISP dialects expose (EXSUBR / EXTSUBR). The type
test is by symbol equality of the (TYPE VAL) tag, which is
portable across AutoCAD / BricsCAD / clautolisp.|;
(defun alref-function-value-p (val / kind)
  (setq kind (type val))
  (or (= kind 'SUBR)
      (= kind 'USUBR)
      (= kind 'EXSUBR)
      (= kind 'EXTSUBR)))

;|Return the symbol-name of KEY (a symbol) as a string, falling
back through the available implementations. AutoCAD + BricsCAD
expose vl-symbol-name; clautolisp does too. The bare-Lisp
fallback uses vl-princ-to-string and strips the leading quote
when present.|;
(defun alref-symbol-name (key / )
  (cond
    ((and (boundp 'vl-symbol-name) (= (type vl-symbol-name) 'SUBR))
     (vl-symbol-name key))
    ((and (boundp 'vl-princ-to-string) (= (type vl-princ-to-string) 'SUBR))
     (vl-princ-to-string key))
    (t
     ;; Last-resort: read back what (type key) printed, after a
     ;; round-trip through princ. Pragmatic for legal identifiers
     ;; on every implementation we target — if it ever fails, the
     ;; caller can pass a string instead.
     (princ key))))

;|Coerce KEY (a string OR a symbol OR an integer chapter number)
into the basename of the matching page. Returns nil when no page
matches. Strings are tried as symbol names first, then chapter
titles; integers are interpreted as chapter numbers.|;
(defun alref-resolve-key (key / )
  (cond
    ((= (type key) 'INT)
     (alref-find-chapter-page (itoa key)))
    ((= (type key) 'SYM)
     (alref-find-symbol-page (strcase (alref-symbol-name key))))
    ((= (type key) 'STR)
     ;; AutoLISP's `or' is boolean — it returns T/NIL, not the
     ;; first non-NIL value the way Common Lisp's does. We need
     ;; the actual basename here (a string fed to strcat downstream
     ;; in alref-page-path), so we use the cond-as-or idiom: a
     ;; clause with just a test expression returns that test value
     ;; when non-NIL. That's the canonical AutoLISP way to express
     ;; "first non-NIL of these expressions."
     (cond
       ((alref-find-symbol-page (strcase key)))
       ((alref-find-chapter-page key))
       (t nil)))
    (t nil)))

;|T iff the spec documents a CAD command named UPPERCASED-NAME (a
'Command' entry of pages/symbols.txt) -- a name that can also be a
function's or a system variable's (LOAD, OPEN, SNAP ...).|;
(defun alref-command-entry-p (uppercased-name / found)
  (foreach entry (alref-load-symbols)
    (if (and (= (car entry) uppercased-name) (= (cadr entry) "Command"))
      (setq found T)))
  found)

;|Every page documenting UPPERCASED-NAME, in pages/symbols.txt order (the
chapters' order: a function's page before a command's of the same name).|;
(defun alref-find-symbol-pages (uppercased-name / acc)
  (foreach entry (alref-load-symbols)
    (if (= (car entry) uppercased-name)
      (setq acc (cons (caddr entry) acc))))
  (reverse acc))

;|Look up UPPERCASED-NAME in the cached symbols index. Returns
the basename (a string) on hit, nil on miss.|;
(defun alref-find-symbol-page (uppercased-name / entries entry)
  (setq entries (alref-load-symbols))
  (setq entry (assoc uppercased-name entries))
  (if entry (caddr entry) nil))

;|Look up KEY among the chapter-level pages. KEY can be a
chapter number ('1', '21A') OR a chapter title fragment
('Functions', 'Macros'). Returns the basename on hit, nil on
miss.|;
(defun alref-find-chapter-page (key / entries entry candidate basename title)
  (setq entries (alref-load-index))
  (setq candidate nil)
  (foreach entry entries
    ;; A chapter page has basename '<N>-<slug>' AND its title is
    ;; the chapter title (no further '*' nesting). We detect
    ;; chapter pages by basename pattern + the slug not containing
    ;; entry markers like 'function-entry-' — a simple proxy.
    ;;
    ;; AutoLISP has no `let' — the previous version of this fn
    ;; used (let ...) and crashed at first call. Locals declared
    ;; via the `/' convention on the defun argument list.
    (setq basename (car entry))
    (setq title (cadr entry))
    (if (and (null candidate)
             (or (alref-string-contains-p key title)
                 (alref-string-contains-p key basename)))
      (setq candidate basename)))
  candidate)

;|Return the contents of pages/BASENAME.txt as a single string,
or nil when the page isn't installed.|;
(defun alref-page-text (basename / lines)
  (setq lines (alref-slurp-lines (alref-page-path basename)))
  (if (null lines)
    nil
    (apply 'strcat (alref-intersperse "\n" lines))))

;|Insert SEP between every pair of elements in LST. Used by
alref-page-text to rejoin slurped lines into one big string.|;
(defun alref-intersperse (sep lst / acc first)
  (setq acc nil)
  (setq first t)
  (foreach x lst
    (if first
      (progn (setq acc (cons x acc)) (setq first nil))
      (progn (setq acc (cons x (cons sep acc))))))
  (reverse acc))

;|Coerce KEY (symbol or string) to its uppercased name string for
runtime-symbol probes. Returns nil for non-symbol/non-string keys
(integers, etc.) — those can only be chapter numbers, never
runtime-symbol references.|;
(defun alref-key->name (key / )
  (cond
    ((= (type key) 'SYM) (strcase (alref-symbol-name key)))
    ((= (type key) 'STR) (strcase key))
    (t nil)))

;|T iff UPPERCASED-NAME names a symbol currently bound in the
image (the same test atoms-family applies). Lets alref-describe /
alref-documentation distinguish a runtime-only symbol from one
the user just typed and hasn't bound.|;
(defun alref-runtime-bound-p (uppercased-name / sym)
  (setq sym (read uppercased-name))
  (and sym (boundp sym)))

;|Print the alref-apropos-style line for a runtime symbol that
has no spec page — one of:

    NAME<TAB>Function
    NAME<TAB>Variable<TAB>VALUE
    NAME<TAB>Variable<TAB>NIL

The shape matches alref-apropos so the user sees a consistent
display whether the symbol is documented or not.|;
(defun alref-print-runtime-state (uppercased-name / sym)
  (setq sym (read uppercased-name))
  (princ uppercased-name)
  (princ "\t")
  (cond
    ((not (boundp sym))
     (princ "Variable\tNIL"))
    ((alref-function-value-p (eval sym))
     (princ "Function"))
    (t
     (princ "Variable\t")
     (prin1 (eval sym))))
  (terpri))

;;; --- live per-binding documentation (source-aware-defun-documentation)
;;; clautolisp registers a ;|…|; doc block against a defun'd/setq'd
;;; binding, queryable via the CLAUTOLISP-DOCUMENTATION{,-KIND} builtins.
;;; alref consults them by late binding so the SAME alref.lsp stays
;;; portable to AutoCAD / BricsCAD, where the builtins are absent.

;|If FN-NAME (a string naming a symbol) is bound to a callable in the
current image, call it with ARG and return the result; nil when the
symbol is unbound or not callable.|;
(defun alref-call-by-name (fn-name arg / sym fn)
  (setq sym (read fn-name))
  (cond
    ((and (= (type sym) 'SYM) (boundp sym))
     (setq fn (eval sym))
     (if (alref-function-value-p fn) (apply fn (list arg)) nil))
    (t nil)))

;|The doc-string attached to NAME's innermost binding via the
CLAUTOLISP-DOCUMENTATION builtin, or nil when the builtin is absent
or no doc was recorded.|;
(defun alref-runtime-doc (name)
  (alref-call-by-name "CLAUTOLISP-DOCUMENTATION" name))

;|The kind tag ('FUNCTION or 'VARIABLE) attached to NAME's innermost
binding via CLAUTOLISP-DOCUMENTATION-KIND, or nil.|;
(defun alref-runtime-doc-kind (name)
  (alref-call-by-name "CLAUTOLISP-DOCUMENTATION-KIND" name))

;;; --- namespaces ----------------------------------------------------
;;;
;;; A name lives in up to four NAMESPACES, each with its own meaning:
;;;   FUNCTION  -- a callable binding (and the spec's Function / Special Form
;;;                / Macro entries);
;;;   VARIABLE  -- a non-callable binding (and the spec's Variable entries);
;;;   SYSVAR    -- a host system variable (and the spec's System Variable
;;;                entries);
;;;   COMMAND   -- a CAD command: the spec's Command entries, and every
;;;                function C:NAME, which IS the command NAME.
;;; The same name can be in several: LOAD is a function and a command; a
;;; function C:HELLO is the command HELLO, a different thing from a function
;;; HELLO. Every lookup below works on ENTRIES (NAME NAMESPACE SOURCE), one
;;; per name and namespace: SOURCE is the spec page basename, or for a live
;;; binding the string "*" (or, for a command defined by a C: function, that
;;; function's name, "C:HELLO").

(setq *alref-namespaces* '("FUNCTION" "VARIABLE" "SYSVAR" "COMMAND"))

;|The namespace of a pages/symbols.txt KIND, or nil for the spec's other
entries (Reader Syntax, Type ...).|;
(defun alref-kind->namespace (kind)
  (cond
    ((member kind '("Function" "Special Form" "Macro")) "FUNCTION")
    ((= kind "Variable") "VARIABLE")
    ((= kind "System Variable") "SYSVAR")
    ((= kind "Command") "COMMAND")
    (t nil)))

;| True when ENTRIES already hold NAME in namespace NS. |;
(defun alref-entry-present-p (name ns entries / found)
  (foreach e entries
    (if (and (= (car e) name) (= (cadr e) ns)) (setq found T)))
  found)

;| Whether NAME matches PATTERN: the whole name when EXACT, else a case-insensitive substring. |;
(defun alref-name-matches-p (pattern name exact)
  (if exact (= (strcase pattern) name) (alref-string-contains-p pattern name)))

;|Every (NAME NAMESPACE SOURCE) whose NAME matches PATTERN -- a
case-insensitive substring, or the whole name when EXACT -- in one of
NAMESPACES (a list of namespace strings; nil = all four, plus the spec's
other entries). Spec entries first, in pages/symbols.txt order, then the
live image's bindings, then the host's system variables.|;
(defun alref-entries (pattern namespaces exact / acc ns sym val cmd)
  (setq acc nil)
  ;; 1. the spec catalog
  (foreach entry (alref-load-symbols)
    (setq ns (alref-kind->namespace (cadr entry)))
    (if (and (alref-name-matches-p pattern (car entry) exact)
             (if namespaces (member ns namespaces) T)
             (not (alref-entry-present-p (car entry) (if ns ns (cadr entry)) acc)))
      (setq acc (cons (list (car entry) (if ns ns (cadr entry)) (caddr entry)) acc))))
  ;; 2. the live image: functions, variables, and the C: commands
  (foreach name (alref-runtime-symbol-names)
    (setq sym (read name))
    (if (and sym (boundp sym))
      (progn
        (setq val (eval sym))
        (setq ns (if (alref-function-value-p val) "FUNCTION" "VARIABLE"))
        (if (and (alref-name-matches-p pattern name exact)
                 (if namespaces (member ns namespaces) T)
                 (not (alref-entry-present-p name ns acc)))
          (setq acc (cons (list name ns "*") acc)))
        ;; C:NAME is the command NAME (its own namespace).
        (if (and (= ns "FUNCTION") (> (strlen name) 2) (= (substr name 1 2) "C:"))
          (progn
            (setq cmd (substr name 3))
            (if (and (alref-name-matches-p pattern cmd exact)
                     (if namespaces (member "COMMAND" namespaces) T)
                     (not (alref-entry-present-p cmd "COMMAND" acc)))
              (setq acc (cons (list cmd "COMMAND" name) acc))))))))
  ;; 3. the host's system variables (clautolisp can enumerate them)
  (if (if namespaces (member "SYSVAR" namespaces) T)
    (foreach name (alref-sysvar-names-matching pattern)
      (if (and (alref-name-matches-p pattern name exact)
               (not (alref-entry-present-p name "SYSVAR" acc)))
        (setq acc (cons (list name "SYSVAR" "*") acc)))))
  (reverse acc))

;|Print ENTRY's apropos line: NAME<TAB>Function | Variable<TAB>VALUE |
Sysvar<TAB>VALUE | Command [<TAB>(C:NAME)] | <spec kind>.|;
(defun alref-entry-line (entry / name ns src sym)
  (setq name (car entry) ns (cadr entry) src (caddr entry))
  (princ name)
  (princ "\t")
  (cond
    ((= ns "FUNCTION") (princ "Function"))
    ((= ns "VARIABLE")
     (setq sym (read name))
     (princ "Variable\t")
     (if (and sym (boundp sym)) (prin1 (eval sym)) (princ "NIL")))
    ((= ns "SYSVAR")
     (princ "Sysvar")
     (if (getvar name) (progn (princ "\t") (prin1 (getvar name)))))
    ((= ns "COMMAND")
     (princ "Command")
     (if (and (> (strlen src) 2) (= (substr src 1 2) "C:"))
       (progn (princ "\t(") (princ src) (princ ")"))))
    (t (princ ns)))
  (terpri))

;| Print the apropos line of every entry matching PATTERN in NAMESPACES (nil = all); return the count. |;
(defun alref-apropos-in (pattern namespaces / entries)
  (setq entries (alref-entries pattern namespaces nil))
  (foreach e entries (alref-entry-line e))
  (length entries))

;| The names of ENTRIES, each once, in order. |;
(defun alref-names-of (entries / acc)
  (foreach e entries
    (if (not (member (car e) acc)) (setq acc (cons (car e) acc))))
  (reverse acc))

;;; The text of one entry, for describe / documentation.

;| The namespace label of ENTRY, for headers: Function, Variable, System variable, Command. |;
(defun alref-entry-label (entry / ns)
  (setq ns (cadr entry))
  (cond
    ((= ns "FUNCTION") "Function")
    ((= ns "VARIABLE") "Variable")
    ((= ns "SYSVAR") "System variable")
    ((= ns "COMMAND") "Command")
    (t ns)))

;|The documentation of ENTRY: its spec page, or the live binding's
recorded documentation (for a C: command, its C: function's), or
"not documented".|;
(defun alref-entry-text (entry / src doc)
  (setq src (caddr entry))
  (cond
    ((and (/= src "*") (not (and (> (strlen src) 2) (= (substr src 1 2) "C:"))))
     (alref-page-text src))
    ((setq doc (alref-runtime-doc (if (= src "*") (car entry) src))) doc)
    (t "not documented")))

;| The header line printed before a live entry: === Command: HELLO (function C:HELLO) ===. |;
(defun alref-entry-header (entry / src)
  (setq src (caddr entry))
  (strcat "=== " (alref-entry-label entry) ": " (car entry)
          (if (and (> (strlen src) 2) (= (substr src 1 2) "C:"))
            (strcat " (function " src ")")
            "")
          " ==="))

;| True when ENTRY comes from a spec page (not from a live binding). |;
(defun alref-spec-page-p (entry / src)
  (setq src (caddr entry))
  (and (/= src "*") (not (and (> (strlen src) 2) (= (substr src 1 2) "C:")))))

;|The documentation of KEY in NAMESPACES (nil = all): one entry's text, or
when KEY names several (a function and a command ...) all of them, each
under a header naming its namespace. A chapter number / title (KEY not a
name) gives that chapter's page. nil when nothing matches.|;
(defun alref-documentation-in (key namespaces / name entries acc)
  (setq name (alref-key->name key))
  (setq entries (if name (alref-entries name namespaces T)))
  (cond
    ((null entries)
     (if (and (null namespaces) (alref-resolve-key key))
       (alref-page-text (alref-resolve-key key))
       nil))
    ((null (cdr entries)) (alref-entry-text (car entries)))
    (t
     (foreach e entries
       (setq acc (cons (if (alref-spec-page-p e)
                         (alref-entry-text e)
                         (strcat (alref-entry-header e) "\n" (alref-entry-text e)))
                       acc)))
     (apply 'strcat (cdr (apply 'append
                                (mapcar '(lambda (x) (list "\n\n" x)) (reverse acc))))))))

;|Print the documentation of KEY in NAMESPACES (nil = all) -- every
matching entry, spec pages as they are, a live binding's documentation
under a header followed by its apropos line; KEY<TAB>Inexistant when
nothing matches. Returns the matched entries (or the chapter page's
basename).|;
(defun alref-describe-in (key namespaces / name entries basename)
  (setq name (alref-key->name key))
  (setq entries (if name (alref-entries name namespaces T)))
  (cond
    (entries
     (foreach e entries
       (if (alref-spec-page-p e)
         (princ (alref-entry-text e))
         (progn
           (princ (alref-entry-header e)) (terpri)
           (princ (alref-entry-text e)) (terpri)
           (alref-entry-line e)))
       (terpri))
     entries)
    ((and (null namespaces) (setq basename (alref-resolve-key key)))
     (princ (alref-page-text basename))
     (terpri)
     basename)
    (t
     (princ key)
     (princ "\tInexistant")
     (terpri)
     nil)))

;;; --- public API ------------------------------------------------------

;|The names matching PATTERN (case-insensitive substring) in every
namespace -- spec catalog, live image (a C:NAME function also gives the
command NAME), host system variables -- each name once.|;
(defun alref-apropos-list (pattern)
  (alref-names-of (alref-entries pattern nil nil)))
;| The names matching PATTERN (case-insensitive substring) in the FUNCTION namespace (functions, special forms) only. |;
(defun alref-apropos-list-function (pattern)
  (alref-names-of (alref-entries pattern '("FUNCTION") nil)))
;| The names matching PATTERN (case-insensitive substring) in the VARIABLE namespace only. |;
(defun alref-apropos-list-variable (pattern)
  (alref-names-of (alref-entries pattern '("VARIABLE") nil)))
;| The names matching PATTERN (case-insensitive substring) in the SYSVAR namespace (system variables) only. |;
(defun alref-apropos-list-sysvar (pattern)
  (alref-names-of (alref-entries pattern '("SYSVAR") nil)))
;| The names matching PATTERN (case-insensitive substring) in the COMMAND namespace (CAD commands, and the commands C:NAME functions define) only. |;
(defun alref-apropos-list-command (pattern)
  (alref-names-of (alref-entries pattern '("COMMAND") nil)))

;|Print one name per line for (alref-apropos-list PATTERN). Returns the
count.|;
(defun alref-lookup (pattern / names)
  (setq names (alref-apropos-list pattern))
  (foreach name names (princ name) (terpri))
  (length names))

;|Print one line per name AND namespace matching PATTERN:

    NAME<TAB>Function
    NAME<TAB>Variable<TAB>VALUE        (NIL when unbound)
    NAME<TAB>Sysvar<TAB>VALUE
    NAME<TAB>Command                   (a CAD command the spec documents)
    NAME<TAB>Command<TAB>(C:NAME)      (the command a C:NAME function defines)
    NAME<TAB><spec kind>               (Reader Syntax, Type ...)

A name in several namespaces gets a line for each: LOAD is a Function and
a Command; a function C:HELLO gives C:HELLO<TAB>Function AND
HELLO<TAB>Command<TAB>(C:HELLO). Returns the number of lines.|;
(defun alref-apropos (pattern)
  (alref-apropos-in pattern nil))
;| alref-apropos restricted to the FUNCTION namespace (functions, special forms): print one line per match; return the count. |;
(defun alref-apropos-function (pattern) (alref-apropos-in pattern '("FUNCTION")))
;| alref-apropos restricted to the VARIABLE namespace: print one line per match; return the count. |;
(defun alref-apropos-variable (pattern) (alref-apropos-in pattern '("VARIABLE")))
;| alref-apropos restricted to the SYSVAR namespace (system variables): print one line per match; return the count. |;
(defun alref-apropos-sysvar (pattern) (alref-apropos-in pattern '("SYSVAR")))
;| alref-apropos restricted to the COMMAND namespace (CAD commands, and the commands C:NAME functions define): print one line per match; return the count. |;
(defun alref-apropos-command (pattern) (alref-apropos-in pattern '("COMMAND")))

;|Print every page / documentation of KEY (a symbol or a name string), in
all its namespaces; a chapter number or title prints that chapter.|;
(defun alref-describe (key)
  (alref-describe-in key nil))
;| alref-describe restricted to the FUNCTION namespace (functions, special forms): print every page of KEY there. |;
(defun alref-describe-function (key) (alref-describe-in key '("FUNCTION")))
;| alref-describe restricted to the VARIABLE namespace: print every page of KEY there. |;
(defun alref-describe-variable (key) (alref-describe-in key '("VARIABLE")))
;| alref-describe restricted to the SYSVAR namespace (system variables): print every page of KEY there. |;
(defun alref-describe-sysvar (key) (alref-describe-in key '("SYSVAR")))
;| alref-describe restricted to the COMMAND namespace (CAD commands, and the commands C:NAME functions define): print every page of KEY there. |;
(defun alref-describe-command (key) (alref-describe-in key '("COMMAND")))

;|The documentation of KEY as a string: the spec page, else the live
binding's recorded documentation, else "not documented" for a bound
name; all of them, each under its namespace's header, when KEY is in
several namespaces; nil when KEY is nothing.|;
(defun alref-documentation (key)
  (alref-documentation-in key nil))
;| alref-documentation restricted to the FUNCTION namespace (functions, special forms): the documentation string of KEY there, or nil. |;
(defun alref-documentation-function (key) (alref-documentation-in key '("FUNCTION")))
;| alref-documentation restricted to the VARIABLE namespace: the documentation string of KEY there, or nil. |;
(defun alref-documentation-variable (key) (alref-documentation-in key '("VARIABLE")))
;| alref-documentation restricted to the SYSVAR namespace (system variables): the documentation string of KEY there, or nil. |;
(defun alref-documentation-sysvar (key) (alref-documentation-in key '("SYSVAR")))
;| alref-documentation restricted to the COMMAND namespace (CAD commands, and the commands C:NAME functions define): the documentation string of KEY there, or nil. |;
(defun alref-documentation-command (key) (alref-documentation-in key '("COMMAND")))

;|Search the body of every documented page for PATTERN
(case-insensitive substring). Returns a list of basenames whose
page contains a match. Slow (reads all 1126 pages on each call)
— intended for interactive lookups, not batch jobs.|;
(defun alref-help (pattern / entries entry basename text matches)
  (setq entries (alref-load-index))
  (setq matches nil)
  (foreach entry entries
    (setq basename (car entry))
    (setq text (alref-page-text basename))
    (if (and text (alref-string-contains-p pattern text))
      (setq matches (cons basename matches))))
  (reverse matches))

;; The load banner is advisory only; keep a plain (load "alref.lsp") quiet
;; unless the user asked for chatter with *AUTOLISP-VERBOSE*. An unbound
;; *AUTOLISP-VERBOSE* reads as nil in AutoLISP (and clautolisp), so this stays
;; silent on hosts that do not define it.
(if *AUTOLISP-VERBOSE*
  (progn
    (princ (strcat "alref.lsp " *alref-version*
                   " loaded. (alref-set-root \"…\") to point at the install root."))
    (terpri)))
(princ "")
