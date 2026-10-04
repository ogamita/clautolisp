;;;; -*- mode:lisp; coding:utf-8 -*-
;;;;
;;;; Version-gated AutoLISP operators (dialect-platform-version-axis).
;;;;
;;;; pjb 2026-10-03: "when we have definite reference material specifying
;;;; differences between versions, we must implement them in different
;;;; dialect versions, even if we can't test them (yet)." Each row below is
;;;; a function the vendor documentation says appeared, or disappeared, in a
;;;; given release; its source is cited. A call of a gated operator under a
;;;; dialect of that product whose VERSION lacks it gets the
;;;; `[version-operator]' notice (once per operator per session; an error
;;;; under PORTABILITY-WARNING-MODE :error) -- the same treatment as a
;;;; vendor-only operator out of its dialect. Dialects without a version
;;;; (strict, clautolisp, lax) are never gated.
;;;;
;;;; Versions: AutoCAD by year (2014), BricsCAD by major version (21). A
;;;; BricsCAD point release (V22.2) is gated at its major version: the
;;;; dialects carry no minor version.

(in-package #:clautolisp.autolisp-runtime)

(defparameter *version-gated-operators*
  ;; (NAME PRODUCT SINCE UNTIL) -- available when SINCE <= version < UNTIL
  ;; (NIL = unbounded). Sources: help.autodesk.com "What's New or Changed
  ;; with AutoLISP" (GUID-037BF4D4-755E-4A5C-8136-80E85CCEDF3E) and the
  ;; function pages; BricsCAD release notes (boa.bricscad.octave.com
  ;; releasenotes.jsp) and the DevRef history pages.
  '(;; AutoCAD 2013: new, Windows only.
    ("VLAX-MACHINE-PRODUCT-KEY" :autocad 2013 nil)
    ;; AutoCAD 2014: new.
    ("FINDTRUSTEDFILE" :autocad 2014 nil)
    ("SHOWHTMLMODALWINDOW" :autocad 2014 nil)
    ;; AutoCAD 2025: new, Windows only.
    ("ACET-LOAD-EXPRESSTOOLS" :autocad 2025 nil)
    ;; BricsCAD V18.1: dos_command added.
    ("DOS_COMMAND" :bricscad 18 nil)
    ;; BricsCAD V19.2.14: (vle-enableserverbusy).
    ("VLE-ENABLESERVERBUSY" :bricscad 19 nil)
    ;; BricsCAD V21.1.04: property functions, vl-infp / vl-nanp.
    ("DUMPALLPROPERTIES" :bricscad 21 nil)
    ("GETPROPERTYVALUE" :bricscad 21 nil)
    ("ISPROPERTYVALID" :bricscad 21 nil)
    ("VL-INFP" :bricscad 21 nil)
    ("VL-NANP" :bricscad 21 nil)
    ;; BricsCAD V22: vla-PostCommand (22.1.04), vle-file-encoding (22.2.04).
    ("VLA-POSTCOMMAND" :bricscad 22 nil)
    ("VLE-FILE-ENCODING" :bricscad 22 nil)
    ;; BricsCAD V23.1: vl-subent-*, vle-sunid.
    ("VL-SUBENT-ATPOINT" :bricscad 23 nil)
    ("VLE-SUNID" :bricscad 23 nil)
    ;; BricsCAD V24: local undo.
    ("VL-LOCAL-UNDO-PUSH" :bricscad 24 nil)
    ;; BricsCAD V25.1.06: vle-vector-to2d.
    ("VLE-VECTOR-TO2D" :bricscad 25 nil)
    ;; BricsCAD V26.1.07: "We removed the (mod) and (round) functions, as
    ;; they are not compatible with AutoLISP."
    ("MOD" :bricscad nil 26)
    ("ROUND" :bricscad nil 26))
  "(NAME PRODUCT SINCE UNTIL): the operators a product's documentation says
appeared (SINCE) or were removed (UNTIL) in a given version.")

(defun version-gated-operator-gates (name)
  "The (PRODUCT SINCE UNTIL) gates of operator NAME, or NIL."
  (loop for (row-name product since until) in *version-gated-operators*
        when (string-equal row-name name)
          collect (list product since until)))

(defun %version-gate-violation (gates product version)
  "The gate GATES PRODUCT / VERSION falls outside, or NIL."
  (and (integerp version)
       (find-if (lambda (gate)
                  (destructuring-bind (gate-product since until) gate
                    (and (eq gate-product product)
                         (or (and since (< version since))
                             (and until (>= version until))))))
                gates)))
