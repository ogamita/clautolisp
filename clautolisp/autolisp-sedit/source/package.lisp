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
   #:adornment #:adornment-p #:make-adornment #:adornment-text #:node-text
   #:atom-node #:atom-node-p #:make-atom-node #:atom-node-value
   #:list-node #:list-node-p #:make-list-node #:list-node-children
   #:comment-node #:comment-node-p #:make-comment-node #:comment-node-text
   #:file-node #:file-node-p #:make-file-node
   #:file-node-name #:file-node-children #:file-node-modified
   #:dir-node #:dir-node-p #:make-dir-node #:dir-node-name #:dir-node-entries
   #:branch-node-p #:node-children #:node-with-children #:node-level-of-children
   #:sexp->tree #:tree->sexp
   ;; --- formatting: parser + pretty-printer + comments (§5.2–§5.3, §6.7) ---
   #:parse-source #:parse-form #:unparse
   #:comment-level #:comment-line-level #:comment-block-p #:merge-comments
   #:*comment-column* #:*text-editor* #:*print-width* #:*special-indent*
   ;; --- the zipper (§6.2) ---
   #:loc #:loc-p #:make-loc #:loc-focus #:loc-ctx #:node->loc
   #:loc-at-root-p #:loc-level #:loc-root #:loc-path #:loc-follow
   #:loc-down #:loc-up #:loc-left #:loc-right #:loc-first #:loc-last #:loc-skip
   ;; --- editing transitions (§6.3): pure Loc -> Loc algebra ---
   #:edit-insert #:edit-add #:edit-replace #:edit-delete
   #:edit-wrap #:edit-splice #:edit-slurp #:edit-barf #:edit-split #:edit-join
   ;; --- the editor machine state (§6.5) + undo (§6.4) ---
   #:sedit-state #:sedit-state-p #:make-sedit-state
   #:sedit-state-loc #:sedit-state-clip #:sedit-state-mode #:sedit-state-undo
   #:state-focus
   #:undo-record #:undo-record-p #:make-undo-record #:undo-record-op #:undo-record-loc
   #:undo-op-name #:sedit-can-undo-p #:sedit-undo-description #:sedit-undo
   ;; state-level commands: mutations record undo, motions / copy do not
   #:sedit-insert #:sedit-add #:sedit-replace #:sedit-delete
   #:sedit-wrap #:sedit-splice #:sedit-slurp #:sedit-barf #:sedit-split #:sedit-join
   #:sedit-copy #:sedit-cut #:sedit-paste
   #:sedit-down #:sedit-up #:sedit-left #:sedit-right
   #:sedit-first #:sedit-last #:sedit-skip
   ;; --- REPL source recording (§3) ---
   #:recording #:recording-p #:make-recording
   #:recording-definitions #:recording-log
   #:record-form #:recorded-definition #:definition-name
   #:recording-forms #:session-source
   #:*sedit-recording* #:sedit-recording #:record-source
   ;; --- storage: files, directories, save/load (§2.3–§2.4, §5.7–§5.9) ---
   #:sedit-load #:sedit-save #:read-directory
   #:sedit-fs-new-file #:sedit-fs-rename #:sedit-fs-delete
   #:*auto-saving* #:should-auto-save-p
   ;; --- the session and its §2 result ---
   #:sedit-session #:sedit-session-p
   #:sedit-session-state #:sedit-session-origin #:sedit-session-initial
   #:sedit-open #:session-result #:sedit-result-node
   #:*clal-sedit-initial-form* #:*clal-sedit-last-result*
   ;; --- modes, the transition machine, and the driver (§1, §5, §6.6) ---
   #:sedit-command #:sedit-run #:render-selection
   #:sedit-mode-prompt #:sedit-help-text
   ;; --- clipboard (§5.4 + clipboard-interface.org) ---
   #:clipboard-provider #:clipboard-provider-p #:make-clipboard-provider
   #:clipboard-provider-name #:clipboard-provider-available-p
   #:clipboard-provider-put-text #:clipboard-provider-get-text
   #:make-null-provider #:make-x11-provider #:make-wayland-provider
   #:make-macos-provider #:make-windows-provider #:make-osc52-provider
   #:default-clipboard-providers #:active-provider #:reset-clipboard-selection
   #:clipboard-put-text #:clipboard-get-text
   #:clipboard-copy-node #:clipboard-paste-node #:node->clip-object #:clip-object->node
   #:*clipboard* #:*clal-clipboard*
   #:*system-clipboard-enabled* #:*clipboard-provider* #:*clipboard-providers*
   #:*clipboard-x11-also-primary* #:*clipboard-osc52-enabled* #:*clipboard-demoted*))
