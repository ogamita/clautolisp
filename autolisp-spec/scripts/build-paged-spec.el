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
'Special Form Entry: NAME', 'Special Operator Entry: NAME',
'Variable Entry: NAME', 'Macro Entry: NAME', 'Type Entry: NAME'),
return (KIND . NAME) — both strings, NAME uppercased. Returns nil
otherwise.

'Special Form' and 'Special Operator' are both surfaced as the
'Special Form' KIND in symbols.txt — the spec uses the two terms
interchangeably (Autodesk says 'Special Function', the AutoLISP
draft says 'Special Form'). The runtime alref library treats a
'Special Form' KIND or a hardcoded special-operator name as the
'Operator' apropos kind."
  (when (string-match
         "^\\(Function\\|Reader Syntax\\|Special Form\\|Special Operator\\|Variable\\|Macro\\|Type\\)\\s-+Entry:\\s-+\\(.+\\)$"
         subsection-title)
    (cons (match-string 1 subsection-title)
          (upcase (string-trim (match-string 2 subsection-title))))))

;;; --- section accumulator ------------------------------------------

(cl-defstruct alref-build/section
  "One emitted page: chapter number, level (1 or 2), original
title, slugified title, body lines (a list of strings in reverse
order — `push`-ed onto, reversed on emit), optional entry
metadata (KIND . NAME) for symbol-index entries, plus the
adjacent basenames the navigation header links to (prev / next /
up — strings, nil at the ends of the document or the chapter
roots).

FLAGS holds the spec-coverage letter set (a subset of \"AB\")
derived from the entry's *** Availability section; computed
once during the dedicated COMPUTE-AVAILABILITY pass before
the body is destructively finalised by write-pages.

OP-FLAGS is the tri-state availability letter set (a subset of
\"ABC\", adding C for clautolisp) emitted into availability.txt
and consumed by the runtime's out-of-dialect operator warnings
(deferred-clautolisp-out-of-dialect-warnings.issue). It is kept
separate from FLAGS so symbols.txt's column 4 stays the A/B set
the alref library already expects."
  chapter level title slug body entry flags op-flags
  prev next up)

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
         (princ "#+OPTIONS: toc:nil num:nil html-postamble:nil\n")
         (when chapter
           (princ (format "#+PROPERTY: ALREF-CHAPTER %s\n" chapter)))
         (princ (format "#+PROPERTY: ALREF-LEVEL %d\n" level))
         (when entry
           (princ (format "#+PROPERTY: ALREF-ENTRY-KIND %s\n" (car entry)))
           (princ (format "#+PROPERTY: ALREF-ENTRY-NAME %s\n" (cdr entry))))
         (terpri)
         ;; Top-of-page navigation strip. The links are
         ;; org-mode file: links so org-html renders them as
         ;; href="basename.html". Pages with no prev / next /
         ;; up get a bracketed placeholder so the layout doesn't
         ;; jump as the user walks the chain.
         (let ((prev (alref-build/section-prev section))
               (next (alref-build/section-next section))
               (up   (alref-build/section-up   section)))
           (princ "<<navigation>>\n")
           (princ (if prev
                      (format "[[file:%s.html][← Prev]]" prev)
                      "[← Prev]"))
           (princ " | ")
           (princ (if up
                      (format "[[file:%s.html][↑ Chapter]]" up)
                      "[↑ Chapter]"))
           (princ " | ")
           (princ (if next
                      (format "[[file:%s.html][Next →]]" next)
                      "[Next →]"))
           (princ " | [[file:index.html][Index]]")
           (princ " | [[file:symbols.html][Symbols]]\n\n"))
         (princ (format "%s %s\n" (make-string level ?\*) title))
         (princ body)))
      (t
       (error "build-paged-spec.el: unknown format %S" format)))))

