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

(defconst alref-html/css
  "<style>
body{font-family:sans-serif;max-width:60em;margin:2em auto;padding:0 1em;color:#222;line-height:1.5}
h1,h2,h3,h4{font-family:sans-serif;color:#111}
a{color:#0066cc;text-decoration:none}
a:hover{text-decoration:underline}
/* Backticked spans the spec uses for code, names, and outputs.
   Same tinted monospace look as pre.example so the visual
   recovery is consistent across kinds; em stays italic to
   distinguish project/system names from literal code, tt drops
   the italic + slightly brighter tint to set output apart. */
code,em.alref-name,tt.alref-result{
  font-family:Menlo,Consolas,monospace;
  background:#f5f5f5;border:1px solid #e0e0e0;border-radius:3px;
  padding:0 0.35em;font-size:0.95em
}
em.alref-name{font-style:italic;background:#f7f2ec;border-color:#e6dccc}
tt.alref-result{background:#eef5ee;border-color:#d4e3d4}
pre.example{
  font-family:Menlo,Consolas,monospace;
  background:#f5f5f5;border:1px solid #e0e0e0;border-radius:4px;
  padding:0.6em 0.8em;overflow-x:auto;font-size:0.95em
}
</style>"
  "CSS head injected into every per-section HTML page so backticked
spans (code / em / tt) all carry the tinted-monospace look the
spec's example blocks already use.")

(defconst alref-html/code-em-names
  '("clautolisp" "alfe" "autolisp" "visual lisp" "visuallisp"
    "autocad" "bricscad" "hyperspec" "elisp" "emacs"
    "autodesk" "bricsys")
  "Lower-cased project / vendor / language names. Backticked
mentions of these in the spec are *names* — not code — and get
retagged from <code> to <em class='alref-name'>.")

(defun alref-html/retag-code-spans (html)
  "Walk HTML for ``backticked`` spans (the org source's quoting
convention) and emit a semantic HTML tag based on the content:

  <em class='alref-name'>    project / vendor / language name
                             (clautolisp, alfe, AutoCAD, …)
  <tt class='alref-result'>  evaluation result: a span containing
                             '=>' or the bare T / NIL literals
  <code>                     everything else — the default for
                             code samples, function names,
                             operators, sysvars, string literals

Why the source-side backticks aren't already <code>: org-mode
treats backticks as plain text characters; its built-in code
markup is =verbatim= or ~code~. The spec source was written in a
markdown-ish style with backticks, so the backticks survive
org-html-export verbatim. This post-pass is the recovery: detect
the backticked spans in the rendered HTML and emit the right
semantic tag for each."
  (replace-regexp-in-string
   ;; `…` containing no newline, no nested backtick, no angle
   ;; bracket (so we don't accidentally chew into HTML tag
   ;; attribute values that happen to live near a backtick).
   "`\\([^`<\n]+\\)`"
   (lambda (full-match)
     (let* ((content (match-string 1 full-match))
            (downcased (downcase content)))
       (cond
         ;; '=>' marks 'evaluate to' lines; the whole span is a
         ;; result expression -> tt.
         ((string-match-p "=>" content)
          (format "<tt class='alref-result'>%s</tt>" content))
         ;; Bare T / NIL / nil are conventional AutoLISP literals
         ;; used as evaluation results.
         ((member content '("T" "NIL" "nil" "t"))
          (format "<tt class='alref-result'>%s</tt>" content))
         ;; Known project / vendor names — these are emphasis,
         ;; not literal code. List is small and lower-cased so we
         ;; can match case-insensitively without losing the
         ;; original casing in the output.
         ((member downcased alref-html/code-em-names)
          (format "<em class='alref-name'>%s</em>" content))
         (t
          (format "<code>%s</code>" content)))))
   html t t))

(defun alref-html/export-section (org-file html-dir)
  "Run org-html-export-to-html on ORG-FILE, then move the result
into HTML-DIR. Returns the destination HTML pathname.

Uses find-file + kill-buffer rather than with-temp-buffer so
org-html-export-to-html has a real file context — the temp-buffer
recipe silently no-ops the export. Disables org-html's default
postamble (the 'Created by Emacs … using …' footer) since the
nav header at the top of each org page is sufficient. Injects
the alref CSS via `org-html-head' so every page picks up the
backtick-span styling without needing per-page #+HTML_HEAD
directives.

After org-html writes the file, runs RETAG-CODE-SPANS on its
content to recover the semantic distinction between code / em /
tt that the source's uniform backticks lost on the way to HTML."
  (let* ((basename (file-name-base org-file))
         (html-target (expand-file-name (format "%s.html" basename) html-dir))
         (org-out (concat (file-name-sans-extension org-file) ".html")))
    (let ((buffer (find-file-noselect org-file)))
      (unwind-protect
          (with-current-buffer buffer
            (let ((org-export-with-toc nil)
                  (org-export-with-section-numbers nil)
                  (org-html-postamble nil)
                  (org-html-head alref-html/css)
                  (org-html-htmlize-output-type 'css))
              (org-html-export-to-html)))
        (kill-buffer buffer)))
    (when (file-exists-p org-out)
      (when (file-exists-p html-target) (delete-file html-target))
      (rename-file org-out html-target))
    ;; Post-process to retag the semantically-distinct backtick
    ;; spans (code / em / tt). Read, transform, rewrite.
    (when (file-exists-p html-target)
      (let ((raw (with-temp-buffer
                   (insert-file-contents html-target)
                   (buffer-string))))
        (with-temp-file html-target
          (insert (alref-html/retag-code-spans raw)))))
    html-target))

(defun alref-html/write-index-html (index html-dir)
  "Generate HTML-DIR/index.html — links to every page in INDEX
order, grouped by chapter."
  (let ((path (expand-file-name "index.html" html-dir)))
    (with-temp-file path
      (insert "<!DOCTYPE html>\n<html><head>\n")
      (insert "<meta charset='utf-8'>\n")
      (insert "<title>AutoLISP Spec — Index</title>\n")
      (insert alref-html/css)
      (insert "<style>")
      (insert "h2{margin-top:1.5em;border-bottom:1px solid #ccc;padding-bottom:0.2em}")
      (insert "ul{list-style:none;padding-left:1em;margin:0.3em 0}")
      (insert "li{margin:0.15em 0}</style>\n")
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
      (insert alref-html/css)
      (insert "<style>")
      (insert "h2{margin-top:1.5em}")
      (insert "ul{column-count:3;column-gap:2em;list-style:none;padding-left:0}")
      (insert "li{margin:0.1em 0;break-inside:avoid}</style>\n")
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
