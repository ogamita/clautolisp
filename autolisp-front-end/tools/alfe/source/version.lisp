(in-package #:alfe.tool)

;;;; Current version of the alfe front-end.
;;;;
;;;; Format: MAJOR.MINOR.DEVELOP. The DEVELOP counter is bumped on
;;;; every change that touches alfe source code, mirroring the
;;;; convention used by clautolisp/tools/clautolisp/source/version.lisp.
;;;; The memory rule for the clautolisp version bump applies here too —
;;;; see ../../PLAN.md for the wording.
;;;;
;;;; alfe TRACKS clautolisp's version. `alfe --clautolisp' embeds
;;;; essentially the whole clautolisp engine, so a change to clautolisp's
;;;; sources bumps alfe too — keep this at least in step with
;;;; clautolisp/tools/clautolisp/source/version.lisp. alfe's own changes
;;;; bump it independently on top of that. (It had drifted, stuck at
;;;; 1.9.0 while clautolisp reached 1.9.7 and alfe gained the AutoCAD
;;;; start-engine PROBE fix and --on-error; realigned here.)

(defparameter *version* "1.9.14")
