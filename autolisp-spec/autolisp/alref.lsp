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
;;;;   (alref-set-root "/path/to/share/autolisp-spec/")
;;;;
;;;; Defaults to "/opt/share/autolisp-spec/"; load-time autodetection
;;;; isn't possible in stock AutoLISP (no file-system-aware autoload
;;;; primitive), so set the root explicitly in your init file or
;;;; pass it on the first call.
;;;;
;;;; Portable across AutoCAD / BricsCAD / clautolisp: uses only the
;;;; strict-subset primitives (open, read-line, close, strcat, substr,
;;;; strlen, strcase, princ, terpri, basic list ops). No vl-string-*,
;;;; no host-specific extensions.

;; Default install root. Matches the repo-wide PREFIX=/opt/local
;; convention documented in the root Makefile's install target.
;; Override at load time via:
;;   (alref-set-root "/usr/local/share/autolisp-spec/")
(setq *alref-root* "/opt/local/share/autolisp-spec/")

(defun alref-set-root (path)
  "Point the library at the install directory. The directory must
contain the documented layout (pages/, html/, info/ subdirs +
symbols.txt + index.txt under pages/)."
  (setq *alref-root* path)
  path)

;;; --- low-level helpers --------------------------------------------

(defun alref-slurp-lines (path / f acc line)
  "Read PATH (a file) into a list of its lines, in order. Returns
nil when the file is missing or unreadable."
  (setq f (open path "r"))
  (if (null f)
    nil
    (progn
      (setq acc nil)
      (while (setq line (read-line f))
        (setq acc (cons line acc)))
      (close f)
      (reverse acc))))

(defun alref-tab-char ( )
  "ASCII 9 — the TAB character we use as the index/symbols field
separator. (chr 9) is portable across AutoLISP implementations
where #\\Tab isn't a reader form."
  (chr 9))

(defun alref-string-position (needle haystack start / len-h len-n i)
  "1-indexed position of NEEDLE in HAYSTACK starting at column
START (1 = beginning), or nil when not found. Plain naive scan;
avoids vl-string-search for portability."
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

(defun alref-string-contains-p (needle haystack)
  "T iff NEEDLE appears anywhere in HAYSTACK (case-insensitive)."
  (not (null (alref-string-position
              (strcase needle)
              (strcase haystack)
              1))))

(defun alref-split-tab (line / tab1 tab2)
  "Parse a tab-separated three-column line into (FIELD-1 FIELD-2
FIELD-3). Returns nil when the line doesn't have exactly two
tabs."
  (setq tab1 (alref-string-position (alref-tab-char) line 1))
  (if (null tab1)
    nil
    (progn
      (setq tab2 (alref-string-position (alref-tab-char) line (1+ tab1)))
      (if (null tab2)
        nil
        (list (substr line 1 (1- tab1))
              (substr line (1+ tab1) (- tab2 tab1 1))
              (substr line (1+ tab2)))))))

(defun alref-page-path (basename / )
  "Compose the absolute pathname of pages/BASENAME.txt under the
configured root."
  (strcat *alref-root* "pages/" basename ".txt"))

;;; --- index loaders (cached after first read) ---------------------

(setq *alref-symbols-cache* nil)
(setq *alref-symbols-root* nil)

(defun alref-load-symbols ( / path lines acc parsed)
  "Return the parsed contents of pages/symbols.txt as a list of
(SYMBOL KIND BASENAME) triples. Re-reads the file on the first
call after `alref-set-root' moves the root."
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

(defun alref-load-index ( / path lines acc tab basename title)
  "Return the parsed contents of pages/index.txt as a list of
(BASENAME TITLE) pairs. Cached after the first read."
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

;;; --- public API ----------------------------------------------------

(defun alref-apropos-list (pattern / matches entry)
  "Return the list of documented symbol names that contain
PATTERN as a substring (case-insensitive). Sorted in the order
the symbols index was emitted (chapter-major, then walking order
within each chapter — close enough to alphabetical-by-kind for
interactive use)."
  (setq matches nil)
  (foreach entry (alref-load-symbols)
    (if (alref-string-contains-p pattern (car entry))
      (setq matches (cons (car entry) matches))))
  (reverse matches))

(defun alref-lookup (pattern / names)
  "Print one symbol per line for every entry in
(alref-apropos-list PATTERN). Returns the count of matches."
  (setq names (alref-apropos-list pattern))
  (foreach name names
    (princ name)
    (terpri))
  (length names))

(defun alref-function-value-p (val / kind)
  "T iff VAL is a callable function value: a SUBR (built-in),
USUBR (user-defined via DEFUN), or one of the external-subroutine
flavours AutoLISP dialects expose (EXSUBR / EXTSUBR). The type
test is by symbol equality of the (TYPE VAL) tag, which is
portable across AutoCAD / BricsCAD / clautolisp."
  (setq kind (type val))
  (or (= kind 'SUBR)
      (= kind 'USUBR)
      (= kind 'EXSUBR)
      (= kind 'EXTSUBR)))

(defun alref-apropos (pattern / matches name sym)
  "Print every documented symbol matching PATTERN with its current
live state in the AutoLISP runtime:

    NAME<TAB>Function                — bound to a callable.
    NAME<TAB>Variable<TAB>VALUE      — bound to a non-callable value.
    NAME<TAB>Variable<TAB>NIL        — symbol present but unbound.

Symbols not present in the documented index are never shown by
this function; reach those via (alref-describe NAME), which
reports an explicit `Inexistant' line.

The Variable/Function distinction is by (TYPE (EVAL SYM)) at the
moment apropos runs, so loading a library that defines new
functions makes them show up as Function on the next call.

Returns the count of matches printed."
  (setq matches (alref-apropos-list pattern))
  (foreach name matches
    (setq sym (read name))
    (princ name)
    (princ "\t")
    (cond
      ((not (boundp sym))
       ;; AutoLISP conflates unbound with bound-to-nil in much of its
       ;; surface (READ of an unbound symbol returns nil, etc.); we
       ;; surface the absence here as `Variable<TAB>NIL' rather than
       ;; a separate `Unbound' kind because the user-facing distinction
       ;; is "no value" — same display either way.
       (princ "Variable\tNIL"))
      ((alref-function-value-p (eval sym))
       (princ "Function"))
      (t
       (princ "Variable\t")
       (prin1 (eval sym))))
    (terpri))
  (length matches))

