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
;;;; Each candidate now sits alone, in its own top-level form, in the
;;;; order they appeared in the function that died.
;;;;
;;;; issues/open/bricscad-refuses-to-load-what-it-will-run.issue

(defun cad-probe-lr--expression-position ()
  ;; FOREACH as an ARGUMENT to another call, rather than as a statement.
  (list (foreach e (list 1 2 3) (* e 10))))

(defun cad-probe-lr--empty-list ()
  ;; FOREACH over NIL rather than over a list.
  (foreach e nil 99))

(defun cad-probe-lr--no-body ()
  ;; FOREACH with NO BODY FORMS AT ALL.
  (foreach e (list 1 2 3)))

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