(defun alref-build/attach-chapter-tocs (sections)
  "Walk SECTIONS and, for every level-1 chapter page, append a
\"Contents\" subsection listing the chapter's level-2 children
as org-mode file: links. The chapter pages otherwise hold only
the introductory prose — without this pass they'd land as
near-empty stubs in the HTML build.

Called after COMPUTE-ADJACENCY so the recorded basenames are the
final on-disk filenames. Mutates the body slot in place."
  (let* ((real-sections (cl-remove-if
                         (lambda (s) (string= (alref-build/section-slug s)
                                              "frontmatter"))
                         sections))
         (chapter-children (make-hash-table :test 'equal)))
    ;; First pass: bucket subsections under their chapter.
    (dolist (section real-sections)
      (when (= (alref-build/section-level section) 2)
        (let ((up (alref-build/section-up section)))
          (when up
            (push section (gethash up chapter-children))))))
    ;; Second pass: append TOC to each chapter's body.
    (dolist (section real-sections)
      (when (= (alref-build/section-level section) 1)
        (let* ((basename (alref-build/section-filename section))
               (children (nreverse (gethash basename chapter-children))))
          (when children
            ;; Push the TOC lines onto the (still-reverse-order)
            ;; body. The block leads with a blank line so the
            ;; ** Contents heading parses cleanly under the
            ;; chapter's own * <Title> heading that
            ;; SECTION-PAGE will emit.
            (push "" (alref-build/section-body section))
            (push "** Contents" (alref-build/section-body section))
            (push "" (alref-build/section-body section))
            (dolist (child children)
              (let ((child-name (alref-build/section-filename child))
                    (child-title (alref-build/section-title child)))
                (push (format "- [[file:%s.html][%s]]"
                              child-name child-title)
                      (alref-build/section-body section))))))))))

(defun alref-build/compute-adjacency (sections)
  "Fill in the PREV / NEXT / UP slots on every SECTION. PREV and
NEXT walk the linear page sequence (skipping the synthetic
'frontmatter'); UP for a level-2 subsection points at the
chapter page it sits under, or nil for chapter-level pages.
Called after DISAMBIGUATE-SLUGS so the recorded basenames are
the final, on-disk filenames."
  (let* ((real-sections (cl-remove-if
                         (lambda (s) (string= (alref-build/section-slug s)
                                              "frontmatter"))
                         sections))
         (current-chapter-page nil))
    (dotimes (i (length real-sections))
      (let* ((section (nth i real-sections))
             (level (alref-build/section-level section))
             (prev (and (> i 0)
                        (alref-build/section-filename
                         (nth (1- i) real-sections))))
             (next (and (< (1+ i) (length real-sections))
                        (alref-build/section-filename
                         (nth (1+ i) real-sections)))))
        (setf (alref-build/section-prev section) prev)
        (setf (alref-build/section-next section) next)
        (cond
          ((= level 1)
           (setq current-chapter-page (alref-build/section-filename section))
           (setf (alref-build/section-up section) nil))
          (t
           (setf (alref-build/section-up section) current-chapter-page)))))))

(defun alref-build/availability-flags-from-lines (lines)
  "Walk LINES (a list of strings, in forward order) looking for
the '*** Availability' section and return a string of letters
denoting per-vendor spec coverage: 'A' for AutoCAD, 'B' for
BricsCAD, both as 'AB', empty string when the section is missing
or marks both vendors as 'not documented'. The runtime alref
library augments this with a per-image 'C' flag computed live
from `atoms-family'.

The Availability section is a literal org sublist of the form

    *** Availability
    - AutoCAD 2026: documented.
    - BricsCAD V26: presumed compatible.
    - Status: ...

Any value other than the explicit 'not documented' counts as
specified, so 'documented', 'presumed compatible', 'parallel
to ...', 'returns T on success', vendor-specific wording etc.
all flip the corresponding flag on."
  (let ((tail lines)
        (in-availability nil)
        (flags ""))
    (while tail
      (let ((line (car tail)))
        (cond
          ((string-match-p "^\\*\\*\\* Availability\\b" line)
           (setq in-availability t))
          ((and in-availability (string-match-p "^\\*\\*\\*" line))
           (setq in-availability nil))
          (in-availability
           (when (string-match
                  "^-\\s-+AutoCAD\\b[^:]*:\\s-*\\(.*\\)$" line)
             (let ((rest (string-trim (match-string 1 line))))
               (unless (string-match-p "^not\\b" rest)
                 (unless (cl-search "A" flags)
                   (setq flags (concat flags "A"))))))
           (when (string-match
                  "^-\\s-+BricsCAD\\b[^:]*:\\s-*\\(.*\\)$" line)
             (let ((rest (string-trim (match-string 1 line))))
               (unless (string-match-p "^not\\b" rest)
                 (unless (cl-search "B" flags)
                   (setq flags (concat flags "B"))))))))
        (setq tail (cdr tail))))
    flags))

(defun alref-build/operator-availability-flags-from-lines (lines)
  "Like `alref-build/availability-flags-from-lines', but tri-state: also
recognises a `- clautolisp...: VALUE' line and adds 'C' to the returned
flag string (unless the value starts with 'not'). The result is a subset
of \"ABC\" — A=AutoCAD, B=BricsCAD, C=clautolisp — consumed by the
runtime's out-of-dialect operator warnings via availability.txt.

Kept distinct from the A/B `flags' that feed symbols.txt so the alref
library's column-4 expectations are untouched."
  (let ((tail lines)
        (in-availability nil)
        (flags ""))
    (while tail
      (let ((line (car tail)))
        (cond
          ((string-match-p "^\\*\\*\\* Availability\\b" line)
           (setq in-availability t))
          ((and in-availability (string-match-p "^\\*\\*\\*" line))
           (setq in-availability nil))
          (in-availability
           (when (string-match
                  "^-\\s-+AutoCAD\\b[^:]*:\\s-*\\(.*\\)$" line)
             (let ((rest (string-trim (match-string 1 line))))
               (unless (string-match-p "^not\\b" rest)
                 (unless (cl-search "A" flags)
                   (setq flags (concat flags "A"))))))
           (when (string-match
                  "^-\\s-+BricsCAD\\b[^:]*:\\s-*\\(.*\\)$" line)
             (let ((rest (string-trim (match-string 1 line))))
               (unless (string-match-p "^not\\b" rest)
                 (unless (cl-search "B" flags)
                   (setq flags (concat flags "B"))))))
           (when (string-match
                  "^-\\s-+clautolisp\\b[^:]*:\\s-*\\(.*\\)$" line)
             (let ((rest (string-trim (match-string 1 line))))
               (unless (string-match-p "^not\\b" rest)
                 (unless (cl-search "C" flags)
                   (setq flags (concat flags "C"))))))))
        (setq tail (cdr tail))))
    flags))

(defun alref-build/compute-availability (sections)
  "Populate the FLAGS (A/B, for symbols.txt) and OP-FLAGS (A/B/C, for
availability.txt) slots of every entry-bearing SECTION before write-pages
destructively reverses the body. Reads the body slot non-destructively
(the slot still holds a reverse-order list at this point — we walk it in
forward order via `reverse')."
  (dolist (section sections)
    (when (alref-build/section-entry section)
      (let* ((rev-body (alref-build/section-body section))
             (lines (reverse rev-body)))
        (setf (alref-build/section-flags section)
              (alref-build/availability-flags-from-lines lines))
        (setf (alref-build/section-op-flags section)
              (alref-build/operator-availability-flags-from-lines lines))))))

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
subsection, as `SYMBOL\tKIND\tBASENAME\tFLAGS`. FLAGS is a
possibly-empty subset of the letters \"AB\" denoting per-vendor
spec coverage extracted from the entry's `*** Availability'
section; the runtime alref library augments it with a per-image
'C' flag from `atoms-family'.

The 4th column is a backward-compatible extension: legacy
3-column readers see the basename in the third field unchanged
and ignore the trailing tab + flags."
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
            (insert "\t")
            (insert (or (alref-build/section-flags section) ""))
            (insert "\n")))))))

(defconst alref-build/operator-kinds
  '("Function" "Special Form" "Macro")
  "Entry KINDs that name a callable operator, and so get a line in
availability.txt. Variables, types and reader syntax are excluded — the
out-of-dialect warning only fires on operator application.")

(defun alref-build/write-availability (sections output-dir)
  "Write OUTPUT-DIR/availability.txt — one `SYMBOL\tFLAGS` line per
documented operator (entry KIND in `alref-build/operator-kinds'). FLAGS is
the tri-state OP-FLAGS letter set (subset of \"ABC\": A=AutoCAD,
B=BricsCAD, C=clautolisp) from the entry's *** Availability section.

This is the data file the clautolisp runtime consumes for its
out-of-dialect operator warnings (deferred-clautolisp-out-of-dialect-
warnings.issue): an operator whose flags lie outside the active dialect's
documented surface gets a single advisory diagnostic on first use."
  (let ((path (expand-file-name "availability.txt" output-dir)))
    (with-temp-file path
      (insert "# SYMBOL<TAB>FLAGS  (A=AutoCAD B=BricsCAD C=clautolisp)\n")
      (insert "# Generated by build-paged-spec.el from the *** Availability\n")
      (insert "# sections of the AutoLISP/Visual-LISP specification draft.\n")
      (dolist (section sections)
        (let ((entry (alref-build/section-entry section)))
          (when (and entry
                     (member (car entry) alref-build/operator-kinds))
            (insert (cdr entry))
            (insert "\t")
            (insert (or (alref-build/section-op-flags section) ""))
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
    (alref-build/compute-adjacency sections)
    (alref-build/compute-availability sections)
    (alref-build/attach-chapter-tocs sections)
    (let ((count (alref-build/write-pages sections output-dir format)))
      (alref-build/write-index sections output-dir)
      (alref-build/write-symbols sections output-dir)
      (alref-build/write-availability sections output-dir)
      (message "build-paged-spec: emitted %d pages." count))))
