;;;; -*- mode:lisp; coding:utf-8 -*-
;;;;
;;;; The dialect-portability knowledge base.
;;;;
;;;; autolisp-spec chapter 25 ("Normative Rules: Dialect Portability
;;;; Warnings") requires ONE knowledge base behind every portability
;;;; diagnostic, so that the run-time emitter and any future static
;;;; linter answer from the same table rather than from scattered
;;;; `case' forms. This file is that table; the emitters live in
;;;; api.lisp because they need the runtime's error signalling and the
;;;; once-per-occurrence dedup, and they consult this catalogue for
;;;; every decision that is knowledge rather than mechanism.
;;;;
;;;; Deliberately dependency-free: pure data plus lookup. It is loaded
;;;; before api.lisp and knows nothing about evaluation, which is what
;;;; lets a static analyser use it without starting a runtime.
;;;;
;;;; POPULATION POLICY. Entries are added as cross-vendor hazards are
;;;; CONFIRMED, not speculatively -- this is the policy the governing
;;;; issue (clautolisp-dialect-portability-warnings) sets, and it is
;;;; why this table is short while chapter 24 of the spec lists 473
;;;; BricsCAD-only names. Of those, 215 are implemented by clautolisp
;;;; today and are therefore genuine SILENT hazards: they run here and
;;;; on BricsCAD and fail on AutoCAD. That backlog is enumerated by
;;;; clautolisp/tools/portability-catalogue/extract-bricscad-only.sh
;;;; (regenerate rather than hand-transcribe) and is tracked in the
;;;; issue. Each entry needs its supporting-host set confirmed before
;;;; it lands here.

(in-package #:clautolisp.autolisp-runtime)

;;; ==================================================================
;;; PART 1 — the register of dialect warnings, keyed by TAG
;;; ==================================================================
;;;
;;; pjb's ruling of 2026-08-14 on clautolisp-dialect-portability-warnings,
;;; which is what settled the long-open "canonical message format"
;;; question:
;;;
;;;   1. "It's nice to have a unique tag identifying the warning. This
;;;      let us write a reference documentation for these warning giving
;;;      more detailed explanations and references than we may in a
;;;      warning message while executing the program."
;;;   2. Report the source file, the line, and the name of the function
;;;      concerned -- we warn once per occurrence, so we can afford to
;;;      spend a little time finding them.
;;;   3. The warning text itself is as clear and concise as it can be,
;;;      ideally standing on a single line.
;;;   4. The exact message is NOT formally specified anywhere.
;;;   5. Keep a register of these warnings, keyed by the [tag], holding
;;;      the message template, the detail of how the dialects diverge,
;;;      and the URLs to the diverging reference material. It becomes an
;;;      annex to the user manual.
;;;
;;; So the tag is the STABLE part of the contract -- it is what tests
;;; match, what a user greps for, and what the annex is indexed by --
;;; while the prose is free to improve. Everything a reader needs beyond
;;; one line lives here rather than in the message.
;;;
;;; This register is the ONE source: the emitters format from
;;; DIALECT-WARNING-MESSAGE and the manual annex is GENERATED from these
;;; entries (see RENDER-DIALECT-WARNINGS-ANNEX). Do not restate an
;;; entry's prose in the annex file by hand -- it would drift.

(defstruct (dialect-warning
            (:constructor %make-dialect-warning))
  "One catalogued dialect warning: the register entry behind one [tag].

TAG         the bracketed identifier, e.g. \"path-dotdot\". STABLE: it is
            the warning's name in tests, in user greps, and in the annex.
TITLE       a short noun phrase naming the hazard.
KIND        which family the tag belongs to. They share the bracketed
            shape but not their mechanism, and flattening them would
            make the annex lie about how they behave:
            :portability       -- a construct one engine has and another
                                  does not. One templated message,
                                  emitted through %PORTABILITY-DIAGNOSTIC,
                                  gated by the construct catalogue.
            :extension-notice  -- a clautolisp extension used outside
                                  --dialect clautolisp. One message.
            :vendor-divergence -- clautolisp follows the spec where a
                                  vendor does not; the note says what the
                                  vendor does and that we decline it.
            :encoding          -- a code from *ENC-DIAGNOSTIC-CODES*.
                                  Message VARIES by call site; suppressed
                                  per-code by CLAL-SUPPRESS-ENC-DIAGNOSTIC.
            :trust             -- a code from *SECURELOAD-DIAGNOSTIC-CODES*,
                                  the warn-and-proceed path of SECURELOAD.
MESSAGE     the one-line message, as a FORMAT control string. It is the
            whole runtime text after the tag and the location. EMPTY for
            the code families, whose text is written at each call site.
ARGUMENTS   what MESSAGE's format arguments are, in order -- for the
            maintainer, since a control string does not say.
EXAMPLE     one real diagnostic line, so the annex shows what the reader
            will actually see rather than a control string full of
            tildes. Kept beside MESSAGE so the two are revised together.
DIALECTS    how the construct varies across dialects: who provides it,
            who rejects it, who stays silent and why.
RATIONALE   why it is not portable -- the part that does not fit on the
            warning line and is the reason the annex exists.
REFERENCES  list of (LABEL . LOCATION): vendor documentation URLs, and
            in-repo documents/issues carrying the evidence. Empty vendor
            documentation is itself a finding for an undocumented
            extension, and is stated as such rather than left blank."
  (tag "" :type string)
  (title "" :type string)
  (kind :portability :type keyword)
  (message "" :type string)
  (arguments "" :type string)
  (example "" :type string)
  (dialects "" :type string)
  (rationale "" :type string)
  (references '() :type list))

(defvar *dialect-warnings* (make-hash-table :test #'equal)
  "TAG (a string) -> DIALECT-WARNING. The register.")

(defvar *dialect-warning-order* '()
  "Tags in registration order, so the annex and any listing come out in a
stable order rather than a hash-table's.")

(defun register-dialect-warning (&rest initargs &key tag &allow-other-keys)
  "Add or replace the register entry for TAG. Returns the entry."
  (let ((entry (apply #'%make-dialect-warning initargs)))
    (unless (gethash tag *dialect-warnings*)
      (setf *dialect-warning-order*
            (append *dialect-warning-order* (list tag))))
    (setf (gethash tag *dialect-warnings*) entry)))

(defun find-dialect-warning (tag)
  "The register entry for TAG (a string), or NIL."
  (and (stringp tag) (gethash tag *dialect-warnings*)))

(defun dialect-warning-tags ()
  "Every registered tag, in registration order."
  (copy-list *dialect-warning-order*))

(defun map-dialect-warnings (function)
  "Call FUNCTION on each register entry, in registration order. For the
annex generator and for any `--list-dialect-warnings' style report."
  (dolist (tag *dialect-warning-order*)
    (let ((entry (gethash tag *dialect-warnings*)))
      (when entry (funcall function entry)))))

