;;;; The cadgui session: the live cador document the Qt6 shell renders.
;;;; cadgui-2-qt6-gui-host.issue slice A (CL side).

(in-package #:clautolisp.cadgui)

(defstruct cadgui-session
  "A live cadgui session: the cador document host it renders. One per shell
process for now; multi-document (cador's cooperative scheduler) is a later
increment."
  host)

(defvar *cadgui-session* nil
  "The active cadgui session, or NIL before the shell starts one.")

(defun cadgui-start ()
  "Create a fresh cadgui session on a new, empty cador document and make it
active, with the cador prompt-stream bound to the GUI input bridge (slice D) so
getpoint/entsel/ssget drive from the canvas. The embedded-ECL Qt6 shell calls
this once at startup. Returns the session."
  (let ((host (clautolisp.cador:make-cador)))
    (cadgui-install-input host)
    (setf *cadgui-session* (make-cadgui-session :host host))))

(defun cadgui-session-or-start ()
  "The active session, starting one on demand."
  (or *cadgui-session* (cadgui-start)))
