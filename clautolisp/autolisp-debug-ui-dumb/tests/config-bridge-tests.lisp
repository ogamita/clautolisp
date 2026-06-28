;;;; FiveAM tests for the CL <-> AutoLISP configuration bridge
;;;; (clautolisp.debug.ui config-bridge, command reference §8).

(in-package #:clautolisp.ui.dumb.tests)

(in-suite dumb-ui-suite)

(test bridge-value-conversion-roundtrip
  ;; the default CL config survives CL -> AutoLISP -> CL unchanged
  (let* ((cl clautolisp.debug.ui:*default-aldo-configuration*)
         (back (clautolisp.debug.ui:autolisp->cl-config
                (clautolisp.debug.ui:cl-config->autolisp cl))))
    (is (equal cl back))))

(test bridge-scalar-conversions
  (let ((al (clautolisp.debug.ui:cl-config->autolisp
             '((:navigator . :sexp) (:pager-height . 24)
               (:break-on-caught . nil) (:addr . "127.0.0.1")))))
    ;; keyword -> AutoLISP symbol, string -> autolisp-string, int/nil preserved
    (let ((back (clautolisp.debug.ui:autolisp->cl-config al)))
      (is (eq :sexp (cdr (assoc :navigator back))))
      (is (eql 24 (cdr (assoc :pager-height back))))
      (is (null (cdr (assoc :break-on-caught back))))
      (is (string= "127.0.0.1" (cdr (assoc :addr back))))))
  ;; T maps to the AutoLISP T symbol and back
  (is (eq t (clautolisp.debug.ui:autolisp->cl-config
             (clautolisp.debug.ui:cl-config->autolisp t)))))

(test bridge-variable-read-write
  (clautolisp.autolisp-runtime:reset-default-evaluation-context)
  ;; unbound initially
  (is (not (clautolisp.debug.ui:config-variable-bound-p)))
  (is (null (clautolisp.debug.ui:read-config-variable)))
  ;; write a CL config to the AutoLISP variable, read it back as CL
  (clautolisp.debug.ui:write-config-variable
   '((:navigator . :line) (:pager-height . 42)
     (:decorations (:current-pp :unicode (9205)) (:current-pp :ascii ">"))))
  (is (clautolisp.debug.ui:config-variable-bound-p))
  (let ((back (clautolisp.debug.ui:read-config-variable)))
    (is (eq :line (cdr (assoc :navigator back))))
    (is (eql 42 (cdr (assoc :pager-height back))))
    ;; nested decorations survive (code-point list + string)
    (is (member '(:current-pp :unicode (9205)) (cdr (assoc :decorations back))
                :test #'equal))
    (is (member '(:current-pp :ascii ">") (cdr (assoc :decorations back))
                :test #'equal))))

(test bridge-sync-from-and-to-variable
  (clautolisp.autolisp-runtime:reset-default-evaluation-context)
  (let ((clautolisp.debug.ui:*aldo-configuration*
          (copy-tree clautolisp.debug.ui:*default-aldo-configuration*)))
    ;; to-variable then read shows the working copy in the canonical store
    (clautolisp.debug.ui:set-aldo-setting "navigator" "line")
    (clautolisp.debug.ui:sync-config-to-variable)
    (is (eq :line (cdr (assoc :navigator (clautolisp.debug.ui:read-config-variable)))))
    ;; an AutoLISP-side change flows back in via from-variable
    (clautolisp.debug.ui:write-config-variable
     '((:navigator . :sexp) (:theme . :ascii)))
    (is (clautolisp.debug.ui:sync-config-from-variable))
    (is (eq :sexp (clautolisp.debug.ui:get-aldo-setting :navigator)))
    (is (eq :ascii (clautolisp.debug.ui:get-aldo-setting :theme)))))
