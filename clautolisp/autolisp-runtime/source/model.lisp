(in-package #:clautolisp.autolisp-runtime.internal)

(defparameter *autolisp-symbol-table* (make-hash-table :test #'equal))
(defparameter *autolisp-current-directory*
  (namestring (uiop:ensure-directory-pathname (truename "."))))
(defparameter *autolisp-support-paths* (list *autolisp-current-directory*))
(defparameter *autolisp-trusted-paths* '())
(defparameter *autolisp-trusted-init-files* '()
  "Absolute namestrings of the user init files the engine auto-loads at
startup (~/.autolisp + XDG variants). The SECURELOAD trust resolver
treats these as trusted by EXACT path so loading them is never gated.
Empty under --no-init. Registered by the launch wiring; see the
clautolisp-secureload-trust-model spec.")

(defstruct autolisp-symbol
  (name "" :type string)
  (original-name nil :type (or null string))
  (plist '() :type list)
  ;; Last (NAMESPACE . BINDING-CELL) this symbol resolved to, or NIL.
  ;;
  ;; Looking a symbol up in a namespace was a TYPECASE on the namespace
  ;; plus an EQ hash lookup, on every variable read, every assignment and
  ;; every function call — 13% of a call-dominated profile. A binding
  ;; cell, once made, is never removed from its namespace and no
  ;; namespace's table is ever cleared or replaced, so the answer is
  ;; stable and worth remembering. What changes on a redefinition is the
  ;; cell's VALUE, which is read through the cell either way — so this
  ;; caches the lookup without caching the definition.
  ;;
  ;; ONE entry, deliberately: a symbol is used in one namespace at a
  ;; time in any hot loop, and a bigger cache would cost more to consult
  ;; than the hash lookup it replaces. Alternating namespaces simply miss.
  ;;
  ;; Stored as a single CONS so the pair is written in one slot store. A
  ;; two-slot cache could be read torn — namespace from one writer, cell
  ;; from another — and hand back a cell belonging to the wrong
  ;; namespace; a cons is built before it is published and never mutated.
  (binding-cache nil :type list)
  ;; Last (GENERATION . HANDLER) answer to "is this symbol a special
  ;; operator?", or NIL for never asked.
  ;;
  ;; The interpreter asks that question about the operator of EVERY
  ;; compound form it evaluates, and the answer cost a STRING-UPCASE
  ;; (which allocates a fresh string each time) followed by an ASSOC
  ;; with STRING= over the whole dispatch table. For an ordinary
  ;; function call — the common case — that scan runs to the end and
  ;; fails, every single time.
  ;;
  ;; A NIL handler is a valuable answer, not a missing one, so the
  ;; entry is a CONS whose CAR is the generation: the cons being
  ;; present is what distinguishes "not a special operator" from "not
  ;; asked yet".
  ;;
  ;; The table is runtime-mutable (the debugger registers %CLAL-POLL),
  ;; so unlike BINDING-CACHE this answer can go stale. It is stamped
  ;; with *SPECIAL-OPERATOR-GENERATION*, which every mutation of the
  ;; table bumps; a stale stamp is simply a miss. Stored as a single
  ;; CONS for the same torn-read reason as BINDING-CACHE.
  (special-operator-cache nil :type list)
  ;; How many LIVE dynamic frames bind this symbol. Zero means no frame
  ;; in any chain binds it, so the walk that LOOKUP-FUNCTION,
  ;; FIND-DYNAMIC-BINDING and their callers perform can be SKIPPED
  ;; outright rather than run to its end and fail.
  ;;
  ;; This is not a cache and not a heuristic: it is a count, maintained
  ;; at the two -- and only two -- places a frame gains or loses a
  ;; binding, (SETF FRAME-BINDING) and POP-DYNAMIC-FRAME. Zero is an
  ;; exact statement, which is what makes skipping the walk equivalent
  ;; rather than merely usually-right.
  ;;
  ;; WHY IT EXISTS. Resolving a name walked the WHOLE dynamic-frame
  ;; chain, doing an EQ ASSOC in every frame, before falling back to the
  ;; namespace. For a function name -- which is essentially never
  ;; dynamically bound -- that walk failed in every frame, every call.
  ;; So every call and every global read cost O(call-stack depth), and a
  ;; program got slower the deeper it ran, for no reason it could see:
  ;; the identical loop measured 3.7x slower forty frames down.
  ;;
  ;; DIRECTION OF ERROR. Over-counting costs speed and nothing else --
  ;; the walk simply happens, exactly as it did before. Under-counting
  ;; would be a correctness bug, so nothing here clamps: a count driven
  ;; negative by some future mistake stays negative, fails the ZEROP
  ;; test, and walks. The safe answer is the one you get by being wrong.
  ;;
  ;; The count is global to the symbol, so it assumes one thread mutates
  ;; a given context'"'"'s frames at a time -- which is already true of the
  ;; frame chain itself, and of everything else hanging off the context.
  (dynamic-binding-count 0 :type fixnum))

;;; AutoLISP is a Lisp-1 dialect: a symbol carries a single binding
;;; cell that is shared by variable and function uses. SETQ and DEFUN
;;; both write to that single cell; the most recent write wins.
;;;
;;; The runtime models that with a single `binding-cell` struct per
;;; symbol per namespace. The optional `compatibility-definition`
;;; slot is the side-channel DEFUN-Q stores a list-form copy of the
;;; function in (only DEFUN-Q populates it; ordinary SETQ and DEFUN
;;; clear it). See autolisp-spec, chapter 7, "Single-Cell Symbol
;;; Binding (Lisp-1)" for the normative rule and its vendor evidence.

(defstruct binding-cell
  (value nil)
  (bound-p nil :type boolean)
  (compatibility-definition nil :type list)
  ;; Per-binding documentation for source-aware-defun-documentation.
  ;; Holds nil, (function "STR"), or (variable "STR"); the head
  ;; symbol records which special operator last installed the doc
  ;; so SETQ can preserve a variable-doc across plain mutation
  ;; while clearing a stale function-doc when the binding is
  ;; reassigned with no preceding ;| ... |; block. Read via
  ;; LOOKUP-DOCUMENTATION; surfaced to AutoLISP via the
  ;; CLAUTOLISP-DOCUMENTATION{,-KIND} builtins.
  (doc nil :type list))

(defstruct document-namespace
  (name "DOCUMENT" :type string)
  (bindings (make-hash-table :test #'eq))
  ;; Phase 14a: lifecycle state per the host-object ontology.
  ;; (:loading -> :loaded <-> :active <-> :inactive -> :closing -> :closed,
  ;;  with a transient :saving substate during write).
  (state :loaded :type keyword)
  ;; Per-document reactor registry. Hash-table from reactor-id to
  ;; reactor struct. Phase 14b populates entries via the vlr-* family;
  ;; Phase 14a leaves the table empty but reachable.
  (reactors (make-hash-table :test #'eq))
  ;; Per-document persistent-reactor symbol-name index. Maps a
  ;; reactor-id to a property list (:type :callbacks :data :owners)
  ;; suitable for serialisation / round-trip via
  ;; cador-snapshot. Maintained by vlr-pers / vlr-pers-release.
  (persistent-reactor-index (make-hash-table :test #'eq))
  ;; Phase 14a back-pointer: the runtime-session that owns this
  ;; document. Set by make-runtime-session and preserved across
  ;; register-runtime-session-document. Lets signal-document-event
  ;; locate the session reliably without scanning the active
  ;; evaluation context.
  (session nil))

(defstruct blackboard-namespace
  (name "BLACKBOARD" :type string)
  (bindings (make-hash-table :test #'eq)))

(defstruct separate-vlx-namespace
  (name "VLX" :type string)
  (bindings (make-hash-table :test #'eq)))

(defstruct dynamic-binding
  symbol
  (value nil)
  (bound-p nil :type boolean)
  ;; See binding-cell's doc slot — same semantics for the dynamic
  ;; shadow that `/'-locals / lambda parameters / foreach iteration
  ;; variables push onto the stack. lookup-documentation walks the
  ;; frame chain and returns this slot on the innermost hit.
  (doc nil :type list))

(defstruct dynamic-frame
  ;; BINDINGS is either an ALIST of (symbol . dynamic-binding) — the
  ;; ordinary case — or an EQ hash table, once the frame holds more
  ;; entries than an alist searches cheaply. See FRAME-BINDING in
  ;; api.lisp, which is the only thing that should read this slot.
  ;;
  ;; It used to be a hash table always, allocated in this initform, i.e.
  ;; ONE HASH TABLE PER FUNCTION CALL — to hold, typically, a single
  ;; parameter. It showed up in a call-dominated profile as
  ;; %MAKE-HASH-TABLE + %ALLOC-HASH-TABLE + GROW-HASH-TABLE together
  ;; costing more than the lookups they served, plus the garbage they
  ;; made. An empty list allocates nothing.
  (bindings '())
  parent)

(defstruct runtime-session
  (document-namespaces (make-hash-table :test #'equal))
  (separate-vlx-namespaces (make-hash-table :test #'equal))
  (exported-functions (make-hash-table :test #'equal))
  (blackboard-namespace (make-blackboard-namespace))
  (propagated-symbols (make-hash-table :test #'eq))
  (errno 0 :type integer)
  ;; clautolisp exit-status channel (autolisp-set-status / autolisp-status
  ;; / (quit [status])). A pending process exit code that a script records
  ;; via (autolisp-set-status N) and that (quit) — and the CLI's normal
  ;; end-of-run — pick up. Defaults to 0 (success). Mirrors the CAD-side
  ;; alfe `autolisp-set-status` bootstrap so a single C:MAIN is portable.
  ;; See issues/open/autolisp-set-status-and-quit-status.issue.
  (exit-status 0 :type integer)
  current-document
  ;; Phase 6: every runtime session carries the dialect descriptor
  ;; that drove its instantiation. Builtins that have product-divergent
  ;; lex / mode behaviour (currently `atof` hex-float, `open` `ccs=`)
  ;; consult the active session's dialect.
  (dialect nil)
  ;; Phase 8: every runtime session also carries a HAL backend
  ;; (`host`) that decides where CAD-host effects land. Defaults to
  ;; nil when the session is created from the runtime alone; the
  ;; autolisp-host module installs a NullHost singleton via the
  ;; *default-runtime-host* parameter once its package is loaded.
  ;; Higher-level callers (the CLI, the file-compat harness, etc.)
  ;; can pass any object satisfying the HAL contract.
  (host nil)
  ;; Phase 14a: host-object ontology. The runtime models the
  ;; application as a single-state-machine value and the
  ;; document-manager implicitly via the document-namespaces table.
  ;; Lifecycle: :running -> :quitting -> :quit. Application-scoped
  ;; reactors live here (vlr-docmanager / vlr-editor / vlr-linker /
  ;; vlr-lisp / vlr-miscellaneous).
  (application-state :running :type keyword)
  (application-reactors (make-hash-table :test #'eq))
  ;; Optional per-session debug listener for tests. When non-nil,
  ;; signal-document-event / signal-application-event push their
  ;; argument tuples onto this list (newest first). Tests inspect
  ;; the list, then clear it. Production callers leave it nil.
  (event-trace nil)
  ;; Session-level source-file encoding override. When non-nil
  ;; (a keyword such as :UTF-8 / :ISO-8859-1 / :WINDOWS-1252),
  ;; AUTOLISP-LOAD-FILE-IN-CONTEXT uses this instead of the
  ;; dialect's default-source-encoding for files loaded WITHOUT
  ;; an explicit :external-format. Set by the CLI from the user's
  ;; `-e ENC' flag, so a single `-e utf-8' at the alfe / clautolisp
  ;; command line takes effect for every load — including the
  ;; nested `(load …)` calls a user's init file makes (which was
  ;; the failure mode before this slot existed: the runtime
  ;; couldn't see the CLI's encoding because it ran far below the
  ;; CLI layer).
  (default-source-encoding nil)
  ;; Dialect portability warnings (autolisp-spec ch.25): the per-run
  ;; once-per-occurrence dedup table. Keyed by the *source occurrence*
  ;; (the lambda-list cons of a defun/lambda, i.e. object identity),
  ;; NOT by construct class -- so `foo' and `bar' each warn on their own
  ;; first evaluation, a loop around one `foo' warns only once, and a
  ;; guarded/never-evaluated occurrence never warns. A fresh table is
  ;; consed per session, so a new run (fresh process / fresh
  ;; make-runtime-session) starts with a clean slate. See
  ;; emit-lambda-list-extension-warning.
  (portability-warnings-seen (make-hash-table :test #'eq))
  ;; Dedup for the `..'-path portability warning (open / findfile / load
  ;; on a path with a `..' component). Keyed by the path STRING (EQUAL),
  ;; so a loop that opens the same `..' path warns once per run. Consed
  ;; per session like PORTABILITY-WARNINGS-SEEN. See
  ;; emit-dotdot-path-portability-warning / cad-path-dotdot-resolution.
  (dotdot-path-warnings-seen (make-hash-table :test #'equal)))

(defstruct evaluation-context
  session
  current-document
  current-namespace
  dynamic-frame)

(defparameter *default-document-namespace*
  (make-document-namespace :name "DEFAULT"))
(defparameter *default-runtime-session*
  (make-runtime-session :current-document *default-document-namespace*))
(defparameter *default-evaluation-context*
  (make-evaluation-context
   :session *default-runtime-session*
   :current-document *default-document-namespace*
   :current-namespace *default-document-namespace*
   :dynamic-frame nil))
(defparameter *active-evaluation-context* nil)

(defstruct autolisp-string
  (value "" :type string))

(defstruct autolisp-file
  stream
  (path nil)
  (mode nil))

(defstruct autolisp-ename
  value)

(defstruct autolisp-pickset
  value)

(defstruct autolisp-subr
  (name "" :type string)
  function)

(defstruct autolisp-usubr
  (name "" :type string)
  (lambda-list '() :type list)
  (body '() :type list)
  environment
  ;; Debugger support (clautolisp-debugger plan §3a, the interpreter
  ;; two-bodies discipline). INSTRUMENTED-BODY, when non-nil, is a
  ;; copy of BODY with %CLAL-POLL poll-point nodes woven in; the
  ;; evaluator runs it instead of BODY when *DEBUGGING* is set (see
  ;; call-autolisp-function-in-context). DEBUG-METADATA holds the
  ;; clautolisp.debug:function-debug-metadata record produced by the
  ;; instrumenter (form-id ↔ source position, kinds, parent map,
  ;; bound-names, function-id). Both default to NIL; an
  ;; un-instrumented function carries zero debug overhead.
  (instrumented-body nil :type list)
  (debug-metadata nil)
  ;; Compiler support (compiler.issue, Tier 2). COMPILED-BODY, when it
  ;; holds a function, is a Common Lisp function of one argument (the
  ;; evaluation context) evaluating BODY — the transpiler's fork, a THIRD
  ;; body alongside the plain and the instrumented one. The evaluator
  ;; runs it in place of BODY, except while a debug session is active:
  ;; there an instrumented body wins, so stepping and breakpoints keep
  ;; working exactly as before. It also holds :FAILED after a compilation
  ;; that errored, which is not the same as NIL — NIL means "not tried
  ;; yet" and would be retried on every call.
  ;;
  ;; CALL-COUNT is what decides when compiling is worth its own cost. A
  ;; function called once — which is most of a freshly loaded file — must
  ;; not pay for a compilation it will never amortise, so the fork is
  ;; woven lazily, on the call that crosses the threshold.
  ;;
  ;; COMPILED-INSTRUMENTED-BODY is the FOURTH body: the transpiler's fork
  ;; of INSTRUMENTED-BODY. Without it a debug session forces everything
  ;; back through the interpreter, because compiling was skipped whenever
  ;; *DEBUGGING* was set. That is the right answer only if instrumented
  ;; code cannot be compiled -- and it can, once the transpiler open-codes
  ;; the %CLAL-POLL node instead of handing it back to the interpreter.
  ;; Same :FAILED convention as COMPILED-BODY.
  (compiled-body nil)
  (compiled-instrumented-body nil)
  (call-count 0 :type fixnum)
  ;; Memoised result of SPLIT-USUBR-LAMBDA-LIST: (REQUIRED REST-PARAM
  ;; LOCALS), or NIL when it has not been computed yet. A lambda list
  ;; never changes after the function object is made, yet binding a frame
  ;; re-walked it on EVERY call — two POSITION-IFs, up to three SUBSEQs
  ;; and the whole validation, per call, to reach the same answer.
  ;;
  ;; Filled lazily, and only on SUCCESS. That is deliberate: a malformed
  ;; lambda list must keep signalling on every call, exactly as it did
  ;; before, rather than signalling once at definition time — computing
  ;; it eagerly in the constructor would move the error from the call to
  ;; the DEFUN, which is a behaviour change and not this slot's business.
  (lambda-list-split nil :type list))

(defstruct autolisp-catch-all-error
  (message "" :type string)
  condition)

(defstruct autolisp-variant
  value)

(defstruct autolisp-safearray
  value)

(defstruct autolisp-vla-object
  value)

;;; ---- PRINT-OBJECT methods for AutoLISP runtime values --------------
;;;
;;; *COLOR-OUTPUT* lives in terminal-color.lisp, which is loaded AFTER
;;; this file (it depends on the structs defined above). The DECLAIM
;;; tells the compiler that the symbol names a special variable so the
;;; reference inside the AUTOLISP-SYMBOL PRINT-OBJECT method below
;;; compiles without a "undefined variable" warning. The DEFPARAMETER
;;; in terminal-color.lisp later attaches the actual value cell.
(declaim (special clautolisp.autolisp-runtime:*color-output*))
;;;
;;; Why: CL's default DEFSTRUCT printer renders an AutoLISP symbol "T"
;;; as `#S(CLAUTOLISP.AUTOLISP-RUNTIME.INTERNAL:AUTOLISP-SYMBOL :NAME
;;; "T" :ORIGINAL-NAME "T" :PLIST NIL)' — useful for the debugger, but
;;; opaque in error messages and trace output where an AutoLISP
;;; developer just wants to see what their code is seeing.
;;;
;;; The methods below render each runtime value type with its AutoLISP
;;; surface syntax: a symbol becomes its name, a string becomes
;;; "abc" / abc depending on *print-escape*, an entity becomes
;;; `<Entity name: …>', etc. CL handles cons cells, nil, integers, and
;;; floats natively — and our methods are dispatched recursively by
;;; the list printer for nested values, so `(princ (cons sym other))'
;;; comes out as `(T 42)' instead of the structure dump.
;;;
;;; *print-escape* (NIL for princ, T for prin1) controls whether
;;; AutoLISP strings get quoted; AutoLISP follows the same convention
;;; (princ "abc" -> abc, prin1 "abc" -> "abc"). Other types are
;;; printed identically under both modes — there is no quote-able
;;; surface syntax for SUBR / USUBR / ENAME / SAFEARRAY / etc.
;;;
;;; A failsafe handler-case keeps the printer from looping if any
;;; underlying slot accessor errors out: on failure we fall back to
;;; the default structure printer (PRINT-NOT-READABLE-OBJECT). This
;;; matters because PRINT-OBJECT runs inside the debugger and a
;;; loop here would deadlock recovery.

(defun %print-autolisp-string (string-value stream)
  "Print STRING-VALUE (a Common Lisp string carried by an
autolisp-string) honouring *PRINT-ESCAPE*. Mirrors
autolisp-builtins-core::escape-prin1-string, kept in the runtime
because the print-object method lives here."
  (if *print-escape*
      (progn
        (write-char #\" stream)
        (loop for ch across string-value do
              (case ch
                (#\\ (write-string "\\\\" stream))
                (#\" (write-string "\\\"" stream))
                (t   (write-char ch stream))))
        (write-char #\" stream))
      (write-string string-value stream)))

(defmethod print-object ((object autolisp-symbol) stream)
  ;; Symbols are the one runtime value that gets a colour accent
  ;; when the CLI has armed *COLOR-OUTPUT* (yellow on dark, blue on
  ;; light terminals). The OR clause keeps the cheap path —
  ;; `(write-string name stream)` — when colour is off, which is
  ;; the case for every non-CLI caller and for piped output where
  ;; *COLOR-OUTPUT* is NIL by policy. See terminal-color.lisp.
  (handler-case
      (let ((colour (and (boundp 'clautolisp.autolisp-runtime:*color-output*)
                         clautolisp.autolisp-runtime:*color-output*)))
        (if colour
            (clautolisp.autolisp-runtime:write-ansi-colorized
             (autolisp-symbol-name object) colour stream)
            (write-string (autolisp-symbol-name object) stream)))
    (error ()
      (call-next-method))))

(defmethod print-object ((object autolisp-string) stream)
  (handler-case
      (%print-autolisp-string (autolisp-string-value object) stream)
    (error ()
      (call-next-method))))

(defmethod print-object ((object autolisp-subr) stream)
  (handler-case
      (format stream "#<SUBR ~A>" (autolisp-subr-name object))
    (error ()
      (call-next-method))))

(defmethod print-object ((object autolisp-usubr) stream)
  (handler-case
      (format stream "#<USUBR ~A>" (autolisp-usubr-name object))
    (error ()
      (call-next-method))))

(defmethod print-object ((object autolisp-ename) stream)
  (handler-case
      (format stream "<Entity name: ~A>" (autolisp-ename-value object))
    (error ()
      (call-next-method))))

(defmethod print-object ((object autolisp-pickset) stream)
  (handler-case
      (format stream "<Selection set: ~A>" (autolisp-pickset-value object))
    (error ()
      (call-next-method))))

(defmethod print-object ((object autolisp-file) stream)
  (handler-case
      (format stream "#<file ~A>" (or (autolisp-file-path object) "?"))
    (error ()
      (call-next-method))))

(defmethod print-object ((object autolisp-vla-object) stream)
  (handler-case
      (format stream "#<VLA-OBJECT ~A>" (autolisp-vla-object-value object))
    (error ()
      (call-next-method))))

(defmethod print-object ((object autolisp-safearray) stream)
  (handler-case
      (format stream "#<SAFEARRAY>")
    (error ()
      (call-next-method))))

(defmethod print-object ((object autolisp-variant) stream)
  (handler-case
      (let ((pair (autolisp-variant-value object)))
        (if (consp pair)
            (format stream "#<VARIANT ~A ~A>" (car pair) (cdr pair))
            (format stream "#<VARIANT>")))
    (error ()
      (call-next-method))))

(defmethod print-object ((object autolisp-catch-all-error) stream)
  (handler-case
      (format stream "#<catch-all-error ~S>"
              (autolisp-catch-all-error-message object))
    (error ()
      (call-next-method))))
