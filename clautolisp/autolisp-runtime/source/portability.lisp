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

;;; The two rest-parameter spellings. These predate the catalogue and
;;; their message text is pinned by existing tests and, per the
;;; governing issue, the canonical wording is a pjb decision -- so the
;;; emitter keeps its own format string and consults these entries only
;;; for the support decision.

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
