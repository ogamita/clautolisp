;;; alref.el --- AutoLISP Spec reference for Emacs  -*- lexical-binding: t -*-

;; Copyright (C) Pascal J. Bourguignon
;; License: CC-BY-SA (same as the spec)

;;; Commentary:
;;
;; Emacs-side companion to the paged build of the AutoLISP /
;; Visual LISP language specification. Loads the symbols + index
;; files produced by autolisp-spec/scripts/build-paged-spec.el at
;; first use, then exposes two main user-facing commands:
;;
;;   `alref-lookup' (M-x alref-lookup) — completing-read over every
;;   documented symbol, opens the matching HTML page (or the plain
;;   text page when the HTML render isn't installed) in the
;;   browser. Companion to `M-x hyperspec-lookup' from the Common
;;   Lisp world.
;;
;;   `alref-autodoc-mode' — a buffer-local minor mode (like
;;   slime-autodoc) that shows the operator signature of the
;;   symbol at point in the minibuffer. Picks up compatibility
;;   indicators ([A]/[B]/[C]/[ABC]) from the symbol's Compatibility
;;   table when the page provides one.
;;
;; Install:
;;
;;   $PREFIX/share/emacs/site-lisp/autolisp-spec/alref.el is added
;;   to load-path by site-load.el (or by the user's init file).
;;   The variable `alref-spec-directory' must point at the
;;   $PREFIX/share/autolisp-spec/ data root. The default below
;;   tries `/opt/share/autolisp-spec/' first, then a sibling-of-
;;   this-elisp-file path so a freshly-built tree works without
;;   any setq.

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'browse-url)

(defgroup alref nil
  "AutoLISP / Visual LISP language specification reference."
  :group 'tools
  :prefix "alref-")

(defcustom alref-spec-directory nil
  "Root of the installed paged spec.

Expected layout under this directory:

  pages/         — plain-text per-section pages
  pages/index.txt   — section index (one line per page)
  pages/symbols.txt — symbol → page map (alref-lookup keys off this)
  html/          — HTML version (alref-lookup opens these)
  html/index.html
  html/symbols.html
  info/          — Info version

When nil, ALREF tries a small set of well-known locations at load
time (see `alref--default-spec-directory'); set this in your init
file to point alref at a non-default install root."
  :type '(choice (const :tag "Autodetect" nil)
                 (directory :tag "Spec install root"))
  :group 'alref)

