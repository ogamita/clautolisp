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
               :format-control "libredwg failed to read ~S: ~A (code ~D)"
               :format-arguments (list source (dwg-error-text rc) rc)))
      (let ((drawing (dxf-read-drawing dxf)))
        (setf (drawing-format drawing) :dwg
              (drawing-path drawing) (or (ignore-errors (truename source))
                                         (pathname source)))
        drawing))))

(defun dwg-write-drawing (drawing destination &key version)
  "Write DRAWING to the DWG file DESTINATION: the DXF codec emits a temp DXF
which libredwg converts to DWG. VERSION (a $ACADVER keyword such as :ac1032)
is stamped into the temp DXF's $ACADVER; libredwg's DXF importer reads it and
its DWG writer emits that version. NIL uses the drawing's own version.

The DWG version thus follows the DXF $ACADVER through libredwg — the shim
(clal_dxf_to_dwg) takes no explicit version argument. If a build of libredwg
does not honour $ACADVER on conversion, the DWG version falls back to
libredwg's default; the requested version is still recorded on the drawing."
  (ensure-shim-loaded)
  ;; libredwg's dwg_write_file errors (IOERROR) if the target already
  ;; exists; WRITE-DRAWING's contract is to overwrite, so clear it.
  (when (probe-file destination)
    (delete-file destination))
  (uiop:with-temporary-file (:pathname dxf :type "dxf")
    (dxf-write-drawing drawing dxf :version (or version (drawing-version drawing)))
    (let ((rc (%dxf-to-dwg (uiop:native-namestring dxf)
                           (uiop:native-namestring destination))))
      (when (>= rc +dwg-err-critical+)
        (error 'drawing-error
               :format-control "libredwg failed to write ~S from the DXF this ~
drawing produced: ~A (code ~D)"
               :format-arguments (list destination (dwg-error-text rc) rc)))
      drawing)))

(register-drawing-codec :dwg
                        :reader #'dwg-read-drawing
                        :writer #'dwg-write-drawing)
