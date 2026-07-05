;;;; clautolisp/autolisp-sedit/source/package.lisp

(defpackage #:clautolisp.sedit
  (:use #:cl)
  (:documentation
   "sedit — the S-expression structural editor (clautolisp-sedit-spec.org). This
package is Phase 1: the pure core — the adorned-tree domain (§6.1), the Huet
zipper Loc = (t, C) with its O(1) structure-sharing motions (§6.2), and the
editing transitions (§6.3). It has no clautolisp dependencies, so it is reusable
outside the debugger (the aldo form navigator and clal-sedit build on it in later
phases). Formatting/adornment (§5, Phase 3), undo (§6.4, Phase 2), files/dirs and
clal-sedit (Phases 4–5), and the clipboard providers (Phase 6) come later.")
  (:export
   ;; --- adorned-tree domain (§6.1) ---
   #:node #:node-p #:node-adornment
   #:atom-node #:atom-node-p #:make-atom-node #:atom-node-value
   #:list-node #:list-node-p #:make-list-node #:list-node-children
   #:comment-node #:comment-node-p #:make-comment-node #:comment-node-text
   #:file-node #:file-node-p #:make-file-node
   #:file-node-name #:file-node-children #:file-node-modified
   #:dir-node #:dir-node-p #:make-dir-node #:dir-node-name #:dir-node-entries
   #:branch-node-p #:node-children #:node-with-children #:node-level-of-children
   #:sexp->tree #:tree->sexp
   ;; --- the zipper (§6.2) ---
   #:loc #:loc-p #:make-loc #:loc-focus #:loc-ctx #:node->loc
   #:loc-at-root-p #:loc-level #:loc-root #:loc-path #:loc-follow
   #:loc-down #:loc-up #:loc-left #:loc-right #:loc-first #:loc-last #:loc-skip
   ;; --- editing transitions (§6.3) ---
   #:edit-insert #:edit-add #:edit-replace #:edit-delete
   #:edit-wrap #:edit-splice #:edit-slurp #:edit-barf #:edit-split #:edit-join
   ;; --- the editor state + clipboard (§6.3/§6.5) ---
   #:sedit-state #:sedit-state-p #:make-sedit-state
   #:sedit-state-loc #:sedit-state-clip #:sedit-state-mode #:state-focus
   #:sedit-copy #:sedit-cut #:sedit-paste))
