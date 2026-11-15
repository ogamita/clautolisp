(in-package #:clautolisp.autolisp-cli)

;;;; Option defaults from the environment (cli-option-environment-defaults).
;;;;
;;;; An option that sets run state can take its default from an environment
;;;; variable, for the callers that cannot -- or should not -- edit every
;;;; command line (CI jobs, daemons, wrappers). The precedence is, for an
;;;; option both programs share:
;;;;
;;;;     command line  >  CLAUTOLISP_<X> / ALFE_<X>  >  AUTOLISP_<X>  >  default
;;;;
;;;; AUTOLISP_<X> is read by both programs alike; CLAUTOLISP_<X> overrides it
;;;; for the clautolisp program only, ALFE_<X> for alfe only. An option of one
;;;; program has only its program's variable (CLAUTOLISP_TRACE, ALFE_CAD).
;;;;
;;;; The unit is the option GROUP, not the option: --strict, --lax and
;;;; --dialect are one group, so any of them on the command line keeps
;;;; AUTOLISP_DIALECT out. Each option-spec names its group
;;;; (OPTION-SPEC-ENVIRONMENT); the parser records the groups the command line
;;;; set; APPLY-ENVIRONMENT-DEFAULTS then fills the others.
;;;;
;;;; Two kinds of group are LAYERED instead (OPTION-SPEC-ENVIRONMENT-LAYER-P):
;;;; the -E encodings and their replacements, and -O. Their options combine
;;;; (a bare -E and a -Esource; -O speed=3 -O debug=0), so "the group was
;;;; given" is no answer: the environment fills a layer of its own, below the
;;;; whole command line, and the resolvers consult it last.
;;;;
;;;; An empty variable is an unset one. An invalid value is a usage error
;;;; naming the VARIABLE (each option's own parser, given the variable's name
;;;; where it would get the option's), never silently ignored.
;;;;
;;;; A clautolisp program driven by a front end (--front-end-bindings: alfe
;;;; --backend subprocess) does not read these variables at all: alfe
;;;; resolved them already, from its own environment, and handed over the
;;;; result on the child's command line. Reading them again would let a
;;;; CLAUTOLISP_<X> meant for the user's own clautolisp runs contradict alfe.

(defparameter *option-environment-groups*
  '(;; (GROUP SUFFIX SCOPE)
    ;; SCOPE :SHARED      -> AUTOLISP_<SUFFIX>, overridden by CLAUTOLISP_<SUFFIX>
    ;;                       (clautolisp) and ALFE_<SUFFIX> (alfe);
    ;; SCOPE :CLAUTOLISP  -> CLAUTOLISP_<SUFFIX> only;
    ;; SCOPE :ALFE        -> ALFE_<SUFFIX> only.
    ;; scripts/check-user-visible-documentation.py reads this table: keep
    ;; every entry on one line, in this shape.
    (:host                              "HOST"                              :shared)
    (:dialect                           "DIALECT"                           :shared)
    (:verbosity                         "VERBOSITY"                         :shared)
    (:dwg                               "DWG"                               :shared)
    (:dcl                               "DCL"                               :shared)
    (:dribble                           "DRIBBLE"                           :shared)
    (:dribble-interactors               "DRIBBLE_INTERACTORS"               :shared)
    (:on-error                          "ON_ERROR"                          :shared)
    (:on-interrupt                      "ON_INTERRUPT"                      :shared)
    (:on-quit                           "ON_QUIT"                           :shared)
    (:debugger-ui                       "DEBUGGER_UI"                       :shared)
    (:aldb-listen                       "ALDB_LISTEN"                       :shared)
    (:encoding                          "ENCODING"                          :shared)
    (:source-encoding                   "SOURCE_ENCODING"                   :shared)
    (:file-encoding                     "FILE_ENCODING"                     :shared)
    (:file-read-encoding                "FILE_READ_ENCODING"                :shared)
    (:file-write-encoding               "FILE_WRITE_ENCODING"               :shared)
    (:console-encoding                  "CONSOLE_ENCODING"                  :shared)
    (:console-in-encoding               "CONSOLE_IN_ENCODING"               :shared)
    (:console-out-encoding              "CONSOLE_OUT_ENCODING"              :shared)
    (:cadstdio-encoding                 "CADSTDIO_ENCODING"                 :shared)
    (:cadstdio-in-encoding              "CADSTDIO_IN_ENCODING"              :shared)
    (:cadstdio-out-encoding             "CADSTDIO_OUT_ENCODING"             :shared)
    (:log-encoding                      "LOG_ENCODING"                      :shared)
    (:terminal-encoding                 "TERMINAL_ENCODING"                 :shared)
    (:terminal-in-encoding              "TERMINAL_IN_ENCODING"              :shared)
    (:terminal-out-encoding             "TERMINAL_OUT_ENCODING"             :shared)
    (:encoding-replacement              "ENCODING_REPLACEMENT"              :shared)
    (:file-write-encoding-replacement   "FILE_WRITE_ENCODING_REPLACEMENT"   :shared)
    (:terminal-out-encoding-replacement "TERMINAL_OUT_ENCODING_REPLACEMENT" :shared)
    (:trace                             "TRACE"                             :clautolisp)
    (:optimize                          "OPTIMIZE"                          :clautolisp)
    (:cad                               "CAD"                               :alfe)
    (:backend-variant                   "BACKEND_VARIANT"                   :alfe))
  "The option groups that take a default from the environment, with the
suffix of their variables and who reads them. See the comment above.")

(defun %program-prefix (program)
  (ecase program
    (:clautolisp "CLAUTOLISP_")
    (:alfe "ALFE_")))

(defun option-environment-variables (group program)
  "The variables PROGRAM (:CLAUTOLISP or :ALFE) reads for GROUP, the first
winning: (\"CLAUTOLISP_HOST\" \"AUTOLISP_HOST\"), (\"CLAUTOLISP_TRACE\"), or
NIL when PROGRAM reads none for it."
  (let ((entry (assoc group *option-environment-groups*)))
    (when entry
      (destructuring-bind (suffix scope) (rest entry)
        (cond ((eq scope :shared)
               (list (concatenate 'string (%program-prefix program) suffix)
                     (concatenate 'string "AUTOLISP_" suffix)))
              ((eq scope program)
               (list (concatenate 'string (%program-prefix program) suffix))))))))

(defun option-environment-variable-names (&optional program)
  "Every option-default variable PROGRAM reads (both programs' when PROGRAM
is NIL), without duplicates: for a sandbox to clear, or documentation to
list."
  (let ((names '()))
    (dolist (entry *option-environment-groups* (nreverse names))
      (dolist (p (if program (list program) '(:clautolisp :alfe)))
        (dolist (name (option-environment-variables (first entry) p))
          (pushnew name names :test #'string=))))))

(defun %getenv-nonempty (name)
  (let ((value (uiop:getenv name)))
    (and value (plusp (length value)) value)))

(defvar *environment-getenv* '%getenv-nonempty
  "The function APPLY-ENVIRONMENT-DEFAULTS reads a variable with: NAME ->
its value, or NIL when unset or empty. Tests bind it to read a table instead
of the process environment.")

(defun %environment-value (variables)
  "The value of the first set variable of VARIABLES, and its name."
  (dolist (variable variables (values nil nil))
    (let ((value (funcall *environment-getenv* variable)))
      (when (and value (plusp (length value)))
        (return (values value variable))))))

(defparameter *environment-true-words* '("1" "y" "yes" "true" "on" "t"))
(defparameter *environment-false-words* '("0" "n" "no" "false" "off" "nil"))

(defun %environment-boolean-word (value)
  "T, NIL, or :NEITHER for VALUE, a boolean environment word."
  (cond ((member value *environment-true-words* :test #'string-equal) t)
        ((member value *environment-false-words* :test #'string-equal) nil)
        (t :neither)))

(defun environment-boolean (value variable)
  "VALUE of the boolean VARIABLE as T or NIL; a usage error naming VARIABLE
when it is neither (1, y, yes, true, on / 0, n, no, false, off)."
  (let ((b (%environment-boolean-word value)))
    (when (eq b :neither)
      (error 'cli-usage-error
             :option variable
             :message (format nil "~A=~A is not a boolean (expected 1, yes, true, on, or 0, no, false, off)"
                              variable value)))
    b))

(defun %environment-primary-spec (group-specs)
  "The spec through which a group's environment value is applied: the first
with an ENVIRONMENT-HANDLER, else the first that takes a value, else the first
(a boolean flag). GROUP-SPECS are in the parser's order, so a program's own
spec shadows the shared one exactly as on the command line."
  (or (find-if #'option-spec-environment-handler group-specs)
      (find-if #'option-spec-takes-arg-p group-specs)
      (first group-specs)))

(defun %apply-environment-value (spec options value variable)
  (let ((handler (option-spec-handler spec)))
    (cond ((option-spec-environment-handler spec)
           (funcall (option-spec-environment-handler spec) options value variable))
          ((and (option-spec-takes-arg-p spec) (option-spec-optional-arg-p spec))
           ;; --dribble: a boolean (the default file, or none), or the value.
           (case (%environment-boolean-word value)
             ((t)   (funcall handler options nil variable))
             ((nil) nil)
             (t     (funcall handler options value variable))))
          ((option-spec-takes-arg-p spec)
           (funcall handler options value variable))
          (t
           (when (environment-boolean value variable)
             (funcall handler options nil variable))))))

(defun apply-environment-defaults (options specs program)
  "Fill OPTIONS from the environment, after the command line was parsed into
it with SPECS: for each group of *OPTION-ENVIRONMENT-GROUPS* that SPECS has
and PROGRAM (:CLAUTOLISP or :ALFE) reads, the first set variable, unless the
command line set the group (a layered group always: it writes a layer below
the command line). Records (GROUP . VARIABLE) in
CLI-OPTIONS-ENVIRONMENT-SOURCES. Returns OPTIONS."
  (dolist (entry *option-environment-groups* options)
    (let* ((group (first entry))
           (variables (option-environment-variables group program))
           (group-specs (and variables
                             (remove group specs :key #'option-spec-environment
                                                 :test-not #'eq))))
      (when group-specs
        (let ((spec (%environment-primary-spec group-specs)))
          (when (or (option-spec-environment-layer-p spec)
                    (not (member group (cli-options-given-environment-groups options))))
            (multiple-value-bind (value variable) (%environment-value variables)
              (when value
                (%apply-environment-value spec options value variable)
                (push (cons group variable)
                      (cli-options-environment-sources options))))))))))

(defun option-environment-source (options group)
  "The variable that set GROUP in OPTIONS, or NIL (the command line or the
default did)."
  (and (not (member group (cli-options-given-environment-groups options)))
       (cdr (assoc group (cli-options-environment-sources options)))))
