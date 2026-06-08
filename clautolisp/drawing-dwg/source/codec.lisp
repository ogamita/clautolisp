(in-package #:clautolisp.drawing.dwg)

;;;; The :dwg codec (Phase 17e).
;;;;
;;;; DWG <-> drawing via libredwg + the Phase-17c DXF codec as the
;;;; in-process interchange. Registered with clautolisp.drawing on load.

(defun dwg-read-drawing (source)
  "Read the DWG file SOURCE into a DRAWING: libredwg converts it to DXF
in a temp file, which the DXF codec parses. DRAWING-FORMAT is set to
:dwg."
  (ensure-shim-loaded)
  (uiop:with-temporary-file (:pathname dxf :type "dxf")
    (let ((rc (%dwg-to-dxf (uiop:native-namestring (truename source))
                           (uiop:native-namestring dxf))))
      (when (>= rc +dwg-err-critical+)
        (error 'drawing-error
               :format-control "libredwg failed to read ~S (error code ~D)"
               :format-arguments (list source rc)))
      (let ((drawing (dxf-read-drawing dxf)))
        (setf (drawing-format drawing) :dwg
              (drawing-path drawing) (or (ignore-errors (truename source))
                                         (pathname source)))
        drawing))))

(defun dwg-write-drawing (drawing destination &key version)
  "Write DRAWING to the DWG file DESTINATION: the DXF codec emits a
temp DXF which libredwg converts to DWG. VERSION is reserved (the DWG
version is taken from the DXF/libredwg defaults for now)."
  (declare (ignore version))
  (ensure-shim-loaded)
  ;; libredwg's dwg_write_file errors (IOERROR) if the target already
  ;; exists; WRITE-DRAWING's contract is to overwrite, so clear it.
  (when (probe-file destination)
    (delete-file destination))
  (uiop:with-temporary-file (:pathname dxf :type "dxf")
    (dxf-write-drawing drawing dxf)
    (let ((rc (%dxf-to-dwg (uiop:native-namestring dxf)
                           (uiop:native-namestring destination))))
      (when (>= rc +dwg-err-critical+)
        (error 'drawing-error
               :format-control "libredwg failed to write ~S (error code ~D)"
               :format-arguments (list destination rc)))
      drawing)))

(register-drawing-codec :dwg
                        :reader #'dwg-read-drawing
                        :writer #'dwg-write-drawing)
