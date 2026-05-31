(in-package #:clautolisp.inspect)

;;;; The debugger workspace (spec §16.2): numbered slots $1, $2, … plus
;;;; the alias $0 for the currently-displayed value. Slots live in a
;;;; debugger-private namespace that does NOT intrude on AutoLISP's global
;;;; symbol table — they are resolved by the inspector's own eval layer
;;;; (session-eval), never by the AutoLISP evaluator. Names are strings
;;;; like "$4"; values are AutoLISP runtime values (or backend proxies).

(defstruct workspace
  (slots (make-hash-table :test 'equal))   ; name string -> value
  (counter 0 :type fixnum))                ; high-water mark for $N allocation

(defun next-slot-name (workspace)
  "Allocate and return the next free slot name (a string like \"$4\")."
  (format nil "$~D" (incf (workspace-counter workspace))))

(defun workspace-bind (workspace name value)
  "Bind NAME (a string such as \"$4\") to VALUE; return NAME. If NAME is
$N with N above the high-water mark, the counter advances so later
auto-allocations don't collide."
  (setf (gethash name (workspace-slots workspace)) value)
  (let ((n (and (> (length name) 1) (char= (char name 0) #\$)
                (ignore-errors (parse-integer name :start 1)))))
    (when (and n (> n (workspace-counter workspace)))
      (setf (workspace-counter workspace) n)))
  name)

(defun workspace-ref (workspace name)
  "Return (values value present-p) for slot NAME."
  (gethash name (workspace-slots workspace)))

(defun workspace-list (workspace)
  "Return an alist (name . value) of all bound slots."
  (let ((result '()))
    (maphash (lambda (name value) (push (cons name value) result))
             (workspace-slots workspace))
    result))

(defun workspace-clear (workspace &optional name)
  "Remove slot NAME, or all slots when NAME is omitted (spec §24)."
  (if name
      (remhash name (workspace-slots workspace))
      (clrhash (workspace-slots workspace)))
  (values))
