(in-package #:clautolisp.autolisp-host)

;;;; NullHost — the trivial backend.
;;;;
;;;; Every operation signals :host-not-supported. This is the
;;;; default backend installed in a fresh runtime-session: programs
;;;; that exercise only the language-level surface (numeric, list,
;;;; string, control flow, error handling) keep working, while
;;;; programs that touch the CAD host fail loudly with a structured
;;;; runtime error pointing at the operation by name.

(defclass nihil (host)
  ()
  (:default-initargs :name "nihil")
  (:documentation "Default trivial host backend. Every CAD-facing
operation signals :host-not-supported."))

(defun make-nihil (&key (name "nihil"))
  (make-instance 'nihil :name name))

(defparameter *nihil* (make-nihil)
  "Process-wide singleton NullHost. Sessions that do not specify a
backend share this instance.")

;;; --- Method definitions ------------------------------------------
;;;
;;; Every method body just delegates to signal-host-not-supported.
;;; Spelling each one out (rather than via a macro) keeps eldoc /
;;; xref readable and makes future per-method overrides cheap.

;; Entity API
(defmethod host-entget ((host nihil) ename &optional applist)
  (declare (ignore ename applist))
  (signal-host-not-supported host 'entget))

(defmethod host-entmod ((host nihil) group-code-list)
  (declare (ignore group-code-list))
  (signal-host-not-supported host 'entmod))

(defmethod host-entmake ((host nihil) group-code-list)
  (declare (ignore group-code-list))
  (signal-host-not-supported host 'entmake))

(defmethod host-entmakex ((host nihil) group-code-list)
  (declare (ignore group-code-list))
  (signal-host-not-supported host 'entmakex))

(defmethod host-entdel ((host nihil) ename)
  (declare (ignore ename))
  (signal-host-not-supported host 'entdel))

(defmethod host-entupd ((host nihil) ename)
  (declare (ignore ename))
  (signal-host-not-supported host 'entupd))

(defmethod host-entlast ((host nihil))
  (signal-host-not-supported host 'entlast))

(defmethod host-entnext ((host nihil) ename)
  (declare (ignore ename))
  (signal-host-not-supported host 'entnext))

(defmethod host-handent ((host nihil) handle-string)
  (declare (ignore handle-string))
  (signal-host-not-supported host 'handent))

;; Selection-set API
(defmethod host-ssget ((host nihil) filter &key mode)
  (declare (ignore filter mode))
  (signal-host-not-supported host 'ssget))

(defmethod host-ssadd ((host nihil) pickset ename)
  (declare (ignore pickset ename))
  (signal-host-not-supported host 'ssadd))

(defmethod host-ssdel ((host nihil) pickset ename)
  (declare (ignore pickset ename))
  (signal-host-not-supported host 'ssdel))

(defmethod host-ssname ((host nihil) pickset index)
  (declare (ignore pickset index))
  (signal-host-not-supported host 'ssname))

(defmethod host-sslength ((host nihil) pickset)
  (declare (ignore pickset))
  (signal-host-not-supported host 'sslength))

(defmethod host-ssmemb ((host nihil) pickset ename)
  (declare (ignore pickset ename))
  (signal-host-not-supported host 'ssmemb))

(defmethod host-ssgetfirst ((host nihil))
  (signal-host-not-supported host 'ssgetfirst))

(defmethod host-sssetfirst ((host nihil) pickset)
  (declare (ignore pickset))
  (signal-host-not-supported host 'sssetfirst))

;; Symbol tables
(defmethod host-tblsearch ((host nihil) kind name)
  (declare (ignore kind name))
  (signal-host-not-supported host 'tblsearch))

(defmethod host-tblnext ((host nihil) kind &key rewind)
  (declare (ignore kind rewind))
  (signal-host-not-supported host 'tblnext))

(defmethod host-tblobjname ((host nihil) kind name)
  (declare (ignore kind name))
  (signal-host-not-supported host 'tblobjname))

;; Dictionaries
(defmethod host-namedobjdict ((host nihil))
  (signal-host-not-supported host 'namedobjdict))

(defmethod host-dictsearch ((host nihil) dict name &key next-after)
  (declare (ignore dict name next-after))
  (signal-host-not-supported host 'dictsearch))

(defmethod host-dictnext ((host nihil) dict &key rewind)
  (declare (ignore dict rewind))
  (signal-host-not-supported host 'dictnext))

(defmethod host-dictadd ((host nihil) dict name object-ename)
  (declare (ignore dict name object-ename))
  (signal-host-not-supported host 'dictadd))

(defmethod host-dictremove ((host nihil) dict name)
  (declare (ignore dict name))
  (signal-host-not-supported host 'dictremove))

(defmethod host-dictrename ((host nihil) dict old new)
  (declare (ignore dict old new))
  (signal-host-not-supported host 'dictrename))

;; Sysvars
(defmethod host-getvar ((host nihil) name)
  (declare (ignore name))
  (signal-host-not-supported host 'getvar))

(defmethod host-setvar ((host nihil) name value)
  (declare (ignore name value))
  (signal-host-not-supported host 'setvar))

(defmethod host-set-derived-sysvar ((host nihil) name value)
  ;; Silent no-op rather than signalling: the launch-time wiring
  ;; calls this unconditionally; nihil has no sysvar table
  ;; to update and that's fine.
  (declare (ignore name value))
  nil)

(defmethod host-define-sysvar ((host nihil) name kind value read-only-p)
  ;; Silent no-op for the same reason as host-set-derived-sysvar: the
  ;; dialect-trust-default launch wiring calls this unconditionally and
  ;; nihil has no sysvar table to populate.
  (declare (ignore name kind value read-only-p))
  nil)

(defmethod host-undefine-sysvar ((host nihil) name)
  ;; Silent no-op for the same reason as host-define-sysvar: the
  ;; dialect sysvar-overlay launch wiring calls this unconditionally and
  ;; nihil has no sysvar table to drop entries from.
  (declare (ignore name))
  nil)

(defmethod host-sysvar-names ((host nihil))
  (signal-host-not-supported host 'sysvar-names))

;; Command dispatch
(defmethod host-command ((host nihil) arguments)
  (declare (ignore arguments))
  (signal-host-not-supported host 'command))

(defmethod host-command-log ((host nihil))
  (signal-host-not-supported host 'command-log))

;; Interactive prompts
(defmethod host-prompt ((host nihil) string)
  (declare (ignore string))
  (signal-host-not-supported host 'prompt))

(defmethod host-initget ((host nihil) bits keywords)
  (declare (ignore bits keywords))
  (signal-host-not-supported host 'initget))

(defmethod host-getstring ((host nihil) prompt &key controls)
  (declare (ignore prompt controls))
  (signal-host-not-supported host 'getstring))

(defmethod host-getint ((host nihil) prompt &key controls)
  (declare (ignore prompt controls))
  (signal-host-not-supported host 'getint))

(defmethod host-getreal ((host nihil) prompt &key controls)
  (declare (ignore prompt controls))
  (signal-host-not-supported host 'getreal))

(defmethod host-getpoint ((host nihil) prompt &key base controls)
  (declare (ignore prompt base controls))
  (signal-host-not-supported host 'getpoint))

(defmethod host-getcorner ((host nihil) prompt &key base controls)
  (declare (ignore prompt base controls))
  (signal-host-not-supported host 'getcorner))

(defmethod host-getdist ((host nihil) prompt &key base controls)
  (declare (ignore prompt base controls))
  (signal-host-not-supported host 'getdist))

(defmethod host-getangle ((host nihil) prompt &key base controls)
  (declare (ignore prompt base controls))
  (signal-host-not-supported host 'getangle))

(defmethod host-getorient ((host nihil) prompt &key base controls)
  (declare (ignore prompt base controls))
  (signal-host-not-supported host 'getorient))

(defmethod host-getkword ((host nihil) prompt &key controls)
  (declare (ignore prompt controls))
  (signal-host-not-supported host 'getkword))

;; Graphics
(defmethod host-grdraw ((host nihil) from to colour highlight)
  (declare (ignore from to colour highlight))
  (signal-host-not-supported host 'grdraw))

(defmethod host-grtext ((host nihil) kind text colour highlight)
  (declare (ignore kind text colour highlight))
  (signal-host-not-supported host 'grtext))

(defmethod host-grvecs ((host nihil) vectors transform)
  (declare (ignore vectors transform))
  (signal-host-not-supported host 'grvecs))

(defmethod host-grclear ((host nihil))
  (signal-host-not-supported host 'grclear))

(defmethod host-grread ((host nihil) track key-press cursor)
  (declare (ignore track key-press cursor))
  (signal-host-not-supported host 'grread))

(defmethod host-redraw ((host nihil) ename mode)
  (declare (ignore ename mode))
  (signal-host-not-supported host 'redraw))

;;; Install the NullHost singleton as the runtime's default backend
;;; on load. Downstream code may rebind *default-runtime-host* to
;;; switch — this is just the universal fallback.
(setf clautolisp.autolisp-runtime:*default-runtime-host* *nihil*)

;;; Wire the runtime's COMMAND special form to the HAL command
;;; channel. The runtime cannot name HOST-COMMAND itself (it sits
;;; below this system in the dependency order), so it routes through
;;; this hook — installed once here, alongside the default-backend
;;; install above.
(setf clautolisp.autolisp-runtime:*host-command-function* #'host-command)
