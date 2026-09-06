;;;; probes/sources/probe-load-refusal.lsp
;;;;
;;;; WHICH FORM WILL BRICSCAD NOT READ FROM A FILE?
;;;;
;;;; THIS SUITE IS THE EXPERIMENT, not a description of one. Every other
;;;; suite here keeps questionable syntax inside a STRING and READs it at
;;;; run time, because a host that refuses to read a file answers with
;;;; silence and takes the whole suite down with it. This one does the
;;;; opposite ON PURPOSE: the forms are written out, in the file, because
;;;; LOADING THEM IS THE QUESTION.
;;;;
;;;; THEREFORE IT MUST BE RUN ALONE, split, in a job of its own:
;;;;
;;;;     PROBE_SUITES=load-refusal PROBE_SPLIT_SUITES=load-refusal
;;;;
;;;; Split, each top-level form below becomes its own file with its own
;;;; progress marker, so the LAST MARKER IN THE RESULTS NAMES THE FORM
;;;; the engine would not take. Run unsplit, or alongside another suite,
;;;; a refusal is once again a silence -- which is exactly the two days
;;;; this file exists to stop anyone spending again.
;;;;
;;;; THE BACKGROUND. BricsCAD would not load probe-foreach-scope.lsp, on
;;;; macOS and on Windows, before a single probe ran, with no diagnostic:
;;;; the process simply sat until the harness's timeout. The per-form
;;;; split narrowed it to ONE FUNCTION, which contained three candidates
;;;; at once. All three EXECUTE correctly in BricsCAD when read at run
;;;; time -- that is how the (1 2 3) divergence for a body-less foreach
;;;; was measured -- so the refusal is in whatever READS a file being
;;;; loaded, and not in the evaluator.
;;;;
;;;; THE ORDER OF THE FORMS BELOW IS THE EXPERIMENT'S DESIGN, not
;;;; housekeeping. A refusal HANGS the engine, so everything after the
;;;; first culprit is never attempted: ONE RUN FINDS AT MOST ONE
;;;; CULPRIT, and it finds the FIRST. So the candidate whose status is
;;;; still unknown goes FIRST, and the ones already settled go last.
;;;;
;;;; SETTLED (2026-09-02, BricsCAD macOS, two runs):
;;;;
;;;;   (foreach e (list 1 2 3))                  LOADS -- marker written
;;;;   (list (foreach e (list 1 2 3) (* e 10)))  LOADS -- marker written
;;;;   (foreach e nil 99)                        LOAD NEVER RETURNS
;;;;
;;;; Loading a file that contains (foreach VAR nil ...) makes BricsCAD
;;;; STOP MAKING PROGRESS: no marker, nothing after it, until the
;;;; harness timeout. It executes the same form happily when the form
;;;; is READ at run time, so the evaluator is not implicated.
;;;;
;;;; SAY `THE LOAD DOES NOT RETURN', NOT `IT REFUSES' AND NOT `IT WILL
;;;; NOT READ' (pjb, 2026-09-06). The results file names FUNCTIONS that
;;;; loaded; the culprit's identity comes from the FRAGMENT FILE, and
;;;; its verdict from a marker that is ABSENT. Each load is wrapped in
;;;; VL-CATCH-ALL-APPLY, so an error the engine signalled would have
;;;; been caught and recorded -- none was, which rules out a catchable
;;;; refusal and rules IN nothing: a reader rejection, a crash and a
;;;; modal dialog all fit the same silence.
;;;;
;;;; Two runs, each clearing a different candidate, so neither verdict
;;;; rests on one observation. The order below is what made round 2
;;;; possible: the then-unknown body-less form was moved FIRST.
;;;;
;;;; The suite is KEPT rather than deleted: it is now a regression test
;;;; against a future BricsCAD that changes any of the three answers,
;;;; and the Windows confirmation has still not been run.
;;;;
;;;; issues/open/bricscad-refuses-to-load-what-it-will-run.issue

(defun cad-probe-lr--no-body ()
  ;; FOREACH with NO BODY FORMS AT ALL. STATUS UNKNOWN -- first, so that
  ;; this run reaches it whatever the others do.
  (foreach e (list 1 2 3)))

(defun cad-probe-lr--expression-position ()
  ;; FOREACH as an ARGUMENT to another call. Loaded fine in round 1;
  ;; kept so a future BricsCAD version cannot change that unnoticed.
  (list (foreach e (list 1 2 3) (* e 10))))

(defun cad-probe-lr--empty-list ()
  ;; FOREACH over a literal NIL. THE KNOWN CULPRIT, so it goes LAST:
  ;; anything after it in this file will not be reached.
  (foreach e nil 99))

(defun cad-probe-run-load-refusal-probes ()
  ;; Reaching here at all is the headline result: it means every form
  ;; above LOADED. The per-form markers say which ones did when it is
  ;; not reached.
  (cad-probe-capture "load-refusal"
                     "the whole file loaded"
                     (function cad-probe-lr--no-body))
  (cad-probe-capture "load-refusal"
                     "(list (foreach e '(1 2 3) (* e 10)))"
                     (function cad-probe-lr--expression-position))
  (cad-probe-capture "load-refusal"
                     "(foreach e nil 99)"
                     (function cad-probe-lr--empty-list)))
