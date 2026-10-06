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
;;;   :PROGRAM    needs the clautolisp PROGRAM's own machinery (its REPL,
;;;               recorder, DCL renderers, cadtui), which alfe's image does
;;;               not embed: the run IS the program's -- the default variant
;;;               runs it as the subprocess (alfe.cli:clautolisp-program-
;;;               requirement), --backend direct is a usage error. Identical
;;;               by construction;
;;; Each :ENGINE / :PROGRAM entry says, with :FORWARD, how the SUBPROCESS
;;; variant hands the option to the child -- BUILD-SUBPROCESS-ARGV is derived
;;; from this table, so an option cannot be added here without saying how
;;; the child receives it, nor forwarded without being classified:
;;;   (FN ...)      functions of the subprocess session returning the argv
;;;                 fragment (one fragment per distinct function, in table
;;;                 order, so the -E family is forwarded once);
;;;   :PLAN         an action of the plan, forwarded as its -l / -x / -i;
;;;   :ENVIRONMENT  through the child's environment ($NO_COLOR).
;;;
;;;   :DIVERGENT  KNOWN to behave differently in the two variants. None is
;;;               left; the disposition stays so a future exception has to be
;;;               written down here rather than discovered.

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
    ("--dialect"            :engine "direct: RESOLVE-CLAUTOLISP-DIALECT; subprocess: --dialect NAME"
     :forward (%forward-dialect))
    ("--strict"             :engine "as --dialect strict"
     :forward (%forward-dialect))
    ("--lax"                :engine "as --dialect lax"
     :forward (%forward-dialect))
    ("--host"               :engine "direct: RESOLVE-CLAUTOLISP-HOST; subprocess: --host NAME (cadtui is :PROGRAM: the default variant runs it as the subprocess, --backend direct is a usage error)"
     :forward (%forward-host))
    ("--dwg"                :engine "direct: HOST-OPEN-STARTUP-DRAWING with the DWG codec loaded; subprocess: --dwg FILE; same message and status when unreadable"
     :forward (%forward-dwg))
    ("--load"               :engine "direct: in-process load binding *AUTOLISP-LOAD-PATHNAME*; subprocess: -l"
     :forward :plan)
    ("--eval"               :engine "direct: in-process, binding *AUTOLISP-EXPRESSION*; subprocess: -x"
     :forward :plan)
    ("--main"               :engine "both: evaluated as -x \"(NAME)\""
     :forward :plan)
    ("--quit"               :engine "ends the plan; implicit in the child"
     :forward :plan)
    ("--no-color"           :engine "direct: *COLOR-OUTPUT*; subprocess: $NO_COLOR"
     :forward :environment)
    ("--encoding"           :engine "every situation below"
     :forward (%forward-source-encoding %situation-cli-flags))
    ("--source-encoding"    :engine "direct: session default source encoding; subprocess: -Esource"
     :forward (%forward-source-encoding))
    ("--file-encoding"      :engine "direct: *AUTOLISP-FILE-READ/WRITE-ENCODING*; subprocess: -Efile-read/-write"
     :forward (%situation-cli-flags))
    ("--file-read-encoding" :engine "as --file-encoding, read side"
     :forward (%situation-cli-flags))
    ("--file-write-encoding" :engine "as --file-encoding, write side"
     :forward (%situation-cli-flags))
    ("--log-encoding"       :engine "direct: *AUTOLISP-LOG-ENCODING*; subprocess: -Elog"
     :forward (%situation-cli-flags))
    ("--terminal-encoding"  :engine "direct: alfe's own streams; subprocess: -Eterminal-in/-out and the capture decoding"
     :forward (%situation-cli-flags))
    ("--terminal-input-encoding"  :engine "as --terminal-encoding, input side"
     :forward (%situation-cli-flags))
    ("--terminal-output-encoding" :engine "as --terminal-encoding, output side"
     :forward (%situation-cli-flags))
    ("--console-encoding"   :engine "the engine's console IS its terminal: folded into --terminal-encoding"
     :forward (%situation-cli-flags))
    ("--console-input-encoding"  :engine "folded into --terminal-input-encoding"
     :forward (%situation-cli-flags))
    ("--console-output-encoding" :engine "folded into --terminal-output-encoding"
     :forward (%situation-cli-flags))
    ;; accepted, acted on by neither variant
    ("--mode"               :no-effect "CAD launch mode")
    ("--bootstrap-phase"    :no-effect "CAD bootstrap truncation")
    ("--timeout"            :no-effect "no per-action timeout in either variant; *AUTOLISP-TIMEOUT* via the shared bindings")
    ("--cadstdio-encoding"  :no-effect "no CAD subprocess pipes")
    ("--cadstdio-input-encoding"  :no-effect "no CAD subprocess pipes")
    ("--cadstdio-output-encoding" :no-effect "no CAD subprocess pipes")
    ;; the clautolisp program's own machinery: the run is the program's
    ("--interactive"        :program "the clautolisp REPL (interactors, comma commands, the aldo debugger on an error); also a run with no action"
     :forward :plan)
    ("--dribble"            :program "the program's recorder of its REPL (nothing to record in a batch run, as with clautolisp)"
     :forward (%dribble-cli-flags))
    ("--dribble-interactors" :program "as --dribble"
     :forward (%dribble-cli-flags))
    ("--dcl"                :program "gui / ncurses: the program's renderers, on alfe's terminal; tui / auto: the line renderer in both variants (the child's captured stdout is no TTY), forwarded as --dcl"
     :forward (%forward-dcl)))
  "The treatment of every option alfe accepts, under --clautolisp, by the two
engine variants: (LONG-NAME DISPOSITION HOW &key FORWARD). See the comment
above.")

(defun clautolisp-option-disposition (long-name)
  "The disposition of the option LONG-NAME in *CLAUTOLISP-OPTION-CONTRACT*,
or NIL when the contract does not classify it."
  (second (assoc long-name *clautolisp-option-contract* :test #'string=)))

(defun clautolisp-option-forward (long-name)
  "The :FORWARD of the option LONG-NAME in *CLAUTOLISP-OPTION-CONTRACT*: a
list of argv-fragment functions, :PLAN, :ENVIRONMENT, or NIL."
  (getf (cdddr (assoc long-name *clautolisp-option-contract* :test #'string=))
        :forward))

(defun contract-subprocess-forwarders ()
  "The argv-fragment functions of the contract, each once, in table order."
  (let ((result '()))
    (dolist (entry *clautolisp-option-contract* (nreverse result))
      (let ((forward (getf (cdddr entry) :forward)))
        (when (listp forward)
          (dolist (fn forward)
            (pushnew fn result)))))))
