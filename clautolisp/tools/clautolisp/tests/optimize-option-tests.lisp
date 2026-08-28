;;;; clautolisp/tools/clautolisp/tests/optimize-option-tests.lisp
;;;;
;;;; CLI parse tests for --optimize / -O (issues/open/compiler.issue).
;;;;
;;;; The option is the command-line spelling of (CLAL-OPTIMIZE '((SPEED 3) …)),
;;;; and it exists for one reason: a (clal-optimize …) written inside a .lsp
;;;; takes effect only when that call is EVALuated, which is after the file
;;;; containing it has been read and its DEFUNs built. AutoLISP has no macros
;;;; and no compilation-time effects, so there is no DECLAIM to borrow. Only
;;;; the command line can set the qualities before the first file is loaded.
;;;;
;;;; These tests are about the PARSE — that the CLI produces the right
;;;; (QUALITY . LEVEL) pairs and rejects nonsense. What a level MEANS is not
;;;; retested here; that algebra has one implementation
;;;; (APPLY-CLAL-OPTIMIZATION) and its own tests in the builtins-core suite.

(in-package #:clautolisp.tools.clautolisp.tests)

(in-suite clautolisp-tool-suite)

(defun %optimize-pairs (&rest arguments)
  "Parse ARGUMENTS and return the accumulated ((QUALITY . LEVEL) …)."
  (clautolisp.autolisp-cli:cli-options-optimization
   (clautolisp.tools.clautolisp::parse-arguments arguments)))

(test optimize-absent-leaves-the-slot-nil
  "No --optimize means NIL, which is not the same as `every quality at 0':
an absent option must leave every level exactly as it was. The tool only
calls SET-CLAL-OPTIMIZATION-LEVELS when the slot is non-NIL, so this is the
distinction that keeps the default configuration reachable."
  (is (null (%optimize-pairs "-x" "(+ 1 2)"))))

(test optimize-quality-equals-level
  (is (equal '((:speed . 3)) (%optimize-pairs "--optimize" "speed=3")))
  (is (equal '((:debug . 0)) (%optimize-pairs "--optimize" "debug=0")))
  (is (equal '((:space . 2)) (%optimize-pairs "-O" "space=2")))
  ;; Quality names are case-insensitive, like every other CLI value here.
  (is (equal '((:speed . 1)) (%optimize-pairs "-O" "SPEED=1"))))

(test optimize-embedded-value-form
  "`--optimize=speed=3' splits on the FIRST equals sign, so the option value
is `speed=3' and not `speed'."
  (is (equal '((:speed . 3)) (%optimize-pairs "--optimize=speed=3"))))

(test optimize-bare-quality-means-level-3
  "A bare quality name is level 3 — the same reading CLAL-OPTIMIZE gives a
bare quality symbol. One vocabulary, two spellings."
  (is (equal '((:debug . 3)) (%optimize-pairs "-O" "debug")))
  (is (equal '((:speed . 3)) (%optimize-pairs "--optimize" "speed"))))

(test optimize-bare-integer-means-speed
  "A bare N is speed=N: `-O2' has meant that everywhere for decades, and
SPEED is the quality a bare optimization level is about."
  (is (equal '((:speed . 2)) (%optimize-pairs "-O" "2")))
  (is (equal '((:speed . 0)) (%optimize-pairs "--optimize" "0"))))

(test optimize-attached-short-forms
  "-O0 … -O3 are four literal short options, because the shared parser
matches short options by exact string (the -E<situation> family is
enumerated the same way). Each is exactly `-O speed=N'."
  (is (equal '((:speed . 0)) (%optimize-pairs "-O0")))
  (is (equal '((:speed . 1)) (%optimize-pairs "-O1")))
  (is (equal '((:speed . 2)) (%optimize-pairs "-O2")))
  (is (equal '((:speed . 3)) (%optimize-pairs "-O3"))))

(test optimize-comma-separated-specifiers
  (is (equal '((:speed . 3) (:debug . 0))
             (%optimize-pairs "-O" "speed=3,debug=0")))
  (is (equal '((:debug . 1) (:space . 2) (:speed . 3))
             (%optimize-pairs "--optimize" "debug=1,space=2,speed=3")))
  ;; Whitespace around a specifier is tolerated, so a quoted
  ;; `-O "speed=3, debug=0"' works as written.
  (is (equal '((:speed . 3) (:debug . 0))
             (%optimize-pairs "-O" "speed=3, debug=0"))))

(test optimize-occurrences-accumulate
  "Repeating the option appends rather than replaces: `-O speed=3 -O debug=0'
is the same request as `-O speed=3,debug=0'. Replacing would make the second
occurrence silently drop the first, which is not what anyone types it for."
  (is (equal '((:speed . 3) (:debug . 0))
             (%optimize-pairs "-O" "speed=3" "-O" "debug=0")))
  (is (equal '((:speed . 2) (:speed . 3))
             (%optimize-pairs "-O2" "-O3"))))

(test optimize-rejects-unknown-quality
  (signals clautolisp.autolisp-cli:cli-usage-error
    (%optimize-pairs "-O" "safety=3"))
  (signals clautolisp.autolisp-cli:cli-usage-error
    (%optimize-pairs "-O" "compilation-speed")))

(test optimize-rejects-out-of-range-and-non-integer-levels
  "Levels are 0..3, as CLAL-OPTIMIZE's are — the CLI must not admit a level
the AutoLISP surface would reject."
  (signals clautolisp.autolisp-cli:cli-usage-error (%optimize-pairs "-O" "speed=4"))
  (signals clautolisp.autolisp-cli:cli-usage-error (%optimize-pairs "-O" "speed=-1"))
  (signals clautolisp.autolisp-cli:cli-usage-error (%optimize-pairs "-O" "speed=fast"))
  (signals clautolisp.autolisp-cli:cli-usage-error (%optimize-pairs "-O" "speed=2x"))
  (signals clautolisp.autolisp-cli:cli-usage-error (%optimize-pairs "-O" "4")))

(test optimize-rejects-an-empty-value
  (signals clautolisp.autolisp-cli:cli-usage-error (%optimize-pairs "--optimize="))
  (signals clautolisp.autolisp-cli:cli-usage-error (%optimize-pairs "-O" ""))
  (signals clautolisp.autolisp-cli:cli-usage-error (%optimize-pairs "-O" ",")))

(test optimize-missing-value-is-a-usage-error
  "`clautolisp -O' with nothing after it must say so rather than silently
consuming the next thing — there is no next thing."
  (signals clautolisp.autolisp-cli:cli-usage-error (%optimize-pairs "-O")))

(test optimize-does-not-shadow-the-debug-verbosity-flag
  "--debug is the verbosity flag; `debug' is an optimization QUALITY VALUE.
The two live in different positions and must not be confused: --optimize
debug=0 asks for no instrumented fork and says nothing about verbosity."
  (let ((options (clautolisp.tools.clautolisp::parse-arguments
                  (list "--optimize" "debug=0" "-x" "(+ 1 2)"))))
    (is (equal '((:debug . 0))
               (clautolisp.autolisp-cli:cli-options-optimization options)))
    (is (eq :info (clautolisp.autolisp-cli:cli-options-verbosity options)))))
