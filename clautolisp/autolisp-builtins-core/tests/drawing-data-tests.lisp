(in-package #:clautolisp.autolisp-builtins-core.tests)

(in-suite autolisp-builtins-core-suite)

;;;; End-to-end AutoLISP tests for the drawing-data + selection layer
;;;; (REGAPP, XData round-trip, the named-object-dictionary tree,
;;;; XRECORD lifecycle, symbol tables, and the ssget filter grammar)
;;;; driven through the reader + evaluator against a fresh cador.
;;;;
;;;; Each program returns an integer (a count, or 1/0 for a boolean)
;;;; so the CL-side assertion is a simple EQL — no wrapper unwrapping.

(defun %dd-run (source)
  "Evaluate SOURCE through the evaluator on a fresh mock host; return
the raw result value."
  (reset-autolisp-symbol-table)
  (run-autolisp-string source :setup-fn #'%install-cador-and-core))

;;; --- REGAPP ------------------------------------------------------

(test dd-regapp-registers-then-rejects-duplicate
  ;; first regapp returns the name; second returns nil.
  (is (eql 1 (%dd-run "(if (and (regapp \"SCHMS\") (not (regapp \"SCHMS\"))) 1 0)")))
  ;; an invalid name (reserved char) fails via SNVALID -> nil
  (is (eql 1 (%dd-run "(if (regapp \"BAD/NAME\") 0 1)"))))

;;; --- Divergence D1: R13+ subclass-marker enforcement (dialect) ---

(defun %d1-run (source dialect-keyword)
  "Evaluate SOURCE under DIALECT-KEYWORD on a fresh mock host, capturing
*error-output*; return (values RESULT WARNING-STRING). FiveAM's progress
dots go to *standard-output*, so rebinding *error-output* is clean."
  (reset-autolisp-symbol-table)
  (let ((warn (make-string-output-stream))
        (dialect (or (clautolisp.autolisp-reader:find-autolisp-dialect dialect-keyword)
                     (error "unknown dialect ~S" dialect-keyword))))
    (let ((result (let ((*error-output* warn))
                    (run-autolisp-string source
                                         :dialect dialect
                                         :setup-fn #'%install-cador-and-core))))
      (values result (get-output-stream-string warn)))))

;; A marker-less ELLIPSE (R13+): AutoCAD rejects it, BricsCAD accepts it.
(defparameter *d1-markerless-ellipse*
  "(if (= (type (entmakex (list (cons 0 \"ELLIPSE\")
                                (cons 10 (list 0.0 0.0 0.0))
                                (cons 11 (list 1.0 0.0 0.0))
                                (cons 40 0.5) (cons 41 0.0) (cons 42 6.28))))
         'ENAME) 1 0)")

;; The same ELLIPSE WITH the AutoCAD subclass markers supplied.
(defparameter *d1-marked-ellipse*
  "(if (= (type (entmakex (list (cons 0 \"ELLIPSE\")
                                (cons 100 \"AcDbEntity\") (cons 100 \"AcDbEllipse\")
                                (cons 10 (list 0.0 0.0 0.0))
                                (cons 11 (list 1.0 0.0 0.0))
                                (cons 40 0.5) (cons 41 0.0) (cons 42 6.28))))
         'ENAME) 1 0)")

;; A marker-less LINE (pre-R13): accepted by every vendor, marker or not.
(defparameter *d1-markerless-line*
  "(if (= (type (entmakex (list (cons 0 \"LINE\")
                                (cons 10 (list 0.0 0.0 0.0))
                                (cons 11 (list 1.0 1.0 0.0)))))
         'ENAME) 1 0)")

;; The autolisp-spec resolves D1 in AutoCAD's favour (markers required),
;; so the NORMATIVE dialects (autocad, clautolisp, strict) reject
;; marker-less input; the DEVIANT dialects (bricscad, lax) accept it.
;; strict (any divergence) and bricscad (the non-condoned deviant) warn.

(test dd-d1-normative-dialects-reject-markerless-r13-entity
  (dolist (d '(:autocad-2026 :clautolisp :strict))
    (is (eql 0 (nth-value 0 (%d1-run *d1-markerless-ellipse* d)))
        "marker-less ELLIPSE should be rejected under ~S" d)))

(test dd-d1-deviant-dialects-accept-markerless-r13-entity
  (dolist (d '(:bricscad-v26 :lax))
    (is (eql 1 (nth-value 0 (%d1-run *d1-markerless-ellipse* d)))
        "marker-less ELLIPSE should be accepted under ~S" d)))

(test dd-d1-warns-under-bricscad-and-strict-only
  (dolist (d '(:bricscad-v26 :strict))
    (multiple-value-bind (r w) (%d1-run *d1-markerless-ellipse* d)
      (declare (ignore r))
      (is (search "entmake-subclass-marker" w)
          "expected the [entmake-subclass-marker] warning under ~S; got: ~S" d w)))
  (dolist (d '(:autocad-2026 :clautolisp :lax))
    (multiple-value-bind (r w) (%d1-run *d1-markerless-ellipse* d)
      (declare (ignore r))
      (is (string= "" w) "no warning expected under ~S; got: ~S" d w))))

(test dd-d1-explicit-markers-portable-across-all-dialects
  ;; With the markers supplied, the create succeeds everywhere — including
  ;; the strict dialects — with no warning.
  (dolist (d '(:autocad-2026 :strict :bricscad-v26 :clautolisp :lax))
    (multiple-value-bind (r w) (%d1-run *d1-marked-ellipse* d)
      (is (eql 1 r) "marked ELLIPSE should create under ~S" d)
      (is (string= "" w) "no warning expected under ~S; got: ~S" d w))))

(test dd-d1-pre-r13-entity-unaffected-by-marker-contract
  ;; A LINE is pre-R13: no marker requirement under any dialect.
  (dolist (d '(:autocad-2026 :strict :bricscad-v26 :clautolisp :lax))
    (multiple-value-bind (r w) (%d1-run *d1-markerless-line* d)
      (is (eql 1 r) "markerless LINE should create under ~S" d)
      (is (string= "" w) "no warning expected for LINE under ~S; got: ~S" d w))))

;;; --- Invalid INSERT: undefined block (cador-entmakex-invalid-insert) --
;;;
;;; An INSERT whose group-2 block is undefined is rejected by BOTH AutoCAD and
;;; BricsCAD. cador's permissive construction mode accepted it; now the vendor
;;; dialects reject it (nil, nothing added), clautolisp/strict accept + warn
;;; [entmakex-invalid-insert], and lax accepts silently.

;; An INSERT (with the block-reference subclass markers) to an UNDEFINED block.
(defparameter *ii-insert-undefined-block*
  "(if (= (type (entmakex (list (cons 0 \"INSERT\")
                                (cons 100 \"AcDbEntity\") (cons 100 \"AcDbBlockReference\")
                                (cons 2 \"NO_SUCH_BLOCK\")
                                (cons 8 \"0\")
                                (cons 10 (list 0.0 0.0 0.0)))))
         'ENAME) 1 0)")

;; The same INSERT, but the block MYBLK is defined first via a BLOCK/ENDBLK pair.
(defparameter *ii-insert-defined-block*
  "(progn
     (entmake (list (cons 0 \"BLOCK\") (cons 2 \"MYBLK\") (cons 70 0)
                    (cons 10 (list 0.0 0.0 0.0))))
     (entmake (list (cons 0 \"ENDBLK\")))
     (if (= (type (entmakex (list (cons 0 \"INSERT\")
                                  (cons 100 \"AcDbEntity\") (cons 100 \"AcDbBlockReference\")
                                  (cons 2 \"MYBLK\")
                                  (cons 8 \"0\")
                                  (cons 10 (list 0.0 0.0 0.0)))))
            'ENAME) 1 0))")

(test dd-invalid-insert-vendor-dialects-reject-undefined-block
  (dolist (d '(:autocad-2026 :bricscad-v26))
    (is (eql 0 (nth-value 0 (%d1-run *ii-insert-undefined-block* d)))
        "INSERT to an undefined block should be rejected under ~S" d)))

(test dd-invalid-insert-permissive-dialects-accept-undefined-block
  (dolist (d '(:clautolisp :strict :lax))
    (is (eql 1 (nth-value 0 (%d1-run *ii-insert-undefined-block* d)))
        "INSERT to an undefined block should be accepted (permissive) under ~S" d)))

(test dd-invalid-insert-warns-under-clautolisp-and-strict-only
  (dolist (d '(:clautolisp :strict))
    (multiple-value-bind (r w) (%d1-run *ii-insert-undefined-block* d)
      (declare (ignore r))
      (is (search "entmakex-invalid-insert" w)
          "expected the [entmakex-invalid-insert] warning under ~S; got: ~S" d w)))
  (dolist (d '(:autocad-2026 :bricscad-v26 :lax))
    (multiple-value-bind (r w) (%d1-run *ii-insert-undefined-block* d)
      (declare (ignore r))
      (is (string= "" w) "no warning expected under ~S; got: ~S" d w))))

(test dd-invalid-insert-defined-block-creates-everywhere
  ;; A block reference to a DEFINED block is valid: it creates under every
  ;; dialect, with no warning.
  (dolist (d '(:autocad-2026 :bricscad-v26 :clautolisp :strict :lax))
    (multiple-value-bind (r w) (%d1-run *ii-insert-defined-block* d)
      (is (eql 1 r) "INSERT to a defined block should create under ~S" d)
      (is (string= "" w) "no warning expected under ~S; got: ~S" d w))))

(test dd-invalid-insert-reject-leaves-no-entity-visible
  ;; Acceptance #5: when the vendor-compatible path returns nil, no invalid
  ;; entity becomes visible through ENTLAST.
  (dolist (d '(:autocad-2026 :bricscad-v26))
    (is (eql 1 (nth-value 0
                (%d1-run
                 "(progn (entmakex (list (cons 0 \"INSERT\")
                                         (cons 100 \"AcDbEntity\") (cons 100 \"AcDbBlockReference\")
                                         (cons 2 \"NO_SUCH_BLOCK\") (cons 8 \"0\")
                                         (cons 10 (list 0.0 0.0 0.0))))
                         (if (entlast) 0 1))"
                 d)))
        "ENTLAST must stay nil after a rejected INSERT under ~S" d)))

;;; --- Divergence D3: entmod on a non-graphical XRECORD (dialect) --

;; Create an XRECORD under a dict key, entmod its group-1 value, read it
;; back; return the readback string. On AutoCAD entmod no-ops (old value),
;; on BricsCAD it updates.
(defparameter *d3-xrecord-entmod*
  "(setq nod (namedobjdict))
   (setq xr (entmakex (list (cons 0 \"XRECORD\") (cons 100 \"AcDbXrecord\") (cons 1 \"v1\"))))
   (dictadd nod \"K\" xr)
   (entmod (list (cons -1 xr) (cons 0 \"XRECORD\") (cons 100 \"AcDbXrecord\") (cons 1 \"v2\")))
   (cdr (assoc 1 (dictsearch nod \"K\")))")

(defun %d3-readback (dialect-keyword)
  "Run the xrecord-entmod probe under DIALECT-KEYWORD; return
(values READBACK-STRING WARNING)."
  (multiple-value-bind (r w) (%d1-run *d3-xrecord-entmod* dialect-keyword)
    (values (and (typep r 'autolisp-string) (autolisp-string-value r)) w)))

;; The autolisp-spec resolves D3 in AutoCAD's favour (entmod does not
;; modify a non-graphical object -> no-op), so the NORMATIVE dialects
;; (autocad, clautolisp, strict) keep the old value; the DEVIANT dialects
;; (bricscad, lax) apply. strict and bricscad warn.

(test dd-d3-normative-dialects-noop-entmod-on-xrecord
  (dolist (d '(:autocad-2026 :clautolisp :strict))
    (is (string= "v1" (%d3-readback d))
        "entmod on xrecord should be a no-op under ~S" d)))

(test dd-d3-deviant-dialects-apply-entmod-on-xrecord
  (dolist (d '(:bricscad-v26 :lax))
    (is (string= "v2" (%d3-readback d))
        "entmod on xrecord should apply under ~S" d)))

(test dd-d3-warns-under-bricscad-and-strict-only
  (dolist (d '(:bricscad-v26 :strict))
    (multiple-value-bind (r w) (%d3-readback d)
      (declare (ignore r))
      (is (search "entmod-nongraphical" w)
          "expected the [entmod-nongraphical] warning under ~S; got: ~S" d w)))
  (dolist (d '(:autocad-2026 :clautolisp :lax))
    (multiple-value-bind (r w) (%d3-readback d)
      (declare (ignore r))
      (is (string= "" w) "no warning expected under ~S; got: ~S" d w))))

(test dd-d3-graphical-entmod-unaffected-by-object-gate
  ;; entmod on a graphical entity (CIRCLE) always applies, every dialect,
  ;; no warning -- the D3 gate is non-graphical-objects only.
  (dolist (d '(:autocad-2026 :strict :bricscad-v26 :clautolisp :lax))
    (multiple-value-bind (r w)
        (%d1-run "
  (setq e (entmakex (list (cons 0 \"CIRCLE\") (cons 10 (list 0.0 0.0 0.0)) (cons 40 1.0))))
  (entmod (list (cons -1 e) (cons 0 \"CIRCLE\") (cons 10 (list 0.0 0.0 0.0)) (cons 40 2.0)))
  (cdr (assoc 40 (entget e)))" d)
      (is (and (numberp r) (= r 2.0)) "CIRCLE entmod should apply under ~S (got ~S)" d r)
      (is (string= "" w) "no warning expected for a graphical entmod under ~S; got: ~S" d w))))

;;; --- XData round-trip with the full group-code set ---------------

(test dd-xdata-full-codeset-round-trips-through-entmod
  ;; Attach xdata using every SCHMS group code plus points and the
  ;; brace controls, then read them back verbatim and count the pairs
  ;; recovered under the application list.
  (is (eql 8
           (%dd-run "
  (regapp \"APP\")
  (setq e (entmakex (list (cons 0 \"CIRCLE\") (cons 10 (list 0.0 0.0 0.0)) (cons 40 1.0))))
  (entmod (append (entget e)
                  (list (list -3 (list \"APP\"
                                       (cons 1000 \"str\")
                                       (cons 1002 \"{\")
                                       (cons 1003 \"0\")
                                       (cons 1005 (cdr (assoc 5 (entget e))))
                                       (cons 1040 1.5)
                                       (cons 1070 42)
                                       (cons 1071 100000)
                                       (cons 1002 \"}\"))))))
  (setq xd (cdr (assoc -3 (entget e (list \"APP\")))))
  ;; xd = ((\"APP\" (1000 . str) (1002 . {) ...)); count the xdata pairs
  (length (cdr (car xd)))"))))

(defun %xd-verdict (dialect-keyword pair-source)
  "Under DIALECT-KEYWORD, ENTMOD a fresh CIRCLE with one xdata pair built by
PAIR-SOURCE (AutoLISP text; E is the circle). Return (ENTMOD-RETURNED-P
PAIRS-READ-BACK) as a two-digit integer: 10 * (entmod non-nil) + pairs."
  (%d1-run (format nil "
  (regapp \"APP\")
  (setq e (entmakex (list (cons 0 \"CIRCLE\") (cons 10 (list 0.0 0.0 0.0)) (cons 40 1.0))))
  (setq r (entmod (append (entget e) (list (list -3 (list \"APP\" ~A))))))
  (+ (if r 10 0) (length (cdr (car (cdr (assoc -3 (entget e (list \"APP\"))))))))" pair-source)
           dialect-keyword))

(test dd-xdata-entmod-checks-handles-and-layers-as-the-vendors-do
  ;; probes/sources/probe-xdata.lsp, 2026-10-03. AutoCAD rejects the whole
  ;; ENTMOD (nil, nothing attached) for a 1005 handle naming no object or a
  ;; 1003 naming no layer; BricsCAD accepts the dangling handle and, for
  ;; the missing layer, returns the list but drops the xdata.
  (dolist (d '(:autocad :strict))
    (is (eql 0  (%xd-verdict d "(cons 1005 \"2A\")")) "~S dangling 1005" d)
    (is (eql 0  (%xd-verdict d "(cons 1003 \"NO_SUCH_LAYER\")")) "~S missing layer" d)
    (is (eql 11 (%xd-verdict d "(cons 1005 (cdr (assoc 5 (entget e))))")) "~S live 1005" d)
    (is (eql 11 (%xd-verdict d "(cons 1003 \"0\")")) "~S layer 0" d))
  (dolist (d '(:bricscad :bricscad-mac))
    (is (eql 11 (%xd-verdict d "(cons 1005 \"2A\")")) "~S dangling 1005" d)
    (is (eql 10 (%xd-verdict d "(cons 1003 \"NO_SUCH_LAYER\")")) "~S missing layer" d)
    (is (eql 11 (%xd-verdict d "(cons 1003 \"0\")")) "~S layer 0" d)))

(test dd-xdata-preserves-order-and-multiplicity
  ;; Two 1000 strings in a set order must come back in the same order.
  (is (eql 1
           (%dd-run "
  (regapp \"APP\")
  (setq e (entmakex (list (cons 0 \"CIRCLE\") (cons 10 (list 0.0 0.0 0.0)) (cons 40 1.0))))
  (entmod (append (entget e)
                  (list (list -3 (list \"APP\" (cons 1000 \"first\") (cons 1000 \"second\"))))))
  (setq xd (cdr (car (cdr (assoc -3 (entget e (list \"APP\")))))))
  ;; xd = ((1000 . first) (1000 . second)) -> check both order and count
  (if (and (= (length xd) 2)
           (= (strcase (cdr (nth 0 xd))) \"FIRST\")
           (= (strcase (cdr (nth 1 xd))) \"SECOND\"))
      1 0)"))))

(test dd-entget-without-applist-suppresses-xdata
  (is (eql 1
           (%dd-run "
  (regapp \"APP\")
  (setq e (entmakex (list (cons 0 \"CIRCLE\") (cons 10 (list 0.0 0.0 0.0)) (cons 40 1.0))))
  (entmod (append (entget e) (list (list -3 (list \"APP\" (cons 1000 \"x\"))))))
  (if (and (null (assoc -3 (entget e)))
           (assoc -3 (entget e (list \"APP\"))))
      1 0)"))))

(test dd-xdata-multi-application-filter
  ;; Two applications' xdata on one entity; entget with one app name
  ;; surfaces only that app; the wildcard surfaces both.
  (is (eql 1
           (%dd-run "
  (regapp \"A1\") (regapp \"A2\")
  (setq e (entmakex (list (cons 0 \"CIRCLE\") (cons 10 (list 0.0 0.0 0.0)) (cons 40 1.0))))
  (entmod (append (entget e)
                  (list (list -3 (list \"A1\" (cons 1000 \"one\"))
                                  (list \"A2\" (cons 1000 \"two\"))))))
  (if (and (= (length (cdr (assoc -3 (entget e (list \"A1\"))))) 1)
           (= (length (cdr (assoc -3 (entget e (list \"A2\"))))) 1)
           (= (length (cdr (assoc -3 (entget e (list \"*\"))))) 2))
      1 0)"))))

;;; --- XDSIZE / XDROOM (xdata size accounting) -------------------
;;;
;;; The vendor numbers MEASURED by probes/sources/probe-xdata.lsp
;;; (suites "xdsize" / "xdroom"; 2026-10-23) on AutoCAD 2022 Windows,
;;; BricsCAD V25 Windows and BricsCAD V26 macOS, replayed case by case
;;; under the matching dialect (see XDATA-GROUP-BYTE-SIZE and
;;; issues/open/xdroom-xdsize-not-implemented.issue, "* Measured").
;;; The applications are the probe's: "CLAUTOLISP_XDP" (14 chars) and
;;; "CLAUTOLISP_XDPX" (15). -1 stands for a NIL result.

(defparameter *xd-probe-cases*
  ;; (CASE XDSIZE-ARGUMENT AUTOCAD BRICSCAD-WINDOWS BRICSCAD-MACOS)
  '(("header"                  "(list (list app))"                          0  30  60)
    ("header +1 char"          "(list (list app2))"                         0  32  64)
    ("-3 sentinel form"        "(list -3 (list app))"                       0  30  60)
    ("1000 empty string"       "(list (list app '(1000 . \"\")))"           6  30  60)
    ("1000 3 chars"            "(list (list app '(1000 . \"abc\")))"       12  36  72)
    ("1000 10 chars"           "(list (list app '(1000 . \"abcdefghij\")))" 26  50 100)
    ("1000 non-ASCII 1 char"   "(list (list app (cons 1000 (chr 233))))"    8  32  64)
    ("1002 brace pair"         "(list (list app '(1002 . \"{\") '(1002 . \"}\")))" 7 34 68)
    ("1003 layer 0"            "(list (list app '(1003 . \"0\")))"          6  32  64)
    ("1004 binary 4 bytes"     "(list (list app '(1004 . \"DEADBEEF\")))"   9  46  92)
    ("1005 handle 1 char"      "(list (list app '(1005 . \"1\")))"         12  32  64)
    ("1005 handle 2 chars"     "(list (list app '(1005 . \"2A\")))"        12  34  68)
    ("1010 point"              "(list (list app '(1010 1.0 2.0 3.0)))"     28  55  85)
    ("1011 world position"     "(list (list app '(1011 1.0 2.0 3.0)))"     28  55  85)
    ("1040 real"               "(list (list app '(1040 . 1.5)))"           12  39  69)
    ("1041 distance"           "(list (list app '(1041 . 1.5)))"           12  39  69)
    ("1042 scale"              "(list (list app '(1042 . 1.5)))"           12  39  69)
    ("1070 int16"              "(list (list app '(1070 . 42)))"             6  33  63)
    ("1071 int32"              "(list (list app '(1071 . 100000)))"         8  35  65)
    ("two applications"
     "(list (list app '(1000 . \"abc\")) (list app2 '(1040 . 1.5)))"       24  36  72)
    ("documented example"
     "(list -3 (list app '(1000 . \"SUITOFARMOR\") '(1002 . \"{\") '(1040 . 0.0)
                    '(1040 . 1.0) '(1002 . \"}\")))"                        50  74 130)
    ("error unregistered app"
     "(list (list \"CLAUTOLISP_NOT_REGISTERED\" '(1000 . \"x\")))"         -1  54 108)
    ("error unknown code 1099" "(list (list app '(1099 . 1)))"             -1  30  60)
    ("error unbalanced brace"  "(list (list app '(1002 . \"{\")))"          5  32  64)))

(defparameter *xd-probe-dialects*
  ;; dialect keyword -> column of *xd-probe-cases*
  '((:autocad . 2) (:bricscad . 3) (:bricscad-mac . 4)))

(defun %xd-run (source dialect-keyword)
  (values (%d1-run (concatenate 'string
                                "(setq app \"CLAUTOLISP_XDP\" app2 \"CLAUTOLISP_XDPX\")
                                 (regapp app) (regapp app2) "
                                source)
                   dialect-keyword)))

(defun %xd-size (argument dialect-keyword)
  (%xd-run (format nil "(setq r (xdsize ~A)) (if r r -1)" argument) dialect-keyword))

(test dd-xdsize-measured-vendor-sizes
  (loop for (dialect . column) in *xd-probe-dialects*
        do (loop for case in *xd-probe-cases*
                 for expected = (nth column case)
                 for got = (%xd-size (second case) dialect)
                 do (is (eql expected got)
                        "xdsize ~S under ~S: expected ~S, got ~S"
                        (first case) dialect expected got))))

(test dd-xdsize-autocad-nil-sets-errno
  ;; AutoCAD answers NIL, not an error; ERRNO tells why (unmeasured
  ;; codes, from the Error Codes Reference: 50 bad application, 48 bad
  ;; group). Success clears ERRNO.
  (is (eql 50 (%xd-run "(if (null (xdsize '((\"NOAPP\" (1000 . \"x\"))))) (getvar \"ERRNO\") -1)"
                       :autocad)))
  (is (eql 48 (%xd-run "(if (null (xdsize (list (list app '(1099 . 1))))) (getvar \"ERRNO\") -1)"
                       :autocad)))
  (is (eql 48 (%xd-run "(if (null (xdsize (list (list app '(1070 . \"x\"))))) (getvar \"ERRNO\") -1)"
                       :autocad)))
  (is (eql 0 (%xd-run "(xdsize (list (list app '(1070 . 1)))) (getvar \"ERRNO\")" :autocad))))

(test dd-xdsize-default-dialect-follows-autocad
  ;; Every non-BricsCAD dialect follows AutoCAD (the default too).
  (is (eql 50 (%dd-run "(regapp \"MYAPP\")
  (xdsize '(-3 (\"MYAPP\" (1000 . \"SUITOFARMOR\") (1002 . \"{\")
                           (1040 . 0.0) (1040 . 1.0) (1002 . \"}\"))))")))
  (is (eql 1 (%dd-run "(if (xdsize '((\"NOAPP\" (1000 . \"x\")))) 0 1)")))
  (is (eql 24 (%xd-size "(list (list app '(1000 . \"abc\")) (list app2 '(1040 . 1.5)))"
                        :clautolisp))))

(test dd-xdsize-argument-errors
  ;; not a list / no argument
  (is (eql 1 (%dd-run "(if (vl-catch-all-error-p (vl-catch-all-apply 'xdsize '(42))) 1 0)")))
  (is (eql 1 (%dd-run "(if (vl-catch-all-error-p (vl-catch-all-apply 'xdsize nil)) 1 0)")))
  ;; the empty list sizes to 0 on both products (unmeasured)
  (is (eql 0 (%xd-run "(xdsize '())" :autocad)))
  (is (eql 0 (%xd-run "(xdsize '())" :bricscad))))

(defparameter *xd-probe-xdroom*
  "(setq e (entmakex (list (cons 0 \"CIRCLE\") (cons 10 (list 0.0 0.0 0.0)) (cons 40 1.0))))
   (setq fresh (xdroom e))
   (entmod (append (entget e)
                   (list (list -3 (list app '(1000 . \"abc\") '(1070 . 1) '(1040 . 1.5))))))
   (list fresh (xdroom e) (xdsize (assoc -3 (entget e (list app)))))")

(test dd-xdroom-measured-vendor-room
  ;; (fresh circle, after 1000 "abc" + 1070 + 1040, xdsize of that xdata)
  (is (equal '(16383 16359 24) (%xd-run *xd-probe-xdroom* :autocad)))
  (is (equal '(16383 16352 48) (%xd-run *xd-probe-xdroom* :bricscad)))
  (is (equal '(16383 16352 84) (%xd-run *xd-probe-xdroom* :bricscad-mac))))

(test dd-xdroom-reports-remaining-xdata-room
  ;; attached xdata is deducted, every application counted:
  ;; AutoCAD (3 + 9) + (3 + 9); BricsCAD (10 + 9) + (10 + 9)
  (let ((source "(entmod (append (entget (setq e (entmakex (list (cons 0 \"CIRCLE\")
                                   (cons 10 (list 0.0 0.0 0.0)) (cons 40 1.0)))))
                  (list (list -3 (list app (cons 1000 \"abc\"))
                                  (list app2 (cons 1040 2.5))))))
  (xdroom e)"))
    (is (eql (- 16383 24) (%xd-run source :autocad)))
    (is (eql (- 16383 38) (%xd-run source :bricscad))))
  ;; AutoCAD: xdroom + xdsize of the entity's own xdata = the budget
  (is (eql 16383 (%dd-run "
  (regapp \"APP\")
  (setq e (entmakex (list (cons 0 \"CIRCLE\") (cons 10 (list 0.0 0.0 0.0)) (cons 40 1.0))))
  (entmod (append (entget e) (list (list -3 (list \"APP\" (cons 1070 7) (list 1010 1.0 2.0 0.0))))))
  (+ (xdroom e) (xdsize (assoc -3 (entget e (list \"*\")))))"))))

(test dd-xdroom-argument-errors
  ;; a non-ename argument is an error
  (is (eql 1 (%dd-run "(if (vl-catch-all-error-p (vl-catch-all-apply 'xdroom '(\"x\"))) 1 0)")))
  (is (eql 1 (%dd-run "(if (vl-catch-all-error-p (vl-catch-all-apply 'xdroom nil)) 1 0)")))
  ;; a deleted entity: nil
  (is (eql 1 (%dd-run "
  (setq e (entmakex (list (cons 0 \"CIRCLE\") (cons 10 (list 0.0 0.0 0.0)) (cons 40 1.0))))
  (entdel e)
  (if (xdroom e) 0 1)"))))

(test dd-xdsize-on-the-nihil-host
  ;; Without a drawing (the nihil host) an empty xdata list still sizes
  ;; to 0, but under AutoCAD rules an application name cannot be checked
  ;; against an APPID table: the call signals (host-not-supported),
  ;; catchably.
  (reset-autolisp-symbol-table)
  (is (eql 0 (run-autolisp-string "(xdsize '())" :setup-fn #'install-core-into)))
  (reset-autolisp-symbol-table)
  (is (eql 1 (run-autolisp-string
              "(if (vl-catch-all-error-p (vl-catch-all-apply 'xdsize '(((\"APP\" (1070 . 1)))))) 1 0)"
              :setup-fn #'install-core-into))))

;;; --- Named-object dictionary + XRECORD lifecycle ----------------

(test dd-dictionary-xrecord-lifecycle
  (is (eql 1
           (%dd-run "
  (setq nod (namedobjdict))
  (setq xr (entmakex (list (cons 0 \"XRECORD\") (cons 100 \"AcDbXrecord\")
                           (cons 1 \"payload\") (cons 70 5))))
  (dictadd nod \"MYDICT_ENTRY\" xr)
  (setq found (dictsearch nod \"MYDICT_ENTRY\"))
  (if (and (= (type nod) 'ENAME)
           found
           (= (strcase (cdr (assoc 0 found))) \"XRECORD\")
           (= (cdr (assoc 1 found)) \"payload\")
           (= (cdr (assoc 70 found)) 5))
      1 0)"))))

(test dd-dictionary-duplicate-and-absent-return-nil
  (is (eql 1
           (%dd-run "
  (setq nod (namedobjdict))
  (setq xr (entmakex (list (cons 0 \"XRECORD\") (cons 100 \"AcDbXrecord\") (cons 1 \"a\"))))
  (dictadd nod \"K\" xr)
  (if (and (null (dictadd nod \"K\" xr))       ; duplicate key
           (null (dictsearch nod \"ABSENT\")))  ; absent key
      1 0)"))))

(test dd-xrecord-mutate-via-entmod-through-dict
  ;; entmod that UPDATES an xrecord is the lenient (BricsCAD) behaviour;
  ;; under the strict default it is a no-op (AutoCAD parity, divergence
  ;; D3), so exercise it under --dialect bricscad-v26. The D3-specific
  ;; per-dialect behaviour is asserted in dd-d3-* below.
  (is (eql 1
           (nth-value 0 (%d1-run "
  (setq nod (namedobjdict))
  (setq xr (entmakex (list (cons 0 \"XRECORD\") (cons 100 \"AcDbXrecord\") (cons 1 \"v1\"))))
  (dictadd nod \"K\" xr)
  (entmod (list (cons -1 xr) (cons 0 \"XRECORD\") (cons 100 \"AcDbXrecord\") (cons 1 \"v2\")))
  (if (= (cdr (assoc 1 (dictsearch nod \"K\"))) \"v2\") 1 0)"
                                  :bricscad-v26)))))

(test dd-dictremove-detaches-entry
  (is (eql 1
           (%dd-run "
  (setq nod (namedobjdict))
  (setq xr (entmakex (list (cons 0 \"XRECORD\") (cons 100 \"AcDbXrecord\") (cons 1 \"a\"))))
  (dictadd nod \"K\" xr)
  (dictremove nod \"K\")
  (if (null (dictsearch nod \"K\")) 1 0)"))))

(test dd-dictnext-enumerates-entries
  ;; Counts the test's XRECORDs (group 1): a fresh drawing's NOD also holds
  ;; the vendors' default entries (cador-entget-subclass-layout-and-record-
  ;; pointers, item 5).
  (is (eql 3
           (%dd-run "
  (setq nod (namedobjdict))
  (dictadd nod \"A\" (entmakex (list (cons 0 \"XRECORD\") (cons 100 \"AcDbXrecord\") (cons 1 \"a\"))))
  (dictadd nod \"B\" (entmakex (list (cons 0 \"XRECORD\") (cons 100 \"AcDbXrecord\") (cons 1 \"b\"))))
  (dictadd nod \"C\" (entmakex (list (cons 0 \"XRECORD\") (cons 100 \"AcDbXrecord\") (cons 1 \"c\"))))
  (setq n 0)
  (setq d (dictnext nod T))
  (while d (if (assoc 1 d) (setq n (1+ n))) (setq d (dictnext nod)))
  n"))))

;;; --- Symbol tables ----------------------------------------------

(test dd-tblsearch-standard-tables
  (is (eql 1
           (%dd-run "
  (if (and (tblsearch \"LAYER\" \"0\")
           (tblsearch \"LTYPE\" \"Continuous\")
           (tblsearch \"STYLE\" \"Standard\")
           (tblsearch \"APPID\" \"ACAD\")
           (null (tblsearch \"LAYER\" \"NOSUCH\")))
      1 0)"))))

(test dd-tblnext-walks-layers
  ;; add two layers via a block-agnostic table op is not exposed to
  ;; AutoLISP; instead walk the default LAYER table which has "0".
  (is (eql 1
           (%dd-run "
  (setq r (tblnext \"LAYER\" T))
  (if (and r (= (cdr (assoc 2 r)) \"0\")) 1 0)"))))

;;; --- ssget filter grammar (whole-database scan) -----------------

(defun %seed-ss ()
  "AutoLISP source that seeds three LINEs (colours 1/2/3, layers
WALL/WALL/DOOR) and one CIRCLE bearing MYAPP xdata."
  "
  (entmake (list (cons 0 \"LINE\") (cons 8 \"WALL\") (cons 62 1)
                 (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 1.0 0.0 0.0))))
  (entmake (list (cons 0 \"LINE\") (cons 8 \"WALL\") (cons 62 2)
                 (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 2.0 0.0 0.0))))
  (entmake (list (cons 0 \"LINE\") (cons 8 \"DOOR\") (cons 62 3)
                 (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 3.0 0.0 0.0))))
  (regapp \"MYAPP\")
  (setq c (entmakex (list (cons 0 \"CIRCLE\") (cons 8 \"DOOR\")
                          (cons 10 (list 5.0 5.0 0.0)) (cons 40 1.0))))
  (entmod (append (entget c) (list (list -3 (list \"MYAPP\" (cons 1000 \"t\"))))))")

(defun %ss-count (filter-source)
  "Run the seed then (ssget \"X\" FILTER) and return the member count."
  (%dd-run (format nil "~A~%(setq ss (ssget \"X\" ~A))~%(if ss (sslength ss) 0)"
                   (%seed-ss) filter-source)))

(test dd-ssget-type-filter
  (is (eql 3 (%ss-count "(list (cons 0 \"LINE\"))")))
  (is (eql 4 (%ss-count "nil"))))

(test dd-ssget-comma-layer-and-wildcard
  (is (eql 2 (%ss-count "(list (cons 0 \"LINE\") (cons 8 \"WALL,SLAB\"))")))
  (is (eql 4 (%ss-count "(list (cons 8 \"*\"))"))))

(test dd-ssget-or-filter
  (is (eql 2 (%ss-count
              "(list (cons 0 \"LINE\") (cons -4 \"<OR\") (cons 62 1) (cons 62 3) (cons -4 \"OR>\"))"))))

(test dd-ssget-and-not-filters
  (is (eql 1 (%ss-count
              "(list (cons 0 \"LINE\") (cons -4 \"<NOT\") (cons 8 \"WALL\") (cons -4 \"NOT>\"))")))
  (is (eql 2 (%ss-count
              "(list (cons -4 \"<AND\") (cons 0 \"LINE\") (cons 8 \"WALL\") (cons -4 \"AND>\"))"))))

(test dd-ssget-relational-filter
  (is (eql 2 (%ss-count "(list (cons 0 \"LINE\") (cons -4 \">\") (cons 62 1))")))
  (is (eql 1 (%ss-count "(list (cons 0 \"LINE\") (cons -4 \"<\") (cons 62 2))"))))

(test dd-ssget-xdata-filter
  (is (eql 1 (%ss-count "(list (cons 0 \"CIRCLE\") (list -3 (list \"MYAPP\")))")))
  (is (eql 0 (%ss-count "(list (list -3 (list \"OTHERAPP\")))"))))

(test dd-ssget-never-returns-dictionaries
  ;; create a dictionary object; ssget "X" with no filter still sees
  ;; only the graphical entities.
  (is (eql 4 (%dd-run (format nil "~A~%(namedobjdict)~%(setq ss (ssget \"X\"))~%(if ss (sslength ss) 0)"
                              (%seed-ss))))))

;;; --- ssname / ssadd / ssdel / ssmemb ----------------------------

(test dd-selection-set-membership-ops
  (is (eql 1
           (%dd-run (format nil "~A
  (setq ss (ssget \"X\" (list (cons 0 \"LINE\"))))
  (setq e0 (ssname ss 0))
  (setq empty (ssadd))
  (setq one (ssadd e0))
  (if (and (= (sslength ss) 3)
           (= (sslength empty) 0)
           (= (sslength one) 1)
           (ssmemb e0 one)
           (progn (ssdel e0 one) (= (sslength one) 0)))
      1 0)" (%seed-ss))))))

;;; --- out-of-scope interactive modes fail cleanly ----------------

(test dd-ssget-interactive-modes-do-not-crash
  ;; Out-of-scope interactive/graphical selection modes fail *cleanly*:
  ;; they signal a catchable AutoLISP error (caught by vl-catch-all-apply
  ;; / *error*) rather than crashing the engine. Headless code guards
  ;; them; nothing here escapes to the process.
  (is (eql 1 (%dd-run "(if (vl-catch-all-error-p
                            (vl-catch-all-apply 'ssget nil))
                          1 0)")))          ; (ssget) interactive pick
  (is (eql 1 (%dd-run "(if (vl-catch-all-error-p
                            (vl-catch-all-apply 'ssget (list \"_W\")))
                          1 0)")))          ; window mode
  (is (eql 1 (%dd-run "(if (vl-catch-all-error-p
                            (vl-catch-all-apply 'ssget (list \"_CP\")))
                          1 0)"))))         ; crossing-polygon mode

(test dd-type-of-a-catch-all-error
  ;; (type (vl-catch-all-apply ...)) of an error is VL-CATCH-ALL-APPLY-ERROR
  ;; (entget-pointers probe, section 13); clautolisp used to signal.
  (is (string= "VL-CATCH-ALL-APPLY-ERROR"
               (clautolisp.autolisp-runtime:autolisp-symbol-name
                (%dd-run "(type (vl-catch-all-apply (quote /) (list 1 0)))")))))
