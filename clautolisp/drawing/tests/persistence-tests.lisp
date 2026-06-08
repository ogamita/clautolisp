(in-package #:clautolisp.drawing.tests)

(in-suite drawing-suite)

;;; --- format probing ----------------------------------------------

(test probe-drawing-format-by-extension
  (is (eq :dxf-ascii (probe-drawing-format "/tmp/plan.dxf")))
  (is (eq :dxf-ascii (probe-drawing-format "/tmp/PLAN.DXF")))   ; case-insensitive
  (is (eq :dwg (probe-drawing-format "/tmp/plan.dwg")))
  (is (null (probe-drawing-format "/tmp/plan.xyz")))
  (is (null (probe-drawing-format "/tmp/plan"))))

;;; --- dispatch errors (no codec registered) -----------------------

(test read-drawing-signals-on-undeterminable-format
  (let ((*drawing-codecs* (make-hash-table)))
    (signals drawing-format-error (read-drawing "/tmp/plan.xyz"))))

(test read-drawing-signals-when-no-reader-registered
  (let ((*drawing-codecs* (make-hash-table)))
    ;; .dxf probes to :dxf-ascii, but nothing is registered.
    (signals drawing-format-error (read-drawing "/tmp/plan.dxf"))))

(test write-drawing-signals-when-no-writer-registered
  (let ((*drawing-codecs* (make-hash-table))
        (d (make-drawing)))
    (signals drawing-format-error (write-drawing d "/tmp/plan.dxf"))))

;;; --- dispatch round-trip through a stub codec --------------------

(test read-write-dispatch-through-registered-codec
  (let ((*drawing-codecs* (make-hash-table))
        (written nil))
    (register-drawing-codec
     :native
     :reader (lambda (source) (declare (ignore source)) (make-drawing :name "stub"))
     :writer (lambda (drawing destination &key version)
               (declare (ignore drawing destination version))
               (setf written t)))
    (let ((d (read-drawing "/tmp/whatever.bin" :format :native)))
      (is (drawing-p d))
      (is (string= "stub" (drawing-name d)))
      (is (eq :native (drawing-format d)))             ; provenance set
      (is (not (null (drawing-path d))))
      (is (eq d (write-drawing d "/tmp/out.bin" :format :native :version :ac1027)))
      (is (eq t written))
      (is (eq :ac1027 (drawing-version d))))))

;;; --- error translation at the dispatch boundary ------------------

(test reader-plain-error-is-wrapped-as-drawing-read-error
  (let ((*drawing-codecs* (make-hash-table)))
    (register-drawing-codec
     :boom :reader (lambda (source) (declare (ignore source)) (error "kaboom")))
    (handler-case (read-drawing "/tmp/x.bin" :format :boom)
      (drawing-read-error (e)
        (is (eq :boom (drawing-error-source-format e)))
        (is (not (null (drawing-error-cause e)))))
      (:no-error (&rest _) (declare (ignore _)) (is nil "expected drawing-read-error")))))

(test reader-drawing-error-passes-through-unwrapped
  (let ((*drawing-codecs* (make-hash-table)))
    (register-drawing-codec
     :picky :reader (lambda (source)
                      (declare (ignore source))
                      (error 'drawing-format-error :bad-format :picky
                             :format-control "nope")))
    ;; A drawing-error from the codec is NOT re-wrapped as a read-error.
    (signals drawing-format-error (read-drawing "/tmp/x.bin" :format :picky))))
