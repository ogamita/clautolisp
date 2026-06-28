;;;; Bridge between the debugger's CL working configuration (keyword alist) and
;;;; the canonical AutoLISP store *CLAL-ALDO-CONFIGURATION* (an AutoLISP assoc
;;;; list living in the runtime, persisted by the builtins-core clal-* builtins;
;;;; chosen layering, command reference §8).
;;;;
;;;; The debugger keeps a CL working copy (for the renderer / validation / TUI)
;;;; and keeps it in sync with the canonical AutoLISP variable: changes made in
;;;; AutoLISP (rc/init files, the REPL, clal-load-aldo-configuration) flow IN via
;;;; SYNC-CONFIG-FROM-VARIABLE; changes made through `set' flow OUT via
;;;; SYNC-CONFIG-TO-VARIABLE.  Uses the runtime only (no builtins-core
;;;; dependency); the variable is read/written through a current evaluation
;;;; context.

(in-package #:clautolisp.debug.ui)

(defparameter +aldo-config-variable-name+ "*CLAL-ALDO-CONFIGURATION*")

(defun aldo-config-variable-symbol ()
  (clautolisp.autolisp-runtime:intern-autolisp-symbol +aldo-config-variable-name+))

;;; --- value conversion -------------------------------------------------

(defun %al->cl (object)
  "Convert an AutoLISP runtime value to the CL working representation: a symbol
named T / NIL maps to CL T / NIL, any other symbol to an upper-cased keyword; an
AutoLISP string to a CL string; numbers and conses are preserved structurally."
  (cond
    ((null object) nil)
    ((typep object 'clautolisp.autolisp-runtime:autolisp-symbol)
     (let ((name (string-upcase
                  (clautolisp.autolisp-runtime:autolisp-symbol-name object))))
       (cond ((string= name "NIL") nil)
             ((string= name "T") t)
             (t (intern name :keyword)))))
    ((typep object 'clautolisp.autolisp-runtime:autolisp-string)
     (clautolisp.autolisp-runtime:autolisp-string-value object))
    ((consp object) (cons (%al->cl (car object)) (%al->cl (cdr object))))
    (t object)))

(defun %cl->al (object)
  "Inverse of %AL->CL: a keyword becomes an AutoLISP symbol (its upper-cased
name); CL T becomes the AutoLISP symbol T; a CL string an AutoLISP string;
numbers / NIL / conses are preserved structurally."
  (cond
    ((null object) nil)
    ((eq object t) (clautolisp.autolisp-runtime:intern-autolisp-symbol "T"))
    ((keywordp object)
     (clautolisp.autolisp-runtime:intern-autolisp-symbol
      (string-upcase (symbol-name object))))
    ((stringp object) (clautolisp.autolisp-runtime:make-autolisp-string object))
    ((consp object) (cons (%cl->al (car object)) (%cl->al (cdr object))))
    (t object)))

(defun autolisp->cl-config (al-config) (%al->cl al-config))
(defun cl-config->autolisp (cl-config) (%cl->al cl-config))

;;; --- the canonical variable -------------------------------------------

(defun config-variable-bound-p ()
  "True when *CLAL-ALDO-CONFIGURATION* has a value in the current context."
  (clautolisp.autolisp-runtime:autolisp-symbol-value-bound-p
   (aldo-config-variable-symbol)))

(defun read-config-variable ()
  "The canonical configuration as a CL keyword alist, or NIL when the AutoLISP
variable is unbound."
  (when (config-variable-bound-p)
    (%al->cl (clautolisp.autolisp-runtime:autolisp-symbol-value
              (aldo-config-variable-symbol)))))

(defun write-config-variable (cl-config)
  "Set *CLAL-ALDO-CONFIGURATION* from the CL alist CL-CONFIG; returns CL-CONFIG."
  (clautolisp.autolisp-runtime:set-variable
   (aldo-config-variable-symbol) (%cl->al cl-config))
  cl-config)

;;; --- syncing the working copy with the canonical variable -------------

(defun sync-config-from-variable ()
  "If the canonical AutoLISP variable is bound, replace the CL working
configuration *ALDO-CONFIGURATION* with its converted value. Returns T when a
sync happened. (Lets rc/init/REPL edits to *CLAL-ALDO-CONFIGURATION* take
effect in the debugger.)"
  (when (config-variable-bound-p)
    (setf *aldo-configuration* (read-config-variable))
    t))

(defun sync-config-to-variable ()
  "Write the CL working configuration *ALDO-CONFIGURATION* out to the canonical
AutoLISP variable. Returns the configuration written."
  (write-config-variable *aldo-configuration*))
