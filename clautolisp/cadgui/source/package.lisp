;;;; The cadgui host: the GRAPHICAL UI-tree host, the Qt6 peer of cadtui on the
;;;; cador core (cadgui-2-qt6-gui-host.issue). This package is the CL side of the
;;;; cadgui host -- the protocol the embedded-ECL Qt6 shell calls: the display
;;;; list to paint, the view extents, interactive input, and command evaluation.
;;;; The C++ shell owns the window + per-frame paint; CL owns the model, and the
;;;; boundary is crossed only on regen and on input (never per frame).

(defpackage #:clautolisp.cadgui
  (:use #:common-lisp)
  (:export
   ;; Session
   #:cadgui-session
   #:cadgui-session-host
   #:*cadgui-session*
   #:cadgui-start
   #:cadgui-session-or-start
   ;; Scene (slices B/C/F) -- what the shell pulls to paint
   #:cadgui-display-list
   #:cadgui-extents
   ;; Model builders (so a demo / the shell can populate the model via the real
   ;; cador engine; the full AutoLISP command eval is slice E)
   #:cadgui-add-line
   #:cadgui-add-circle
   #:cadgui-entity-count
   ;; Interactive input bridge (slice D) -- a GUI-backed cador prompt stream so
   ;; getpoint/entsel/ssget drive from the canvas. The shell sets the hook to its
   ;; nested-event-loop await; it returns the next input line (e.g. a point "x,y").
   #:cadgui-input-stream
   #:*cadgui-input-hook*
   #:*cadgui-pending-input*
   #:cadgui-point-line
   #:cadgui-install-input
   ;; Command evaluation (slice E)
   #:cadgui-eval-command))
