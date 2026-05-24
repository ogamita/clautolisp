(in-package #:autolisp-front-end.tests)

;;;; Single top-level FiveAM suite for the alfe front-end. Per-area
;;;; tests pull this in via (in-suite autolisp-front-end-suite); the
;;;; ASDF :test-op runs the whole suite via RUN-ALL-TESTS in run.lisp.

(def-suite autolisp-front-end-suite
  :description "Aggregate FiveAM suite for the alfe front-end.")

(in-suite autolisp-front-end-suite)
