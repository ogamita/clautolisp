;;;; scripts/verify-pathname-mapping.lisp
;;;;
;;;; Conformance harness for the cross-environment path/pathname mapping
;;;; layer (clautolisp-windows-pathname-mapping spec §8).  Self-contained:
;;;; run from the repo root with
;;;;   sbcl --non-interactive --load scripts/verify-pathname-mapping.lisp
;;;; (or ccl --load ...).  Exits 0 when every check passes, 1 on a failed
;;;; check, 2 when the system cannot load.
;;;;
;;;; Two layers of coverage, both runnable on ANY host:
;;;;   * a SYNTHETIC (build x run) matrix (spec §8) built from injected
;;;;     mapping-environments — this is the portable core and is what the
;;;;     Linux/macOS CI runners exercise.  All translation logic is proved
;;;;     here without needing a real Windows host.
;;;;   * a REAL-FILE round trip through the *live* detected build/run
;;;;     frames — the identity mapping on Unix, and the real native /
;;;;     cygwin / msys2 / wsl frames on the Windows runners.
(require :asdf)
(let ((ql (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname))))
  (when (probe-file ql) (load ql)))
(handler-case
    (asdf:load-asd
     (truename (merge-pathnames
                "clautolisp/clautolisp.asd"
                (uiop:ensure-directory-pathname
                 (or (uiop:getenv "CI_PROJECT_DIR") (uiop:getcwd))))))
  (error (e) (format t "~&LOAD FAILED (asd): ~A~%" e) (uiop:quit 2)))
(handler-case
    (asdf:load-system "clautolisp/autolisp-runtime")
  (error (e) (format t "~&LOAD FAILED (system): ~A~%" e) (uiop:quit 2)))

