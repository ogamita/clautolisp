;;; build-paged-spec.el --- Split the autolisp spec into per-section pages.
;;;
;;; Reads a single org source file and emits, one file per * chapter and
;;; one file per ** subsection, into the configured output directory.
;;; Also writes an index file mapping section title → page filename and a
;;; symbols file mapping documented entry names (the ones introduced by
;;; '** Function Entry: NAME' / '** Reader Syntax Entry: NAME' / similar)
;;; to their pages, so downstream consumers (the Emacs `alref-lookup`
;;; command and the AutoLISP `alref-*` library) can do constant-time
;;; symbol lookup without rescanning the whole spec.
;;;
;;; Invoke via:
;;;
;;;   emacs --batch --script build-paged-spec.el \
;;;       INPUT.org OUTPUT-DIR FORMAT
;;;
;;; where FORMAT is one of:
;;;
;;;   text  — emits plain-text pages with org directives stripped
;;;           (#+LATEX, #+begin_example/end_example, the front-matter
;;;           #+TITLE/#+AUTHOR/etc.).
;;;   org   — emits org-mode pages with the org directives preserved
;;;           and a per-section #+TITLE / #+UP / #+PREV / #+NEXT header
;;;           added; downstream HTML and Info builds consume this form.
;;;
;;; The script is self-contained — only relies on cl-lib and the
;;; standard org-mode reader; no third-party packages.

(require 'cl-lib)
(require 'subr-x)

;;; --- argv ----------------------------------------------------------

(defun alref-build/argv ()
  "Return the script-mode argv tail (after the --script <file> args)."
  (let* ((all command-line-args-left))
    (or all
        (error "build-paged-spec.el: missing arguments — INPUT.org OUTPUT-DIR FORMAT"))))

;;; --- slug + chapter helpers ---------------------------------------

(defun alref-build/encode-operators (string)
  "Replace AutoLISP operator characters in STRING with letter-only
tokens, so that slugification yields unique, readable filenames
for the arithmetic + comparison entries instead of collapsing
them all to the bare prefix. Mirrors a small subset of HyperSpec's
URL-encoding table — just the operator chars that actually appear
in the spec's entry titles, plus the namespace-separator '::' and
the '->' coercion arrow."
  (let ((s string))
    ;; Multi-character patterns first so they don't get half-eaten
    ;; by the single-character pass below.
    (setq s (replace-regexp-in-string "->"  " to "    s))
    (setq s (replace-regexp-in-string "<="  " lte "   s))
    (setq s (replace-regexp-in-string ">="  " gte "   s))
    (setq s (replace-regexp-in-string "/="  " neq "   s))
    (setq s (replace-regexp-in-string "::"  " ns "    s))
    ;; Standalone '-' operators: the bare '-' (preceded by ': ') and
    ;; the '1-' / 'foo-' family (preceded by an alphanumeric, at
    ;; end of name). Word-internal hyphens stay intact.
    (setq s (replace-regexp-in-string ":\\s-+-\\($\\|\\s-\\)" ": minus\\1" s))
    (setq s (replace-regexp-in-string "\\([0-9A-Za-z]\\)-\\($\\|\\s-\\)" "\\1 minus\\2" s))
    ;; Single-character operators that never appear in regular
    ;; section titles, so substitution is unconditional.
    (setq s (replace-regexp-in-string "\\+"  " plus "   s))
    (setq s (replace-regexp-in-string "\\*"  " star "   s))
    (setq s (replace-regexp-in-string "/"    " slash "  s))
    (setq s (replace-regexp-in-string "="    " eq "     s))
    (setq s (replace-regexp-in-string "<"    " lt "     s))
    (setq s (replace-regexp-in-string ">"    " gt "     s))
    (setq s (replace-regexp-in-string "~"    " tilde "  s))
    (setq s (replace-regexp-in-string "\\$"  " dollar " s))
    s))

(defun alref-build/slugify (string)
  "Lowercase STRING, encode operator chars to letter tokens (so a
title like 'Function Entry: +' becomes 'function-entry-plus' and
'Function Entry: 1-' becomes 'function-entry-1-minus' rather than
both colliding on 'function-entry'), then replace runs of
non-alphanumeric chars with '-' and trim leading/trailing '-'."
  (let* ((encoded (alref-build/encode-operators string))
         (down (downcase encoded))
         (replaced (replace-regexp-in-string "[^a-z0-9]+" "-" down))
         (trimmed (replace-regexp-in-string "\\(^-+\\|-+$\\)" "" replaced)))
    (if (string-empty-p trimmed) "section" trimmed)))

(defun alref-build/parse-chapter-number (heading-text)
  "Extract the leading chapter number from a '* N Title' heading.
Returns the number as a string ('1', '10', '21A') or nil when no
leading digit-run is present (which would indicate a malformed
chapter heading)."
  (when (string-match "^\\([0-9][0-9A-Z]*\\)\\b" heading-text)
    (match-string 1 heading-text)))

(defun alref-build/strip-chapter-prefix (heading-text)
  "Drop the leading chapter number from HEADING-TEXT so the title
becomes 'Introduction' rather than '1 Introduction'. Returns the
unmodified string when no chapter number is present."
  (replace-regexp-in-string "^[0-9][0-9A-Z]*\\s-+" "" heading-text))

(defun alref-build/entry-symbol (subsection-title)
  "When SUBSECTION-TITLE matches one of the documented entry-type
patterns ('Function Entry: NAME', 'Reader Syntax Entry: NAME',
'Special Operator Entry: NAME', 'Variable Entry: NAME', 'Macro
Entry: NAME', 'Type Entry: NAME'), return (KIND . NAME) — both
strings, NAME uppercased. Returns nil otherwise."
  (when (string-match
         "^\\(Function\\|Reader Syntax\\|Special Operator\\|Variable\\|Macro\\|Type\\)\\s-+Entry:\\s-+\\(.+\\)$"
         subsection-title)
    (cons (match-string 1 subsection-title)
          (upcase (string-trim (match-string 2 subsection-title))))))

;;; --- section accumulator ------------------------------------------

(cl-defstruct alref-build/section
  "One emitted page: chapter number, level (1 or 2), original
title, slugified title, body lines (a list of strings in reverse
order — `push`-ed onto, reversed on emit), and optional entry
metadata (KIND . NAME) for symbol-index entries."
  chapter level title slug body entry)

(defun alref-build/section-filename (section)
  "Compose the on-disk basename for SECTION: <chapter>-<slug>."
  (let ((chapter (alref-build/section-chapter section))
        (slug    (alref-build/section-slug section)))
    (if chapter
        (format "%s-%s" chapter slug)
        slug)))

(defun alref-build/finalise-body (section)
  "Reverse SECTION's accumulated body lines, drop a trailing run of
blank lines, and re-join into a single string ready for write-out."
  (let* ((lines (nreverse (alref-build/section-body section))))
    (while (and lines (string-empty-p (car (last lines))))
      (setq lines (butlast lines)))
    (mapconcat #'identity lines "\n")))

;;; --- parser --------------------------------------------------------

(defun alref-build/strip-line-for-text-p (line)
  "True iff LINE is an org directive we drop in :text format —
the front-matter #+TITLE / #+AUTHOR / #+VERSION etc., the
#+LATEX directives interleaved through the body, and the
#+begin_example / #+end_example block fences. The contents of
example blocks (the code samples) are preserved; only the fences
themselves go away."
  (string-match-p
   "^#\\+\\(TITLE:\\|AUTHOR:\\|OPTIONS:\\|SUBTITLE:\\|VERSION:\\|LICENSE:\\|LATEX:\\|begin_example\\|end_example\\)"
   line))

(defun alref-build/parse-org-file (input-file)
  "Walk INPUT-FILE line by line and return the ordered list of
SECTION records. The first record represents pre-first-chapter
content (the org front matter) and is dropped by the caller —
its slug is `frontmatter`."
  (let ((sections nil)
        (current  (make-alref-build/section
                   :chapter nil :level 0
                   :title "Frontmatter" :slug "frontmatter"
                   :body nil :entry nil))
        (current-chapter nil))
    (with-temp-buffer
      (insert-file-contents input-file)
      (goto-char (point-min))
      (while (not (eobp))
        (let ((line (buffer-substring-no-properties
                     (line-beginning-position)
                     (line-end-position))))
          (cond
            ;; '* N Title' — start of a new chapter.
            ((string-match "^\\*\\s-+\\(.+\\)$" line)
             (push current sections)
             (let* ((raw-title (match-string 1 line))
                    (chapter   (alref-build/parse-chapter-number raw-title))
                    (title     (alref-build/strip-chapter-prefix raw-title))
                    (slug      (alref-build/slugify title)))
               (setq current-chapter chapter)
               (setq current
                     (make-alref-build/section
                      :chapter chapter :level 1
                      :title title :slug slug
                      :body nil :entry nil))))
            ;; '** Title' — start of a new subsection.
            ((string-match "^\\*\\*\\s-+\\(.+\\)$" line)
             (push current sections)
             (let* ((title (match-string 1 line))
                    (slug  (alref-build/slugify title))
                    (entry (alref-build/entry-symbol title)))
               (setq current
                     (make-alref-build/section
                      :chapter current-chapter :level 2
                      :title title :slug slug
                      :body nil :entry entry))))
            ;; Anything else: accumulate into the current section.
            (t
             (push line (alref-build/section-body current)))))
        (forward-line 1)))
    (push current sections)
    (nreverse sections)))

;;; --- emit ----------------------------------------------------------

(defun alref-build/strip-text-body (raw)
  "Apply :text-format stripping to RAW (a multi-line string).
Drops #+LATEX, #+begin_example, #+end_example markers but keeps
the code lines that lived inside the example blocks."
  (mapconcat #'identity
             (cl-remove-if #'alref-build/strip-line-for-text-p
                           (split-string raw "\n"))
             "\n"))

(defun alref-build/section-page (section format)
  "Render SECTION as a multi-line string ready to write to disk.
FORMAT is :text or :org.

In :text format the org directives are stripped, but the section
title is prepended as a plain `=== Title ===` banner and a
trailing '[chapter N — see <index>]' breadcrumb is appended so
the page is meaningful read in isolation.

In :org format we preserve the directives and re-emit the section
heading at level 1 (chapter pages) or level 2 (subsection pages),
plus a `:PROPERTIES: :ALREF-CHAPTER: N :END:` block downstream
HTML/Info post-processors can consume."
  (let* ((chapter (alref-build/section-chapter section))
         (level   (alref-build/section-level section))
         (title   (alref-build/section-title section))
         (entry   (alref-build/section-entry section))
         (body    (alref-build/finalise-body section)))
    (cond
      ((eq format :text)
       (with-output-to-string
         (princ "=== ")
         (princ title)
         (princ " ===")
         (terpri)
         (when chapter
           (princ (format "Chapter %s.\n" chapter)))
         (when entry
           (princ (format "%s entry: %s.\n" (car entry) (cdr entry))))
         (terpri)
         (princ (alref-build/strip-text-body body))))
      ((eq format :org)
       (with-output-to-string
         (princ (format "#+TITLE: %s\n" title))
         (when chapter
           (princ (format "#+PROPERTY: ALREF-CHAPTER %s\n" chapter)))
         (princ (format "#+PROPERTY: ALREF-LEVEL %d\n" level))
         (when entry
           (princ (format "#+PROPERTY: ALREF-ENTRY-KIND %s\n" (car entry)))
           (princ (format "#+PROPERTY: ALREF-ENTRY-NAME %s\n" (cdr entry))))
         (terpri)
         (princ (format "%s %s\n" (make-string level ?\*) title))
         (princ body)))
      (t
       (error "build-paged-spec.el: unknown format %S" format)))))

(defun alref-build/disambiguate-slugs (sections)
  "Walk SECTIONS in order and ensure every (chapter, slug) pair is
unique. When two sections under the same chapter would emit the
same filename — the encoder didn't disambiguate them — append a
'-N' suffix to the second, third, … occurrences. Mutates the slug
slot in place so downstream INDEX / SYMBOLS / page writes see the
final filenames.

In a well-encoded spec this loop never fires; it's the safety net
that turns a future slug clash from a silently-overwritten page
into a deterministically-distinct one."
  (let ((seen (make-hash-table :test 'equal)))
    (dolist (section sections)
      (let* ((basename (alref-build/section-filename section))
             (count    (gethash basename seen 0)))
        (when (> count 0)
          (let ((suffixed (format "%s-%d"
                                  (alref-build/section-slug section)
                                  (1+ count))))
            (setf (alref-build/section-slug section) suffixed)))
        (puthash basename (1+ count) seen)))))

(defun alref-build/write-pages (sections output-dir format)
  "Write each SECTION to OUTPUT-DIR as <basename>.txt (:text) or
<basename>.org (:org). Skips the synthetic 'frontmatter' section
that holds the spec's #+TITLE etc. — those aren't part of any
chapter and have no useful page form."
  (let ((extension (cl-ecase format (:text "txt") (:org "org")))
        (count 0))
    (make-directory output-dir t)
    (dolist (section sections)
      (unless (string= (alref-build/section-slug section) "frontmatter")
        (let* ((basename (alref-build/section-filename section))
               (path (expand-file-name
                      (format "%s.%s" basename extension)
                      output-dir))
               (content (alref-build/section-page section format)))
          (with-temp-file path
            (insert content)
            (unless (eq ?\n (char-before (point-max)))
              (insert "\n")))
          (cl-incf count))))
    count))

(defun alref-build/write-index (sections output-dir)
  "Write OUTPUT-DIR/index.txt — one line per emitted page in
walking order, each as `BASENAME\tTITLE`. The Emacs and AutoLISP
sides build their lookup tables off this file at load time."
  (let ((path (expand-file-name "index.txt" output-dir)))
    (with-temp-file path
      (dolist (section sections)
        (unless (string= (alref-build/section-slug section) "frontmatter")
          (insert (alref-build/section-filename section))
          (insert "\t")
          (insert (alref-build/section-title section))
          (insert "\n"))))))

(defun alref-build/write-symbols (sections output-dir)
  "Write OUTPUT-DIR/symbols.txt — one line per entry-typed
subsection, as `SYMBOL\tKIND\tBASENAME`. Used by alref-lookup +
the AutoLISP alref-apropos-list to resolve a symbol name to its
documentation page in O(1) (after loading the file)."
  (let ((path (expand-file-name "symbols.txt" output-dir)))
    (with-temp-file path
      (dolist (section sections)
        (let ((entry (alref-build/section-entry section)))
          (when entry
            (insert (cdr entry))
            (insert "\t")
            (insert (car entry))
            (insert "\t")
            (insert (alref-build/section-filename section))
            (insert "\n")))))))

;;; --- main ----------------------------------------------------------

(let* ((argv (alref-build/argv))
       (input-file (or (nth 0 argv)
                       (error "missing INPUT.org argument")))
       (output-dir (or (nth 1 argv)
                       (error "missing OUTPUT-DIR argument")))
       (format-arg (or (nth 2 argv) "text"))
       (format (cond ((string= format-arg "text") :text)
                     ((string= format-arg "org")  :org)
                     (t (error "unknown FORMAT %S; expected text or org"
                               format-arg)))))
  (message "build-paged-spec: %s → %s (format %s)"
           input-file output-dir format-arg)
  (let ((sections (alref-build/parse-org-file input-file)))
    (alref-build/disambiguate-slugs sections)
    (let ((count (alref-build/write-pages sections output-dir format)))
      (alref-build/write-index sections output-dir)
      (alref-build/write-symbols sections output-dir)
      (message "build-paged-spec: emitted %d pages." count))))
