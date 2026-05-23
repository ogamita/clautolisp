;;;; autolisp-front-end/source/file-protocol-stub.lisp
;;;;
;;;; Stub for the file-IPC protocol driver shared by the CAD backends.
;;;; Filled in by ../issues/open/alfe-file-protocol.issue (Phase 2):
;;;; atomic writes, status polling, line-to-form reader, runtime
;;;; bootstrap emission.

(defpackage #:alfe.protocol.file
  (:use #:cl)
  (:documentation
   "Placeholder package for the file-IPC protocol driver. The runtime
AutoLISP side (`autolisp-remote-io.lsp`) is kept as-is — Phase 2 only
rewrites the alfe-side driver here."))

(in-package #:alfe.protocol.file)
