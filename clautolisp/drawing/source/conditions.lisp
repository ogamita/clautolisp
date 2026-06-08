(in-package #:clautolisp.drawing)

;;;; Conditions for the drawing CL API (Phase 17b, REVIEW-6).
;;;;
;;;; These are plain Common-Lisp conditions, deliberately *distinct*
;;;; from clautolisp.autolisp-runtime's autolisp-runtime-error. The
;;;; host adapter is responsible for translating a drawing-error into
;;;; the appropriate AutoLISP runtime error at the boundary (e.g. when
;;;; a (command "_.OPEN" …) fails). Every condition carries enough
;;;; structured context — which drawing, which entity handle, which
;;;; file, which format — to diagnose the failure without parsing the
;;;; report string.

(define-condition drawing-error (error)
  ((drawing :initarg :drawing :initform nil :reader drawing-error-drawing
            :documentation "The DRAWING the error concerns, or NIL.")
   (handle  :initarg :handle  :initform nil :reader drawing-error-handle
            :documentation "The entity handle (integer or hex string)
the error concerns, or NIL.")
   (format-control :initarg :format-control :initform "drawing error"
                   :reader drawing-error-format-control)
   (format-arguments :initarg :format-arguments :initform '()
                     :reader drawing-error-format-arguments))
  (:report (lambda (condition stream)
             (apply #'format stream
                    (drawing-error-format-control condition)
                    (drawing-error-format-arguments condition))
             (let ((d (drawing-error-drawing condition))
                   (h (drawing-error-handle condition)))
               (when (or d h)
                 (format stream " [")
                 (when d (format stream "drawing ~S" (drawing-name d)))
                 (when (and d h) (format stream ", "))
                 (when h (format stream "handle ~A" h))
                 (format stream "]")))))
  (:documentation "Base class for all clautolisp.drawing errors."))

(define-condition drawing-read-error (drawing-error)
  ((source        :initarg :source        :initform nil :reader drawing-error-source)
   (source-format :initarg :source-format :initform nil :reader drawing-error-source-format)
   (cause         :initarg :cause         :initform nil :reader drawing-error-cause))
  (:documentation "READ-DRAWING failed: unknown content or a codec
parse error. SOURCE is the file, SOURCE-FORMAT the format attempted,
CAUSE the wrapped underlying condition (or NIL)."))

(define-condition drawing-write-error (drawing-error)
  ((destination   :initarg :destination   :initform nil :reader drawing-error-destination)
   (target-format :initarg :target-format :initform nil :reader drawing-error-target-format)
   (cause         :initarg :cause         :initform nil :reader drawing-error-cause))
  (:documentation "WRITE-DRAWING failed. DESTINATION is the target
file, TARGET-FORMAT the format attempted, CAUSE the wrapped condition."))

(define-condition drawing-format-error (drawing-error)
  ((bad-format :initarg :bad-format :initform nil :reader drawing-error-bad-format)
   (location   :initarg :location   :initform nil :reader drawing-error-location))
  (:documentation "An unknown / unsupported / undeterminable drawing
format. BAD-FORMAT is the offending keyword (or NIL when the format
could not be determined at all); LOCATION is the source/destination."))