;;; ------------------------------------------------------------------
;;; The register's entries
;;; ------------------------------------------------------------------
;;;
;;; MESSAGE keeps to one line and says only what this occurrence is: the
;;; construct, and the dialect it is not portable to. It deliberately no
;;; longer carries "use --dialect X to silence" -- that is advice, it is
;;; the same for every occurrence, and it belongs to the annex (pjb's
;;; points 1 and 3). The tag is what leads a reader there.

(register-dialect-warning
 :tag "lambda-list-extension"
 :title "Rest parameter in a lambda list"
 :message "~A `~A': rest parameter not portable to ~(~A~)"
 :arguments "WHO (\"DEFUN\" / \"LAMBDA\"), the token as written, the dialect name"
 :example ": [lambda-list-extension] drawing.lsp:12 in COMPUTE-AREA: DEFUN `&REST': rest parameter not portable to strict"
 :dialects
 "Portable AutoLISP has NO rest parameter: a defun/lambda lambda list is
`required* [/ locals*]' and nothing else. The two spellings differ:

- `&REST' is a real, undocumented BricsCAD extension (V25 and V26) --
  confirmed by harvest, EXTPROBE REST-BINDS=(2 3 4). Silent under
  --dialect bricscad-v25 / bricscad-v26.
- `&' is clautolisp's own historical spelling and is native NOWHERE:
  the same harvest had BricsCAD REJECT it (\"too few / too many
  arguments\"). It therefore warns under every dialect except
  clautolisp and lax.

--dialect clautolisp is silent for both (they are its blessed
extensions); --dialect lax is silent for everything; --strict and the
AutoCAD dialects warn for both."
 :rationale
 "A function written with a rest parameter will not load on AutoCAD at
all, and one written with `&' will not load on BricsCAD either. The
warning fires when the defun/lambda is EVALUATED, so a guarded branch
that is never reached never warns."
 :references
 '(("clautolisp: the governing issue" . "issues/open/clautolisp-dialect-portability-warnings.issue")
   ("clautolisp: harvest evidence" . "autolisp-spec/documentation/bricscad-undocumented-extensions.org")
   ("clautolisp: normative rules" . "autolisp-spec chapter 25, \"Normative Rules: Dialect Portability Warnings\"")))

(register-dialect-warning
 :tag "ext-bricscad-undocumented"
 :title "Undocumented BricsCAD Common-Lisp construct"
 :message "~A: BricsCAD extension, not portable to ~(~A~)"
 :arguments "the construct as written (\"LET\"), the dialect name"
 :example ": [ext-bricscad-undocumented] drawing.lsp:31 in DRAW-BLOCK: LET: BricsCAD extension, not portable to autocad-2026"
 :dialects
 "BricsCAD's AutoLISP quietly implements a few Common-Lisp constructs
that portable AutoLISP does not have, and that Bricsys does not
document. What the 2026-08-07 harvest against a real BricsCAD V26
established, construct by construct:

- LET exists and binds in PARALLEL, CL-style (EXTPROBE LET-SUM=3,
  LET-PARALLEL=(1 10): the inner Y saw the OUTER X). clautolisp
  implements it, so it is silent here and under --dialect bricscad.
- LET* does NOT exist on BricsCAD either (\"no function definition
  <LET*>\"), refuting what the issue had assumed. It is not a vendor
  extension at all, so clautolisp declines it.
- SETF exists but is BROKEN: it returns a constant sentinel 2 for every
  value written and does not assign at all (SETF-THEN-FOO=nil).
  clautolisp declines to imitate it.

Silent under --dialect bricscad-v25 / bricscad-v26 (native),
--dialect clautolisp (implemented as a blessed extension) and --lax.
Warns under --strict and the AutoCAD dialects."
 :rationale
 "These constructs run on BricsCAD and on clautolisp and fail on
AutoCAD -- the most dangerous shape of non-portability, because nothing
in your development loop reveals it. The declined ones (SETF, LET*) are
a different case: calling them is already an `undefined function'
error, and the note exists to explain that the omission is deliberate."
 :references
 '(("clautolisp: harvest + per-construct evidence" . "autolisp-spec/documentation/bricscad-undocumented-extensions.org")
   ("clautolisp: the vendor issue" . "issues/open/bricscad-undocumented-clisms.issue")
   ("Bricsys documentation" . "NONE -- these constructs are undocumented by the vendor, which is precisely why this tag exists. Behaviour here is established by probing a real BricsCAD V26, not by reading a manual.")))

(register-dialect-warning
 :tag "path-dotdot"
 :title "`..' component in a path"
 :message "~A ~S: `..' resolves differently on POSIX and Windows"
 :arguments "WHO (the builtin name, e.g. \"OPEN\"), the path as written"
 :example ": [path-dotdot] drawing.lsp:42 in LOAD-BLOCK: OPEN \"../lib/a.dwg\": `..' resolves differently on POSIX and Windows"
 :dialects
 "This one does not vary by DIALECT so much as by the target's
OPERATING SYSTEM, which is why it warns almost everywhere:

- POSIX hosts -- clautolisp on every platform, and BricsCAD on macOS --
  resolve `..' PHYSICALLY (UP): the walk goes through the real
  directory, so a `..' through a missing directory FAILS, and a `..'
  after a symbolic link lands in the link TARGET's parent.
- Windows CADs -- AutoCAD and BricsCAD -- collapse `..' TEXTUALLY
  (BACK): it succeeds through a missing directory and ignores symbolic
  links entirely.

Even when both resolve, the two disagree the moment a symbolic link
precedes the `..'. Silent ONLY under --lax; every other dialect warns,
including --clautolisp, because the hazard is real whichever engine's
semantics you prefer."
 :rationale
 "clautolisp chose UP everywhere (1.7.5) rather than following the host,
so that one program behaves the same on every platform. The warning is
what keeps that choice honest: it tells you the path is one whose
meaning changes when the program moves."
 :references
 '(("clautolisp: the probed matrix" . "issues/closed/cad-path-dotdot-resolution.issue")
   ("Autodesk: open (AutoLISP), 2024 ENU" . "https://help.autodesk.com/cloudhelp/2024/ENU/AutoCAD-AutoLISP-Reference/files/GUID-089A323F-21FF-4337-99A9-375758E23BA4.htm")))

