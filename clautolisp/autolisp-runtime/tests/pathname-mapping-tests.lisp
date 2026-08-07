(in-package #:clautolisp.autolisp-runtime.tests)

(in-suite autolisp-runtime-suite)

;;; Tests for the cross-environment path/pathname mapping layer
;;; (clautolisp-windows-pathname-mapping spec).  The synthetic frames make
;;; the Windows-only translation logic exercisable on Linux/macOS.

;; Convenience constructors -------------------------------------------------

(defun %posix () (clautolisp.pathname-mapping:identity-environment))
(defun %native ()
  (clautolisp.pathname-mapping:make-environment-for-kind
   :native-windows :home "C:/Users/pjb"))
(defun %msys2 ()
  (clautolisp.pathname-mapping:make-environment-for-kind
   :msys2 :home "/home/pjb" :install-root "C:/msys64/"))
(defun %cygwin ()
  (clautolisp.pathname-mapping:make-environment-for-kind
   :cygwin :home "/home/pjb" :install-root "C:/cygwin64/"))
(defun %wsl ()
  (clautolisp.pathname-mapping:make-environment-for-kind
   :wsl :home "/home/pjb"))

;; ---------------------------------------------------------------------------
;; W0 — identity mapping on Unix is a strict no-op
;; ---------------------------------------------------------------------------

(test pathmap-identity-map-in-is-noop
  (let ((p (%posix)))
    (dolist (s '("/tmp/x.lsp" "relative/y.lsp" "../up/z.lsp"
                 "/home/pjb/a b/c.lsp" "C:/looks/native.lsp"))
      (is (string= s (clautolisp.pathname-mapping:map-in-namestring
                      s :run p :build p))
          "identity map-in changed ~S" s))))

