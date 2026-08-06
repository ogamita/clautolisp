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
                 (product nil)
                 (platform nil)
                 (version nil)
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
  ;; The platform + version axis (dialect-platform-version-axis.issue).
  ;; PRODUCT   — :autocad / :bricscad, or NIL for the vendor-neutral
  ;;             profiles (:strict / :clautolisp / :lax).
  ;; PLATFORM  — :windows / :macos / :linux, or NIL when the profile is
  ;;             platform-independent (strict/clautolisp/lax). The vendor
  ;;             dialects carry a concrete platform so builtins can gate
  ;;             platform-specific portability diagnostics (e.g. the
  ;;             `/...' subfolder-recursion warning that fires only on
  ;;             AutoCAD-Windows).
  ;; VERSION   — the product release as an integer (AutoCAD calendar year
  ;;             2022/2026/2027…; BricsCAD major 25/26…), or NIL when the
  ;;             profile is not tied to a specific release. When the CLI
  ;;             names a bare product (`--dialect autocad'), VERSION is the
  ;;             "latest known" for that product (see
  ;;             *autolisp-dialect-latest-version*).
  (product nil :type (or null keyword))
  (platform nil :type (or null keyword))
  (version nil :type (or null integer))
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
   :product :autocad
   :platform :windows
   :version 2026
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
   :product :autocad
   :platform :windows
   :version 2022
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
   :product :bricscad
   :platform :windows
   :version 26
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
   :product :bricscad
   :platform :windows
   :version 25
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
    :autocad-2022 :autocad-2026 :autocad :autocad-mac
    :bricscad-v25 :bricscad-v26 :bricscad :bricscad-mac :bricscad-linux
    :clautolisp
    :lax)
  "Ordered list of selectable dialect-name keywords (strict first, lax