(register-dialect-warning
 :tag "path-slash-ellipsis"
 :title "Forward-slash `/...' subfolder-recursion wildcard"
 :message "~A ~S: `/...' needs the back-slash spelling on AutoCAD-Windows"
 :arguments "WHO (the builtin name, e.g. \"FINDFILE\"), the path as written"
 :example ": [path-slash-ellipsis] setup.lsp:7 in INIT: FINDFILE \"support/.../tools.lsp\": `/...' needs the back-slash spelling on AutoCAD-Windows"
 :dialects
 "AutoCAD's support/trusted-path syntax has a `...' wildcard meaning
\"this directory and all of its subfolders\". The SEPARATOR introducing
it is what is not portable:

- AutoCAD on Windows accepts only the back-slash spelling `\\...'; a
  forward-slash `/...' silently fails to expand -- no error, just no
  match, which is the worst failure mode.
- clautolisp and AutoCAD on macOS accept `/...'.

Gated on the dialect's PLATFORM facet, so it warns under the Windows
vendor dialects (--autocad, --bricscad) and stays silent on
--dialect autocad-mac and on the platform-neutral profiles (--strict,
--clautolisp, --lax, whose platform is unset). This is the first
consumer of the platform axis."
 :rationale
 "Silent non-expansion means the program does not fail where the mistake
is -- it fails later, looking like a missing file. Spelling it `\\...'
works on every target."
 :references
 '(("clautolisp: the platform axis" . "issues/open/dialect-platform-version-axis.issue")
   ("clautolisp: pathname mapping spec" . "clautolisp/documentation/clautolisp-windows-pathname-mapping-spec.org")))

(register-dialect-warning
 :tag "path-case"
 :title "Path found only by folding case"
 :message "~A ~S: found as ~S -- the case differs, and only a case-insensitive filesystem forgives it"
 :arguments "WHO (the builtin name, e.g. \"LOAD\"), the path as written, the real name"
 :example ": [path-case] sigfic.lsp:12 in LOAD-DIAL: LOAD \"dial/sigfic.lsp\": found as \"DIAL/SIGFIC.LSP\" -- the case differs, and only a case-insensitive filesystem forgives it"
 :dialects
 "This one is about the FILESYSTEM, not the dialect, so it warns
wherever the fold actually happened. It is emitted only when
CLAUTOLISPCASEINSENSITIVEPATHS is 1 and a path was located under a name
that differs from the one written -- never on an exact match, which is
the common case and costs nothing.

Windows and macOS filesystems are case-insensitive by default, so a
program developed there never learns that its path spellings disagree
with the disk. Linux tells it, by failing. The sysvar exists so such a
corpus can run unmodified; the warning exists so that running it is not
the same as pretending the problem is gone."
 :rationale
 "A strict engine is the only one that VALIDATES the case of a path.
Silently folding would trade one lost signal for another: the program
would work here and keep the latent defect for the next strict system.
Warning keeps both -- the run proceeds, and the developer learns which
spelling is wrong and what the real name is. Without it the sysvar would
merely sweep the problem under the carpet."
 :references
 '(("clautolisp: the request and its incident" . "issues/open/case-insensitive-pathname-resolution.issue")
   ("clautolisp: the `..' warning this is modelled on" . "issues/closed/cad-path-dotdot-resolution.issue")))

;;; ------------------------------------------------------------------
;;; :extension-notice — a clautolisp extension used out of dialect
;;; ------------------------------------------------------------------

