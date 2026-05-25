;;; build-paged-info.el --- Render the spec as a GNU Info manual.
;;;
;;; Uses Org's stock texinfo exporter (ox-texinfo) to produce
;;; <build>/info/autolisp-spec.info from
;;; documentation/autolisp-visual-lisp-specification-draft.org —
;;; a single Info manual with chapter / section / subsection nodes
;;; the user navigates via M-x info or 'info autolisp-spec' at a
;;; shell.
;;;
;;; The matching directory entry is appended to <build>/info/dir so
;;; the install target picks it up for the system-wide info index.
;;;
;;; Invoke via:
;;;
;;;   emacs --batch --script build-paged-info.el SPEC.org BUILD-DIR
;;;
;;; Requires the `makeinfo` binary on $PATH (part of GNU texinfo).
;;; Without it ox-texinfo's :info backend errors out; the
;;; intermediate .texi file is still emitted for diagnostics.

(require 'cl-lib)
(require 'org)
(require 'ox-texinfo)
(require 'subr-x)

(defun alref-info/argv ()
  (or command-line-args-left
      (error "build-paged-info.el: missing SPEC.org BUILD-DIR arguments")))

(defun alref-info/inject-texinfo-directives (org-file dest)
  "Copy ORG-FILE to DEST, prepending the texinfo metadata
ox-texinfo needs to produce a real Info manual:

  #+TEXINFO_FILENAME: autolisp-spec.info
  #+TEXINFO_HEADER: @syncodeindex pg cp
  #+TEXINFO_DIR_CATEGORY: AutoLISP specification
  #+TEXINFO_DIR_TITLE: autolisp-spec: (autolisp-spec).
  #+TEXINFO_DIR_DESC: AutoLISP / Visual LISP language specification.

The original org source isn't modified — the spec stays a pure
HyperSpec-style reference and we layer the info metadata on the
fly. Returns DEST."
  (with-temp-file dest
    (insert "#+TEXINFO_FILENAME: autolisp-spec.info\n")
    (insert "#+TEXINFO_HEADER: @syncodeindex pg cp\n")
    (insert "#+TEXINFO_DIR_CATEGORY: AutoLISP specification\n")
    (insert "#+TEXINFO_DIR_TITLE: autolisp-spec: (autolisp-spec).\n")
    (insert "#+TEXINFO_DIR_DESC: AutoLISP / Visual LISP language specification.\n")
    (insert-file-contents org-file))
  dest)

(defun alref-info/write-dir-entry (info-dir)
  "Append a directory entry for the manual to INFO-DIR/dir.
The line follows GNU Info's documented '* ALIAS: (FILENAME).
DESCRIPTION.' shape so install-info can splice it into the
system-wide dir on the install step."
  (let ((dir-path (expand-file-name "dir" info-dir)))
    (with-temp-file dir-path
      (insert "This is the file .../info/dir, which contains the\n")
      (insert "topmost node of the Info hierarchy, called (dir)Top.\n")
      (insert "The first time you invoke Info you start off looking at this node.\n\n")
      (insert "File: dir,\tNode: Top,\tThis is the top of the INFO tree\n\n")
      (insert "  This (the Directory node) gives a menu of major topics.\n\n")
      (insert "* Menu:\n\n")
      (insert "AutoLISP specification\n")
      (insert "* autolisp-spec: (autolisp-spec).      AutoLISP / Visual LISP language specification.\n"))
    dir-path))

;;; --- main ----------------------------------------------------------

(let* ((argv (alref-info/argv))
       (spec-org (or (nth 0 argv)
                     (error "build-paged-info.el: missing SPEC.org")))
       (build-dir (or (nth 1 argv)
                      (error "build-paged-info.el: missing BUILD-DIR")))
       (info-dir (expand-file-name "info" build-dir))
       (work-org (expand-file-name "autolisp-spec.org" info-dir)))
  (make-directory info-dir t)
  (alref-info/inject-texinfo-directives spec-org work-org)
  (message "build-paged-info: exporting %s -> .texi" work-org)
  ;; Emacs only produces the .texi here. The Makefile runs
  ;; `makeinfo` separately because under `make`, the inherited
  ;; PATH may not include /opt/local/bin etc., and
  ;; org-texinfo-export-to-info's silent failure on a missing
  ;; makeinfo is hard to diagnose. Splitting the two steps gives
  ;; us an explicit failure point + lets the user override the
  ;; binary via $MAKEINFO without touching this script.
  ;; Pre-seed org-texinfo-supports-math--cache so ox-texinfo skips
  ;; its one-time probe. The probe creates a temp file as
  ;; `testXXXXXX.info' (note the `.info' extension instead of
  ;; `.texi') and invokes makeinfo on it, which prints a noisy
  ;; warning to stderr:
  ;;   makeinfo: warning: input file ...info; did you mean
  ;;   ...texi?
  ;; The probe result is irrelevant under batch mode: any
  ;; current GNU texinfo (>=5.0, 2013) supports @math, and if a
  ;; very old one doesn't, the real export downstream would fail
  ;; loudly with a clear error rather than this silent fallback.
  ;; Pre-seeding to t is therefore safe and removes the warning.
  (setq org-texinfo-supports-math--cache t)
  ;; Cap exported headline depth at 2 so Function Entries (level 2,
  ;; e.g. "Function Entry: LOAD_DIALOG") render as a single
  ;; self-contained Info node. Level-3 sub-parts (Name, Class,
  ;; Syntax, Arguments and Values, Description, Return Values, Side
  ;; Effects, Availability, Source Notes, Examples, Notes,
  ;; Compatibility, …) then export as @item entries with
  ;; @anchor{NAME} inside the parent section — no @node line, no
  ;; @menu entry, no fragmentation into one-line navigable stubs.
  ;; Cross-references via [[*NAME]] still resolve through the
  ;; @anchor. PDF output is unaffected: this only changes the
  ;; one-off ox-texinfo export run inside this script.
  (let ((buffer (find-file-noselect work-org)))
    (unwind-protect
        (with-current-buffer buffer
          (let ((org-export-with-toc nil)
                (org-export-with-section-numbers t)
                (org-export-headline-levels 2))
            (org-texinfo-export-to-texinfo)))
      (kill-buffer buffer)))
  (alref-info/write-dir-entry info-dir)
  (message "build-paged-info: wrote %s + dir entry. Run makeinfo to produce the .info file."
           (expand-file-name "autolisp-spec.texi" info-dir)))
