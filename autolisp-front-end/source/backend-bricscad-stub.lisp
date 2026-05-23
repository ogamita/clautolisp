;;;; autolisp-front-end/source/backend-bricscad-stub.lisp
;;;;
;;;; Stub for the BricsCAD backend (macOS/Linux batch, Windows COM).
;;;; Filled in by ../issues/open/alfe-backend-bricscad.issue (Phase 3).

(defpackage #:alfe.backend.bricscad
  (:use #:cl)
  (:documentation
   "Placeholder package for the BricsCAD backend. Will specialise the
ALFE.BACKEND generics on a BRICSCAD-BACKEND class and drive the engine
through ALFE.PROTOCOL.FILE."))

(in-package #:alfe.backend.bricscad)