(register-dialect-warning
 :tag "exit-status-extension"
 :title "Exit-status operator"
 :kind :extension-notice
 :message "`~A' is a clautolisp extension, not portable to ~(~A~)"
 :arguments "the form as written, the dialect name"
 :example ": [exit-status-extension] in MAIN: `(clal-exit 2)' is a clautolisp extension, not portable to strict"
 :dialects
 "Setting a process exit status from AutoLISP is a clautolisp notion: on
the CAD hosts there is no process of your own to give a status to. What
alfe does there instead is record the status through its own injected
=autolisp-set-status=, so the same program can report a result under
both. Silent under --dialect clautolisp; flagged everywhere else."
 :rationale
 "The operator does not fail on a CAD host -- it simply has nowhere to
put the status, so a script relying on it to signal failure to a shell
would report success. The notice is what makes that visible before the
program is moved."
 :references
 '(("clautolisp: emitted by" . "clautolisp/autolisp-builtins-core/source/api.lisp, REQUIRE-EXIT-STATUS")))

(register-dialect-warning
 :tag "terpri-file-extension"
 :title "TERPRI with a file argument"
 :kind :extension-notice
 :message "`(terpri <file>)' is a clautolisp extension, not portable to ~(~A~)"
 :arguments "the dialect name"
 :example ": [terpri-file-extension] in WRITE-REPORT: `(terpri <file>)' is a clautolisp extension, not portable to autocad-2026"
 :dialects
 "AutoCAD 2026 and BricsCAD V26 both have =terpri=, but command-line
only: it takes no argument and writes a newline to the console. Passing
a file descriptor is a clautolisp extension. Silent under --dialect
clautolisp; flagged everywhere else."
 :rationale
 "The portable spelling is =(princ \"\\n\" <file>)=, which writes the same
byte on every engine. Left as-is, the call is a plain wrong-number-of-
arguments error on the vendor engines."
 :references
 '(("clautolisp: emitted by" . "clautolisp/autolisp-builtins-core/source/api.lisp, the TERPRI builtin")))

;;; ------------------------------------------------------------------
;;; :vendor-divergence — clautolisp follows the spec, a vendor does not
;;; ------------------------------------------------------------------

(register-dialect-warning
 :tag "entmake-subclass-marker"
 :title "ENTMAKE data missing an R13+ subclass marker"
 :kind :vendor-divergence
 :message "~A is an R13+ entity; the autolisp-spec (per AutoCAD) requires its (100 . …) subclass marker~P"
 :arguments "the entity type, the number of missing markers (for the plural)"
 :example ": [entmake-subclass-marker] in MAKE-LINE: LINE is an R13+ entity; the autolisp-spec (per AutoCAD) requires its (100 . \"AcDbLine\") subclass marker"
 :dialects
 "R13 and later entities carry subclass markers -- group-100 entries
naming each level of the class hierarchy -- and the autolisp-spec, which
follows AutoCAD, requires them in the ENTMAKE / ENTMAKEX data.

BricsCAD accepts the data with the markers omitted. That is a
RECOGNISED divergence, and clautolisp does NOT condone it: the create
returns nil under --autocad, --clautolisp and --strict, exactly as
AutoCAD does. The warning explains the nil."
 :rationale
 "This one bites in the direction people do not expect: code developed
against BricsCAD looks correct, and fails on AutoCAD by returning nil
from ENTMAKE with no other sign. Adding the markers works on both."
 :references
 '(("clautolisp: emitted by" . "clautolisp/cador/source/entity-api.lisp, EMIT-ENTMAKE-MARKER-DIVERGENCE-WARNING")
   ("clautolisp: divergence register" . "issues/open/vendor-probe-autocad-bricscad-divergences.issue")))

(register-dialect-warning
 :tag "vl-catch-all-apply-arity"
 :title "VL-CATCH-ALL-APPLY called without an argument list"
 :kind :portability
 :message "(vl-catch-all-apply f) without an argument list works on AutoCAD and BricsCAD but is documented by neither; --dialect strict asks for the documented subset. Pass nil explicitly."
 :arguments "none"
 :example ": [vl-catch-all-apply-arity] in LOAD-VLE: (vl-catch-all-apply f) without an argument list works on AutoCAD and BricsCAD but is documented by neither; --dialect strict asks for the documented subset. Pass nil explicitly."
 :dialects
 "Autodesk's documentation gives arg-list as REQUIRED, and this
specification followed it. BOTH ENGINES ACCEPT IT OMITTED, and both
treat the missing list as empty -- measured, not inferred:

  BricsCAD V26 -- the vle-extension.lsp shipped inside the application
  and loaded by the engine at startup calls (vl-catch-all-apply
  'vl-load-com). An engine rejecting the form could not load its own
  file.

  AutoCAD 2022 -- probe run 20260817T070448Z on a real accoreconsole:
  (vl-catch-all-apply (lambda () 42)) returned 42, and the same call on
  a function requiring an argument produced the engine's own arity error
  (\"nombre d'arguments insuffisants\"), which is what an EMPTY list
  produces.

So this is NOT a vendor divergence -- there is nothing for one engine to
do differently from the other. It is an UNDOCUMENTED tolerance, and that
is a different hazard: --strict means the documented portable subset, so
it warns; --autocad and --bricscad ask for a specific engine's measured
behaviour and stay silent; --clautolisp and --lax silence it as they do
everything of this kind."
 :rationale
 "Two engines agreeing today is not a promise for tomorrow. Nothing in
either vendor's documentation obliges them to keep accepting the
one-argument form, and code that relies on it has no contract to point
at when a future version tightens the check. Passing nil explicitly
costs four characters and means the same thing everywhere.

The warning briefly said the opposite -- that BricsCAD tolerated what
AutoCAD refused -- on the strength of the documentation alone. The probe
that settled it is kept in the tree precisely so the claim rests on a
measurement."
 :references
 '(("clautolisp: emitted by" . "clautolisp/autolisp-builtins-core/source/api.lisp, EMIT-VL-CATCH-ALL-APPLY-ARITY-WARNING")
   ("clautolisp: the probe that measured both engines" . "probes/sources/probe-vl-catch-all-apply.lsp")
   ("clautolisp: issue" . "issues/closed/vl-catch-all-apply-optional-arglist.issue")
   ("BricsCAD: the vendor file that uses it" . "BricsCAD V26.app/Contents/MacOS/vle-extension.lsp")))

(register-dialect-warning
 :tag "entmod-nongraphical"
 :title "ENTMOD on a non-graphical object"
 :kind :vendor-divergence
 :message "entmod on ~A: a non-graphical object's contents are not modified by entmod -- it is a no-op"
 :arguments "the object type (XRECORD, DICTIONARY, …)"
 :example ": [entmod-nongraphical] in UPDATE-XREC: entmod on XRECORD: a non-graphical object's contents are not modified by entmod -- it is a no-op"
 :dialects
 "The autolisp-spec, following AutoCAD, specifies that ENTMOD does not
modify the contents of a non-graphical object (XRECORD, DICTIONARY):
the call is a no-op. Such objects are edited through the object protocol
 (=vlax-put=) or the =dict*= functions.

BricsCAD applies the change. Again a recognised, non-condoned
divergence: under --autocad, --clautolisp and --strict the call stays a
no-op, and this note explains why nothing happened."
 :rationale
 "Silently doing nothing is the worst outcome to debug, and it is what
AutoCAD does. The note turns it into something you can see, and names
the two APIs that do work."
 :references
 '(("clautolisp: emitted by" . "clautolisp/cador/source/entity-api.lisp, EMIT-ENTMOD-OBJECT-DIVERGENCE-WARNING")
   ("clautolisp: the D3 divergence" . "issues/open/vendor-probe-autocad-bricscad-divergences.issue")))

;;; ------------------------------------------------------------------
;;; :encoding — the *ENC-DIAGNOSTIC-CODES* family
;;; ------------------------------------------------------------------
;;;
;;; These eight share one emitter (SIGNAL-ENCODING-DIAGNOSTIC) and one
;;; suppression surface, but each call site writes its own text, so
;;; MESSAGE stays empty here and EXAMPLE carries a real line. They are
;;; ALSO uniformly silenced by --lax, like every other dialect
;;; diagnostic, and are never runtime errors.
;;;
;;; The authoritative per-code descriptions are in
;;; issues/closed/encoding-dispatch.issue under "Diagnostics"; what is
;;; recorded here is what a user needs to act, not a second spec.

(register-dialect-warning
 :tag "enc-foreign-dialect"
 :title "Encoding control belonging to another dialect"
 :kind :encoding
 :arguments "varies by call site"
 :example ": [enc-foreign-dialect] LOAD's positional [encoding] argument (\"cp1252\") is a clautolisp extension; --autocad has no per-call encoding control on LOAD."
 :dialects
 "Fires when a program uses an encoding control that exists in SOME
dialect but not the selected one -- LOAD's positional encoding argument,
OPEN's encoding options, the LISPSYS sysvar. The message names both the
spelling and the dialect that does not have it. Silent under --lax."
 :rationale
 "Encoding controls are the least portable corner of AutoLISP: each
engine grew its own, and using the wrong one is silent -- the argument
is ignored and the file is decoded with the default. The diagnostic is
the only sign."
 :references
 '(("clautolisp: authoritative descriptions" . "issues/closed/encoding-dispatch.issue, section \"Diagnostics\"")
   ("clautolisp: the situation model" . "issues/open/encoding-situations-cli-options.issue")))