(defun alref-symbol-name (key / )
  "Return the symbol-name of KEY (a symbol) as a string, falling
back through the available implementations. AutoCAD + BricsCAD
expose vl-symbol-name; clautolisp does too. The bare-Lisp
fallback uses vl-princ-to-string and strips the leading quote
when present."
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

(defun alref-resolve-key (key / )
  "Coerce KEY (a string OR a symbol OR an integer chapter number)
into the basename of the matching page. Returns nil when no page
matches. Strings are tried as symbol names first, then chapter
titles; integers are interpreted as chapter numbers."
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

(defun alref-find-symbol-page (uppercased-name / entries entry)
  "Look up UPPERCASED-NAME in the cached symbols index. Returns
the basename (a string) on hit, nil on miss."
  (setq entries (alref-load-symbols))
  (setq entry (assoc uppercased-name entries))
  (if entry (caddr entry) nil))

(defun alref-find-chapter-page (key / entries entry candidate basename title)
  "Look up KEY among the chapter-level pages. KEY can be a
chapter number ('1', '21A') OR a chapter title fragment
('Functions', 'Macros'). Returns the basename on hit, nil on
miss."
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

(defun alref-page-text (basename / lines)
  "Return the contents of pages/BASENAME.txt as a single string,
or nil when the page isn't installed."
  (setq lines (alref-slurp-lines (alref-page-path basename)))
  (if (null lines)
    nil
    (apply 'strcat (alref-intersperse "\n" lines))))

(defun alref-intersperse (sep lst / acc first)
  "Insert SEP between every pair of elements in LST. Used by
alref-page-text to rejoin slurped lines into one big string."
  (setq acc nil)
  (setq first t)
  (foreach x lst
    (if first
      (progn (setq acc (cons x acc)) (setq first nil))
      (progn (setq acc (cons x (cons sep acc))))))
  (reverse acc))

(defun alref-describe (key / basename text)
  "Print the spec page for KEY (a symbol, a string symbol-name,
a chapter number, or a chapter title). When KEY does not resolve
to any documented symbol or chapter, prints:

    KEY<TAB>Inexistant

— matching the alref-apropos `Variable/Function/Variable NIL'
display family. The Inexistant row is reachable only via
alref-describe; alref-apropos filters the documented index and
never sees a missing symbol."
  (setq basename (alref-resolve-key key))
  (if (null basename)
    (progn
      (princ key)
      (princ "\tInexistant")
      (terpri)
      nil)
    (progn
      (setq text (alref-page-text basename))
      (if (null text)
        (progn
          (princ "alref-describe: page file missing: ")
          (princ basename)
          (terpri)
          nil)
        (progn
          (princ text)
          (terpri)
          basename)))))

(defun alref-documentation (key / basename)
  "Like alref-describe but returns the page text as a string
instead of printing. Useful for tooling that wants to inspect or
forward the page."
  (setq basename (alref-resolve-key key))
  (if (null basename)
    nil
    (alref-page-text basename)))

(defun alref-help (pattern / entries entry basename text matches)
  "Search the body of every documented page for PATTERN
(case-insensitive substring). Returns a list of basenames whose
page contains a match. Slow (reads all 1126 pages on each call)
— intended for interactive lookups, not batch jobs."
  (setq entries (alref-load-index))
  (setq matches nil)
  (foreach entry entries
    (setq basename (car entry))
    (setq text (alref-page-text basename))
    (if (and text (alref-string-contains-p pattern text))
      (setq matches (cons basename matches))))
  (reverse matches))

(princ "alref.lsp loaded. (alref-set-root \"…\") to point at the install root.")
(terpri)
(princ)
