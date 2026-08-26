(in-package #:clautolisp.ui.tui)

;;;; Faces (TUI module spec §5.3). A FACE is named by a SYMBOL and maps to a set
;;;; of display parameters — foreground / background colour, bold, underline,
;;;; inverse video. Using the same face symbol everywhere yields the same
;;;; appearance; the user customises by redefining a face (DEFINE-FACE), and may
;;;; define new ones. Backends resolve a face symbol to their concrete terminal
;;;; attributes; the mock screen records the symbol as-is.
;;;;
;;;; The screen protocol's :ATTR argument is a face symbol. The plain colour
;;;; names and the legacy attribute keywords (:bold :invert :underline :normal)
;;;; are registered as faces too, so existing callers keep working unchanged.

(defvar *faces* (make-hash-table :test 'eq)
  "Registry: face symbol -> display-parameter plist
(:fg COLOR :bg COLOR :bold BOOL :underline BOOL :invert BOOL). COLOR is a
colour-name keyword (:black :red … :white) or NIL.")

(defun define-face (name &key fg bg bold underline invert)
  "Define or redefine the face NAME (a symbol) with the given display
parameters. Returns NAME."
  (check-type name symbol)
  (setf (gethash name *faces*)
        (list :fg fg :bg bg :bold bold :underline underline :invert invert))
  name)

(defun face-parameters (name)
  "The display-parameter plist of face NAME, or NIL when NAME is not a face."
  (and (symbolp name) (gethash name *faces*)))

(defun facep (name)
  "True when NAME designates a defined face."
  (and (symbolp name) (nth-value 1 (gethash name *faces*))))

(defun list-faces ()
  "The names of all defined faces."
  (loop for name being the hash-keys of *faces* collect name))

;;; --- predefined faces ------------------------------------------------

;; the eight ANSI colours, as foreground faces (legacy: :attr was a colour name)
(dolist (color '(:black :red :green :yellow :blue :magenta :cyan :white))
  (define-face color :fg color))

;; legacy attribute keywords, as faces
(define-face :normal)
(define-face :bold :bold t)
(define-face :invert :invert t)
(define-face :underline :underline t)

;; semantic faces used by the debugger / TUI (customisable) — a caller passes
;; the SEMANTIC name, not a raw colour, so the whole look is themable in one
;; place.
(define-face :current-line    :fg :yellow)   ; the current stopping line
(define-face :breakpoint      :fg :red)      ; a breakpointed poll point
(define-face :poll-point      :fg :blue)     ; a plain poll point
(define-face :selection       :bold t)       ; the structural selection
(define-face :active-status   :invert t)     ; active window status line
(define-face :inactive-status :underline t)  ; inactive window status line
