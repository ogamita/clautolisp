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

(defparameter *version* "1.5.0")
