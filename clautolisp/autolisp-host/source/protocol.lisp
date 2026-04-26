(in-package #:clautolisp.autolisp-host)

;;;; Host Abstraction Layer (HAL).
;;;;
;;;; Phase 8 of the implementation roadmap (see
;;;; clautolisp/documentation/implementation-roadmap.org).
;;;;
;;;; The HAL decouples *what* AutoLISP host-facing builtins do from
;;;; *where* their effects land. Each operation is defined as a
;;;; generic function on a single `host` object; backends supply
;;;; methods.
;;;;
;;;; Three backends are planned:
;;;;
;;;;   - NullHost  (this file) — every operation signals a structured
;;;;                              :host-not-supported runtime error.
;;;;                              Default for programs that exercise
;;;;                              only the language-level surface.
;;;;   - MockHost  (Phase 9)   — in-memory deterministic CAD
;;;;                              substrate.
;;;;   - LiveHost  (Phase 16)  — bridge to a live BricsCAD or
;;;;                              AutoCAD process.
;;;;
;;;; The dialect descriptor (clautolisp.autolisp-reader:autolisp-dialect)
;;;; controls language semantics and is *orthogonal* to the host
;;;; backend choice. A given runtime-session carries one of each.

(defclass host ()
  ((name :initarg :name
         :reader  host-name
         :initform "host"
         :type    string
         :documentation "Short identifying name printed in
diagnostics. Backends should override with a vendor-specific name."))
  (:documentation "Abstract base class for every clautolisp host
backend. Methods on `host` provide the AutoLISP host surface
(entities, selection sets, tables, sysvars, command dispatch,
graphics, interactive prompts). Subclasses are responsible for
specialising every method they support; the rest fall through to
the NULL-HOST default and signal :host-not-supported."))

(defun hostp (object)
  (typep object 'host))

;;; --- Standard helper for unsupported operations -------------------

(defun signal-host-not-supported (host operation)
  "Raise the standard runtime error for a host backend that does
not implement OPERATION."
  (signal-autolisp-runtime-error
   :host-not-supported
   "Host backend ~A does not support ~A."
   (host-name host)
   operation))

;;; --- Generic-function declarations ---------------------------------
;;;
;;; The signatures below are stable Phase-8 contract. New host
;;; surface added in later phases extends this list; existing
;;; signatures must not change without a documented migration in
;;; the implementation roadmap.

;; Entity API (autolisp-spec ch.16)
(defgeneric host-entget    (host ename)               (:documentation "Return the DXF group-code list for ENAME, or nil."))
(defgeneric host-entmod    (host group-code-list)     (:documentation "Apply changes to an existing entity from a DXF group-code list."))
(defgeneric host-entmake   (host group-code-list)     (:documentation "Create a new graphical entity from a DXF group-code list."))
(defgeneric host-entmakex  (host group-code-list)     (:documentation "Create a non-graphical entity (XRECORD etc.) from a DXF list."))
(defgeneric host-entdel    (host ename)               (:documentation "Delete or undelete an entity by ENAME."))
(defgeneric host-entupd    (host ename)               (:documentation "Force a redraw of ENAME after low-level mutation."))
(defgeneric host-entlast   (host)                     (:documentation "Return the ENAME of the last non-deleted entity, or nil."))
(defgeneric host-entnext   (host ename)               (:documentation "Return the ENAME after ENAME, or nil."))
(defgeneric host-handent   (host handle-string)       (:documentation "Resolve a hex handle string to an ENAME."))

;; Selection-set API
(defgeneric host-ssget       (host filter &key mode)  (:documentation "Acquire a selection set under MODE / FILTER."))
(defgeneric host-ssadd       (host pickset ename)     (:documentation "Add ENAME to PICKSET, returning the updated pickset."))
(defgeneric host-ssdel       (host pickset ename)     (:documentation "Remove ENAME from PICKSET."))
(defgeneric host-ssname      (host pickset index)     (:documentation "Return the ENAME at INDEX in PICKSET, or nil."))
(defgeneric host-sslength    (host pickset)           (:documentation "Return the cardinality of PICKSET as a non-negative integer."))
(defgeneric host-ssmemb      (host pickset ename)     (:documentation "True iff ENAME is a member of PICKSET."))
(defgeneric host-ssgetfirst  (host)                   (:documentation "Return the host's pickfirst selection."))
(defgeneric host-sssetfirst  (host pickset)           (:documentation "Set the host's pickfirst selection."))

;; Symbol tables (block, layer, ltype, style, view, ucs, vport, dimstyle, appid)
(defgeneric host-tblsearch  (host kind name)          (:documentation "Look up a table-record by KIND and NAME."))
(defgeneric host-tblnext    (host kind &key rewind)   (:documentation "Walk the named symbol table; REWIND restarts."))
(defgeneric host-tblobjname (host kind name)          (:documentation "Return the ENAME of the table-record with KIND/NAME."))

;; Named-object dictionaries
(defgeneric host-namedobjdict (host)                  (:documentation "Return the ENAME of the root named-object dictionary."))
(defgeneric host-dictsearch   (host dict-ename name &key next-after)
                                                       (:documentation "Look up an entry in a dictionary."))
(defgeneric host-dictnext     (host dict-ename &key rewind)
                                                       (:documentation "Walk the entries of a dictionary."))
(defgeneric host-dictadd      (host dict-ename name object-ename)
                                                       (:documentation "Add an entry to a dictionary."))
(defgeneric host-dictremove   (host dict-ename name)   (:documentation "Remove an entry from a dictionary."))
(defgeneric host-dictrename   (host dict-ename old new)(:documentation "Rename an entry in a dictionary."))

;; System variables
(defgeneric host-getvar (host name)                   (:documentation "Return the value of the named system variable."))
(defgeneric host-setvar (host name value)             (:documentation "Set the named system variable to VALUE; returns VALUE."))

;; Command dispatch
(defgeneric host-command (host arguments)             (:documentation "Issue an AutoLISP (command ...) sequence."))

;; Interactive prompts
(defgeneric host-prompt    (host string)              (:documentation "Display a prompt string."))
(defgeneric host-initget   (host bits keywords)       (:documentation "Apply per-call input-control flags to the next get* call."))
(defgeneric host-getstring (host prompt &key controls)(:documentation "Read a string from the user."))
(defgeneric host-getint    (host prompt &key controls)(:documentation "Read an integer from the user."))
(defgeneric host-getreal   (host prompt &key controls)(:documentation "Read a real from the user."))
(defgeneric host-getpoint  (host prompt &key base controls) (:documentation "Read a point from the user."))
(defgeneric host-getcorner (host prompt &key base controls) (:documentation "Read a rectangle corner from the user."))
(defgeneric host-getdist   (host prompt &key base controls) (:documentation "Read a distance from the user."))
(defgeneric host-getangle  (host prompt &key base controls) (:documentation "Read an angle from the user."))
(defgeneric host-getorient (host prompt &key base controls) (:documentation "Read an oriented angle from the user."))
(defgeneric host-getkword  (host prompt &key controls)(:documentation "Read a keyword from the user."))

;; Graphics
(defgeneric host-grdraw  (host from to colour highlight) (:documentation "Draw a transient line."))
(defgeneric host-grtext  (host kind text colour highlight)(:documentation "Display transient text."))
(defgeneric host-grvecs  (host vectors transform)        (:documentation "Display a transient vector list."))
(defgeneric host-grclear (host)                          (:documentation "Clear the transient graphics layer."))
(defgeneric host-grread  (host track key-press cursor)   (:documentation "Read a graphics-input event."))
(defgeneric host-redraw  (host ename mode)               (:documentation "Force a redraw of ENAME under the host's display mode."))

;; COM / Visual LISP COM bridge (autolisp-spec ch.19)
(defgeneric host-vlax-create-object       (host progid)            (:documentation "Create a new COM object by ProgID."))
(defgeneric host-vlax-get-object          (host progid)            (:documentation "Look up an existing running-instance COM object."))
(defgeneric host-vlax-release-object      (host vla-object)        (:documentation "Release a COM-object reference."))
(defgeneric host-vlax-get-property        (host vla-object name)   (:documentation "Read a property value from a COM object."))
(defgeneric host-vlax-put-property        (host vla-object name value) (:documentation "Write a property value to a COM object."))
(defgeneric host-vlax-invoke-method       (host vla-object name args)  (:documentation "Invoke a method on a COM object."))
(defgeneric host-vlax-property-available-p(host vla-object name)   (:documentation "True if NAME is an available property on the COM object."))
(defgeneric host-vlax-method-applicable-p (host vla-object name)   (:documentation "True if NAME is an applicable method on the COM object."))

;;; --- Base-class fallback methods --------------------------------
;;;
;;; Every operation has a default method on the base `host` class
;;; that signals :host-not-supported. This lets newly-introduced
;;; backends (e.g. MockHost in Phase 9) inherit a sensible "not
;;; yet implemented" failure shape, and lets future hosts override
;;; only the operations they support without writing an explicit
;;; not-supported method for the rest. NullHost overrides every
;;; method explicitly to pin its behaviour.

(defmethod host-entget    ((host host) ename)             (declare (ignore ename)) (signal-host-not-supported host 'entget))
(defmethod host-entmod    ((host host) glist)             (declare (ignore glist)) (signal-host-not-supported host 'entmod))
(defmethod host-entmake   ((host host) glist)             (declare (ignore glist)) (signal-host-not-supported host 'entmake))
(defmethod host-entmakex  ((host host) glist)             (declare (ignore glist)) (signal-host-not-supported host 'entmakex))
(defmethod host-entdel    ((host host) ename)             (declare (ignore ename)) (signal-host-not-supported host 'entdel))
(defmethod host-entupd    ((host host) ename)             (declare (ignore ename)) (signal-host-not-supported host 'entupd))
(defmethod host-entlast   ((host host))                   (signal-host-not-supported host 'entlast))
(defmethod host-entnext   ((host host) ename)             (declare (ignore ename)) (signal-host-not-supported host 'entnext))
(defmethod host-handent   ((host host) handle-string)     (declare (ignore handle-string)) (signal-host-not-supported host 'handent))
(defmethod host-ssget       ((host host) filter &key mode) (declare (ignore filter mode)) (signal-host-not-supported host 'ssget))
(defmethod host-ssadd       ((host host) pickset ename)   (declare (ignore pickset ename)) (signal-host-not-supported host 'ssadd))
(defmethod host-ssdel       ((host host) pickset ename)   (declare (ignore pickset ename)) (signal-host-not-supported host 'ssdel))
(defmethod host-ssname      ((host host) pickset index)   (declare (ignore pickset index)) (signal-host-not-supported host 'ssname))
(defmethod host-sslength    ((host host) pickset)         (declare (ignore pickset)) (signal-host-not-supported host 'sslength))
(defmethod host-ssmemb      ((host host) pickset ename)   (declare (ignore pickset ename)) (signal-host-not-supported host 'ssmemb))
(defmethod host-ssgetfirst  ((host host))                 (signal-host-not-supported host 'ssgetfirst))
(defmethod host-sssetfirst  ((host host) pickset)         (declare (ignore pickset)) (signal-host-not-supported host 'sssetfirst))
(defmethod host-tblsearch  ((host host) kind name)        (declare (ignore kind name)) (signal-host-not-supported host 'tblsearch))
(defmethod host-tblnext    ((host host) kind &key rewind) (declare (ignore kind rewind)) (signal-host-not-supported host 'tblnext))
(defmethod host-tblobjname ((host host) kind name)        (declare (ignore kind name)) (signal-host-not-supported host 'tblobjname))
(defmethod host-namedobjdict ((host host))                (signal-host-not-supported host 'namedobjdict))
(defmethod host-dictsearch   ((host host) dict name &key next-after) (declare (ignore dict name next-after)) (signal-host-not-supported host 'dictsearch))
(defmethod host-dictnext     ((host host) dict &key rewind) (declare (ignore dict rewind)) (signal-host-not-supported host 'dictnext))
(defmethod host-dictadd      ((host host) dict name object-ename) (declare (ignore dict name object-ename)) (signal-host-not-supported host 'dictadd))
(defmethod host-dictremove   ((host host) dict name)      (declare (ignore dict name)) (signal-host-not-supported host 'dictremove))
(defmethod host-dictrename   ((host host) dict old new)   (declare (ignore dict old new)) (signal-host-not-supported host 'dictrename))
(defmethod host-getvar ((host host) name)                 (declare (ignore name)) (signal-host-not-supported host 'getvar))
(defmethod host-setvar ((host host) name value)           (declare (ignore name value)) (signal-host-not-supported host 'setvar))
(defmethod host-command ((host host) arguments)           (declare (ignore arguments)) (signal-host-not-supported host 'command))
(defmethod host-prompt    ((host host) string)            (declare (ignore string)) (signal-host-not-supported host 'prompt))
(defmethod host-initget   ((host host) bits keywords)     (declare (ignore bits keywords)) (signal-host-not-supported host 'initget))
(defmethod host-getstring ((host host) prompt &key controls) (declare (ignore prompt controls)) (signal-host-not-supported host 'getstring))
(defmethod host-getint    ((host host) prompt &key controls) (declare (ignore prompt controls)) (signal-host-not-supported host 'getint))
(defmethod host-getreal   ((host host) prompt &key controls) (declare (ignore prompt controls)) (signal-host-not-supported host 'getreal))
(defmethod host-getpoint  ((host host) prompt &key base controls) (declare (ignore prompt base controls)) (signal-host-not-supported host 'getpoint))
(defmethod host-getcorner ((host host) prompt &key base controls) (declare (ignore prompt base controls)) (signal-host-not-supported host 'getcorner))
(defmethod host-getdist   ((host host) prompt &key base controls) (declare (ignore prompt base controls)) (signal-host-not-supported host 'getdist))
(defmethod host-getangle  ((host host) prompt &key base controls) (declare (ignore prompt base controls)) (signal-host-not-supported host 'getangle))
(defmethod host-getorient ((host host) prompt &key base controls) (declare (ignore prompt base controls)) (signal-host-not-supported host 'getorient))
(defmethod host-getkword  ((host host) prompt &key controls) (declare (ignore prompt controls)) (signal-host-not-supported host 'getkword))
(defmethod host-grdraw  ((host host) from to colour highlight) (declare (ignore from to colour highlight)) (signal-host-not-supported host 'grdraw))
(defmethod host-grtext  ((host host) kind text colour highlight) (declare (ignore kind text colour highlight)) (signal-host-not-supported host 'grtext))
(defmethod host-grvecs  ((host host) vectors transform) (declare (ignore vectors transform)) (signal-host-not-supported host 'grvecs))
(defmethod host-grclear ((host host)) (signal-host-not-supported host 'grclear))
(defmethod host-grread  ((host host) track key-press cursor) (declare (ignore track key-press cursor)) (signal-host-not-supported host 'grread))
(defmethod host-redraw  ((host host) ename mode) (declare (ignore ename mode)) (signal-host-not-supported host 'redraw))
(defmethod host-vlax-create-object        ((host host) progid)            (declare (ignore progid)) (signal-host-not-supported host 'vlax-create-object))
(defmethod host-vlax-get-object           ((host host) progid)            (declare (ignore progid)) (signal-host-not-supported host 'vlax-get-object))
(defmethod host-vlax-release-object       ((host host) vla-object)        (declare (ignore vla-object)) (signal-host-not-supported host 'vlax-release-object))
(defmethod host-vlax-get-property         ((host host) vla-object name)   (declare (ignore vla-object name)) (signal-host-not-supported host 'vlax-get-property))
(defmethod host-vlax-put-property         ((host host) vla-object name value) (declare (ignore vla-object name value)) (signal-host-not-supported host 'vlax-put-property))
(defmethod host-vlax-invoke-method        ((host host) vla-object name args) (declare (ignore vla-object name args)) (signal-host-not-supported host 'vlax-invoke-method))
(defmethod host-vlax-property-available-p ((host host) vla-object name)   (declare (ignore vla-object name)) (signal-host-not-supported host 'vlax-property-available-p))
(defmethod host-vlax-method-applicable-p  ((host host) vla-object name)   (declare (ignore vla-object name)) (signal-host-not-supported host 'vlax-method-applicable-p))
