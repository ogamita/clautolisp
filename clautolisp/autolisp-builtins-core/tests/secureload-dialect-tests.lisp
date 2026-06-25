(in-package #:clautolisp.autolisp-builtins-core.tests)

(in-suite autolisp-builtins-core-suite)

;;;; SECURELOAD / TRUSTEDPATHS dialect-default overlay (Phase 2).
;;;;
;;;; Exercises APPLY-DIALECT-TRUST-SYSVAR-DEFAULTS directly against a
;;;; fresh MockHost: the per-dialect SECURELOAD / TRUSTEDPATHS defaults
;;;; and read-only-ness, registration of the clautolisp-only trust
;;;; sysvars, and the environment-variable override (env > dialect
;;;; default). See documentation/clautolisp-secureload-trust-model-spec.org.

(defun %const-cwd (&rest _)
  "A deterministic getcwd stub for tests (no real cwd dependency)."
  (declare (ignore _))
  "/work/proj")

(defun %trust-host (dialect &optional getenv)
  "A fresh MockHost with the dialect trust defaults applied. GETENV, when
supplied, stubs the environment lookups (a function NAME -> string-or-nil).
The cwd is stubbed to /work/proj so implicit-trusted defaults are
deterministic."
  (let ((mock (clautolisp.autolisp-mock-host:make-mock-host)))
    (if getenv
        (clautolisp.autolisp-builtins-core:apply-dialect-trust-sysvar-defaults
         mock dialect :getenv getenv :getcwd #'%const-cwd)
        (clautolisp.autolisp-builtins-core:apply-dialect-trust-sysvar-defaults
         mock dialect :getcwd #'%const-cwd))
    mock))

(defun %getvar-int (host name)
  (clautolisp.autolisp-builtins-core::%host-sysvar-integer host name))

(defun %getvar-str (host name)
  (clautolisp.autolisp-builtins-core::%host-sysvar-string host name))

(defun %sysvar-read-only-p (host name)
  "True when HOST rejects a setvar of NAME (read-only)."
  (handler-case
      (progn
        (clautolisp.autolisp-host:host-setvar
         host name (clautolisp.autolisp-host:host-getvar host name))
        nil)
    (error () t)))

;;; --- per-dialect SECURELOAD value -----------------------------------

(test secureload-dialect-default-values
  (is (eql 1 (%getvar-int (%trust-host :autocad-2026) "SECURELOAD")))
  (is (eql 0 (%getvar-int (%trust-host :bricscad-v26) "SECURELOAD")))
  ;; strict warns (1), not blocks (2): strict = intersection of dialects.
  (is (eql 1 (%getvar-int (%trust-host :strict) "SECURELOAD")))
  (is (eql 0 (%getvar-int (%trust-host :lax) "SECURELOAD")))
  (is (eql 1 (%getvar-int (%trust-host :clautolisp) "SECURELOAD"))))

(test trustedpaths-dialect-default-is-empty
  (dolist (d '(:autocad-2026 :bricscad-v26 :strict :lax :clautolisp))
    (is (string= "" (%getvar-str (%trust-host d) "TRUSTEDPATHS")))))

;;; --- read-only-ness follows the product -----------------------------

(test secureload-read-only-only-under-bricscad
  ;; BricsCAD locks both; the other dialects leave them settable so
  ;; tests / users can opt in or out.
  (is (%sysvar-read-only-p (%trust-host :bricscad-v26) "SECURELOAD"))
  (is (%sysvar-read-only-p (%trust-host :bricscad-v26) "TRUSTEDPATHS"))
  (is (not (%sysvar-read-only-p (%trust-host :autocad-2026) "SECURELOAD")))
  (is (not (%sysvar-read-only-p (%trust-host :strict) "SECURELOAD")))
  (is (not (%sysvar-read-only-p (%trust-host :clautolisp) "SECURELOAD")))
  (is (not (%sysvar-read-only-p (%trust-host :clautolisp) "TRUSTEDPATHS"))))

;;; --- clautolisp-only sysvars ----------------------------------------

(test clautolisp-trust-sysvars-only-under-clautolisp
  (let ((cl (%trust-host :clautolisp
                         (lambda (n) (declare (ignore n)) nil))))
    (is (string= "./" (%getvar-str cl "CLAUTOLISPSUPPORTFILESEARCHPATH")))
    ;; present (registered) — string, possibly empty with no env paths.
    (is (stringp (%getvar-str cl "CLAUTOLISPIMPLICITLYTRUSTEDFOLDERPATHS"))))
  ;; absent under the other dialects: GETVAR on an unknown sysvar -> nil.
  (let ((ac (%trust-host :autocad-2026)))
    (is (null (%getvar-str ac "CLAUTOLISPSUPPORTFILESEARCHPATH")))
    (is (null (%getvar-str ac "CLAUTOLISPIMPLICITLYTRUSTEDFOLDERPATHS")))))

(test implicitly-trusted-default-substitutes-cwd-prefix-and-xdg
  ;; cwd subtree first (clautolisp convenience), then XDG, then PREFIX.
  (let* ((env (lambda (n)
                (cond ((string= n "CLAUTOLISP_PREFIX") "/opt/local")
                      ((string= n "XDG_DATA_HOME") "/data")
                      (t nil))))
         (cl (%trust-host :clautolisp env)))
    (is (string= "/work/proj/...;/data/autolisp/...;/opt/local/share/autolisp/..."
                 (%getvar-str cl "CLAUTOLISPIMPLICITLYTRUSTEDFOLDERPATHS"))))
  ;; XDG falls back to $HOME/.local/share; no prefix -> cwd + xdg only.
  (let* ((env (lambda (n)
                (cond ((string= n "HOME") "/home/me") (t nil))))
         (cl (%trust-host :clautolisp env)))
    (is (string= "/work/proj/...;/home/me/.local/share/autolisp/..."
                 (%getvar-str cl "CLAUTOLISPIMPLICITLYTRUSTEDFOLDERPATHS")))))

;;; --- environment override (env > dialect default) -------------------

(test env-override-beats-dialect-default
  ;; strict defaults SECURELOAD to 1; SECURELOAD=0 in the env wins.
  (let* ((env (lambda (n) (cond ((string= n "SECURELOAD") "0")
                                ((string= n "TRUSTEDPATHS") "/opt/lisp;/usr/lisp/...")
                                (t nil))))
         (h (%trust-host :strict env)))
    (is (eql 0 (%getvar-int h "SECURELOAD")))
    (is (string= "/opt/lisp;/usr/lisp/..." (%getvar-str h "TRUSTEDPATHS"))))
  ;; An unparsable SECURELOAD env value is ignored (dialect default kept).
  (let* ((env (lambda (n) (cond ((string= n "SECURELOAD") "garbage") (t nil))))
         (h (%trust-host :autocad-2026 env)))
    (is (eql 1 (%getvar-int h "SECURELOAD"))))
  ;; CLAUTOLISP* env vars are ignored outside the clautolisp dialect
  ;; (the cells do not exist there).
  (let* ((env (lambda (n)
                (cond ((string= n "CLAUTOLISPSUPPORTFILESEARCHPATH") "./;./lib")
                      (t nil))))
         (h (%trust-host :autocad-2026 env)))
    (is (null (%getvar-str h "CLAUTOLISPSUPPORTFILESEARCHPATH"))))
  ;; …but honoured under clautolisp.
  (let* ((env (lambda (n)
                (cond ((string= n "CLAUTOLISPSUPPORTFILESEARCHPATH") "./;./lib")
                      (t nil))))
         (h (%trust-host :clautolisp env)))
    (is (string= "./;./lib" (%getvar-str h "CLAUTOLISPSUPPORTFILESEARCHPATH")))))
