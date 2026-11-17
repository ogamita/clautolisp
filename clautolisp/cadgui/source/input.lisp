;;;; The cadgui input bridge (slice D): a GUI-backed cador prompt stream.
;;;;
;;;; cador's host-getpoint / host-entsel / host-ssget all read a line through the
;;;; single chokepoint READ-PROMPT-LINE, from (cador-prompt-stream host) -- the
;;;; same seam --mock-input uses. Under cadgui we bind that stream to a gray
;;;; input stream that BLOCKS, on an empty buffer, via *cadgui-input-hook*: the
;;;; shell sets the hook to its C nested-Qt-event-loop await (run the loop until a
;;;; mouse click, format it as the point line "x,y", return it); a test sets it to
;;;; a scripted provider. So bare (getpoint) / (entsel) drive from the canvas,
;;;; unchanged -- both just await a world point, which cador turns into the point
;;;; (getpoint) or the entity picked there via %pick-entity (entsel).

(in-package #:clautolisp.cadgui)

(defvar *cadgui-input-hook* nil
  "A function of no args returning the next input LINE (a string), blocking until
the shell supplies it, or NIL at end of input. The shell sets it to the C
nested-event-loop await; a test to a scripted provider. NIL => no input (EOF).")

(defvar *cadgui-pending-input* nil
  "NIL, or :POINT while a cador read is blocked awaiting a canvas pick -- the
shell reads it to put the canvas in point/crosshair mode. getpoint and entsel
both await a point, so one kind covers the common case.")

(defun cadgui-point-line (x y)
  "The text line a getpoint/entsel read expects for the world point (X,Y)."
  (format nil "~F,~F" (coerce x 'double-float) (coerce y 'double-float)))

(defclass cadgui-input-stream
    (trivial-gray-streams:fundamental-character-input-stream)
  ((buffer :initform "" :accessor %cis-buffer)
   (pos    :initform 0  :accessor %cis-pos)
   ;; A per-instance reader (no-arg -> next line / NIL), for a PER-DOCUMENT
   ;; input channel (the multi-document driver, multidoc.lisp). NIL falls back
   ;; to the global *cadgui-input-hook*, so the single-document stream is
   ;; unchanged.
   (fill-fn :initform nil :initarg :fill-fn :accessor %cis-fill-fn))
  (:documentation "cador's prompt-stream under cadgui: read-prompt-line reads a
line from here; an empty buffer BLOCKS via this stream's FILL-FN (a per-document
channel) or, failing that, the global *cadgui-input-hook*."))

(defun %cis-fill (s)
  "Block for the next input line and buffer it (with a trailing newline)."
  (setf *cadgui-pending-input* :point)
  (unwind-protect
       (let* ((reader (or (%cis-fill-fn s) *cadgui-input-hook*))
              (line (and reader (funcall reader))))
         (setf (%cis-buffer s) (if line
                                   (concatenate 'string line (string #\Newline))
                                   "")
               (%cis-pos s) 0))
    (setf *cadgui-pending-input* nil)))

(defmethod trivial-gray-streams:stream-read-char ((s cadgui-input-stream))
  (when (>= (%cis-pos s) (length (%cis-buffer s)))
    (%cis-fill s))
  (if (>= (%cis-pos s) (length (%cis-buffer s)))
      :eof
      (prog1 (char (%cis-buffer s) (%cis-pos s)) (incf (%cis-pos s)))))

(defmethod trivial-gray-streams:stream-read-char-no-hang ((s cadgui-input-stream))
  ;; Serve a buffered char if present; otherwise report "nothing ready now" (NIL)
  ;; so read-prompt-line classifies :would-block and then reads a line
  ;; synchronously -- which blocks on the hook. Never blocks itself.
  (if (< (%cis-pos s) (length (%cis-buffer s)))
      (prog1 (char (%cis-buffer s) (%cis-pos s)) (incf (%cis-pos s)))
      nil))

(defmethod trivial-gray-streams:stream-unread-char ((s cadgui-input-stream) ch)
  (declare (ignore ch))
  (when (> (%cis-pos s) 0) (decf (%cis-pos s)))
  nil)

(defun cadgui-install-input (host)
  "Bind HOST's prompt-stream to a cadgui input stream, so host-get* read from the
canvas. Called by cadgui-start. Returns HOST."
  (setf (clautolisp.cador:cador-prompt-stream host)
        (make-instance 'cadgui-input-stream))
  host)
