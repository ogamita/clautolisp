;;;; autolisp-front-end/source/backend-autocad-stub.lisp
;;;;
;;;; Stub for the AutoCAD backend (Windows COM, accoreconsole batch).
;;;; Filled in by ../issues/open/alfe-backend-autocad.issue (Phase 3).

(defpackage #:alfe.backend.autocad
  (:use #:cl)
  (:documentation
   "Placeholder package for the AutoCAD backend. Will specialise the
ALFE.BACKEND generics on an AUTOCAD-BACKEND class and drive the engine
through ALFE.PROTOCOL.FILE plus a Windows COM bridge (VBScript in V1,
direct CFFI in V2)."))

(in-package #:alfe.backend.autocad)
