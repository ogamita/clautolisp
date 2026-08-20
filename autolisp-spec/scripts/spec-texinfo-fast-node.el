;;; spec-texinfo-fast-node.el --- O(1) node naming for the ox-texinfo export.
;;;
;;; WHY THIS EXISTS
;;;
;;; Exporting the whole spec to texi took 51 MINUTES (CI job 15981142889),
;;; and the growth was worse than quadratic: doubling the input roughly
;;; quadrupled the time.
;;;
;;; Measured rather than guessed. Emacs' sampling profiler collects nothing
;;; under --batch (the signal-based sampler never fires), so each suspect
;;; function was advised to count its calls and its own elapsed time, at TWO
;;; input sizes -- one size cannot tell a big constant from a bad exponent.
;;; The function whose share grows is the culprit:
;;;
;;;   headlines   total     org-texinfo--get-node
;;;       2 190    4.13 s   2.20 s  (53%)
;;;       4 931   29.34 s  24.07 s  (82%)
;;;
;;; The cause is plain in ox-texinfo.el. `org-texinfo--get-node' keeps every
;;; (datum . node-name) pair in one ALIST and, for each new node, walks it
;;; twice:
;;;
;;;   (cdr (assq datum cache))               ; linear lookup
;;;   (while (or ... (rassoc name cache))    ; linear uniqueness scan
;;;
;;; Both are O(N) per node, so the export is O(N^2) in nodes -- and worse
;;; when names collide, since each salt attempt rescans. An ordinary org
;;; file never notices; a specification with tens of thousands of nodes
;;; notices for 51 minutes.
;;;
;;; WHAT THIS CHANGES, AND WHAT IT DELIBERATELY DOES NOT
;;;
;;; The replacement keeps the algorithm and -- this is the part that
;;; matters -- the SALTING ORDER identical. It swaps only the two linear
;;; scans for hash lookups, and still maintains the stock alist, so
;;; anything else consulting :texinfo-node-cache sees what it expects.
;;;
;;; Full spec, and MEASURED ON THE SAME MACHINE EACH TIME, because the
;;; two obvious numbers come from different boxes and comparing them
;;; would flatter the result:
;;;
;;;   CI runner:        51 min 19 s  ->  3 min 38   (job 16016817963)
;;;   development box:  65 min 59 s  ->  59.75 s    (both measured)
;;;
;;; On the development box the two full-file exports were compared byte
;;; for byte -- same md5, same 3 639 665 bytes -- which is why the stock
;;; run was sat through rather than extrapolated from a prefix.
;;;
;;; The CI figure is the one that matters for the pipeline, and it is the
;;; smaller win of the two -- 14x rather than 50x -- because that runner
;;; is slower and its org is older. Output byte-identical on both, and
;;; `makeinfo' accepts it under the strict build (no --force, no
;;; --no-validate).
;;;
;;; THE RISK, NAMED
;;;
;;; This overrides another package's internal function, so it is pinned to
;;; a shape of `org-texinfo--get-node' that a future org release may
;;; change. That is exactly what `make check-info-export-equivalence'
;;; guards: it exports a prefix of the REAL spec both ways and fails unless
;;; the two .texi files are byte-identical. If org changes the function,
;;; the check goes red and says so -- rather than the manual quietly
;;; acquiring different node names, which is the kind of drift nobody
;;; notices until a cross-reference is dead.
;;;
;;; That guard is not hypothetical: its FIRST CI run caught this override
;;; failing on the older org in the build image -- org 9.5 wants
;;; `org-element-lineage' to be given a LIST of types and answers
;;; (wrong-type-argument listp headline) for a bare symbol. The two
;;; versions also differ on the reserved-name test. Both are handled
;;; below, and both were found by the check rather than by a user.
;;;
;;; Upstream is the right home for the fix; the build cannot wait for a
;;; released one.

(require 'cl-lib)
(require 'org)
(require 'ox-texinfo)

(defun alref-info/node-index (info)
  "Return (DATUM->NAME . NAME->T) for this export, creating it once."
  (or (plist-get info :alref-node-index)
      (let ((tables (cons (make-hash-table :test 'eq)
                          (make-hash-table :test 'equal))))
        (plist-put info :alref-node-index tables)
        tables)))

(defun alref-info/get-node (datum info)
  "Drop-in replacement for `org-texinfo--get-node' with O(1) uniqueness.
Same names, same salting order, same alist side effect."
  (let* ((index (alref-info/node-index info))
         (by-datum (car index))
         (by-name (cdr index)))
    (or (gethash datum by-datum)
        (let* ((salt 0)
               (basename
                (org-texinfo--sanitize-node
                 (pcase (org-element-type datum)
                   (`headline
                    (org-texinfo--sanitize-title
                     (org-export-get-alt-title datum info) info))
                   (`radio-target
                    (org-export-data (org-element-contents datum) info))
                   (`target
                    (org-element-property :value datum))
                   (_
                    (or (org-element-property :name datum)
                        (org-export-get-reference datum info))))))
               (name basename))
          ;; Org exports deeper elements before their parents, so a parent
          ;; must be given its node first or the child would take the
          ;; shorter name. This recursion must stay BEFORE the uniqueness
          ;; loop: moving it would change which name gets salted.
          ;; `'(headline)' and not `'headline': org 9.7 accepts either,
          ;; org 9.5 -- what the CI image ships -- accepts only the list
          ;; and answers (wrong-type-argument listp headline) otherwise.
          ;; The list form is right on both.
          (let ((parent (org-element-lineage datum '(headline))))
            (when (and parent (not (gethash parent by-datum)))
              (org-texinfo--get-node parent info)))
          ;; The reserved-name test is the CAPITALISED comparison, which
          ;; is what newer org does; older org compared the name
          ;; literally. The capitalised test is the stricter of the two,
          ;; so on older org this can only reserve MORE names -- and only
          ;; a single-word "top"/"TOP" node, since capitalize works
          ;; word by word. Whether that costs anything on the actual
          ;; document is not argued here: check-info-export-equivalence
          ;; compares the two exports IN THE ENVIRONMENT THAT RUNS, so
          ;; the answer is measured per Emacs rather than assumed from a
          ;; version number.
          (while (or (string-equal "Top" (capitalize name))
                     (gethash name by-name))
            (setq name (concat basename (format " (%d)" (cl-incf salt)))))
          (puthash datum name by-datum)
          (puthash name t by-name)
          (plist-put info :texinfo-node-cache
                     (cons (cons datum name)
                           (plist-get info :texinfo-node-cache)))
          name))))

(defun alref-info/enable-fast-node ()
  "Install the fast node naming, once."
  (unless (get 'org-texinfo--get-node 'alref-fast-node)
    (advice-add 'org-texinfo--get-node :override #'alref-info/get-node)
    (put 'org-texinfo--get-node 'alref-fast-node t)))

(defun alref-info/disable-fast-node ()
  "Restore the stock node naming -- used by the equivalence check."
  (when (get 'org-texinfo--get-node 'alref-fast-node)
    (advice-remove 'org-texinfo--get-node #'alref-info/get-node)
    (put 'org-texinfo--get-node 'alref-fast-node nil)))

(provide 'spec-texinfo-fast-node)
