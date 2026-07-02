(in-package #:clautolisp.debug)

;;;; Software watchpoints (command reference §2 watch). clautolisp has no
;;;; hardware watch registers, so a watch is a per-thread record re-checked at
;;;; every poll point (CHECK-WATCHES, called from POLL-POINT): it remembers a
;;;; variable's last observed value and stops when the value changes, or — when
;;;; a predicate thunk is supplied — when that predicate goes from false to true
;;;; (an edge). The cost is one variable read (and optional predicate eval) per
;;;; watched variable per poll point, and only when at least one watch is set.

(defstruct (watch (:constructor %make-watch))
  (symbol nil)              ; the watched autolisp-symbol
  (name "" :type string)    ; its name (for display / lookup)
  (last-value nil)          ; last observed value
  (prev-value nil)          ; value just before the firing change (for the report)
  (last-bound-p nil)        ; was it bound at the last check
  (prev-bound-p nil)        ; bound-state just before the firing change
  (predicate nil)           ; NIL, or a thunk () -> value evaluated at the poll point
  (last-predicate nil))     ; predicate truth at the last check (edge detection)

(defun %watch-truth (predicate)
  "Truth of a watch PREDICATE thunk, treating an error in it as NIL (a broken
predicate must not abort the watched program)."
  (and predicate
       (handler-case (not (null (funcall predicate)))
         (error () nil))))

(defun add-watch (ti symbol name &key predicate)
  "Watch SYMBOL (named NAME) on TI: stop when its value changes, or — when
PREDICATE (a thunk evaluated at the poll point) is supplied — when PREDICATE
goes from false to true. The remembered value is seeded from the current
binding, so only a SUBSEQUENT change fires. Returns the watch."
  (multiple-value-bind (value boundp) (lookup-variable symbol)
    (let ((w (%make-watch :symbol symbol :name name
                          :last-value value :prev-value value
                          :last-bound-p boundp :prev-bound-p boundp
                          :predicate predicate
                          :last-predicate (%watch-truth predicate))))
      (setf (thread-debug-info-watches ti)
            (append (thread-debug-info-watches ti) (list w)))
      w)))

(defun remove-watch (ti name)
  "Remove the watch on the variable named NAME (case-insensitive); return T if
one was removed."
  (let ((before (length (thread-debug-info-watches ti))))
    (setf (thread-debug-info-watches ti)
          (remove-if (lambda (w) (string-equal name (watch-name w)))
                     (thread-debug-info-watches ti)))
    (/= before (length (thread-debug-info-watches ti)))))

(defun clear-watches (ti)
  "Remove every watch on TI."
  (setf (thread-debug-info-watches ti) '()
        (thread-debug-info-fired-watch ti) nil))

(defun list-watches (ti)
  "The watches set on TI (a fresh list)."
  (copy-list (thread-debug-info-watches ti)))

(defun check-watches (ti)
  "Re-check every watch on TI against the current bindings, refreshing each
watch's remembered state. Return the first watch that fired — its value changed
(or its predicate went false→true) since the last poll — or NIL, and record it
as TI's fired-watch. Always refreshes state so a single change fires once."
  (let ((fired nil))
    (dolist (w (thread-debug-info-watches ti))
      (multiple-value-bind (value boundp) (lookup-variable (watch-symbol w))
        (let* ((pred (watch-predicate w))
               (now-true (%watch-truth pred))
               (this-fired
                 (if pred
                     (and now-true (not (watch-last-predicate w)))
                     (or (not (eq boundp (watch-last-bound-p w)))
                         (not (equal value (watch-last-value w)))))))
          (when (and this-fired (null fired))
            (setf (watch-prev-value w) (watch-last-value w)
                  (watch-prev-bound-p w) (watch-last-bound-p w)
                  fired w))
          (setf (watch-last-value w) value
                (watch-last-bound-p w) boundp
                (watch-last-predicate w) now-true))))
    (setf (thread-debug-info-fired-watch ti) fired)
    fired))
