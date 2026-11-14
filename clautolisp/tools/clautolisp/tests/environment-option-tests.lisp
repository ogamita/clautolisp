;;;; clautolisp/tools/clautolisp/tests/environment-option-tests.lisp
;;;;
;;;; The clautolisp program's option defaults from the environment
;;;; (cli-option-environment-defaults): its own options (CLAUTOLISP_TRACE,
;;;; CLAUTOLISP_OPTIMIZE, the dribble pair), the per-program override of a
;;;; shared option, and the rule that a program driven by a front end
;;;; (--front-end-bindings) reads none of them. The shared mechanism has its
;;;; own tests in the autolisp-cli suite.

(in-package #:clautolisp.tools.clautolisp.tests)

(in-suite clautolisp-tool-suite)

(defun %parse-in-environment (environment &rest arguments)
  "Parse ARGUMENTS as the clautolisp program does, with ENVIRONMENT (an alist
of variable -> value) as the process environment."
  (let ((clautolisp.autolisp-cli:*environment-getenv*
          (lambda (name)
            (let ((value (cdr (assoc name environment :test #'string=))))
              (and value (plusp (length value)) value)))))
    (clautolisp.tools.clautolisp::parse-arguments arguments)))

(test clautolisp-trace-from-environment
  (is (clautolisp.autolisp-cli:cli-options-trace-p
       (%parse-in-environment '(("CLAUTOLISP_TRACE" . "1")) "-x" "1")))
  (is (not (clautolisp.autolisp-cli:cli-options-trace-p
            (%parse-in-environment '(("CLAUTOLISP_TRACE" . "0")) "-x" "1"))))
  ;; ALFE_TRACE is nobody's: alfe has no --trace.
  (is (not (clautolisp.autolisp-cli:cli-options-trace-p
            (%parse-in-environment '(("ALFE_TRACE" . "1")) "-x" "1")))))

(test clautolisp-optimize-from-environment-yields-to-the-command-line
  "The variable's pairs come first and the pairs apply left to right, so a
quality the command line names wins and the others keep the variable's level."
  (is (equal '((:speed . 3) (:debug . 0))
             (clautolisp.autolisp-cli:cli-options-optimization
              (%parse-in-environment '(("CLAUTOLISP_OPTIMIZE" . "speed=3,debug=0"))
                                     "-x" "1"))))
  (is (equal '((:speed . 3) (:debug . 0) (:speed . 1))
             (clautolisp.autolisp-cli:cli-options-optimization
              (%parse-in-environment '(("CLAUTOLISP_OPTIMIZE" . "speed=3,debug=0"))
                                     "-O1" "-x" "1")))))

(test clautolisp-dribble-from-environment
  (is (eq t (clautolisp.autolisp-cli:cli-options-dribble
             (%parse-in-environment '(("AUTOLISP_DRIBBLE" . "yes")) "-x" "1"))))
  (is (equal "run.dribble"
             (clautolisp.autolisp-cli:cli-options-dribble
              (%parse-in-environment '(("CLAUTOLISP_DRIBBLE" . "run.dribble")
                                       ("AUTOLISP_DRIBBLE" . "yes"))
                                     "-x" "1")))))

(test clautolisp-variable-overrides-autolisp-variable
  (let ((opts (%parse-in-environment '(("AUTOLISP_DIALECT" . "lax")
                                       ("CLAUTOLISP_DIALECT" . "clautolisp"))
                                     "-x" "1")))
    (is (eq :clautolisp (clautolisp.autolisp-cli:cli-options-dialect opts)))))

(test a-driven-program-ignores-the-option-variables
  "Under --front-end-bindings (alfe --backend subprocess), alfe resolved the
variables from its own environment and put the result on this command line: a
CLAUTOLISP_<X> set for the user's own clautolisp runs must not contradict it."
  (let ((opts (%parse-in-environment '(("CLAUTOLISP_DIALECT" . "lax")
                                       ("AUTOLISP_HOST" . "nihil")
                                       ("CLAUTOLISP_TRACE" . "1"))
                                     "--front-end-bindings" "bindings.sexp"
                                     "-x" "1")))
    (is (eq :strict (clautolisp.autolisp-cli:cli-options-dialect opts)))
    (is (eq :cador (clautolisp.autolisp-cli:cli-options-host opts)))
    (is (not (clautolisp.autolisp-cli:cli-options-trace-p opts)))))
