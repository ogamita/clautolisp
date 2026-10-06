;;;; -*- mode:lisp; coding:utf-8 -*-
;;;;
;;;; The option contract of alfe's clautolisp backend
;;;; (alfe-clautolisp-backend-semantic-parity.issue). Kept apart from
;;;; backend-clautolisp.lisp because it NAMES every option alfe accepts --
;;;; most of which are not transmitted to any engine.

(in-package #:alfe.backend.clautolisp)

;;; --- the option contract of the clautolisp backend -----------------
;;;
;;; alfe-clautolisp-backend-semantic-parity.issue: `--backend direct' and
;;; `--backend subprocess' are two transports for ONE engine, so every option
;;; alfe accepts with --clautolisp must mean the same thing under both. This
;;; table is where each option's treatment is written down ONCE. The test
;;; suite (backend-clautolisp-tests.lisp) fails when alfe's parser accepts an
;;; option this table does not classify, or classifies one the parser no
;;; longer accepts -- so a new shared option cannot be added without deciding
;;; how both variants consume it -- and runs the :ENGINE options through both
;;; variants, comparing what a program observes.
;;;
;;; Dispositions:
;;;   :FRONT-END  consumed by alfe itself, before either engine starts, so it
;;;               cannot differ between the variants;
;;;   :ENGINE     consumed by the engine, by both variants, to the same effect
;;;               (direct: in-process; subprocess: forwarded to the child);
;;;   :NO-EFFECT  accepted, and neither variant acts on it (CAD-only options);
;;;               identical by construction;
;;;   :DIVERGENT  KNOWN to behave differently in the two variants -- the
;;;               remaining work of the ticket. Each entry says how.

(defparameter *clautolisp-option-contract*
  '(;; informational, answered before any engine exists
    ("--help"               :front-end "alfe's usage")
    ("--version"            :front-end "alfe's version")
    ("--list-encodings"     :front-end "printed by alfe")
    ("--list-dialects"      :front-end "printed by alfe")
    ("--list-situations"    :front-end "printed by alfe")
    ("--list-hosts"         :front-end "printed by alfe")
    ("--list-cad-programs"  :front-end "printed by alfe")
    ("--list-plugins"       :front-end "printed by alfe")
    ("--compile-plugin"     :front-end "alfe compiles the plug-in")
    ("--dry-run"            :front-end "alfe prints the plan; no engine")
    ("--print-command"      :front-end "usage error for --clautolisp, both variants")
    ;; backend / variant selection
    ("--clautolisp"         :front-end "selects the backend")
    ("--autocad"            :front-end "selects another backend")
    ("--bricscad"           :front-end "selects another backend")
    ("--cad"                :front-end "selects a CAD backend")
    ("--backend"            :front-end "selects the variant itself")
    ;; alfe run machinery
    ("--workdir"            :front-end "alfe's workdir; *AUTOLISP-WORKDIR* via the shared bindings")
    ("--keep-workdir"       :front-end "alfe's workdir cleanup")
    ("--write-workdir-path" :front-end "written by alfe")
    ("--plugin"             :front-end "alfe plug-ins; *AUTOLISP-PLUGIN-OPTIONS* via the shared bindings")
    ("--plugin-path"        :front-end "alfe plug-ins")
    ("--no-plugins"         :front-end "alfe plug-ins")
    ("--on-error"           :front-end "reporting of alfe's OWN unexpected conditions")
    ("--quiet"              :front-end "alfe's log level; *AUTOLISP-QUIET* via the shared bindings (the child runs --quiet)")
    ("--verbose"            :front-end "alfe's log level; *AUTOLISP-VERBOSE* via the shared bindings")
    ("--debug"              :front-end "alfe's log level; *AUTOLISP-DEBUG* via the shared bindings")
    ("--no-init"            :front-end "alfe resolves its init files into -l actions of the plan (the child runs --no-init)")
    ;; the engine
    ("--dialect"            :engine "direct: RESOLVE-CLAUTOLISP-DIALECT; subprocess: --dialect NAME")
    ("--strict"             :engine "as --dialect strict")
    ("--lax"                :engine "as --dialect lax")
    ("--host"               :engine "direct: RESOLVE-CLAUTOLISP-HOST; subprocess: --host NAME (cadtui: subprocess only, --backend direct is a usage error)")
    ("--dwg"                :engine "direct: HOST-OPEN-STARTUP-DRAWING with the DWG codec loaded; subprocess: --dwg FILE; same message and status when unreadable")
    ("--load"               :engine "direct: in-process load binding *AUTOLISP-LOAD-PATHNAME*; subprocess: -l")
    ("--eval"               :engine "direct: in-process, binding *AUTOLISP-EXPRESSION*; subprocess: -x")
    ("--main"               :engine "both: evaluated as -x \"(NAME)\"")
    ("--quit"               :engine "ends the plan; implicit in the child")
    ("--no-color"           :engine "direct: *COLOR-OUTPUT*; subprocess: $NO_COLOR")
    ("--encoding"           :engine "every situation below")
    ("--source-encoding"    :engine "direct: session default source encoding; subprocess: -Esource")
    ("--file-encoding"      :engine "direct: *AUTOLISP-FILE-READ/WRITE-ENCODING*; subprocess: -Efile-read/-write")
    ("--file-read-encoding" :engine "as --file-encoding, read side")
    ("--file-write-encoding" :engine "as --file-encoding, write side")
    ("--log-encoding"       :engine "direct: *AUTOLISP-LOG-ENCODING*; subprocess: -Elog")
    ("--terminal-encoding"  :engine "direct: alfe's own streams; subprocess: -Eterminal-in/-out and the capture decoding")
    ("--terminal-input-encoding"  :engine "as --terminal-encoding, input side")
    ("--terminal-output-encoding" :engine "as --terminal-encoding, output side")
    ("--console-encoding"   :engine "the engine's console IS its terminal: folded into --terminal-encoding")
    ("--console-input-encoding"  :engine "folded into --terminal-input-encoding")
    ("--console-output-encoding" :engine "folded into --terminal-output-encoding")
    ;; accepted, acted on by neither variant
    ("--mode"               :no-effect "CAD launch mode")
    ("--bootstrap-phase"    :no-effect "CAD bootstrap truncation")
    ("--timeout"            :no-effect "no per-action timeout in either variant; *AUTOLISP-TIMEOUT* via the shared bindings")
    ("--cadstdio-encoding"  :no-effect "no CAD subprocess pipes")
    ("--cadstdio-input-encoding"  :no-effect "no CAD subprocess pipes")
    ("--cadstdio-output-encoding" :no-effect "no CAD subprocess pipes")
    ;; the remaining work
    ("--interactive"        :divergent "direct: alfe's minimal `alfe> ' REPL; subprocess: the clautolisp REPL (interactors, comma commands, and the aldo debugger on an error)")
    ("--dribble"            :divergent "direct: warns and records nothing; subprocess: forwarded, the engine records its REPL")
    ("--dribble-interactors" :divergent "as --dribble")
    ("--dcl"                :divergent "ignored by both variants, but only the subprocess engine has a DCL implementation (autolisp-dcl and its renderer selection are the clautolisp program's)"))
  "The treatment of every option alfe accepts, under --clautolisp, by the two
engine variants: (LONG-NAME DISPOSITION HOW). See the comment above.")

(defun clautolisp-option-disposition (long-name)
  "The disposition of the option LONG-NAME in *CLAUTOLISP-OPTION-CONTRACT*,
or NIL when the contract does not classify it."
  (second (assoc long-name *clautolisp-option-contract* :test #'string=)))
