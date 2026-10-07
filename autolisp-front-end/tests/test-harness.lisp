(in-package #:autolisp-front-end.tests)

;;;; Single top-level FiveAM suite for the alfe front-end. Per-area
;;;; tests pull this in via (in-suite autolisp-front-end-suite); the
;;;; ASDF :test-op runs the whole suite via RUN-ALL-TESTS in run.lisp.

(def-suite autolisp-front-end-suite
  :description "Aggregate FiveAM suite for the alfe front-end.")

(in-suite autolisp-front-end-suite)

;; Shared by dribble and CAD backend tests. Declare before either file is
;; compiled. This mock is an external file-protocol peer, not the cador host.
(defvar *mock-cad-condition* nil
  "The condition that killed the most recent mock CAD thread, or NIL.

The thread's body has to be guarded -- an unhandled error in a thread under
`--disable-debugger' aborts the WHOLE test process -- but a guard that only
swallows turns every mock crash into an indistinguishable driver timeout.
test:alfe:windows reported exactly that for a week: :ABORTED, with no cause,
because the mock had died inside its IGNORE-ERRORS and nothing recorded why.
So the guard records, and the tests that can be defeated by a dead mock quote
this in their failure message.")
