(defpackage #:clautolisp.drawing.dwg
  (:use #:cl)
  (:import-from #:clautolisp.drawing
                #:register-drawing-codec
                #:drawing-format
                #:drawing-path
                ;; DWG-WRITE-DRAWING defaults the version to the drawing's own.
                ;; Not imported, it read as CLAUTOLISP.DRAWING.DWG::DRAWING-VERSION
                ;; -- undefined -- and every version-less DWG save (VLA-SAVEAS)
                ;; failed; verify:packaged-dwg:windows caught it, 2026-10-03.
                #:drawing-version
                #:drawing-error
                #:drawing-library-unavailable
                #:dxf-read-drawing
                #:dxf-write-drawing)
  (:documentation "Phase 17e — the DWG codec for clautolisp.drawing,
backed by the vendored, self-built GNU libredwg
(clautolisp/third-party/libredwg) via a thin CFFI'd C shim
(source/clal_dwg.c -> clal_dwg.<dylib|so>).

DWG read/write is done in-process: libredwg converts DWG<->DXF and the
Phase-17c DXF codec is the interchange (DWG -> DXF -> drawing on read;
drawing -> DXF -> DWG on write). Loading this system registers the
:dwg codec with clautolisp.drawing, so READ-DRAWING / WRITE-DRAWING
handle .dwg once it is loaded. It is deliberately NOT part of the core
clautolisp aggregate: the core stays buildable where libredwg is
absent (the drawing layer then signals DRAWING-FORMAT-ERROR for :dwg).")
  (:export #:dwg-read-drawing
           #:dwg-write-drawing))
