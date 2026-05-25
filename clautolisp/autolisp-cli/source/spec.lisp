(in-package #:clautolisp.autolisp-cli)

;;;; Option-spec datum + common option set shared by clautolisp and alfe.
;;;;
;;;; An option-spec describes one CLI option:
;;;;   LONGS         — list of long-option strings ("--load", "--ld"). May be ().
;;;;   SHORTS        — list of short-option strings ("-l", "-L"). May be ().
;;;;   TAKES-ARG-P   — true iff the option consumes a following value.
;;;;   HANDLER       — (lambda (cli-options value option-name) …) mutates
;;;;                   cli-options. VALUE is the consumed argument when
;;;;                   TAKES-ARG-P, nil otherwise. OPTION-NAME is the long
;;;;                   or short form actually seen (for error messages).
;;;;
;;;; The parser walks argv, dispatches by exact string match to the
;;;; first spec whose LONGS or SHORTS list contains the argument, and
;;;; invokes its HANDLER.
;;;;
;;;; *COMMON-OPTION-SPECS* is the intersection: everything both
;;;; clautolisp and alfe accept. Each tool prepends or appends its own
;;;; tool-specific specs.

(defstruct option-spec
  (longs nil :type list)
  (shorts nil :type list)
  (takes-arg-p nil :type boolean)
  (handler nil :type (or null function)))

(defun %make-common-option-specs ()
  "Build the common-option-specs list once at load time. Returned as
a fresh list so callers can DESTRUCTIVELY extend it with tool-specific
specs without mutating the shared template."
  (list
   ;; --- informational ---------------------------------------------
   (make-option-spec
    :longs '("--help") :shorts '("-h") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-help-p opts) t)))
   (make-option-spec
    :longs '("--version") :shorts '("-V") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-version-p opts) t)))

   ;; --- verbosity -------------------------------------------------
   (make-option-spec
    :longs '("--quiet") :shorts '("-q") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-verbosity opts) :warn)))
   (make-option-spec
    :longs '("--verbose") :shorts '("-v") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-verbosity opts) :verbose)))
   (make-option-spec
    :longs '("--debug") :shorts '("-d") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-verbosity opts) :debug)))

   ;; --- dialect ---------------------------------------------------
   (make-option-spec
    :longs '("--dialect") :shorts nil :takes-arg-p t
    :handler (lambda (opts value name)
               (setf (cli-options-dialect opts)
                     (parse-dialect value name))))
   (make-option-spec
    :longs '("--strict") :shorts nil :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-dialect opts) :strict)))
   (make-option-spec
    :longs '("--autocad") :shorts nil :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-dialect opts) :autocad-2026
                     (cli-options-backend opts) :autocad)))
   (make-option-spec
    :longs '("--bricscad") :shorts nil :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-dialect opts) :bricscad-v26
                     (cli-options-backend opts) :bricscad)))
   (make-option-spec
    :longs '("--clautolisp") :shorts nil :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-dialect opts) :clautolisp
                     (cli-options-backend opts) :clautolisp)))

   ;; --- host ------------------------------------------------------
   (make-option-spec
    :longs '("--host") :shorts nil :takes-arg-p t
    :handler (lambda (opts value name)
               (setf (cli-options-host opts) (parse-host value name))))

   ;; --- actions ---------------------------------------------------
   (make-option-spec
    :longs '("--load") :shorts '("-l") :takes-arg-p t
    :handler (lambda (opts value name)
               (declare (ignore name))
               (setf (cli-options-actions opts)
                     (append (cli-options-actions opts)
                             (list (cons :file value))))))
   (make-option-spec
    :longs '("--eval") :shorts '("-x") :takes-arg-p t
    :handler (lambda (opts value name)
               (declare (ignore name))
               (setf (cli-options-actions opts)
                     (append (cli-options-actions opts)
                             (list (cons :expression value))))))
   (make-option-spec
    :longs '("--interactive") :shorts '("-i") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-interactive-p opts) t)
               (setf (cli-options-actions opts)
                     (append (cli-options-actions opts)
                             (list (cons :interactive t))))))

   ;; --- encoding --------------------------------------------------
   (make-option-spec
    :longs nil :shorts '("-e") :takes-arg-p t
    :handler (lambda (opts value name)
               (declare (ignore name))
               (setf (cli-options-load-encoding opts) value)))
   (make-option-spec
    :longs nil :shorts '("-E") :takes-arg-p t
    :handler (lambda (opts value name)
               (declare (ignore name))
               (setf (cli-options-io-encoding opts) value)))

   ;; --- init files / colour --------------------------------------
   (make-option-spec
    :longs '("--no-init") :shorts '("-norc") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-no-init-p opts) t)))
   (make-option-spec
    :longs '("--no-color") :shorts nil :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-no-color-p opts) t)))))

(defparameter *common-option-specs* (%make-common-option-specs)
  "The intersection of CLI options accepted by both clautolisp and
alfe. Each tool builds its full spec list by appending its
tool-specific specs (alfe's --mode/--backend/--dwg/--epure/etc.;
clautolisp's --mock-input/--gui/--trace). Tools may also append
duplicate handlers — the first match wins, so prepending a custom
handler replaces the common one without removing it.")
