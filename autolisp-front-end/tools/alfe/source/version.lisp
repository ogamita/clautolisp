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
;;;; start-engine PROBE fix and --on-error; realigned here. Realigned
;;;; again to 2.1.0 for the release-2.1.0 cut: clautolisp reached the
;;;; 2.x series with the aldo debugger's three UIs and the sedit editor,
;;;; and version-rules requires a program shipped and changed within a
;;;; series to carry that series' A.B.
;;;;
;;;; Realigned to 2.2.0 with clautolisp's MINOR bump for the
;;;; AutoLISP-to-Common-Lisp compiler: `alfe --clautolisp' embeds that
;;;; engine, so a new feature in it is a new feature in alfe, and the
;;;; rule at the head of this file -- keep at least in step -- is what
;;;; makes that automatic rather than a thing to remember.)

(defparameter *version* "2.2.19")