(register-dialect-warning
 :tag "enc-extension-used"
 :title "Any encoding extension, under --strict"
 :kind :encoding
 :arguments "varies by call site"
 :example ": [enc-extension-used] OPEN encoding (\"utf-8\") is a clautolisp extension; --strict reports every encoding extension."
 :dialects
 "The --strict counterpart of enc-foreign-dialect: --strict reports EVERY
encoding extension, whoever's it is, because strict means portable
AutoLISP and portable AutoLISP has no encoding control at all. Only
--strict emits this; other dialects emit enc-foreign-dialect instead
when the spelling is foreign to them."
 :rationale
 "It is the switch to run before shipping to an unknown engine: it lists
every place the program depends on an encoding facility that portable
AutoLISP does not define."
 :references
 '(("clautolisp: authoritative descriptions" . "issues/closed/encoding-dispatch.issue, section \"Diagnostics\"")))

(register-dialect-warning
 :tag "enc-unsupported-target"
 :title "Encoding not expressible on the target"
 :kind :encoding
 :arguments "varies by call site"
 :example ": [enc-unsupported-target] OPEN: encoding :UTF-16LE has no AutoCAD-native expression (UTF-16 / UTF-32 are not in scope)."
 :dialects
 "Two distinct causes share this code:

- the selected encoding has no expression on the TARGET dialect's engine
  (UTF-16 / UTF-32 are out of scope for AutoCAD's AutoLISP), or
- the encoding is not available on the running Common Lisp
  implementation.

Since 1.8.28 the second cause is much rarer: clautolisp carries its own
single-octet codecs (the CP-125x family, KOI8) built from babel, so the
CP-125x encodings are available on every host regardless of what SBCL or
CCL provides."
 :rationale
 "This is the code that tells you a program cannot be made to work as
written on the target, rather than merely being non-portable -- there is
no spelling that would express the request there."
 :references
 '(("clautolisp: authoritative descriptions" . "issues/closed/encoding-dispatch.issue, section \"Diagnostics\"")
   ("clautolisp: host-independent codecs" . "issues/closed/cp1252-codec-host-independent.issue")))

(register-dialect-warning
 :tag "enc-invalid-value"
 :title "Unparsable encoding name"
 :kind :encoding
 :arguments "varies by call site"
 :example ": [enc-invalid-value] encoding \"utf8!\" is not a recognised encoding name."
 :dialects
 "The encoding name given is not one clautolisp can parse at all -- a
typo rather than a portability question. Listed here because it is part
of the same closed code set and the same suppression surface.

NOTE for anyone auditing the tags by grepping the sources: this code
never appears as a literal =[enc-invalid-value]= anywhere, because
SIGNAL-ENCODING-DIAGNOSTIC builds the bracket from the code keyword. It
is real all the same."
 :rationale
 "Separated from enc-unknown-codepage, which is about a codepage the
drawing or the host names and clautolisp cannot map -- a different
situation with a different remedy."
 :references
 '(("clautolisp: the code set" . "clautolisp/autolisp-runtime/source/api.lisp, *ENC-DIAGNOSTIC-CODES*")))

(register-dialect-warning
 :tag "enc-lispsys-out-of-range"
 :title "LISPSYS set outside {0,1,2}"
 :kind :encoding
 :arguments "varies by call site"
 :example ": [enc-lispsys-out-of-range] (setvar \"LISPSYS\" 3): valid values are 0 (legacy MBCS), 1, or 2 (Unicode)."
 :dialects
 "LISPSYS is an AutoCAD-only sysvar selecting how AutoLISP source files
are decoded: 0 is legacy MBCS (the host codepage), 1 and 2 are Unicode.
Any other value is out of range.

Two things about it are worth knowing and are not obvious. It is
RESTART-LEVEL: =(setvar \"LISPSYS\" n)= in a running session does not
change how that session decodes anything -- only a relaunched AutoCAD
sees the new value. And under alfe it is effectively pinned at 0,
because alfe passes accoreconsole's =/isolate=, which prevents sysvar
changes from persisting."
 :rationale
 "A program that sets LISPSYS expecting an immediate effect gets none,
with no error. Two levels of silence stacked on each other."
 :references
 '(("clautolisp: measured behaviour" . "issues/open/encoding-situations-cli-options.issue, experiment E1")
   ("clautolisp: authoritative descriptions" . "issues/closed/encoding-dispatch.issue, section \"Diagnostics\"")))

(register-dialect-warning
 :tag "enc-codepage-mismatch"
 :title "DWGCODEPAGE differs from SYSCODEPAGE"
 :kind :encoding
 :arguments "varies by call site"
 :example ": [enc-codepage-mismatch] DWGCODEPAGE (\"ansi_1251\") differs from SYSCODEPAGE (\"ansi_1252\"); strings authored under the drawing's codepage may garble."
 :dialects
 "The drawing declares the codepage its strings were authored in
 (DWGCODEPAGE); the host declares the one it interprets strings with
 (SYSCODEPAGE). When they differ, every non-ASCII character in the
drawing is at risk of being read as a different character."
 :rationale
 "The failure is data corruption that looks like a font problem: the
bytes are intact and are being decoded with the wrong table. Knowing
which two codepages disagree is what makes it fixable."
 :references
 '(("clautolisp: authoritative descriptions" . "issues/closed/encoding-dispatch.issue, section \"Diagnostics\"")))

(register-dialect-warning
 :tag "enc-unknown-codepage"
 :title "Codepage clautolisp cannot map"
 :kind :encoding
 :arguments "varies by call site"
 :example ": [enc-unknown-codepage] Codepage \"ansi_1361\" is not recognised by clautolisp; falling back to it as-is."
 :dialects
 "A SYSCODEPAGE or DWGCODEPAGE string that clautolisp has no mapping
for. The value is passed through unchanged rather than replaced by a
guess, so the diagnostic is the only sign that no translation happened."
 :rationale
 "Distinct from enc-invalid-value: here the name is plausible and comes
from the drawing or the host, not from your program. The remedy is to
add the mapping, not to fix a typo."
 :references
 '(("clautolisp: authoritative descriptions" . "issues/closed/encoding-dispatch.issue, section \"Diagnostics\"")))

(register-dialect-warning
 :tag "enc-host-dependent"
 :title "Write resolving to the host's codepage"
 :kind :encoding
 :arguments "varies by call site"
 :example ": [enc-host-dependent] OPEN: writing under \"ANSI\" resolves to the host's SYSCODEPAGE at I/O time; output is not portable across hosts."
 :dialects
 "Info-level. Writing with the encoding named \"ANSI\" does not name a
codepage -- it defers to whatever SYSCODEPAGE the host has at the moment
of the write. The same program run on two machines then produces two
different files."
 :rationale
 "It is the one encoding diagnostic about output rather than input, and
the damage is invisible locally: the file reads back correctly on the
machine that wrote it. Naming a codepage explicitly (e.g. CP-1252)
fixes it."
 :references
 '(("clautolisp: authoritative descriptions" . "issues/closed/encoding-dispatch.issue, section \"Diagnostics\"")))

;;; ------------------------------------------------------------------
;;; :trust — the *SECURELOAD-DIAGNOSTIC-CODES* family
;;; ------------------------------------------------------------------

(register-dialect-warning
 :tag "sec-untrusted-load"
 :title "LOAD of a gated file from an untrusted location"
 :kind :trust
 :arguments "varies by call site"
 :example ": [sec-untrusted-load] loading \"/tmp/x.lsp\" from a location that is not in the trusted paths."
 :dialects
 "The SECURELOAD trust model gates loading executable AutoLISP from
locations outside the trusted paths. At SECURELOAD 1 the load is
honoured and this diagnostic is emitted (warn-and-proceed); at the
stricter setting it is refused instead. Silent under --lax.

Listed in this register because it shares the bracketed-tag shape and
the once-per-run, never-an-error discipline -- but note it is a TRUST
diagnostic, not a portability one: the same program on the same engine
warns or not depending on where its files sit."
 :rationale
 "A load from an untrusted location is how hostile AutoLISP arrives in a
CAD session. Warn-and-proceed is a deliberate middle setting, and this
line is the whole of its output."
 :references
 '(("clautolisp: the code set" . "clautolisp/autolisp-runtime/source/api.lisp, *SECURELOAD-DIAGNOSTIC-CODES*")
   ("clautolisp: the trust model" . "clautolisp/autolisp-builtins-core/source/secureload.lisp")))

(register-dialect-warning
 :tag "sec-untrusted-open"
 :title "OPEN of a gated-extension file from an untrusted location"
 :kind :trust
 :arguments "varies by call site"
 :example ": [sec-untrusted-open] opening \"/tmp/x.fas\" from a location that is not in the trusted paths."
 :dialects
 "The OPEN counterpart of sec-untrusted-load: the same trust gate,
applied to opening a file whose extension is one of the gated,
executable ones. Same warn-and-proceed semantics, same suppression,
silent under --lax."
 :rationale
 "Opening is how a gated file gets read before it gets run; gating both
closes the obvious way round the LOAD check."
 :references
 '(("clautolisp: the code set" . "clautolisp/autolisp-runtime/source/api.lisp, *SECURELOAD-DIAGNOSTIC-CODES*")
   ("clautolisp: the trust model" . "clautolisp/autolisp-builtins-core/source/secureload.lisp")))

;;; ==================================================================
;;; PART 2 — the construct catalogue, keyed by LABEL
;;; ==================================================================
;;;
;;; The register above answers "what does tag T mean?"; the catalogue
;;; below answers "is construct C supported under dialect D?". They meet
;;; at PORTABILITY-CONSTRUCT-TAG: every catalogued construct names the
;;; register entry that explains it, and several constructs share one
;;; tag (LET, SETF and LET* are all [ext-bricscad-undocumented]).

;;; ------------------------------------------------------------------
;;; The entry
;;; ------------------------------------------------------------------

(defstruct (portability-construct
            (:constructor %make-portability-construct))
  "One catalogued construct and the dialects that support it.

LABEL     the construct as a user writes it (\"LET\", \"SETF\", \"&REST\").
KIND      :provided  -- clautolisp implements it, so a use is silent
                        here and the diagnostic is purely advisory;
          :declined  -- clautolisp deliberately does NOT implement it
                        (the vendor behaviour is not worth imitating),
                        so a use is already an error and the
                        diagnostic explains WHY rather than warning.
TAG       the bracketed diagnostic tag, e.g. \"ext-bricscad-undocumented\".
NATIVE-IN the dialect names whose target host provides the construct.
SILENT-IN dialect names that never warn even though their host lacks
          it -- :lax (accept every vendor's extension quietly) and
          :clautolisp (its own blessed extensions).
SUMMARY   one line on what the construct is, for the linter and for
          the :declined explanation.
EVIDENCE  where the behaviour was established, so a reader can audit
          the entry without digging through issues."
  (label "" :type string)
  (kind :provided :type keyword)
  (tag "" :type string)
  (native-in '() :type list)
  (silent-in '() :type list)
  (summary "" :type string)
  (evidence "" :type string))

(defvar *portability-constructs* (make-hash-table :test #'equal)
  "LABEL (upcased string) -> PORTABILITY-CONSTRUCT.")

(defun register-portability-construct (&rest initargs &key label &allow-other-keys)
  "Add or replace the catalogue entry for LABEL. Returns the entry."
  (let ((entry (apply #'%make-portability-construct initargs)))
    (setf (gethash (string-upcase label) *portability-constructs*) entry)))

(defun find-portability-construct (label)
  "The catalogue entry for LABEL (a string, case-insensitive), or NIL.
This is the only lookup: emitters and analysers both come through here."
  (and (stringp label)
       (gethash (string-upcase label) *portability-constructs*)))

(defun map-portability-constructs (function)
  "Call FUNCTION on each catalogue entry. For consumers that enumerate
rather than look up -- a static linter, a documentation generator, or a
`--list-portability-constructs' style report."
  (maphash (lambda (label entry) (declare (ignore label)) (funcall function entry))
           *portability-constructs*))

(defun portability-construct-supported-p (entry dialect-name)
  "T iff DIALECT-NAME's target host provides ENTRY's construct natively."
  (and entry (member dialect-name (portability-construct-native-in entry)) t))

(defun portability-construct-silent-p (entry dialect-name)
  "T iff no diagnostic should be emitted for ENTRY under DIALECT-NAME --
either the host provides the construct, or the dialect is one that
accepts extensions quietly. NIL when ENTRY is NIL: an unknown construct
is not the catalogue's business and never warns."
  (and entry
       (or (portability-construct-supported-p entry dialect-name)
           (and (member dialect-name (portability-construct-silent-in entry)) t))))

;;; ------------------------------------------------------------------
;;; The catalogue
;;; ------------------------------------------------------------------
;;;
;;; Evidence for the five BricsCAD entries is one harvest run against a
;;; real BricsCAD V26 -- CI job vendor:probes:bricscad:macos on master
;;; @ b97d9fd, 2026-08-07, transcript
;;; dist/vendor-probes/bricscad/bricscad-extensions.log. It is worth
;;; reading the raw EXTPROBE values before changing any entry below:
;;; two of the five refuted what the issue had assumed.

(defparameter +bricscad-harvest-evidence+
  "vendor:probes:bricscad:macos harvest against real BricsCAD V26, 2026-08-07"
  "Shared provenance string for the entries the BricsCAD harvest settled.")

(register-portability-construct
 :label "LET"
 :kind :provided
 :tag "ext-bricscad-undocumented"
 ;; Confirmed a REAL extension: EXTPROBE LET-SUM=3 and
 ;; LET-PARALLEL=(1 10) -- the inner Y saw the OUTER X, so the
 ;; bindings are parallel, CL-style. clautolisp implements it.
 :native-in '(:bricscad-v25 :bricscad-v26)
 :silent-in '(:clautolisp :lax)
 :summary "CL-style LET with parallel bindings; portable AutoLISP has no LET."
 :evidence +bricscad-harvest-evidence+)

(register-portability-construct
 :label "SETF"
 :kind :declined
 :tag "ext-bricscad-undocumented"
 ;; NOT a setq alias, and not worth imitating: the harvest returned a
 ;; constant 2 for every value written (nil/1/2/99/"hello"/'(a b)),
 ;; and SETF-THEN-FOO=nil proved it does not assign at all. So the
 ;; "2" is an internal sentinel. clautolisp leaves SETF undefined
 ;; rather than reproduce a broken operator.
 :native-in '()          ; nothing "supports" it in a usable sense
 :silent-in '()          ; the explanation is useful under every dialect
 :summary "BricsCAD's SETF returns a constant sentinel 2 and does NOT assign; clautolisp declines to imitate it."
 :evidence +bricscad-harvest-evidence+)

(register-portability-construct
 :label "LET*"
 :kind :declined
 :tag "ext-bricscad-undocumented"
 ;; The issue assumed LET* was a silent BricsCAD extension; the
 ;; harvest refuted that outright -- "no function definition <LET*>".
 ;; So it is not a vendor extension at all, and adding it would be a
 ;; pure clautolisp invention.
 :native-in '()
 :silent-in '()
 :summary "LET* does not exist on BricsCAD V26 either; it is not a vendor extension."
 :evidence +bricscad-harvest-evidence+)

;;; The two rest-parameter spellings. These predate the catalogue; since
;;; pjb's 2026-08-14 ruling their message text comes from the register's
;;; "lambda-list-extension" entry like every other, and these entries
;;; carry only the support decision.

(register-portability-construct
 :label "&REST"
 :kind :provided
 :tag "lambda-list-extension"
 ;; EXTPROBE REST-BINDS=(2 3 4): the CL spelling works on BricsCAD.
 :native-in '(:bricscad-v25 :bricscad-v26)
 :silent-in '(:clautolisp :lax)
 :summary "Rest parameter in a defun/lambda lambda-list, spelled &REST."
 :evidence +bricscad-harvest-evidence+)

(register-portability-construct
 :label "&"
 :kind :provided
 :tag "lambda-list-extension"
 ;; EXTPROBE AMP-BINDS=ERROR:too few / too many -- BricsCAD REJECTS
 ;; the bare ampersand, so unlike &REST it is native to no vendor.
 ;; clautolisp still accepts it (its own historical spelling), which
 ;; is exactly why it warns everywhere except clautolisp/lax.
 :native-in '()
 :silent-in '(:clautolisp :lax)
 :summary "Rest parameter spelled with a bare &; accepted by clautolisp only, rejected by BricsCAD."
 :evidence +bricscad-harvest-evidence+)

;;; ==================================================================
;;; PART 3 — keeping the two tables in step, and rendering the annex
;;; ==================================================================

(defun unregistered-construct-tags ()
  "Tags named by a catalogued construct that have NO register entry.

The two tables are separate by design (one is keyed by construct, the
other by tag), which means they can drift: a new construct can name a
tag nobody documented, and the user would then get a bracketed
identifier that leads nowhere. This is the check that catches it; a
test calls it and it must stay empty."
  (let ((missing '()))
    (map-portability-constructs
     (lambda (entry)
       (let ((tag (portability-construct-tag entry)))
         (when (and (plusp (length tag))
                    (not (find-dialect-warning tag))
                    (not (member tag missing :test #'string=)))
           (push tag missing)))))
    (nreverse missing)))

(defun unregistered-diagnostic-codes (codes)
  "Those of CODES (a list of diagnostic-code keywords, e.g.
*ENC-DIAGNOSTIC-CODES*) that have no register entry.

The reason this exists: those families build their bracketed tag from
the code keyword at emission time, so the tag appears NOWHERE as a
literal in the sources. Grepping for `[enc-...]' finds only the codes
that happen to be named in a comment, misses the rest, and cannot tell
a real tag from a struct named in brackets. A test calls this with each
closed code set instead, which is exact: add a code without documenting
it and the suite fails."
  (remove-if (lambda (code)
               (find-dialect-warning (string-downcase (symbol-name code))))
             codes))

(defun render-dialect-warnings-annex (&optional (stream *standard-output*))
  "Write the register to STREAM as an org-mode annex for the user manual.

GENERATED, never hand-edited: the register in this file is the single
source, so an entry improved here reaches the manual by re-running the
generator (clautolisp/tools/generate-dialect-warnings-annex.lisp) rather
than by editing prose twice and letting the two drift."
  (format stream "# -*- mode:org; coding:utf-8 -*-~%")
  (format stream "#+TITLE: Annex: dialect portability warnings~%")
  (format stream "#+OPTIONS: toc:2~%~%")
  (format stream "/Generated from the register in~%")
  (format stream "=clautolisp/autolisp-runtime/source/portability.lisp=. Do not edit this~%")
  (format stream "file: edit the register and re-run~%")
  (format stream "=clautolisp/tools/generate-dialect-warnings-annex.lisp=./~%~%")
  (format stream "Every dialect portability warning clautolisp emits carries a~%")
  (format stream "bracketed *tag* identifying it:~%~%")
  (format stream ": [path-dotdot] drawing.lsp:42 in LOAD-BLOCK: OPEN \"../lib/a.dwg\": `..' resolves differently on POSIX and Windows~%~%")
  (format stream "The line is deliberately short. The tag is the stable name of the~%")
  (format stream "warning -- what to grep for, and what to look up here. The location~%")
  (format stream "is =FILE:LINE in FUNCTION=, with whichever parts are known.~%~%")
  (format stream "A warning fires *once per source occurrence per run*, so a construct~%")
  (format stream "inside a loop reports once, and a construct in a branch that is never~%")
  (format stream "reached never reports at all.~%~%")
  (format stream "Every warning is advisory: the program runs. Passing~%")
  (format stream "=--portability-warning-mode error= turns a fired warning into a runtime~%")
  (format stream "error instead (autolisp-spec ch.25); it is opt-in and never a dialect~%")
  (format stream "default, because it changes whether the program runs.~%")
  (format stream "~%The tags fall into five families. They share the bracketed shape~%")
  (format stream "and the once-per-run discipline, but not their mechanism, so the~%")
  (format stream "annex keeps them apart.~%")
  (dolist (family '((:portability
                     . "Portability warnings --- a construct one engine has and another does not")
                    (:extension-notice
                     . "Extension notices --- a clautolisp extension used outside =--dialect clautolisp=")
                    (:vendor-divergence
                     . "Vendor divergences --- clautolisp follows the spec where a vendor does not")
                    (:encoding
                     . "Encoding diagnostics --- the closed =*ENC-DIAGNOSTIC-CODES*= set")
                    (:trust
                     . "Trust diagnostics --- the SECURELOAD warn-and-proceed path")))
    (let ((entries '()))
      (map-dialect-warnings
       (lambda (entry)
         (when (eq (dialect-warning-kind entry) (car family))
           (push entry entries))))
      (setf entries (nreverse entries))
      (when entries
        (format stream "~%* ~A~%" (cdr family))
        (dolist (entry entries)
          (format stream "~%** =[~A]= --- ~A~%~%" (dialect-warning-tag entry)
                  (dialect-warning-title entry))
          (format stream "*** Message~%~%")
          (format stream "~A~%~%" (dialect-warning-example entry))
          (if (plusp (length (dialect-warning-message entry)))
              (format stream
                      "The part after the location is built from the template~%=~A=, whose arguments are: ~A.~%~%"
                      (dialect-warning-message entry)
                      (dialect-warning-arguments entry))
              (format stream
                      "The wording varies: this code is emitted from several call sites,~%each writing its own message. What is stable is the tag.~%~%"))
          (format stream "*** How the dialects diverge~%~%~A~%~%"
                  (dialect-warning-dialects entry))
          (format stream "*** Why it matters~%~%~A~%~%"
                  (dialect-warning-rationale entry))
          (format stream "*** References~%~%")
          (dolist (reference (dialect-warning-references entry))
            (format stream "- ~A: ~A~%" (car reference) (cdr reference)))))))
  (values))
