(in-package #:clautolisp.cadtui)

;;;; Visual screen rendering of the tree (Phase 8, optional backend seam).
;;;;
;;;; The spec's Phase 8 is an OPTIONAL backend that renders the tree VISUALLY
;;;; while "reusing EXACTLY the §5 interpreter" (roadmap 8). The load-bearing
;;;; requirement is that requirement: a visual backend must not fork the
;;;; interaction language. So this file lands the seam that guarantees it — a
;;;; renderer indirection (*SCREEN-RENDERER*) and a headless, deterministic TEXT
;;;; screen renderer over the CLOS tree — plus UI-STEP, which drives one input
;;;; line through the unchanged INTERPRET-LINE and then re-renders. A concrete
;;;; curses widget layer (over tui-core, gated out of the default image exactly
;;;; like the debugger's ncurses UI) is a thin drop-in for *SCREEN-RENDERER*: it
;;;; renders the same tree and drives input through the same UI-STEP, adding no
;;;; grammar of its own.
;;;;
;;;; A screen render is a LAID-OUT view (sections, the active drawing expanded),
;;;; distinct from DUMP-NODE's structural indented dump — it is what a user would
;;;; see, not an address-oriented listing.

(defun %active-drawing (root)
  "ROOT's active drawing (the first :drawing child), or NIL."
  (find :drawing (ui-children root) :key #'ui-role))

(defun %children-of-role (node role)
  (remove role (ui-children node) :key #'ui-role :test-not #'eq))

(defun %labels-line (nodes)
  "The labels (or keys) of NODES joined for a one-line summary."
  (format nil "~{~A~^  ~}"
          (mapcar (lambda (n) (or (ui-label n) (ui-key n))) nodes)))

(defun %render-cad-view (view stream)
  (let* ((drawing (ui-cad-view-drawing view))
         (count (cond (drawing (drawing-entity-count drawing))
                      (t (length (%children-of-role view :entity)))))
         (bounds (viewport-bounds (ui-viewport view))))
    (format stream "  cad-view: ~D entit~:@P~@[  viewport ~A~]~%" count bounds)))

(defun %render-drawing-detail (drawing stream)
  "Render the active DRAWING's expanded detail: its bands, cad-view and console."
  (let ((bands (%children-of-role drawing :band))
        (view  (find :cad-view (ui-children drawing) :key #'ui-role))
        (console (find :console (ui-children drawing) :key #'ui-role)))
    (format stream "--- ~A (active) ---~%" (or (ui-label drawing) (ui-key drawing)))
    (when bands
      (format stream "  bands: ~A~%" (%labels-line bands)))
    (when view (%render-cad-view view stream))
    (when console (format stream "  console>~%"))))

(defun text-screen-renderer (root &key (stream *standard-output*))
  "Render ROOT as a laid-out full-screen TEXT view: a header, the menu bar as a
single line, the drawings list (the active one marked *), the active drawing's
expanded detail, and — when no drawing is active — the application console.
Deterministic and headless (the default *SCREEN-RENDERER*)."
  (format stream "== ~A ==~%" (or (ui-label root) (ui-key root)))
  (let ((menu-bar (find :menu-bar (ui-children root) :key #'ui-role))
        (drawings (%children-of-role root :drawing))
        (active (%active-drawing root)))
    (when menu-bar
      (format stream "menu: ~A~%"
              (%labels-line (%children-of-role menu-bar :menu))))
    (if drawings
        (progn
          (format stream "drawings: ~{~A~^  ~}~%"
                  (mapcar (lambda (d)
                            (format nil "~A~:[~;*~]"
                                    (or (ui-label d) (ui-key d)) (eq d active)))
                          drawings))
          (when active (%render-drawing-detail active stream)))
        ;; no drawing: the application console is what is active (spec §Consoles).
        (let ((console (find :console (ui-children root) :key #'ui-role)))
          (format stream "no drawing~%")
          (when console (format stream "application console>~%")))))
  (values))

(defvar *screen-renderer* #'text-screen-renderer
  "The active screen backend: a function of (ROOT &key STREAM) rendering the
whole tree. The default is the headless TEXT-SCREEN-RENDERER; a curses backend
installs its own here without touching INTERPRET-LINE or the tree.")

(defun render-screen (root &key (stream *standard-output*))
  "Render ROOT's whole tree through the active *SCREEN-RENDERER*."
  (funcall *screen-renderer* root :stream stream))

(defun render-screen-to-string (root)
  "RENDER-SCREEN into a string (for tests and for a backend that paints a buffer)."
  (with-output-to-string (s) (render-screen root :stream s)))

(defun ui-step (line root)
  "Drive one input LINE through the UNCHANGED INTERPRET-LINE, then re-render the
screen. Returns (values command-result screen-string). This is the whole of a
visual backend's event loop body — proof that Phase 8 reuses the §5 interpreter
verbatim rather than forking a grammar."
  (let ((result (interpret-line line root)))
    (values result (render-screen-to-string root))))
