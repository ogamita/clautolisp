;;;; probes/sources/probe-vlax-for-scope.lsp
;;;;
;;;; Ground-truth for what VLAX-FOR does to its loop variable.
;;;;
;;;; THE QUESTION is FOREACH's (probe-foreach-scope.lsp), asked of the
;;;; other loop: does `(vlax-for x collection ...)' BIND x for the duration
;;;; of the loop -- whatever x held before comes back afterwards -- or does
;;;; it ASSIGN to an existing binding and leave the last member behind?
;;;;
;;;; clautolisp answers BIND, since 2.0.26, BY ANALOGY: AutoCAD answered
;;;; BIND for FOREACH (2.0.22), and VLAX-FOR had carried the same
;;;; assign-if-bound code until then. The specification does not say --
;;;; its VLAX-FOR entry has no `bind' and no `rebinding' in it -- so the
;;;; analogy is all there is (issues/open/vlax-for-binding-rule-unprobed).
;;;; These probes are the measurement.
;;;;
;;;; THE COLLECTION is the active document's Layers: every drawing has at
;;;; least layer "0", so the loop always runs. Each case returns
;;;;
;;;;     (<the loop variable afterwards> <iterations run>)
;;;;
;;;; so that BEFORE cannot be mistaken for "the loop never ran". A layer
;;;; left in the variable is shown by its name ("layer:0"), which is the
;;;; assignment answer. A host without an ActiveX object model records
;;;; `error' for each case -- that is an answer about the host, not about
;;;; the rule. (Headless clautolisp HAS one: its drawing model answers
;;;; with layer "0", so its baseline column reads (BEFORE 1), (BEFORE 1),
;;;; (OUTER 1), (nil 1) -- BIND, as 2.0.26 made it.)

(defun cad-probe--vlax-for (case expression thunk)
  (cad-probe-capture "vlax-for-scope" case thunk))

