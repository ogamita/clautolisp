(in-package #:clautolisp.autolisp-reader.internal)

;;;; AutoLISP dialect descriptors.
;;;;
;;;; Phase 6 introduces a small shared value object that captures the
;;;; specific choices a particular AutoLISP dialect makes. The reader
;;;; consumes the descriptor to derive a `reader-options`; the runtime
;;;; consumes it to drive runtime-level switches (e.g. lex models for
;;;; `atof`, `open` mode-string surface). The descriptor is *not* a
;;;; behaviour table in itself — it is a labelled, version-qualified
;;;; selector that downstream code keys on.
;;;;
;;;; Distinct dialect descriptors:
;;;;
;;;;   :strict      — the conservative `clautolisp` profile. Strict
;;;;                  reader, decimal-only `atof`, no host-specific
;;;;                  extensions. Default for unit tests and any
;;;;                  cross-vendor portable code.
;;;;   :autocad-2026 — AutoCAD 2026 surface. Strict reader (Autodesk
;;;;                  documents the lexical grammar tightly), printer
;;;;                  surface as documented for AutoCAD.
;;;;   :bricscad-v26 — BricsCAD V26 surface. Lax reader (BricsCAD's
;;;;                  V25 introduced extended permissive integers and
;;;;                  `\n`-aware strings), `atof` accepts C99 hex-float
;;;;                  per the Phase-5 product test, `open` accepts
;;;;                  `ccs=...` mode strings.
;;;;
;;;; Knobs the descriptor records (more may be added later, but every
;;;; downstream reader/runtime read MUST go through one of these
;;;; accessor names so the descriptor remains the single point of
;;;; truth):
;;;;
;;;;   :token-mode                     :strict / :lax
;;;;   :extended-string-escapes-p      reader option
;;;;   :warn-on-integer-overflow-p     reader option
;;;;   :canonical-case                 reader option
;;;;   :hex-float-atof-p               runtime: accept C99 hex-float
;;;;                                   in `atof`
;;;;   :open-ccs-mode-p                runtime: accept `r,ccs=UTF-8`
;;;;                                   etc. in `open`
;;;;   :unbound-variable-mode          runtime: :silent-nil returns
;;;;                                   nil on a bare reference to an
;;;;                                   unbound symbol — strict across
;;;;                                   every named AutoLISP dialect
;;;;                                   (autolisp-spec ch. 3,
;;;;                                   "Unbound-Variable Reference":
;;;;                                   the host language has no other
;;;;                                   way to expose the bound vs
;;;;                                   unbound distinction since
;;;;                                   `boundp` itself binds the
;;;;                                   tested symbol to nil).
;;;;                                   `:strict-error` is a non-
;;;;                                   conforming diagnostic mode for
;;;;                                   static-analysis or unit-test
;;;;                                   harnesses; programs that rely
;;;;                                   on it do not run on real
;;;;                                   AutoLISP hosts.
;;;;   :default-source-encoding        external-format used by `load`
;;;;                                   (and any reader-driven file
;;;;                                   read) when no explicit
;;;;                                   encoding is supplied. The
;;;;                                   strict dialect uses
;;;;                                   :iso-8859-1 — a 1-1 byte
;;;;                                   coding that never fails — to
;;;;                                   match the Autodesk pre-2025
;;;;                                   ANSI / MBCS legacy default.
;;;;                                   AutoCAD 2026 and BricsCAD V26
;;;;                                   default to :utf-8, matching
;;;;                                   the LISPSYS=1/2 contract and
;;;;                                   the AutoCAD 2025+ change of
;;;;                                   default file encoding.
;;;;   :default-file-encoding          external-format used by
;;;;                                   `open` when its third argument
;;;;                                   is omitted. Defaults match the
;;;;                                   source-encoding rule above.

(defstruct (autolisp-dialect
            (:constructor make-autolisp-dialect
                (&key
                 (name :strict)
                 (token-mode :strict)
                 (extended-string-escapes-p nil)
                 (warn-on-integer-overflow-p nil)
                 (canonical-case :upcase)
                 (hex-float-atof-p nil)
                 (open-ccs-mode-p nil)
                 (unbound-variable-mode :silent-nil)
                 (portability-warning-mode :warn)
                 (default-source-encoding :iso-8859-1)
                 (default-file-encoding   :iso-8859-1))))
  (name :strict :type keyword)
  (token-mode :strict :type keyword)
  (extended-string-escapes-p nil :type boolean)
  (warn-on-integer-overflow-p nil :type boolean)
  (canonical-case :upcase :type keyword)
  (hex-float-atof-p nil :type boolean)
  (open-ccs-mode-p nil :type boolean)
  (unbound-variable-mode :silent-nil :type keyword)
  ;; Dialect portability warnings (autolisp-spec ch.25): when a program
  ;; reaches a construct the dialect's target host lacks (e.g. `&REST'
  ;; under :strict / :autocad-2026), clautolisp still runs it but emits
  ;; an advisory warning. This knob is the optional warning->error
  ;; escalation, mirroring `:unbound-variable-mode :strict-error':
  ;;   :warn  (default) -- advisory, print once per occurrence, run on.
  ;;   :error           -- signal an AutoLISP runtime error instead
  ;;                      (non-conforming: changes whether the program
  ;;                      runs; opt-in, never a dialect default).
  (portability-warning-mode :warn :type keyword)
  (default-source-encoding :iso-8859-1 :type keyword)
  (default-file-encoding   :iso-8859-1 :type keyword))

(defparameter *autolisp-dialect-strict*
  (make-autolisp-dialect :name :strict))

(defparameter *autolisp-dialect-autocad-2026*
  (make-autolisp-dialect
   :name :autocad-2026
   :token-mode :strict
   :extended-string-escapes-p nil
   :warn-on-integer-overflow-p t
   :canonical-case :upcase
   :hex-float-atof-p nil
   :open-ccs-mode-p nil
   :unbound-variable-mode :silent-nil
   ;; AutoCAD 2025+ ships UTF-8 as the default file encoding (per
   ;; release-note quoted in autolisp-spec ch.7); the same rule
   ;; applies to LOAD when LISPSYS = 1 or 2.
   :default-source-encoding :utf-8
   :default-file-encoding   :utf-8))

(defparameter *autolisp-dialect-autocad-2022*
  ;; AutoCAD 2022 is the same AutoLISP surface as 2026 EXCEPT for the
  ;; default file/source encoding: UTF-8 became the AutoLISP default
  ;; only in AutoCAD 2025+ (autolisp-spec ch.7), so the 2022 baseline
  ;; is the legacy ANSI/MBCS one (modelled here as ISO-8859-1, the
  ;; conservative single-byte default also used by --strict). Any
  ;; finer 2022-vs-2026 behavioural divergence is a future refinement.
  (make-autolisp-dialect
   :name :autocad-2022
   :token-mode :strict
   :extended-string-escapes-p nil
   :warn-on-integer-overflow-p t
   :canonical-case :upcase
   :hex-float-atof-p nil
   :open-ccs-mode-p nil
   :unbound-variable-mode :silent-nil
   :default-source-encoding :iso-8859-1
   :default-file-encoding   :iso-8859-1))

(defparameter *autolisp-dialect-bricscad-v26*
  (make-autolisp-dialect
   :name :bricscad-v26
   :token-mode :lax
   :extended-string-escapes-p t
   :warn-on-integer-overflow-p t
   :canonical-case :upcase
   :hex-float-atof-p t
   :open-ccs-mode-p t
   :unbound-variable-mode :silent-nil
   :default-source-encoding :utf-8
   :default-file-encoding   :utf-8))

(defparameter *autolisp-dialect-bricscad-v25*
  ;; BricsCAD V25 currently mirrors V26 exactly — no AutoLISP-surface
  ;; divergence has been product-tested between the two yet. Kept as a
  ;; distinct, selectable descriptor so `--dialect bricscad-v25` works
  ;; and so a future V25-specific knob has a home.
  (make-autolisp-dialect
   :name :bricscad-v25
   :token-mode :lax
   :extended-string-escapes-p t
   :warn-on-integer-overflow-p t
   :canonical-case :upcase
   :hex-float-atof-p t
   :open-ccs-mode-p t
   :unbound-variable-mode :silent-nil
   :default-source-encoding :utf-8
   :default-file-encoding   :utf-8))

(defparameter *autolisp-dialect-clautolisp*
  ;; The clautolisp dialect is a superset of :strict — the conservative
  ;; reader and runtime knobs that work on every conforming host,
  ;; PLUS clautolisp-specific extensions (e.g. variadic functions via
  ;; &REST, future quality-of-life conveniences). Code written for
  ;; :clautolisp doesn't run unmodified on real AutoCAD / BricsCAD;
  ;; that's the user's choice when they pick `--dialect clautolisp'
  ;; over `--strict'. Default source/file encoding is UTF-8, matching
  ;; the modern AutoCAD/BricsCAD baseline rather than the legacy
  ;; AutoLISP ANSI/MBCS one — clautolisp is a 21st-century front-end
  ;; for code editing under contemporary tooling.
  (make-autolisp-dialect
   :name :clautolisp
   :token-mode :strict
   :extended-string-escapes-p nil
   :warn-on-integer-overflow-p nil
   :canonical-case :upcase
   :hex-float-atof-p nil
   :open-ccs-mode-p nil
   :unbound-variable-mode :silent-nil
   :default-source-encoding :utf-8
   :default-file-encoding   :utf-8))

(defparameter *autolisp-dialect-lax*
  ;; The lax dialect accepts every vendor's encoding extensions
  ;; without raising the diagnostic the strict / per-vendor dialects
  ;; would: the spec describes it as the catch-all for downstream
  ;; tools that consume code from multiple vendors and don't want to
  ;; commit to one. See encoding-dispatch.issue, section 'Per-dialect
  ;; behavior / --lax'.
  ;;
  ;; Other dialect knobs (token-mode, extended-string-escapes-p, …)
  ;; mirror the clautolisp dialect: lax only relaxes the encoding-
  ;; diagnostic gate, not the rest of the reader / runtime surface.
  (make-autolisp-dialect
   :name :lax
   :token-mode :strict
   :extended-string-escapes-p nil
   :warn-on-integer-overflow-p nil
   :canonical-case :upcase
   :hex-float-atof-p nil
   :open-ccs-mode-p t
   :unbound-variable-mode :silent-nil
   :default-source-encoding :utf-8
   :default-file-encoding   :utf-8))

(defparameter *autolisp-named-dialects*
  ;; Unversioned vendor names (:autocad, :bricscad) are ALIASES that
  ;; map to the last known version of that vendor (autocad -> 2026,
  ;; bricscad -> v26), per alfe-clautolisp-dialect.issue point 2.
  (list (cons :strict        *autolisp-dialect-strict*)
        (cons :autocad-2022  *autolisp-dialect-autocad-2022*)
        (cons :autocad-2026  *autolisp-dialect-autocad-2026*)
        (cons :autocad       *autolisp-dialect-autocad-2026*)   ; alias -> last known
        (cons :bricscad-v25  *autolisp-dialect-bricscad-v25*)
        (cons :bricscad-v26  *autolisp-dialect-bricscad-v26*)
        (cons :bricscad      *autolisp-dialect-bricscad-v26*)   ; alias -> last known
        (cons :clautolisp    *autolisp-dialect-clautolisp*)
        (cons :lax           *autolisp-dialect-lax*)))

(defparameter *autolisp-dialect-names*
  ;; The ordered, user-facing list of dialect names accepted by the
  ;; --dialect option and printed by --list-dialects. strict is always
  ;; first and lax always last (alfe-clautolisp-dialect.issue point 2).
  ;; An unversioned vendor name maps to the last known version.
  '(:strict
    :autocad-2022 :autocad-2026 :autocad
    :bricscad-v25 :bricscad-v26 :bricscad
    :clautolisp
    :lax)
  "Ordered list of selectable dialect-name keywords (strict first, lax
last). Drives --list-dialects and validates --dialect.")

(defun autolisp-dialect-name-string (keyword)
  "Render a dialect-name KEYWORD as its lower-case CLI string
(e.g. :autocad-2026 -> \"autocad-2026\")."
  (string-downcase (symbol-name keyword)))

(defun autolisp-dialect-names ()
  "Return the ordered list of selectable dialect-name strings."
  (mapcar #'autolisp-dialect-name-string *autolisp-dialect-names*))

(defun find-autolisp-dialect (name)
  "Return the canonical dialect descriptor named NAME (a keyword,
string, or unversioned alias), or nil."
  (cdr (assoc (cond ((keywordp name) name)
                    ((stringp name) (intern (string-upcase name) "KEYWORD"))
                    (t (error "Invalid dialect name ~S." name)))
              *autolisp-named-dialects*)))

(defun reader-options-from-dialect (dialect &key source-name retain-comments-p
                                                   recover-malformed-p)
  "Build a `reader-options` from DIALECT, optionally overriding the
non-dialect-level knobs."
  (make-reader-options
   :token-mode (autolisp-dialect-token-mode dialect)
   :extended-string-escapes-p (autolisp-dialect-extended-string-escapes-p dialect)
   :warn-on-integer-overflow-p (autolisp-dialect-warn-on-integer-overflow-p dialect)
   :canonical-case (autolisp-dialect-canonical-case dialect)
   :retain-comments-p retain-comments-p
   :recover-malformed-p recover-malformed-p
   :source-name source-name))
