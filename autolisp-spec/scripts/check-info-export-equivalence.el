;;; -*- lexical-binding: t -*-
;;; check-info-export-equivalence.el --- prove the fast node naming changes
;;; nothing but the clock.
;;;
;;;   emacs --batch --script check-info-export-equivalence.el SPEC.org [NLINES]
;;;
;;; spec-texinfo-fast-node.el overrides an INTERNAL ox-texinfo function. That
;;; buys the Info build a 50x speedup and takes on a real risk in exchange: a
;;; future org may change `org-texinfo--get-node', and a silently diverging
;;; override would give the manual different node names -- which surfaces,
;;; much later, as dead cross-references rather than as a build failure.
;;;
;;; So the claim is TESTED rather than asserted: a prefix of the real spec is
;;; exported twice, once with the override and once without, and the two .texi
;;; files must be byte-identical. A prefix, not the whole file, because the
;;; stock export of the whole file is the 51 minutes this exists to avoid --
;;; and node naming is a per-node property, so a few thousand nodes exercise
;;; it exactly as well as forty thousand.
;;;
;;; Exit status 0 when identical, 1 otherwise.

(require 'cl-lib)
(require 'org)
(require 'ox-texinfo)

(let* ((here (file-name-directory
              (or load-file-name buffer-file-name default-directory)))
       (argv command-line-args-left)
       (spec (or (nth 0 argv)
                 (error "check-info-export-equivalence: missing SPEC.org")))
       (nlines (string-to-number (or (nth 1 argv) "6000")))
       (tmpdir (file-name-as-directory
                (make-temp-file "info-equiv" t)))
       (source (expand-file-name "prefix.org" tmpdir)))
  (load (expand-file-name "spec-texinfo-fast-node.el" here) nil t)

  ;; Cut at a headline so the tree stays well-formed; a prefix ending
  ;; mid-entry would export differently for reasons unrelated to nodes.
  (with-temp-buffer
    (insert-file-contents spec)
    (goto-char (point-min))
    (forward-line nlines)
    (if (re-search-forward "^\\*+ " nil t)
        (beginning-of-line)
      (goto-char (point-max)))
    (let ((body (buffer-substring (point-min) (point))))
      (with-temp-file source
        (insert "#+TEXINFO_FILENAME: equiv.info\n")
        (insert "#+TEXINFO_HEADER: @syncodeindex pg cp\n")
        (insert "#+TEXINFO_DIR_CATEGORY: equivalence check\n")
        (insert "#+TEXINFO_DIR_TITLE: equiv: (equiv).\n")
        (insert "#+TEXINFO_DIR_DESC: equivalence check.\n")
        (insert body))))

  (setq org-texinfo-supports-math--cache t)

  (cl-flet ((export-once
              (label)
              (let ((buffer (find-file-noselect source))
                    (start (float-time))
                    (produced nil))
                (unwind-protect
                    (with-current-buffer buffer
                      (let ((org-export-with-toc nil)
                            (org-export-with-section-numbers t)
                            (org-export-headline-levels 2))
                        (setq produced (org-texinfo-export-to-texinfo))))
                  (kill-buffer buffer))
                (let ((kept (expand-file-name (format "%s.texi" label) tmpdir)))
                  ;; the exporter returns a name relative to the source
                  ;; buffer's directory, not the current one.
                  (copy-file (expand-file-name produced tmpdir) kept t)
                  (message "  %-6s %.2fs" label (- (float-time) start))
                  kept))))

    (message "check-info-export-equivalence: %d lines of %s"
             nlines (file-name-nondirectory spec))
    (alref-info/disable-fast-node)
    (let ((stock (export-once "stock")))
      (alref-info/enable-fast-node)
      (let ((fast (export-once "fast")))
        (let ((a (with-temp-buffer (insert-file-contents-literally stock)
                                   (buffer-string)))
              (b (with-temp-buffer (insert-file-contents-literally fast)
                                   (buffer-string))))
          (if (string= a b)
              (progn
                (message "ok  the fast node index produces byte-identical texi")
                (kill-emacs 0))
            ;; Say WHERE they diverge: "the files differ" would send the
            ;; reader back to a 3 MB diff.
            (let ((la (split-string a "\n"))
                  (lb (split-string b "\n")))
              (message "FAIL: stock and fast exports differ (%d vs %d lines)"
                       (length la) (length lb))
              (cl-loop for x in la
                       for y in lb
                       for i from 1
                       unless (string= x y)
                       do (message "      first difference at line %d:" i)
                          (message "        stock: %s" x)
                          (message "        fast : %s" y)
                          (cl-return))
              (message "      spec-texinfo-fast-node.el no longer matches this")
              (message "      org's org-texinfo--get-node. Re-derive the")
              (message "      override from the current ox-texinfo.el, or drop")
              (message "      it and take the 51 minutes back.")
              (kill-emacs 1))))))))
