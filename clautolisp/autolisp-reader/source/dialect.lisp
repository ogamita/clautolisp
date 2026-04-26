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
                 (unbound-variable-mode :silent-nil))))
  (name :strict :type keyword)
  (token-mode :strict :type keyword)
  (extended-string-escapes-p nil :type boolean)
  (warn-on-integer-overflow-p nil :type boolean)
  (canonical-case :upcase :type keyword)
  (hex-float-atof-p nil :type boolean)
  (open-ccs-mode-p nil :type boolean)
  (unbound-variable-mode :silent-nil :type keyword))

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
   :unbound-variable-mode :silent-nil))

(defparameter *autolisp-dialect-bricscad-v26*
  (make-autolisp-dialect
   :name :bricscad-v26
   :token-mode :lax
   :extended-string-escapes-p t
   :warn-on-integer-overflow-p t
   :canonical-case :upcase
   :hex-float-atof-p t
   :open-ccs-mode-p t
   :unbound-variable-mode :silent-nil))

(defparameter *autolisp-named-dialects*
  (list (cons :strict *autolisp-dialect-strict*)
        (cons :autocad-2026 *autolisp-dialect-autocad-2026*)
        (cons :bricscad-v26 *autolisp-dialect-bricscad-v26*)))

(defun find-autolisp-dialect (name)
  "Return the canonical dialect descriptor named NAME, or nil."
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