last). Drives --list-dialects and validates --dialect. Beyond the
enumerated entries the resolver also accepts derived platform+version
spellings (dialect-platform-version-axis.issue): a product optionally
suffixed with a platform (`-mac' / `-linux', windows being the default)
and/or a version (`autocad-2027', `autocad-mac-2027',
`bricscad-mac-v26'). See FIND-AUTOLISP-DIALECT.")

(defun autolisp-dialect-name-string (keyword)
  "Render a dialect-name KEYWORD as its lower-case CLI string
(e.g. :autocad-2026 -> \"autocad-2026\")."
  (string-downcase (symbol-name keyword)))

(defun autolisp-dialect-names ()
  "Return the ordered list of selectable dialect-name strings."
  (mapcar #'autolisp-dialect-name-string *autolisp-dialect-names*))

;;;; ------------------------------------------------------------------
;;;; Platform + version axis resolution (dialect-platform-version-axis).
;;;;
;;;; Beyond the enumerated named dialects, --dialect accepts DERIVED
;;;; spellings built from a product, an optional platform facet and an
;;;; optional version facet:
;;;;
;;;;   autocad              -> :autocad          windows, latest known
;;;;   autocad-mac          -> :autocad-mac      macOS,   latest known
;;;;   autocad-2022         -> :autocad-2022     windows, version 2022
;;;;   autocad-mac-2027     -> :autocad-mac-2027 macOS,   version 2027
;;;;   bricscad             -> :bricscad         windows, latest known
;;;;   bricscad-mac         -> :bricscad-mac     macOS,   latest known
;;;;   bricscad-linux       -> :bricscad-linux   linux,   latest known
;;;;   bricscad-mac-v26     -> :bricscad-mac-v26 macOS,   version 26
;;;;
;;;; When the platform is omitted it defaults to :windows; when the
;;;; version is omitted it resolves to the "latest known" for the
;;;; product. Derived descriptors are built once and cached so repeated
;;;; lookups return the SAME (EQ) object (dedup / identity keys rely on
;;;; it). The enumerated named dialects (including the legacy
;;;; :autocad-2026 / :bricscad-v26 keywords and the bare-product aliases)
;;;; still resolve through *autolisp-named-dialects* first, unchanged.

(defparameter *autolisp-dialect-latest-version*
  '((:autocad . 2026) (:bricscad . 26))
  "The `latest known' release per product, used when --dialect names a
bare product (or a platform variant) without a version. Bump these as
newer AutoCAD / BricsCAD releases are characterised. Kept at the values
the enumerated aliases already resolve to so existing resolution does
not shift.")

(defun %product-base-dialect (product)
  "The template descriptor whose behavioural knobs a derived PRODUCT
dialect inherits (the latest-known windows descriptor for that product)."
  (ecase product
    (:autocad  *autolisp-dialect-autocad-2026*)
    (:bricscad *autolisp-dialect-bricscad-v26*)))

(defun %split-on-dash (string)
  (loop with start = 0
        for pos = (position #\- string :start start)
        collect (subseq string start (or pos (length string)))
        while pos do (setf start (1+ pos))))

(defun %parse-product-version-token (product token)
  "Parse TOKEN as a version for PRODUCT. Return the integer version, or
NIL when TOKEN is not a version token for PRODUCT. AutoCAD versions are
4-digit calendar years (2022, 2026, 2027…); BricsCAD versions are a
`vNN' or bare-`NN' major number (v25, v26, 25, 26)."
  (case product
    (:autocad
     (when (and (= (length token) 4)
                (every #'digit-char-p token))
       (parse-integer token)))
    (:bricscad
     (let ((digits (if (and (plusp (length token))
                            (char-equal (char token 0) #\v))
                       (subseq token 1)
                       token)))
       (when (and (plusp (length digits))
                  (every #'digit-char-p digits))
         (parse-integer digits))))))

(defun %parse-dialect-spelling (name-string)
  "Decompose NAME-STRING (case-insensitive) into (values PRODUCT PLATFORM
VERSION EXPLICIT-VERSION-P) for a derived platform+version dialect
spelling, or NIL when it is not such a spelling. PLATFORM defaults to
:windows and VERSION to the product's latest known when the respective
facet is absent."
  (let* ((tokens (%split-on-dash (string-downcase name-string)))
         (product (cond ((string= (first tokens) "autocad")  :autocad)
                        ((string= (first tokens) "bricscad") :bricscad)
                        (t nil))))
    (when product
      (let ((platform nil) (version nil) (explicit-version-p nil))
        (dolist (token (rest tokens)
                       (values product
                               (or platform :windows)
                               (or version (cdr (assoc product *autolisp-dialect-latest-version*)))
                               explicit-version-p))
          (cond
            ((member token '("mac" "macos" "osx") :test #'string=)
             (setf platform :macos))
            ((member token '("windows" "win") :test #'string=)
             (setf platform :windows))
            ((string= token "linux")
             (setf platform :linux))
            (t (let ((v (%parse-product-version-token product token)))
                 (if v
                     (setf version v explicit-version-p t)
                     ;; unknown token -> not a recognised spelling
                     (return-from %parse-dialect-spelling nil))))))))))

(defun %canonical-dialect-keyword (product platform version explicit-version-p)
  "The canonical CLI keyword for a derived dialect: the product name,
plus `-mac' / `-linux' when PLATFORM is not :windows, plus a version
suffix when the version was given explicitly (`-2027' for AutoCAD,
`-v26' for BricsCAD)."
  (let ((prod (string-downcase (symbol-name product)))
        (plat (case platform (:macos "-mac") (:linux "-linux") (t "")))
        (ver  (cond ((not explicit-version-p) "")
                    ((eq product :bricscad) (format nil "-v~D" version))
                    (t (format nil "-~D" version)))))
    (intern (string-upcase (concatenate 'string prod plat ver)) "KEYWORD")))

(defparameter *synthesized-dialects* (make-hash-table :test #'eq)
  "Cache of derived platform+version descriptors, keyed by canonical
keyword, so repeated FIND-AUTOLISP-DIALECT calls return the same (EQ)
object.")

(defun %synthesize-dialect (product platform version explicit-version-p)
  (let ((canonical (%canonical-dialect-keyword product platform version explicit-version-p)))
    (or (gethash canonical *synthesized-dialects*)
        (setf (gethash canonical *synthesized-dialects*)
              (let ((d (copy-autolisp-dialect (%product-base-dialect product))))
                (setf (autolisp-dialect-name d)     canonical
                      (autolisp-dialect-product d)   product
                      (autolisp-dialect-platform d)  platform
                      (autolisp-dialect-version d)   version)
                ;; Version-specific encoding: AutoCAD adopted UTF-8 as the
                ;; AutoLISP default only in 2025+ (autolisp-spec ch.7); an
                ;; earlier explicit year keeps the legacy single-byte
                ;; default, mirroring the enumerated :autocad-2022.
                (when (and (eq product :autocad) (integerp version) (< version 2025))
                  (setf (autolisp-dialect-default-source-encoding d) :iso-8859-1
                        (autolisp-dialect-default-file-encoding d)   :iso-8859-1))
                d)))))

(defun find-autolisp-dialect (name)
  "Return the dialect descriptor named NAME (a keyword, string, or
unversioned alias), or nil. Enumerated named dialects (including the
legacy :autocad-2026 / :bricscad-v26 keywords and the bare-product
aliases) resolve directly; otherwise NAME is parsed as a derived
platform+version spelling (dialect-platform-version-axis.issue):
`autocad-mac', `autocad-2027', `autocad-mac-2027', `bricscad-linux',
`bricscad-mac-v26', … Derived descriptors are cached (EQ-stable)."
  (let ((kw (cond ((keywordp name) name)
                  ((stringp name) (intern (string-upcase name) "KEYWORD"))
                  (t (error "Invalid dialect name ~S." name)))))
    (or (cdr (assoc kw *autolisp-named-dialects*))
        (multiple-value-bind (product platform version explicit-version-p)
            (%parse-dialect-spelling (symbol-name kw))
          (when product
            (%synthesize-dialect product platform version explicit-version-p))))))

;;;; ------------------------------------------------------------------
;;;; Feature / version matrix — SCAFFOLD (incremental).
;;;;
;;;; A data-driven table of which AutoLISP features / sysvars /
;;;; behaviours exist (or differ) per product+platform+version, sourced
;;;; incrementally by scanning each AutoCAD / BricsCAD release's
;;;; reference docs and by CAD probes (probes/, `make probe' — see
;;;; dialect-platform-version-axis.issue scope item 4). This is a large,
;;;; incrementally-populated table; only a couple of SEED entries are
;;;; provided here to fix the shape and exercise the lookup. DO NOT try
;;;; to populate every feature at once — add rows as ground truth is
;;;; established from docs/probes.
;;;;
;;;; Row shape: (FEATURE PRODUCT PLATFORM MIN-VERSION VALUE)
;;;;   FEATURE      — a keyword naming the feature/behaviour/sysvar.
;;;;   PRODUCT      — :autocad / :bricscad, or T for "any product".
;;;;   PLATFORM     — :windows / :macos / :linux, or T for "any platform".
;;;;   MIN-VERSION  — the earliest product version (integer) the VALUE
;;;;                  holds for, or NIL for "any / from the beginning".
;;;;   VALUE        — the feature's value/availability for that cell
;;;;                  (commonly T = available / NIL = absent, but may be
;;;;                  any datum, e.g. a default encoding keyword).
;;;;
;;;; Lookup: the MOST SPECIFIC matching row wins (a product/platform-
;;;; specific row beats a T wildcard; among version-matching rows the
;;;; highest MIN-VERSION <= the queried version wins).

(defparameter *autolisp-feature-matrix*
  '(;; UTF-8 became the AutoLISP default source/file encoding in
    ;; AutoCAD 2025+ (autolisp-spec ch.7); earlier AutoCAD is legacy
    ;; single-byte. BricsCAD V25/V26 are UTF-8 throughout.
    (:default-utf8-encoding :autocad  t 2025 t)
    (:default-utf8-encoding :autocad  t nil  nil)
    (:default-utf8-encoding :bricscad t nil  t)
    ;; The `/...' subfolder-recursion wildcard is accepted only with a
    ;; back slash on AutoCAD-Windows; AutoCAD-mac also accepts the
    ;; forward-slash spelling. (First platform-gated consumer; see
    ;; EMIT-FORWARD-SLASH-ELLIPSIS-PORTABILITY-WARNING.)
    (:forward-slash-ellipsis-ok :autocad :macos   nil t)
    (:forward-slash-ellipsis-ok :autocad :windows nil nil))
  "SEED feature/version matrix — see the block comment above for the row
shape and the incremental-population contract. Query via
DIALECT-FEATURE.")

(defun %feature-row-matches-p (row feature product platform version)
  (destructuring-bind (row-feature row-product row-platform row-min-version row-value) row
    (declare (ignore row-value))
    (and (eq row-feature feature)
         (or (eq row-product t)  (eq row-product product))
         (or (eq row-platform t) (eq row-platform platform))
         (or (null row-min-version)
             (and (integerp version) (>= version row-min-version))))))

(defun %feature-row-specificity (row)
  "A sortable specificity score: more concrete rows (named product /
platform, higher MIN-VERSION) beat wildcard/older rows."
  (destructuring-bind (feature product platform min-version value) row
    (declare (ignore feature value))
    (+ (if (eq product t) 0 100)
       (if (eq platform t) 0 100)
       (or min-version 0))))

(defun dialect-feature (feature product platform version)
  "Return (values VALUE FOUNDP) for FEATURE under PRODUCT/PLATFORM/VERSION
from *AUTOLISP-FEATURE-MATRIX*, picking the MOST SPECIFIC matching row.
FOUNDP is NIL (and VALUE NIL) when no row matches — the caller decides
the default for an uncharacterised cell."
  (let ((best nil) (best-score -1))
    (dolist (row *autolisp-feature-matrix*)
      (when (%feature-row-matches-p row feature product platform version)
        (let ((score (%feature-row-specificity row)))
          (when (> score best-score)
            (setf best row best-score score)))))
    (if best
        (values (fifth best) t)
        (values nil nil))))

(defun dialect-feature-for (dialect feature)
  "DIALECT-FEATURE keyed off a DIALECT descriptor's product/platform/
version facets."
  (dialect-feature feature
                   (autolisp-dialect-product dialect)
                   (autolisp-dialect-platform dialect)
                   (autolisp-dialect-version dialect)))

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
