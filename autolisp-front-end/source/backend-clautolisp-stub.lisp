;;;; autolisp-front-end/source/backend-clautolisp-stub.lisp
;;;;
;;;; Stub for the clautolisp backend (in-process + subprocess).
;;;; Filled in by ../issues/open/alfe-backend-clautolisp.issue
;;;; (Phase 1). The skeleton ticket only needs the file to exist so
;;;; the aggregate `autolisp-front-end` system loads cleanly on a
;;;; fresh checkout; the package is empty by design.

(defpackage #:alfe.backend.clautolisp
  (:use #:cl)
  (:documentation
   "Placeholder package for the clautolisp backend. Generics from
ALFE.BACKEND will be specialised on a future CLAUTOLISP-BACKEND
class in alfe-backend-clautolisp.issue."))

(in-package #:alfe.backend.clautolisp)