(test pathmap-identity-map-out-is-noop
  (let ((p (%posix)))
    (dolist (s '("/tmp/x.lsp" "relative/y.lsp" "/home/pjb/a.lsp"))
      (is (string= s (clautolisp.pathname-mapping:map-out-namestring
                      s :run p :build p))))))

(test pathmap-identity-round-trip-stable
  (let ((p (%posix)))
    (dolist (s '("/tmp/x.lsp" "relative/y.lsp" "/a/b/c.lsp"))
      (is (string= s (clautolisp.pathname-mapping:map-out-namestring
                      (clautolisp.pathname-mapping:map-in-namestring
                       s :run p :build p)
                      :run p :build p))))))

(test pathmap-identity-map-in-returns-pathname
  (let ((p (%posix)))
    (is (typep (clautolisp.pathname-mapping:map-in "/tmp/x.lsp" :run p :build p)
               'pathname))))

(test pathmap-posix-is-identity-environment
  (is (clautolisp.pathname-mapping:identity-environment-p (%posix)))
  ;; The WSL trap: WSL is NOT the identity environment (spec §1.1).
  (is (not (clautolisp.pathname-mapping:identity-environment-p (%wsl)))))

(test pathmap-mingw-under-msys2-renders-native
  ;; Regression (Windows/MSYS2 runner, 2026-08-07): a mingw SBCL launched
  ;; under an MSYS2 shell classifies :msys2 (MSYSTEM is set) but its
  ;; (truename "/") is "C:/" — it opens NATIVE C:/… paths, not the /c/…
  ;; mount form. %detect-environment now forces :drive-letter rendering in
  ;; that case. Simulate it by forcing native rendering on an :msys2 frame
  ;; that (like the real mingw CL) reports a native home, and assert the CL
  ;; sees native paths while ~ is still expanded (map-in is NOT a blind
  ;; identity). Before the fix, map-in rewrote C:/…run.lsp -> /c/…run.lsp
  ;; and LOAD/OPEN of absolute paths failed.
  (is (clautolisp.pathname-mapping::%cl-renders-native-drive-paths-p "C:/"))
  (is (clautolisp.pathname-mapping::%cl-renders-native-drive-paths-p "C:\\"))
  (is (not (clautolisp.pathname-mapping::%cl-renders-native-drive-paths-p "/")))
  (let ((e (clautolisp.pathname-mapping::%force-native-drive-style
            (clautolisp.pathname-mapping:make-environment-for-kind
             :msys2 :home "C:/msys64/home/pjb"))))
    (is (eq :drive-letter (clautolisp.pathname-mapping:menv-drive-style e)))
    (is (null (clautolisp.pathname-mapping:menv-mount-table e)))
    ;; an already-native absolute path stays native (openable), NOT /c/… :
    (is (string= "C:/gitlab-runner/x/harness/run.lsp"
                 (clautolisp.pathname-mapping:map-in-namestring
                  "C:/gitlab-runner/x/harness/run.lsp" :run e :build e)))
    ;; …yet ~ is still expanded per the frame home:
    (is (string= "C:/msys64/home/pjb/a.lsp"
                 (clautolisp.pathname-mapping:map-in-namestring
                  "~/a.lsp" :run e :build e)))))

;; ---------------------------------------------------------------------------
;; W2 — run-frame classification from synthetic probe inputs
;; ---------------------------------------------------------------------------

(test pathmap-classify-plain-linux-is-posix
  (is (eq :posix (clautolisp.pathname-mapping:classify-environment-kind
                  :uname-o "GNU/Linux" :os-windows-p nil))))

(test pathmap-classify-wsl-from-proc-version
  ;; uname says Linux, os-windows-p is NIL, yet /proc/version says
  ;; Microsoft — must classify :wsl, not :posix (the §1.1 trap).
  (is (eq :wsl (clautolisp.pathname-mapping:classify-environment-kind
                :uname-o "GNU/Linux"
                :os-windows-p nil
                :proc-version
                "Linux version 5.15.0-microsoft-standard-WSL2"))))

(test pathmap-classify-wsl-from-osrelease
  (is (eq :wsl (clautolisp.pathname-mapping:classify-environment-kind
                :osrelease "5.15.90.1-microsoft-standard-WSL2"))))

(test pathmap-classify-msys2-from-msystem
  (is (eq :msys2 (clautolisp.pathname-mapping:classify-environment-kind
                  :msystem "MINGW64" :os-windows-p t))))

(test pathmap-classify-cygwin-from-ostype
  (is (eq :cygwin (clautolisp.pathname-mapping:classify-environment-kind
                   :ostype "cygwin" :os-windows-p t))))

(test pathmap-classify-native-windows
  (is (eq :native-windows (clautolisp.pathname-mapping:classify-environment-kind
                           :os-windows-p t))))

(test pathmap-standard-drive-mount-prefixes
  (is (string= "/mnt/" (clautolisp.pathname-mapping:standard-drive-mount-prefix :wsl)))
  (is (string= "/cygdrive/" (clautolisp.pathname-mapping:standard-drive-mount-prefix :cygwin)))
  (is (string= "/" (clautolisp.pathname-mapping:standard-drive-mount-prefix :msys2)))
  (is (null (clautolisp.pathname-mapping:standard-drive-mount-prefix :native-windows))))

;; ---------------------------------------------------------------------------
;; W3 — non-identity translation across (build x run) pairs
;; ---------------------------------------------------------------------------

(defun %round-trips (run build s)
  "map-out(map-in(s)) == canonical form of S in the RUN frame (spec §6)."
  (let ((expected (clautolisp.pathname-mapping:from-canonical
                   (clautolisp.pathname-mapping:to-canonical s run) run)))
    (string= expected
             (clautolisp.pathname-mapping:map-out-namestring
              (clautolisp.pathname-mapping:map-in-namestring s :run run :build build)
              :run run :build build))))

(test pathmap-msys2-run-native-build
  (let ((run (%msys2)) (build (%native)))
    (is (string= "C:/Users/pjb/x.lsp"
                 (clautolisp.pathname-mapping:map-in-namestring
                  "/c/Users/pjb/x.lsp" :run run :build build)))
    (is (%round-trips run build "/c/Users/pjb/x.lsp"))))

(test pathmap-native-run-msys2-build
  (let ((run (%native)) (build (%msys2)))
    (is (string= "/c/Users/pjb/x.lsp"
                 (clautolisp.pathname-mapping:map-in-namestring
                  "C:/Users/pjb/x.lsp" :run run :build build)))
    (is (%round-trips run build "C:/Users/pjb/x.lsp"))))

(test pathmap-wsl-run-native-build
  (let ((run (%wsl)) (build (%native)))
    (is (string= "C:/work/a.lsp"
                 (clautolisp.pathname-mapping:map-in-namestring
                  "/mnt/c/work/a.lsp" :run run :build build)))
    (is (%round-trips run build "/mnt/c/work/a.lsp"))))

(test pathmap-native-run-wsl-build
  (let ((run (%native)) (build (%wsl)))
    (is (string= "/mnt/c/work/a.lsp"
                 (clautolisp.pathname-mapping:map-in-namestring
                  "C:/work/a.lsp" :run run :build build)))
    (is (%round-trips run build "C:/work/a.lsp"))))

(test pathmap-cygwin-native-both-ways
  (let ((cyg (%cygwin)) (native (%native)))
    (is (string= "C:/t/a.lsp"
                 (clautolisp.pathname-mapping:map-in-namestring
                  "/cygdrive/c/t/a.lsp" :run cyg :build native)))
    (is (%round-trips cyg native "/cygdrive/c/t/a.lsp"))
    (is (%round-trips native cyg "C:/t/a.lsp"))))

(test pathmap-msys2-install-root-remap
  ;; The MSYS2 POSIX root / is a real directory C:/msys64/ seen from
  ;; native Windows (spec table row 5).
  (let ((msys2 (%msys2)) (native (%native)))
    (is (string= "C:/msys64/home/pjb/a.lsp"
                 (clautolisp.pathname-mapping:map-in-namestring
                  "/home/pjb/a.lsp" :run msys2 :build native)))
    (is (string= "/home/pjb/a.lsp"
                 (clautolisp.pathname-mapping:map-out-namestring
                  "C:/msys64/home/pjb/a.lsp" :run msys2 :build native)))))

(test pathmap-home-expansion-per-run-frame
  ;; ~ resolves per the RUN frame's home (spec §6).
  (let ((native (%native)) (msys2 (%msys2)))
    (is (string= "/c/Users/pjb/a.lsp"
                 (clautolisp.pathname-mapping:map-in-namestring
                  "~/a.lsp" :run native :build msys2)))))

(test pathmap-unc-preserved
  (let ((native (%native)) (msys2 (%msys2)))
    (is (string= "//server/share/a.lsp"
                 (clautolisp.pathname-mapping:map-in-namestring
                  "//server/share/a.lsp" :run native :build msys2)))))

(test pathmap-mixed-separators-normalised
  ;; A native path with backslashes must still canonicalise (spec §6).
  (let ((native (%native)) (msys2 (%msys2)))
    (is (string= "/c/work/sub/a.lsp"
                 (clautolisp.pathname-mapping:map-in-namestring
                  "C:\\work\\sub\\a.lsp" :run native :build msys2)))))

(test pathmap-unmappable-path-signals
  ;; A WSL rootfs path (/home/...) has no drive mount, so it cannot be
  ;; rendered as a native drive path — explicit error, not a wrong file
  ;; (spec §6).
  (let ((wsl (%wsl)) (native (%native)))
    (fiveam:signals clautolisp.pathname-mapping:unmappable-path
      (clautolisp.pathname-mapping:map-in-namestring
       "/home/pjb/a.lsp" :run wsl :build native))))

(test pathmap-already-canonical-under-posix-run-still-mapped
  ;; A C:/... string under a POSIX-rooted run frame is still mapped to the
  ;; build frame; never assume "looks native => pass through" (spec §6).
  (let ((msys2 (%msys2)) (wsl (%wsl)))
    (is (string= "/mnt/c/x/a.lsp"
                 (clautolisp.pathname-mapping:map-in-namestring
                  "C:/x/a.lsp" :run msys2 :build wsl)))))
