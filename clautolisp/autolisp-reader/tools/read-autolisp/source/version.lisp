(in-package #:clautolisp.autolisp-reader.tools.read-autolisp)

;;;; Current version of the read-autolisp tool.
;;;;
;;;; Format: MAJOR.MINOR.DEVELOP. The DEVELOP counter is bumped on
;;;; every change that touches read-autolisp source code, mirroring
;;;; the convention used by clautolisp/tools/clautolisp/source/version.lisp.
;;;; read-autolisp ships with the same release cadence as clautolisp
;;;; (it sits in the same source tree under autolisp-reader/tools/)
;;;; so the numbering tracks clautolisp's, off by enough that the
;;;; two are independently identifiable in bug reports.
;;;;
;;;; A CHANGED LIBRARY IS A CHANGED PROGRAM (pjb, 2026-08-16). This
;;;; binary is a thin CLI over the autolisp-reader system: when that
;;;; system changes, what the user runs changes, even though nothing
;;;; under tools/read-autolisp/ moved. Counting only this directory's
;;;; commits is the wrong measure, and it is what had left the stamp at
;;;; 1.6.0 across the whole 1.8 series -- 1.8.0 here is the first version
;;;; that carries the codec and dialect work the library gained.

(defparameter *version* "1.9.0")