(defcustom alref-browser-function #'browse-url
  "Function to open a help URL. Receives one argument — the URL.
Defaults to `browse-url' (system default browser). Use
`eww-browse-url' for a built-in Emacs browser, or any
single-arg-URL-taking function."
  :type 'function
  :group 'alref)

(defun alref--default-spec-directory ()
  "Search the well-known install locations for the paged spec
data root. Return the first existing directory, or nil if none
match — the user will need to set `alref-spec-directory' by hand."
  (let ((candidates
         (list
          (expand-file-name "../share/autolisp-spec/"
                            (file-name-directory
                             (or load-file-name buffer-file-name "")))
          "/opt/share/autolisp-spec/"
          "/usr/local/share/autolisp-spec/"
          "/usr/share/autolisp-spec/")))
    (cl-loop for dir in candidates
             when (file-directory-p dir)
             return (file-name-as-directory dir))))

(defun alref--spec-directory ()
  "Resolve the spec data root, signalling a friendly error if
neither the custom var nor any default location is populated."
  (or alref-spec-directory
      (alref--default-spec-directory)
      (user-error "alref: spec data directory not found — set `alref-spec-directory' to your install root")))

;;; --- symbol index ---------------------------------------------------
;;
;; symbols.txt is one line per documented symbol:
;;   SYMBOL\tKIND\tBASENAME
;; KIND is the prose-name of the entry kind (Function / Reader Syntax /
;; Special Operator / Variable / Macro / Type). BASENAME is the on-disk
;; stem (filename without extension); appended to pages/ → .txt, html/
;; → .html, etc.

(defvar alref--symbol-table nil
  "Hash table: SYMBOL → (KIND BASENAME). Filled lazily by
`alref--ensure-loaded'.")

(defvar alref--symbol-loaded-from nil
  "Pathname the current `alref--symbol-table' was loaded from.
Used by `alref-reload' to know what to re-read.")

(defun alref--load-symbols-file (path)
  "Parse PATH (the symbols.txt file) into a fresh hash table."
  (let ((table (make-hash-table :test 'equal)))
    (with-temp-buffer
      (insert-file-contents path)
      (goto-char (point-min))
      (while (not (eobp))
        (let ((line (buffer-substring-no-properties
                     (line-beginning-position)
                     (line-end-position))))
          (when (string-match "^\\([^\t]+\\)\t\\([^\t]+\\)\t\\(.+\\)$" line)
            (puthash (match-string 1 line)
                     (list (match-string 2 line) (match-string 3 line))
                     table)))
        (forward-line 1)))
    table))

(defun alref--ensure-loaded ()
  "Make sure `alref--symbol-table' is populated. Re-loads if the
underlying file has been edited since the last read."
  (let* ((root (alref--spec-directory))
         (path (expand-file-name "pages/symbols.txt" root)))
    (unless (file-exists-p path)
      (user-error "alref: symbols index missing at %s — has the spec been built and installed?" path))
    (when (or (null alref--symbol-table)
              (not (equal alref--symbol-loaded-from path)))
      (setq alref--symbol-table (alref--load-symbols-file path)
            alref--symbol-loaded-from path))))

(defun alref-reload ()
  "Force a re-read of the symbol index. Useful after a fresh
spec build during local development."
  (interactive)
  (setq alref--symbol-table nil
        alref--symbol-loaded-from nil)
  (alref--ensure-loaded)
  (message "alref: reloaded %d symbols from %s"
           (hash-table-count alref--symbol-table)
           alref--symbol-loaded-from))

;;; --- lookup ---------------------------------------------------------

(defun alref--page-url (basename)
  "Return the file: URL for BASENAME's HTML page, falling back to
the plain-text page when no HTML build is present."
  (let* ((root (alref--spec-directory))
         (html (expand-file-name (format "html/%s.html" basename) root))
         (txt  (expand-file-name (format "pages/%s.txt" basename) root)))
    (cond ((file-exists-p html) (concat "file://" html))
          ((file-exists-p txt)  (concat "file://" txt))
          (t (user-error "alref: no page found for %s under %s" basename root)))))

(defun alref--all-symbols ()
  "Return a sorted list of every documented symbol name."
  (alref--ensure-loaded)
  (sort (cl-loop for k being the hash-keys of alref--symbol-table collect k)
        #'string<))

;;;###autoload
(defun alref-lookup (symbol)
  "Open the AutoLISP spec page for SYMBOL in the configured
browser. Interactively prompts with completion over every
documented symbol; the prompt's default is the symbol at point
when one matches.

Companion to M-x hyperspec-lookup for Common Lisp users."
  (interactive
   (progn
     (alref--ensure-loaded)
     (let* ((candidates (alref--all-symbols))
            (default (and (thing-at-point 'symbol)
                          (let ((up (upcase (thing-at-point 'symbol))))
                            (and (gethash up alref--symbol-table) up))))
            (prompt (if default
                        (format "AutoLISP symbol (default %s): " default)
                        "AutoLISP symbol: "))
            (chosen (completing-read prompt candidates nil t nil nil default)))
       (list chosen))))
  (alref--ensure-loaded)
  (let ((entry (gethash symbol alref--symbol-table)))
    (unless entry
      (user-error "alref: unknown symbol %s" symbol))
    (funcall alref-browser-function
             (alref--page-url (cadr entry)))))

;;;###autoload
(defun alref-apropos (pattern)
  "Print every documented symbol whose name contains PATTERN
(case-insensitive). Output goes to *alref-apropos*, with each line
showing the symbol, its kind, and its page basename — click or
RET to open."
  (interactive "sapropos pattern: ")
  (alref--ensure-loaded)
  (let* ((needle (downcase pattern))
         (matches (cl-loop for k being the hash-keys of alref--symbol-table
                           when (string-match-p (regexp-quote needle)
                                                (downcase k))
                           collect (cons k (gethash k alref--symbol-table)))))
    (setq matches (sort matches (lambda (a b) (string< (car a) (car b)))))
    (with-current-buffer (get-buffer-create "*alref-apropos*")
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (format "Symbols matching %S (%d):\n\n" pattern (length matches)))
        (dolist (m matches)
          (let ((name (car m))
                (kind (nth 0 (cdr m)))
                (page (nth 1 (cdr m))))
            (insert-button name
                           'action (lambda (_) (alref-lookup name))
                           'follow-link t)
            (insert (format "\t%s\t%s\n" kind page))))
        (goto-char (point-min)))
      (special-mode)
      (display-buffer (current-buffer)))))

;;; --- autodoc minor mode --------------------------------------------
;;
;; Pulled deliberately tight: shows the Syntax line from the symbol's
;; page in the minibuffer when the symbol at point is documented.
;; Compatibility tags ([A]/[B]/[C]) come from the Compatibility row
;; if the page renders one.

(defvar alref--syntax-cache (make-hash-table :test 'equal)
  "Memoised SYMBOL → (DOC-LINE COMPAT-TAG) for autodoc lookups.")

(defun alref--read-page-lines (basename)
  "Slurp the lines of pages/BASENAME.txt — used by the autodoc
extractor. Returns nil when the page isn't installed."
  (let ((path (expand-file-name (format "pages/%s.txt" basename)
                                (alref--spec-directory))))
    (when (file-exists-p path)
      (with-temp-buffer
        (insert-file-contents path)
        (split-string (buffer-string) "\n")))))

(defun alref--extract-syntax (lines)
  "From the plain-text page LINES list, return the value of the
'*** Syntax' subheading (the first non-empty line under it), or
nil when no Syntax section exists."
  (let ((tail lines)
        (found nil))
    (while (and tail (not found))
      (when (string-match-p "^\\*\\*\\* Syntax\\b" (car tail))
        (setq tail (cdr tail))
        (while (and tail (string-empty-p (car tail))) (setq tail (cdr tail)))
        (when tail (setq found (car tail))))
      (setq tail (cdr tail)))
    found))

(defun alref--extract-compat-tag (lines)
  "Best-effort scan of LINES for a Compatibility note. Returns a
short bracketed tag like [A] / [B] / [C] / [AB] / [ABC] when the
page distinguishes vendor coverage, or the empty string when it
doesn't."
  (let ((tail lines)
        (in-compat nil)
        (vendors nil))
    (while tail
      (let ((line (car tail)))
        (cond
          ((string-match-p "^\\*\\*\\* Compatibility\\b" line)
           (setq in-compat t))
          ((and in-compat (string-match-p "^\\*\\*\\*" line))
           (setq in-compat nil))
          (in-compat
           (when (string-match-p "\\bAutoCAD\\b" line)  (push "A" vendors))
           (when (string-match-p "\\bBricsCAD\\b" line) (push "B" vendors))
           (when (string-match-p "\\bclautolisp\\b" line) (push "C" vendors)))))
      (setq tail (cdr tail)))
    (if vendors
        (format "[%s]" (mapconcat #'identity
                                  (cl-remove-duplicates
                                   (nreverse vendors) :test #'string=)
                                  ""))
        "")))

(defun alref--autodoc-for-symbol (symbol)
  "Return the autodoc string for SYMBOL, or nil when SYMBOL isn't
in the index."
  (alref--ensure-loaded)
  (let ((entry (gethash symbol alref--symbol-table)))
    (when entry
      (or (gethash symbol alref--syntax-cache)
          (let* ((lines  (alref--read-page-lines (cadr entry)))
                 (syntax (and lines (alref--extract-syntax lines)))
                 (compat (and lines (alref--extract-compat-tag lines)))
                 (result (cond
                           ((null lines) (format "%s: page not installed" symbol))
                           (syntax (string-trim
                                    (concat compat (when (not (string-empty-p compat)) " ")
                                            syntax)))
                           (t (format "%s: %s" symbol (car entry))))))
            (puthash symbol result alref--syntax-cache)
            result)))))

(defun alref--symbol-at-point ()
  "Return the symbol at point, uppercased, or nil."
  (when-let ((s (thing-at-point 'symbol t)))
    (upcase s)))

(defvar alref-autodoc--last-symbol nil
  "Last symbol the autodoc minor mode displayed for, so cursor
movement within the same name doesn't re-render unchanged.")

(defun alref-autodoc--echo ()
  "Display the autodoc line for the symbol at point in the echo
area. Bound to `post-command-hook' by the minor mode."
  (let ((sym (alref--symbol-at-point)))
    (unless (equal sym alref-autodoc--last-symbol)
      (setq alref-autodoc--last-symbol sym)
      (let ((doc (and sym (alref--autodoc-for-symbol sym))))
        (when doc
          (let ((message-log-max nil))
            (message "%s" doc)))))))

;;;###autoload
(define-minor-mode alref-autodoc-mode
  "Minor mode that shows the AutoLISP spec syntax of the symbol
at point in the echo area, with a [A]/[B]/[C] compatibility tag
when the spec page documents vendor coverage. Similar in spirit
to slime-autodoc-mode."
  :init-value nil
  :lighter " AlRef"
  (if alref-autodoc-mode
      (add-hook 'post-command-hook #'alref-autodoc--echo nil t)
      (remove-hook 'post-command-hook #'alref-autodoc--echo t)))

(provide 'alref)
;;; alref.el ends here
