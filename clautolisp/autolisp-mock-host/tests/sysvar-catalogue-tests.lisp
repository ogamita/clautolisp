(in-package #:clautolisp.autolisp-mock-host.tests)

(in-suite autolisp-mock-host-suite)

;;;; Phase-3 tests: data-driven sysvar catalogue, read-only / unknown-
;;;; name enforcement, ERRNO bridge.
;;;;
;;;; The catalogue under test is *full-sysvar-catalogue* generated
;;;; from autolisp-spec/documentation/system-variables-inventory.sexp;
;;;; it has 1836 entries as of inventory v0.9.0.

;;; --- Catalogue population shape ----------------------------------

(test full-sysvar-catalogue-populates-mock-host
  (let ((mock (make-mock-host)))
    ;; Spot-check well-known canonical sysvars from the issue's
    ;; coupling list (one per category): file/encoding, error,
    ;; angle, units, viewport, command, snap, user-scratch,
    ;; security.
    (dolist (name '("LISPSYS" "EXTNAMES" "ERRNO"
                    "ANGBASE" "ANGDIR" "AUNITS" "AUPREC"
                    "LUNITS" "LUPREC" "DIMZIN" "UNITMODE"
                    "TILEMODE" "CVPORT"
                    "CMDECHO" "OSMODE"
                    "DWGNAME" "DWGPREFIX"
                    "DATE" "CDATE" "TDCREATE" "TDUPDATE"
                    "MAXSORT"
                    "TRUSTEDPATHS" "SECURELOAD"
                    "USERI1" "USERR1" "USERS1"))
      (let ((cell (mock-host-sysvar mock name)))
        (is (typep cell 'sysvar-cell)
            "expected MockHost to carry a sysvar cell for ~A" name)))))

(test full-sysvar-catalogue-count-matches-source
  ;; Sanity: every entry in *full-sysvar-catalogue* shows up in the
  ;; mock's sysvar table after population.
  (let ((mock (make-mock-host)))
    (is (= (length clautolisp.autolisp-mock-host:*full-sysvar-catalogue*)
           (hash-table-count (mock-host-sysvars mock))))))

;;; --- Host-derived flag and non-literal defaults -------------------

(test acadprefix-is-host-derived-and-readonly
  ;; ACADPREFIX is read-only and its initial value varies by host;
  ;; the inventory marks the default (:host-specific) which the
  ;; catalogue installs as the empty string but flags as host-derived.
  (let* ((mock (make-mock-host))
         (cell (mock-host-sysvar mock "ACADPREFIX")))
    (is (sysvar-cell-read-only-p cell))
    (is (sysvar-cell-host-derived-p cell))
    (is (string= "" (sysvar-cell-value cell)))))

(test cmdecho-has-literal-default-and-not-host-derived
  (let* ((mock (make-mock-host))
         (cell (mock-host-sysvar mock "CMDECHO")))
    (is (not (sysvar-cell-host-derived-p cell)))
    (is (not (sysvar-cell-read-only-p cell)))
    (is (eql 1 (sysvar-cell-value cell)))))

(test osmode-is-bitcoded-integer-with-vendor-divergence
  ;; The catalogue installs AutoCAD's literal (4133); BricsCAD ships
  ;; 4135 but the catalogue is the AutoCAD-preferring merge.
  (let* ((mock (make-mock-host))
         (cell (mock-host-sysvar mock "OSMODE")))
    (is (eq :integer (sysvar-cell-kind cell)))
    (is (eql 4133 (sysvar-cell-value cell)))
    (is (not (sysvar-cell-read-only-p cell)))))

;;; --- Read-only enforcement (HOST-SETVAR, the protocol entry point) -

(test host-setvar-rejects-read-only-with-sysvar-read-only-code
  (let ((mock (make-mock-host)))
    (handler-case
        (progn
          (host-setvar mock "ACADPREFIX" "/tmp/anywhere")
          (is nil "expected setvar on read-only ACADPREFIX to signal"))
      (autolisp-runtime-error (c)
        (is (eq :sysvar-read-only (autolisp-runtime-error-code c)))))))

(test host-setvar-on-unknown-name-signals-unknown-sysvar
  (let ((mock (make-mock-host)))
    (handler-case
        (progn
          (host-setvar mock "DEFINITELYNOTASYSVAR" 1)
          (is nil "expected setvar on unknown name to signal"))
      (autolisp-runtime-error (c)
        (is (eq :unknown-sysvar (autolisp-runtime-error-code c)))))))

(test host-getvar-on-unknown-name-returns-nil
  (let ((mock (make-mock-host)))
    (is (null (host-getvar mock "DEFINITELYNOTASYSVAR")))))

;;; --- BricsCAD-dialect sysvar overlay -----------------------------
;;;
;;; APPLY-BRICSCAD-DIALECT-SYSVARS drops the catalogue entries BricsCAD
;;; does not define, so under --bricscad a GETVAR on them returns nil and
;;; a SETVAR signals unknown-sysvar, as on a real BricsCAD. The overlay
;;; must leave the variables BricsCAD *does* share with AutoCAD intact.

(test bricscad-overlay-drops-absent-sysvars
  (let ((mock (make-mock-host)))
    ;; Present before the overlay (AutoCAD-derived catalogue ships them):
    (is (typep (mock-host-sysvar mock "DYNPROMPT") 'sysvar-cell))
    (is (typep (mock-host-sysvar mock "POINTCLOUDDENSITY") 'sysvar-cell))
    (clautolisp.autolisp-mock-host:apply-bricscad-dialect-sysvars mock)
    ;; Gone after the overlay: GETVAR -> nil (unknown name rule).
    (is (null (mock-host-sysvar mock "DYNPROMPT")))
    (is (null (host-getvar mock "DYNPROMPT")))
    (is (null (host-getvar mock "POINTCLOUDDENSITY")))))

(test bricscad-overlay-keeps-shared-sysvars
  (let ((mock (make-mock-host)))
    (clautolisp.autolisp-mock-host:apply-bricscad-dialect-sysvars mock)
    ;; Variables BricsCAD shares with AutoCAD survive the overlay.
    (dolist (name '("OSMODE" "CMDECHO" "CLAYER" "DIMSTYLE"
                    "LISPSYS" "ERRNO" "SECURELOAD"))
      (is (typep (mock-host-sysvar mock name) 'sysvar-cell)
          "bricscad overlay must keep shared sysvar ~A" name))))

(test bricscad-overlay-setvar-on-dropped-signals-unknown
  (let ((mock (make-mock-host)))
    (clautolisp.autolisp-mock-host:apply-bricscad-dialect-sysvars mock)
    (handler-case
        (progn
          (host-setvar mock "DYNPROMPT" 1)
          (is nil "expected setvar on a dropped sysvar to signal"))
      (autolisp-runtime-error (c)
        (is (eq :unknown-sysvar (autolisp-runtime-error-code c)))))))

(test bricscad-overlay-removes-the-expected-count
  ;; All 382 absent names are present in the AutoCAD-derived catalogue,
  ;; and exactly that many cells disappear after the overlay.
  (let* ((mock (make-mock-host))
         (before (hash-table-count (mock-host-sysvars mock))))
    (is (= 382 (length clautolisp.autolisp-mock-host:*bricscad-absent-sysvars*)))
    (dolist (name clautolisp.autolisp-mock-host:*bricscad-absent-sysvars*)
      (is (typep (mock-host-sysvar mock name) 'sysvar-cell)
          "absent-list name ~A must exist in the base catalogue" name))
    (clautolisp.autolisp-mock-host:apply-bricscad-dialect-sysvars mock)
    (is (= (- before 382) (hash-table-count (mock-host-sysvars mock))))))

;;; --- ERRNO bridge -------------------------------------------------
;;;
;;; (getvar "ERRNO") must reflect the live runtime errno, not the
;;; cell's stale snapshot. (setvar "ERRNO" v) must push to the
;;; runtime.

(test host-getvar-errno-reads-runtime-session
  (clautolisp.autolisp-runtime:reset-default-evaluation-context)
  (clautolisp.autolisp-runtime:set-autolisp-errno 0)
  (let ((mock (make-mock-host)))
    (is (eql 0 (host-getvar mock "ERRNO")))
    (clautolisp.autolisp-runtime:set-autolisp-errno 42)
    (is (eql 42 (host-getvar mock "ERRNO")))))

(test host-setvar-on-errno-signals-read-only
  ;; ERRNO is documented read-only on both vendors; user-level
  ;; (setvar "ERRNO" v) must signal :sysvar-read-only. The runtime
  ;; side-door for failing builtins is the internal SET-AUTOLISP-ERRNO
  ;; helper (autolisp-runtime/source/api.lisp).
  (clautolisp.autolisp-runtime:reset-default-evaluation-context)
  (let ((mock (make-mock-host)))
    (handler-case
        (progn
          (host-setvar mock "ERRNO" 7)
          (is nil "expected setvar on read-only ERRNO to signal"))
      (autolisp-runtime-error (c)
        (is (eq :sysvar-read-only (autolisp-runtime-error-code c)))))))

(test host-getvar-errno-tracks-internal-helper
  ;; Internal failing-builtin helpers set ERRNO via SET-AUTOLISP-ERRNO;
  ;; (getvar "ERRNO") from user code reads the same session slot.
  (clautolisp.autolisp-runtime:reset-default-evaluation-context)
  (clautolisp.autolisp-runtime:set-autolisp-errno 0)
  (let ((mock (make-mock-host)))
    (is (eql 0 (host-getvar mock "ERRNO")))
    (clautolisp.autolisp-runtime:set-autolisp-errno 2)
    (is (eql 2 (host-getvar mock "ERRNO")))
    (clautolisp.autolisp-runtime:set-autolisp-errno 0)
    (is (eql 0 (host-getvar mock "ERRNO")))))

;;; --- Catalogue selector ------------------------------------------

(test populate-default-sysvars-seed-keeps-small-list
  (let ((mock (make-instance 'mock-host)))
    (populate-default-sysvars mock :catalogue :seed)
    ;; The legacy seed list ships ~30 entries; nothing close to the
    ;; full catalogue.
    (is (< (hash-table-count (mock-host-sysvars mock)) 50))
    ;; But CMDECHO, USERI1 and DWGNAME -- the conservative
    ;; pre-Phase-3 fixture set -- still show up.
    (is (typep (mock-host-sysvar mock "CMDECHO") 'sysvar-cell))
    (is (typep (mock-host-sysvar mock "USERI1") 'sysvar-cell))
    (is (typep (mock-host-sysvar mock "DWGNAME") 'sysvar-cell))))

(test populate-default-sysvars-full-installs-1836
  (let ((mock (make-instance 'mock-host)))
    (populate-default-sysvars mock :catalogue :full)
    (is (= (length clautolisp.autolisp-mock-host:*full-sysvar-catalogue*)
           (hash-table-count (mock-host-sysvars mock))))))

;;; --- Snapshot/restore round-trips the new flag ------------------

(test snapshot-restore-preserves-host-derived-flag
  (let* ((mock (make-mock-host))
         (snap (mock-host-snapshot mock)))
    (mock-host-restore mock snap)
    (let ((cell (mock-host-sysvar mock "ACADPREFIX")))
      (is (sysvar-cell-host-derived-p cell)))))

;;; --- host-set-derived-sysvar bypasses read-only -------------------
;;;
;;; SYSCODEPAGE and DWGCODEPAGE are documented read-only sysvars, so
;;; HOST-SETVAR refuses to mutate them — correct for user code. The
;;; launch-time wiring (transmit.lisp:apply-launch-codepage-to-sysvars)
;;; needs to push the locale-resolved encoding past that gate; that's
;;; what HOST-SET-DERIVED-SYSVAR is for. These tests cover the contract
;;; in isolation.

(test host-set-derived-sysvar-mutates-read-only-cell
  (let ((mock (make-mock-host)))
    ;; baseline: SYSCODEPAGE installs from the catalogue at "" and the
    ;; cell is read-only
    (let ((cell (mock-host-sysvar mock "SYSCODEPAGE")))
      (is (string= "" (sysvar-cell-value cell)))
      (is (sysvar-cell-read-only-p cell)))
    ;; bypass succeeds — inspect the underlying cell rather than
    ;; host-getvar (which wraps the value in autolisp-string and is
    ;; not a string-designator).
    (host-set-derived-sysvar mock "SYSCODEPAGE" "UTF-8")
    (is (string= "UTF-8" (sysvar-cell-value (mock-host-sysvar mock "SYSCODEPAGE"))))
    ;; the cell remains read-only — only host-side init can mutate
    (let ((cell (mock-host-sysvar mock "SYSCODEPAGE")))
      (is (sysvar-cell-read-only-p cell)))))

(test host-set-derived-sysvar-respects-host-setvar-readonly
  ;; The bypass must not weaken the user-facing host-setvar gate.
  (let ((mock (make-mock-host)))
    (host-set-derived-sysvar mock "SYSCODEPAGE" "UTF-8")
    (handler-case
        (progn
          (host-setvar mock "SYSCODEPAGE" "ISO-8859-1")
          (is nil "host-setvar on read-only SYSCODEPAGE should have signalled"))
      (autolisp-runtime-error (c)
        (is (eq :sysvar-read-only (autolisp-runtime-error-code c)))))))

(test host-set-derived-sysvar-no-ops-on-unknown-name
  ;; Launch wiring fires unconditionally; absent SYSCODEPAGE in a
  ;; stripped catalogue we want a silent no-op, not a signal.
  (let ((mock (make-instance 'mock-host)))
    (populate-default-sysvars mock :catalogue :seed)
    (is (null (mock-host-sysvar mock "SYSCODEPAGE")))
    (is (null (host-set-derived-sysvar mock "SYSCODEPAGE" "UTF-8")))))

;;; --- Live clock sysvars: DATE / CDATE / MILLISECS -----------------

(test host-getvar-date-is-live-julian
  ;; DATE = Julian day number + fraction of the day. Assert structure,
  ;; not an exact value (it tracks the wall clock).
  (let* ((mock (make-mock-host))
         (d (host-getvar mock "DATE")))
    (is (typep d 'double-float))
    ;; Modern dates sit around JDN 2.46e6; bracket generously.
    (is (< 2400000 (floor d) 2500000))
    ;; Fraction of day is in [0,1).
    (let ((frac (- d (floor d))))
      (is (<= 0 frac))
      (is (< frac 1)))))

(test host-getvar-cdate-is-todays-decimal-date
  ;; CDATE integer part is YYYYMMDD for the current local date.
  (multiple-value-bind (sec min hour day month year)
      (decode-universal-time (get-universal-time))
    (declare (ignore sec min hour))
    (let* ((mock (make-mock-host))
           (c (host-getvar mock "CDATE"))
           (expected (+ (* year 10000) (* month 100) day)))
      (is (typep c 'double-float))
      (is (eql expected (floor c))))))

(test host-getvar-millisecs-is-monotonic-integer
  (let* ((mock (make-mock-host))
         (a (host-getvar mock "MILLISECS"))
         (b (host-getvar mock "MILLISECS")))
    (is (integerp a))
    (is (>= a 0))
    (is (>= b a))))

(test host-setvar-on-date-signals-read-only
  ;; DATE / CDATE / MILLISECS are read-only on both vendors.
  (let ((mock (make-mock-host)))
    (dolist (name '("DATE" "CDATE" "MILLISECS"))
      (handler-case
          (progn
            (host-setvar mock name 1)
            (is nil "expected setvar on read-only clock sysvar to signal"))
        (autolisp-runtime-error (c)
          (is (eq :sysvar-read-only (autolisp-runtime-error-code c))))))))

(test clock-sysvars-are-cached-within-a-millisecond
  ;; Deterministic (injected clock): two reads for the SAME millisecond
  ;; return the identical cached value with no recompute; a different
  ;; millisecond refreshes the cache.
  (let ((at #'clautolisp.autolisp-mock-host::%clock-sysvar-at))
    (let ((d1 (funcall at "DATE" 5000))
          (d2 (funcall at "DATE" 5000)))
      (is (eql d1 d2)))                  ; same ms -> cache hit
    (funcall at "MILLISECS" 6000)        ; different ms -> refresh
    (is (eql 6000 (clautolisp.autolisp-mock-host::clock-cache-millis
                   clautolisp.autolisp-mock-host::*clock-cache*)))
    ;; MILLISECS reflects the injected millisecond.
    (is (eql 6000 (funcall at "MILLISECS" 6000)))))

(test clock-cache-throughput-benchmark
  ;; Instructive: how many cached GETVARs fit in one millisecond. Spin
  ;; reading MILLISECS, counting reads until the value ticks, over
  ;; several consecutive windows. The first window is a partial ms, so
  ;; the later windows are the representative ones.
  (let ((mock (make-mock-host))
        (windows '()))
    (dotimes (r 6)
      (let ((start (host-getvar mock "MILLISECS"))
            (n 0))
        (loop for v = (host-getvar mock "MILLISECS")
              while (and (eql v start) (< n 100000000))
              do (incf n))
        (push n windows)))
    (setq windows (nreverse windows))
    (format t "~&[clock-cache] cached MILLISECS reads per ms across ~D windows ~
(first is a partial ms): ~S~%"
            (length windows) windows)
    ;; The later (full-ms) windows should fit many cached reads.
    (is (> (apply #'max windows) 100))))
