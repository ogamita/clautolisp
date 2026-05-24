;;; build-paged-html.el --- Render per-section .org pages as HTML.
;;;
;;; Consumes the per-section .org files emitted by
;;; build-paged-spec.el (in :org format) under OUTPUT-DIR/org/, runs
;;; org-html-export-to-html on each, and writes the resulting .html
;;; into OUTPUT-DIR/html/. Also generates index.html and symbols.html
;;; from the matching index.txt + symbols.txt artefacts.
;;;
;;; Invoke via:
;;;
;;;   emacs --batch --script build-paged-html.el BUILD-DIR
;;;
;;; Where BUILD-DIR is the autolisp-spec build/ root — the script
;;; expects build/org/ as input and writes build/html/ as output.
;;; Both directories are created when missing.
;;;
;;; The per-section .org files carry their own navigation strip
;;; (build-paged-spec.el embeds prev/next/up/index links at the top
;;; of every page), so this driver just delegates the page rendering
;;; to org's stock HTML exporter and concentrates on the two index
;;; pages.

(require 'cl-lib)
(require 'org)
(require 'ox-html)
(require 'subr-x)

(defun alref-html/argv ()
  (or command-line-args-left
      (error "build-paged-html.el: missing BUILD-DIR argument")))

(defun alref-html/load-index (path)
  "Read PATH (build/org/index.txt) and return a list of
(BASENAME . TITLE) pairs in walking order."
  (let (entries)
    (with-temp-buffer
      (insert-file-contents path)
      (goto-char (point-min))
      (while (not (eobp))
        (let ((line (buffer-substring-no-properties
                     (line-beginning-position)
                     (line-end-position))))
          (when (string-match "^\\([^\t]+\\)\t\\(.*\\)$" line)
            (push (cons (match-string 1 line)
                        (match-string 2 line))
                  entries)))
        (forward-line 1)))
    (nreverse entries)))

(defun alref-html/load-symbols (path)
  "Read PATH (build/org/symbols.txt) and return a list of
(SYMBOL KIND BASENAME) triples."
  (let (entries)
    (when (file-exists-p path)
      (with-temp-buffer
        (insert-file-contents path)
        (goto-char (point-min))
        (while (not (eobp))
          (let ((line (buffer-substring-no-properties
                       (line-beginning-position)
                       (line-end-position))))
            (when (string-match "^\\([^\t]+\\)\t\\([^\t]+\\)\t\\(.+\\)$" line)
              (push (list (match-string 1 line)
                          (match-string 2 line)
                          (match-string 3 line))
                    entries)))
          (forward-line 1))))
    (nreverse entries)))

(defun alref-html/export-section (org-file html-dir)
  "Run org-html-export-to-html on ORG-FILE, then move the result
into HTML-DIR. Returns the destination HTML pathname.

Uses find-file + kill-buffer rather than with-temp-buffer so
org-html-export-to-html has a real file context — the temp-buffer
recipe silently no-ops the export. Disables org-html's default
postamble (the 'Created by Emacs … using …' footer) since the
nav header at the top of each org page is sufficient."
  (let* ((basename (file-name-base org-file))
         (html-target (expand-file-name (format "%s.html" basename) html-dir))
         (org-out (concat (file-name-sans-extension org-file) ".html")))
    (let ((buffer (find-file-noselect org-file)))
      (unwind-protect
          (with-current-buffer buffer
            (let ((org-export-with-toc nil)
                  (org-export-with-section-numbers nil)
                  (org-html-postamble nil)
                  (org-html-htmlize-output-type 'css))
              (org-html-export-to-html)))
        (kill-buffer buffer)))
    (when (file-exists-p org-out)
      (when (file-exists-p html-target) (delete-file html-target))
      (rename-file org-out html-target))
    html-target))

(defun alref-html/write-index-html (index html-dir)
  "Generate HTML-DIR/index.html — links to every page in INDEX
order, grouped by chapter."
  (let ((path (expand-file-name "index.html" html-dir)))
    (with-temp-file path
      (insert "<!DOCTYPE html>\n<html><head>\n")
      (insert "<meta charset='utf-8'>\n")
      (insert "<title>AutoLISP Spec — Index</title>\n")
      (insert "<style>body{font-family:sans-serif;max-width:60em;margin:2em auto;padding:0 1em}")
      (insert "h2{margin-top:1.5em;border-bottom:1px solid #ccc;padding-bottom:0.2em}")
      (insert "ul{list-style:none;padding-left:1em;margin:0.3em 0}")
      (insert "li{margin:0.15em 0}a{text-decoration:none;color:#0066cc}a:hover{text-decoration:underline}</style>\n")
      (insert "</head><body>\n")
      (insert "<h1>AutoLISP / Visual LISP Specification</h1>\n")
      (insert "<p><a href='symbols.html'>Symbols index</a> · ")
      (insert "<a href='../pages/'>Plain-text pages</a></p>\n")
      ;; Group consecutive entries by leading chapter number.
      (let ((current-chapter nil))
        (dolist (entry index)
          (let* ((basename (car entry))
                 (title (cdr entry))
                 (chapter (if (string-match "^\\([0-9][0-9A-Z]*\\)-" basename)
                              (match-string 1 basename)
                              nil)))
            (cond
              ((and chapter (not (equal chapter current-chapter)))
               (when current-chapter (insert "</ul>\n"))
               (insert (format "<h2>Chapter %s</h2>\n<ul>\n" chapter))
               (setq current-chapter chapter))
              ((null current-chapter)
               (insert "<ul>\n")
               (setq current-chapter "_")))
            (insert (format "<li><a href='%s.html'>%s</a></li>\n"
                            basename title))))
        (insert "</ul>\n"))
      (insert "</body></html>\n"))
    path))

(defun alref-html/write-symbols-html (symbols html-dir)
  "Generate HTML-DIR/symbols.html — every documented entry name
linked to its page, sorted alphabetically with a per-kind
section."
  (let ((path (expand-file-name "symbols.html" html-dir))
        (by-kind (make-hash-table :test 'equal)))
    (dolist (symbol symbols)
      (let* ((kind (nth 1 symbol)))
        (push symbol (gethash kind by-kind))))
    (with-temp-file path
      (insert "<!DOCTYPE html>\n<html><head>\n")
      (insert "<meta charset='utf-8'>\n")
      (insert "<title>AutoLISP Spec — Symbols</title>\n")
      (insert "<style>body{font-family:sans-serif;max-width:60em;margin:2em auto;padding:0 1em}")
      (insert "h2{margin-top:1.5em}")
      (insert "ul{column-count:3;column-gap:2em;list-style:none;padding-left:0}")
      (insert "li{margin:0.1em 0;break-inside:avoid}a{text-decoration:none;color:#0066cc}")
      (insert "a:hover{text-decoration:underline}code{font-family:Menlo,monospace}</style>\n")
      (insert "</head><body>\n")
      (insert "<h1>Symbols index</h1>\n")
      (insert "<p><a href='index.html'>Back to top index</a></p>\n")
      (let ((kinds (sort (cl-loop for k being the hash-keys of by-kind collect k)
                        #'string<)))
        (dolist (kind kinds)
          (insert (format "<h2>%s entries</h2>\n<ul>\n" kind))
          (let ((entries (sort (gethash kind by-kind)
                              (lambda (a b) (string< (car a) (car b))))))
            (dolist (entry entries)
              (insert (format "<li><a href='%s.html'><code>%s</code></a></li>\n"
                              (nth 2 entry) (nth 0 entry)))))
          (insert "</ul>\n")))
      (insert "</body></html>\n"))
    path))

;;; --- main ----------------------------------------------------------

(let* ((argv (alref-html/argv))
       (build-dir (or (nth 0 argv)
                      (error "build-paged-html: missing BUILD-DIR")))
       (org-dir (expand-file-name "org" build-dir))
       (html-dir (expand-file-name "html" build-dir)))
  (unless (file-directory-p org-dir)
    (error "build-paged-html: %s does not exist — run 'make' which produces build/.org-stamp first." org-dir))
  (make-directory html-dir t)
  (message "build-paged-html: %s -> %s" org-dir html-dir)
  (let ((org-files (directory-files org-dir t "\\.org$"))
        (count 0))
    (dolist (org-file org-files)
      (alref-html/export-section org-file html-dir)
      (cl-incf count))
    (message "build-paged-html: rendered %d section HTML pages." count))
  (let ((index (alref-html/load-index
                (expand-file-name "index.txt" org-dir)))
        (symbols (alref-html/load-symbols
                  (expand-file-name "symbols.txt" org-dir))))
    (alref-html/write-index-html index html-dir)
    (alref-html/write-symbols-html symbols html-dir)
    (message "build-paged-html: wrote index.html (%d entries) + symbols.html (%d symbols)."
             (length index) (length symbols))))
