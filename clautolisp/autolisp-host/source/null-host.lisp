(in-package #:clautolisp.autolisp-host)

;;;; NullHost — the trivial backend.
;;;;
;;;; Every operation signals :host-not-supported. This is the
;;;; default backend installed in a fresh runtime-session: programs
;;;; that exercise only the language-level surface (numeric, list,
;;;; string, control flow, error handling) keep working, while
;;;; programs that touch the CAD host fail loudly with a structured
;;;; runtime error pointing at the operation by name.

(defclass null-host (host)
  ()
  (:default-initargs :name "null-host")
  (:documentation "Default trivial host backend. Every CAD-facing
operation signals :host-not-supported."))

(defun make-null-host (&key (name "null-host"))
  (make-instance 'null-host :name name))

(defparameter *null-host* (make-null-host)
  "Process-wide singleton NullHost. Sessions that do not specify a
backend share this instance.")

;;; --- Method definitions ------------------------------------------
;;;
;;; Every method body just delegates to signal-host-not-supported.
;;; Spelling each one out (rather than via a macro) keeps eldoc /
;;; xref readable and makes future per-method overrides cheap.

;; Entity API
(defmethod host-entget ((host null-host) ename)
  (declare (ignore ename))
  (signal-host-not-supported host 'entget))

(defmethod host-entmod ((host null-host) group-code-list)
  (declare (ignore group-code-list))
  (signal-host-not-supported host 'entmod))

(defmethod host-entmake ((host null-host) group-code-list)
  (declare (ignore group-code-list))
  (signal-host-not-supported host 'entmake))

(defmethod host-entmakex ((host null-host) group-code-list)
  (declare (ignore group-code-list))
  (signal-host-not-supported host 'entmakex))

(defmethod host-entdel ((host null-host) ename)
  (declare (ignore ename))
  (signal-host-not-supported host 'entdel))

(defmethod host-entupd ((host null-host) ename)
  (declare (ignore ename))
  (signal-host-not-supported host 'entupd))

(defmethod host-entlast ((host null-host))
  (signal-host-not-supported host 'entlast))

(defmethod host-entnext ((host null-host) ename)
  (declare (ignore ename))
  (signal-host-not-supported host 'entnext))

(defmethod host-handent ((host null-host) handle-string)
  (declare (ignore handle-string))
  (signal-host-not-supported host 'handent))

;; Selection-set API
(defmethod host-ssget ((host null-host) filter &key mode)
  (declare (ignore filter mode))
  (signal-host-not-supported host 'ssget))

(defmethod host-ssadd ((host null-host) pickset ename)
  (declare (ignore pickset ename))
  (signal-host-not-supported host 'ssadd))

(defmethod host-ssdel ((host null-host) pickset ename)
  (declare (ignore pickset ename))
  (signal-host-not-supported host 'ssdel))

(defmethod host-ssname ((host null-host) pickset index)
  (declare (ignore pickset index))
  (signal-host-not-supported host 'ssname))

(defmethod host-sslength ((host null-host) pickset)
  (declare (ignore pickset))
  (signal-host-not-supported host 'sslength))

(defmethod host-ssmemb ((host null-host) pickset ename)
  (declare (ignore pickset ename))
  (signal-host-not-supported host 'ssmemb))

(defmethod host-ssgetfirst ((host null-host))
  (signal-host-not-supported host 'ssgetfirst))

(defmethod host-sssetfirst ((host null-host) pickset)
  (declare (ignore pickset))
  (signal-host-not-supported host 'sssetfirst))

;; Symbol tables
(defmethod host-tblsearch ((host null-host) kind name)
  (declare (ignore kind name))
  (signal-host-not-supported host 'tblsearch))

(defmethod host-tblnext ((host null-host) kind &key rewind)
  (declare (ignore kind rewind))
  (signal-host-not-supported host 'tblnext))

(defmethod host-tblobjname ((host null-host) kind name)
  (declare (ignore kind name))
  (signal-host-not-supported host 'tblobjname))

;; Dictionaries
(defmethod host-namedobjdict ((host null-host))
  (signal-host-not-supported host 'namedobjdict))

(defmethod host-dictsearch ((host null-host) dict name &key next-after)
  (declare (ignore dict name next-after))
  (signal-host-not-supported host 'dictsearch))

(defmethod host-dictnext ((host null-host) dict &key rewind)
  (declare (ignore dict rewind))
  (signal-host-not-supported host 'dictnext))

(defmethod host-dictadd ((host null-host) dict name object-ename)
  (declare (ignore dict name object-ename))
  (signal-host-not-supported host 'dictadd))

(defmethod host-dictremove ((host null-host) dict name)
  (declare (ignore dict name))
  (signal-host-not-supported host 'dictremove))

(defmethod host-dictrename ((host null-host) dict old new)
  (declare (ignore dict old new))
  (signal-host-not-supported host 'dictrename))

;; Sysvars
(defmethod host-getvar ((host null-host) name)
  (declare (ignore name))
  (signal-host-not-supported host 'getvar))

(defmethod host-setvar ((host null-host) name value)
  (declare (ignore name value))
  (signal-host-not-supported host 'setvar))

;; Command dispatch
(defmethod host-command ((host null-host) arguments)
  (declare (ignore arguments))
  (signal-host-not-supported host 'command))

;; Interactive prompts
(defmethod host-prompt ((host null-host) string)
  (declare (ignore string))
  (signal-host-not-supported host 'prompt))

(defmethod host-initget ((host null-host) bits keywords)
  (declare (ignore bits keywords))
  (signal-host-not-supported host 'initget))

(defmethod host-getstring ((host null-host) prompt &key controls)
  (declare (ignore prompt controls))
  (signal-host-not-supported host 'getstring))

(defmethod host-getint ((host null-host) prompt &key controls)
  (declare (ignore prompt controls))
  (signal-host-not-supported host 'getint))

(defmethod host-getreal ((host null-host) prompt &key controls)
  (declare (ignore prompt controls))
  (signal-host-not-supported host 'getreal))

(defmethod host-getpoint ((host null-host) prompt &key base controls)
  (declare (ignore prompt base controls))
  (signal-host-not-supported host 'getpoint))

(defmethod host-getcorner ((host null-host) prompt &key base controls)
  (declare (ignore prompt base controls))
  (signal-host-not-supported host 'getcorner))

(defmethod host-getdist ((host null-host) prompt &key base controls)
  (declare (ignore prompt base controls))
  (signal-host-not-supported host 'getdist))

(defmethod host-getangle ((host null-host) prompt &key base controls)
  (declare (ignore prompt base controls))
  (signal-host-not-supported host 'getangle))

(defmethod host-getorient ((host null-host) prompt &key base controls)
  (declare (ignore prompt base controls))
  (signal-host-not-supported host 'getorient))

(defmethod host-getkword ((host null-host) prompt &key controls)
  (declare (ignore prompt controls))
  (signal-host-not-supported host 'getkword))

;; Graphics
(defmethod host-grdraw ((host null-host) from to colour highlight)
  (declare (ignore from to colour highlight))
  (signal-host-not-supported host 'grdraw))

(defmethod host-grtext ((host null-host) kind text colour highlight)
  (declare (ignore kind text colour highlight))
  (signal-host-not-supported host 'grtext))

(defmethod host-grvecs ((host null-host) vectors transform)
  (declare (ignore vectors transform))
  (signal-host-not-supported host 'grvecs))

(defmethod host-grclear ((host null-host))
  (signal-host-not-supported host 'grclear))

(defmethod host-grread ((host null-host) track key-press cursor)
  (declare (ignore track key-press cursor))
  (signal-host-not-supported host 'grread))

(defmethod host-redraw ((host null-host) ename mode)
  (declare (ignore ename mode))
  (signal-host-not-supported host 'redraw))

;;; Install the NullHost singleton as the runtime's default backend
;;; on load. Downstream code may rebind *default-runtime-host* to
;;; switch — this is just the universal fallback.
(setf clautolisp.autolisp-runtime:*default-runtime-host* *null-host*)
