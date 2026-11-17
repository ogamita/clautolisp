;;; cadgui-dev -- a DEVELOPMENT-IMAGE system for fast Lisp-side iteration on
;;; the cadgui host (ecl skill EC7/EC10). It is a :program-system (so the ECL
;;; image links ASDF+UIOP and keeps the REPL) that depends on the whole cadgui
;;; engine. Building its image (build-dev-image.lisp) freezes clautolisp/cadgui
;;; and its closure into an executable that starts on the ECL REPL with
;;; everything already initialized; you then (load "edited-file.lisp") to
;;; reload just the file under work -- bytecodes, instant -- instead of
;;; recompiling the engine.
;;;
;;; This is a dev-only, build-only system; it is NOT part of the clautolisp
;;; umbrella and changes no production system.
(asdf:defsystem "cadgui-dev"
  :description "Development-image system freezing clautolisp/cadgui for ECL REPL iteration."
  :class :program-system                 ; EC7: links ASDF+UIOP, keeps (si:top-level t)
  :depends-on ("asdf"                    ; EC9: "asdf" first
               "clautolisp/cadgui")
  :build-pathname "cadgui-dev")          ; => cadgui-dev.image (image-op)
