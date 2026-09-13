(in-package #:clautolisp.cadtui)

;;;; Localisation of the interaction language (Phase 7).
;;;;
;;;; The spec (§Localisation) fixes the architecture: the §5 parser works ONLY
;;;; on canonical English tokens (a Phase-2 decision); localisation is a LEXICAL
;;;; pre-pass applied to a meta-command line BEFORE syntactic analysis — one
;;;; locale = one token-local -> token-international table, never a grammar
;;;; duplicated per language. A dictionary is DATA (an alist per category), not
;;;; code: adding a language is adding a table, never touching the parser or the
;;;; CLOS tree. Translation is bidirectional and programmatic (getcname-style),
;;;; with an identity fallback (an unknown token passes through), so a partial
;;;; dictionary coexists. A token prefixed with _ forces the international form
;;;; (the AutoCAD convention, spec §Principe général), whatever the locale.
;;;;
;;;; SCOPE (headless): the interaction-language dictionaries (verbs + argument
;;;; keywords / role names / option names). The THREE CAD-command dictionaries
;;;; (command names, in-command option keywords, keyboard aliases) are populated
;;;; from live CAD runners per the filed sub-issues (issues/open/cadtui-locale-*).
;;;; The Lisp language itself is never localised (defun/setq/command stay
;;;; English) — the pre-pass only ever runs on an escaped meta-command line.

;;; --- The dictionary registry --------------------------------------

(defvar *locale-dictionaries* (make-hash-table :test 'equal)
  "Maps a locale string (e.g. \"fr_FR\") to a plist CATEGORY => alist of
(international-string . local-string). Categories used by the interaction
pre-pass: :verb and :keyword (argument keywords, role names, option names).")

(defvar *current-locale* "en"
  "The active locale string. \"en\" is the canonical international form: no
translation is applied under it (the identity locale).")

(defun register-locale-dictionary (locale category alist)
  "Record ALIST (of (international . local) pairs) as LOCALE's CATEGORY table.
Returns LOCALE. Re-registering a (locale, category) replaces its table."
  (let ((plist (gethash locale *locale-dictionaries*)))
    (setf (getf plist category) alist
          (gethash locale *locale-dictionaries*) plist))
  locale)

(defun %locale-alist (locale category)
  (getf (gethash locale *locale-dictionaries*) category))

(defun %locale-known-p (locale)
  "True when LOCALE has any registered dictionary (or is the identity \"en\")."
  (or (string-equal locale "en")
      (nth-value 1 (gethash locale *locale-dictionaries*))))

;;; --- Bidirectional name lookup (getcname-style) -------------------

(defun local-name (international locale category)
  "The LOCALE-local form of the INTERNATIONAL token in CATEGORY, or INTERNATIONAL
unchanged when the dictionary has no entry (identity fallback, spec)."
  (or (cdr (assoc international (%locale-alist locale category) :test #'string-equal))
      international))

(defun international-name (any locale category)
  "The canonical international form of ANY token in CATEGORY under LOCALE: the
reverse-lookup of a local form, or ANY unchanged (it is already international, or
unknown). The inverse of LOCAL-NAME."
  (or (car (rassoc any (%locale-alist locale category) :test #'string-equal))
      any))

;;; --- Locale selection (CLI > LC_ALL > LANG > en) ------------------

(defun %normalise-locale (s)
  "Strip an encoding/modifier suffix: \"fr_FR.UTF-8@euro\" => \"fr_FR\"; NIL or an
empty string => NIL."
  (when (and s (plusp (length s)))
    (let* ((at (position #\@ s))
           (s (subseq s 0 at))
           (dot (position #\. s))
           (s (subseq s 0 dot)))
      (and (plusp (length s)) s))))

(defun %candidate-chain (locale)
  "The region-then-language fallback chain, e.g. \"fr_CA\" => (\"fr_CA\" \"fr\")."
  (let ((us (position #\_ locale)))
    (if us (list locale (subseq locale 0 us)) (list locale))))

(defun resolve-locale (&key cli lc-all lang)
  "Resolve the active locale from CLI > LC_ALL > LANG (each normalised), with a
region->language partial fallback and a final fallback to \"en\". Warns (never
fails) when a requested locale has no dictionary at all."
  (let ((requested (or (%normalise-locale cli)
                       (%normalise-locale lc-all)
                       (%normalise-locale lang))))
    (if (null requested)
        "en"
        (or (find-if #'%locale-known-p (%candidate-chain requested))
            (progn
              (warn "cadtui: no dictionary for locale ~S; using en." requested)
              "en")))))

(defun set-current-locale (locale)
  "Set *CURRENT-LOCALE* to LOCALE (resolved to a known one). Returns the locale
actually selected."
  (setf *current-locale* (resolve-locale :cli locale)))

(defun init-locale-from-environment (&key cli)
  "Initialise the active locale from an optional CLI override then LC_ALL/LANG
in the environment. Returns the selected locale."
  (setf *current-locale*
        (resolve-locale :cli cli
                        :lc-all (uiop:getenv "LC_ALL")
                        :lang (uiop:getenv "LANG"))))

;;; --- The lexical pre-pass -----------------------------------------

(defun %translate-token (token locale)
  "Canonicalise one interaction TOKEN under LOCALE: a leading _ forces the
international form (drop the _, no lookup); otherwise reverse-look it up in the
verb table, then the keyword table; identity when unknown."
  (if (and (plusp (length token)) (char= (char token 0) #\_))
      (subseq token 1)
      (let ((as-verb (international-name token locale :verb)))
        (if (string= as-verb token)
            (international-name token locale :keyword)
            as-verb))))

(defun localise-meta-line (line &optional (locale *current-locale*))
  "Rewrite a meta-command LINE from LOCALE into canonical English: every
identifier token (a maximal run of letters/digits/-/_) is canonicalised via
%TRANSLATE-TOKEN; punctuation, numbers, paths and \"...\" string literals pass
through untouched. Under \"en\" LINE is returned unchanged. This is the spec's
lexical pre-pass; the parser only ever sees canonical English."
  (if (string-equal locale "en")
      line
      (with-output-to-string (out)
        (let ((i 0) (n (length line)) (in-string nil))
          (loop while (< i n) do
            (let ((ch (char line i)))
              (cond
                (in-string
                 (write-char ch out)
                 (when (char= ch #\") (setf in-string nil))
                 (incf i))
                ((char= ch #\")
                 (setf in-string t) (write-char ch out) (incf i))
                ;; a token starts on a letter or an underscore (the force sigil).
                ((or (alpha-char-p ch) (char= ch #\_))
                 (let ((start i))
                   (loop while (and (< i n)
                                    (let ((c (char line i)))
                                      (or (alphanumericp c)
                                          (char= c #\-) (char= c #\_))))
                         do (incf i))
                   (write-string (%translate-token (subseq line start i) locale)
                                 out)))
                (t (write-char ch out) (incf i)))))))))

;;; --- Loading dictionaries from the shipped data files -------------
;;;
;;; A locale dictionary is DATA, not code (spec §Format des dictionnaires): the
;;; tables live under cadtui/data/locale/<locale>/<category>.sexp, one alist of
;;; (international . local) per file, the file name naming the category (verb,
;;; keyword for the interaction language; command, option-keyword, alias for the
;;; CAD vocabulary — the last three are probe-measured, see the sibling issues).
;;; Adding a language or a category = adding a file, never touching this code.
;;;
;;; The whole data tree is READ AT COMPILE TIME and baked into the fasl, so the
;;; built image carries the dictionaries with no runtime file dependency (a
;;; partial or absent tree just yields fewer entries — every lookup identity-
;;; falls-back to the international form). LOAD-LOCALE-DATA-FROM-DIRECTORY reloads
;;; a tree at runtime (e.g. after a fresh probe drop) without a rebuild.

;; These three helpers are used both at runtime (LOAD-LOCALE-DATA-FROM-DIRECTORY)
;; and at macroexpansion time (%EMBED-LOCALE-TREE, below, in this same file), so
;; they must exist when the compiler expands that macro — hence the eval-when.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun %read-sexp-file (path)
    "Read the single sexp datum from PATH with standard syntax and *read-eval*
disabled (the data files are inert alists, never code). Forced UTF-8: localised
names carry accents (e.g. ÉTIRER), which must read identically whatever the
build/runtime locale."
    (with-open-file (in path :direction :input :if-does-not-exist :error
                            :external-format :utf-8)
      (with-standard-io-syntax
        (let ((*read-eval* nil) (*package* (find-package :keyword)))
          (read in)))))

  (defun %locale-of-file (file)
    "The locale string a data FILE belongs to: its parent directory name."
    (car (last (pathname-directory file))))

  (defun %category-of-file (file)
    "The category keyword a data FILE declares: its base name, upcased and
interned (\"verb\" => :VERB, \"option-keyword\" => :OPTION-KEYWORD)."
    (intern (string-upcase (pathname-name file)) :keyword)))

(defun load-locale-data-from-directory (directory)
  "Load every <locale>/<category>.sexp under DIRECTORY into the registry,
registering each file's alist under its (locale, category). Returns the number of
files loaded. Missing files/directories are simply skipped."
  (let ((count 0))
    (dolist (file (directory (merge-pathnames "*/*.sexp" directory)) count)
      (register-locale-dictionary (%locale-of-file file)
                                  (%category-of-file file)
                                  (%read-sexp-file file))
      (incf count))))

(defmacro %embed-locale-tree (glob)
  "At COMPILE (or load) time, read every locale data file matching GLOB (relative
to this source file) and expand to code that registers them — baking the shipped
dictionaries into the image so runtime needs no data files present."
  (let* ((here (or *compile-file-truename* *load-truename*))
         (files (directory (merge-pathnames glob here))))
    `(progn
       ,@(loop for file in files
               collect `(register-locale-dictionary
                         ,(%locale-of-file file)
                         ,(%category-of-file file)
                         ',(%read-sexp-file file)))
       ,(length files))))

;; Bake the shipped data tree (cadtui/data/locale/<locale>/<category>.sexp) into
;; the image. This source file is cadtui/source/locale.lisp, so the data tree is
;; ../data/locale/ from here. Re-run LOAD-LOCALE-DATA-FROM-DIRECTORY for a later
;; drop (e.g. fresh probe output converted to command.sexp).
(%embed-locale-tree "../data/locale/*/*.sexp")

;; ...and reload the tree from disk at LOAD/build time when it is reachable.
;; ASDF does not track the embedded data files as dependencies of this source
;; file, so a .sexp edited without also touching locale.lisp would otherwise be
;; missed until the next full rebuild; reloading here means a source-tree build
;; (and the test suite) always reflects the current .sexp files. In a dumped or
;; installed image with no source tree the DIRECTORY glob simply finds nothing
;; and the embedded data (above) stands. Guarded: a missing system/dir is a
;; no-op, never an error.
(eval-when (:load-toplevel :execute)
  (ignore-errors
    (load-locale-data-from-directory
     (asdf:system-relative-pathname "clautolisp/cadtui" "cadtui/data/locale/"))))