(defpackage #:clautolisp.verify-pathmap
  (:use #:cl #:clautolisp.pathname-mapping))
(in-package #:clautolisp.verify-pathmap)

(defvar *fails* 0)
(defun chk (label ok)
  (format t "~&~:[FAIL~;ok  ~]  ~A~%" ok label)
  (unless ok (incf *fails*)))
(defun chk-eq (label expected got)
  (let ((ok (equal expected got)))
    (chk label ok)
    (unless ok (format t "        expected ~S~%        got      ~S~%" expected got))))
(defun chk-signals (label thunk)
  (chk label (handler-case (progn (funcall thunk) nil)
               (unmappable-path () t))))

;;; Synthetic frames ---------------------------------------------------------
(defun native ()
  (make-environment-for-kind :native-windows :home "C:/Users/pjb"))
(defun msys2 ()
  (make-environment-for-kind :msys2 :home "/home/pjb" :install-root "C:/msys64/"))
(defun cygwin ()
  (make-environment-for-kind :cygwin :home "/home/pjb" :install-root "C:/cygwin64/"))
(defun wsl ()
  (make-environment-for-kind :wsl :home "/home/pjb"))
(defun posix () (identity-environment))

(defun canon-in (env s)
  "Canonical form of S rendered back in ENV's own frame (round-trip target)."
  (from-canonical (to-canonical s env) env))

(defun round-trips-p (run build s)
  (string= (canon-in run s)
           (map-out-namestring (map-in-namestring s :run run :build build)
                               :run run :build build)))

;;; ==========================================================================
(format t "~&########## clautolisp pathname-mapping conformance ##########~%")
(describe-mapping-environments)
(format t "~%--- W2: run-frame classification (synthetic probe inputs) ---~%")
(chk-eq "plain linux -> :posix" :posix
        (classify-environment-kind :uname-o "GNU/Linux" :os-windows-p nil))
(chk-eq "WSL trap: /proc/version microsoft -> :wsl (not :posix)" :wsl
        (classify-environment-kind :uname-o "GNU/Linux" :os-windows-p nil
                                   :proc-version "Linux 5.15-microsoft-standard-WSL2"))
(chk-eq "MSYSTEM=MINGW64 -> :msys2" :msys2
        (classify-environment-kind :msystem "MINGW64" :os-windows-p t))
(chk-eq "OSTYPE=cygwin -> :cygwin" :cygwin
        (classify-environment-kind :ostype "cygwin" :os-windows-p t))
(chk-eq "os-windows-p only -> :native-windows" :native-windows
        (classify-environment-kind :os-windows-p t))

(format t "~%--- W0: identity mapping is a strict no-op on :posix ---~%")
(let ((p (posix)))
  (dolist (s '("/tmp/x.lsp" "rel/y.lsp" "../up/z.lsp" "/a b/c.lsp"))
    (chk (format nil "identity map-in no-op ~S" s)
         (string= s (map-in-namestring s :run p :build p)))
    (chk (format nil "identity map-out no-op ~S" s)
         (string= s (map-out-namestring s :run p :build p)))
    (chk (format nil "identity round-trip ~S" s)
         (round-trips-p p p s))))

(format t "~%--- W3: known cross-frame translations (spec §8) ---~%")
(chk-eq "msys2 run /c/.. -> native build C:/.." "C:/Users/pjb/x.lsp"
        (map-in-namestring "/c/Users/pjb/x.lsp" :run (msys2) :build (native)))
(chk-eq "native run C:/.. -> msys2 build /c/.." "/c/Users/pjb/x.lsp"
        (map-in-namestring "C:/Users/pjb/x.lsp" :run (native) :build (msys2)))
(chk-eq "wsl run /mnt/c/.. -> native build C:/.." "C:/work/a.lsp"
        (map-in-namestring "/mnt/c/work/a.lsp" :run (wsl) :build (native)))
(chk-eq "native run C:/.. -> wsl build /mnt/c/.." "/mnt/c/work/a.lsp"
        (map-in-namestring "C:/work/a.lsp" :run (native) :build (wsl)))
(chk-eq "cygwin run /cygdrive/c/.. -> native build C:/.." "C:/t/a.lsp"
        (map-in-namestring "/cygdrive/c/t/a.lsp" :run (cygwin) :build (native)))
(chk-eq "msys2 root / -> native C:/msys64/ (install-root remap)"
        "C:/msys64/home/pjb/a.lsp"
        (map-in-namestring "/home/pjb/a.lsp" :run (msys2) :build (native)))
(chk-eq "native ~/ resolves per run-frame home"
        "/c/Users/pjb/a.lsp"
        (map-in-namestring "~/a.lsp" :run (native) :build (msys2)))
(chk-eq "UNC //server/share preserved" "//server/share/a.lsp"
        (map-in-namestring "//server/share/a.lsp" :run (native) :build (msys2)))
(chk-eq "mixed separators normalised" "/c/work/sub/a.lsp"
        (map-in-namestring "C:\\work\\sub\\a.lsp" :run (native) :build (msys2)))
(chk-eq "already-canonical C:/ under posix-rooted run still mapped"
        "/mnt/c/x/a.lsp"
        (map-in-namestring "C:/x/a.lsp" :run (msys2) :build (wsl)))
(chk-signals "WSL rootfs /home/.. has no drive mount -> unmappable error"
             (lambda () (map-in-namestring "/home/pjb/a.lsp" :run (wsl) :build (native))))

(format t "~%--- W4: round-trip stability across the (build x run) matrix ---~%")
;; §8 table: native/msys2/cygwin builds pair with every run frame; the
;; linux (wsl) build only pairs with wsl runs.
(let* ((run-paths
         (list (list :native (native) '("C:/work/proj/a.lsp" "C:/x/y/z.lsp" "~/a.lsp"))
               (list :msys2  (msys2)  '("/c/work/proj/a.lsp" "/c/x/y/z.lsp" "~/a.lsp"))
               (list :cygwin (cygwin) '("/cygdrive/c/work/a.lsp" "~/a.lsp"))
               (list :wsl    (wsl)    '("/mnt/c/work/a.lsp" "/mnt/d/data/b.lsp"))))
       (builds (list (list :native (native)) (list :msys2 (msys2))
                     (list :cygwin (cygwin)) (list :wsl (wsl)))))
  (dolist (b builds)
    (dolist (r run-paths)
      ;; The WSL/linux build frame only ever runs under WSL (spec §8 "-").
      (when (or (not (eq (first b) :wsl)) (eq (first r) :wsl))
        (dolist (s (third r))
          (chk (format nil "round-trip build=~A run=~A ~S"
                       (first b) (first r) s)
               (round-trips-p (second r) (second b) s)))))))

(format t "~%--- live-frame REAL FILE round trip (identity on Unix) ---~%")
(handler-case
    (let* ((dir (uiop:ensure-directory-pathname
                 (or (uiop:getenv "TMPDIR") (uiop:getenv "TEMP") "/tmp")))
           (file (merge-pathnames "clautolisp-pathmap-probe.lsp" dir)))
      (with-open-file (out file :direction :output :if-exists :supersede
                                :if-does-not-exist :create)
        (format out "(probe)~%"))
      (let* ((user-string (namestring file))     ; as the user/run frame sees it
             (host-path (map-in user-string))     ; -> pathname the host opens
             (opened (probe-file host-path)))
        (chk "map-in of a real file resolves to an openable pathname"
             (and opened t))
        (chk "map-out(map-in(s)) round-trips to the run-frame form"
             (string= (canon-in (run-environment) user-string)
                      (map-out-namestring (map-in-namestring user-string))))
        (ignore-errors (delete-file file))))
  (error (e)
    (chk (format nil "real-file round trip raised: ~A" e) nil)))

;;; ==========================================================================
(format t "~%")
(if (zerop *fails*)
    (progn (format t "pathname-mapping conformance: OK (build=~A run=~A)~%"
                   (menv-kind (build-environment)) (menv-kind (run-environment)))
           (uiop:quit 0))
    (progn (format t "pathname-mapping conformance: ~A FAILURE(S)~%" *fails*)
           (uiop:quit 1)))
