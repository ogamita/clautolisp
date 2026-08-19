(in-package #:clautolisp.autolisp-builtins-core.tests)

(in-suite autolisp-builtins-core-suite)

;;;; Case-insensitive path resolution (case-insensitive-pathname-resolution).
;;;;
;;;; An AutoLISP corpus written on Windows and macOS has never had its
;;;; path spellings checked: those filesystems fold case, so nothing
;;;; there sanctions a mismatch. The same corpus fails on Linux, and in
;;;; the incident behind the feature the path was not even a literal --
;;;; it was derived from a class name, whose case is a naming convention
;;;; unrelated to the disk.
;;;;
;;;; With CLAUTOLISPCASEINSENSITIVEPATHS at 1, every incoming path is
;;;; walked against the filesystem and returned under its REAL name.
;;;;
;;;; A NOTE ON WHERE THIS CAN BE TESTED. The interesting assertions need
;;;; a CASE-SENSITIVE filesystem: where the filesystem already folds
;;;; case, "found the file under another spelling" is indistinguishable
;;;; from "found the file", and the test would pass while proving
;;;; nothing. Rather than naming operating systems -- macOS is usually
;;;; case-insensitive but can be formatted otherwise, and a Linux box can
;;;; mount either -- the harness ASKS THE FILESYSTEM IT IS STANDING ON,
;;;; per test directory. What is asserted unconditionally is everything
;;;; that does not depend on the answer: the default, the creation
;;;; policy, and the shape of the resolver's own decisions.

;;; --- harness ---------------------------------------------------------

(defun %case-host (&optional (value 1))
  "A fresh clautolisp-dialect MockHost installed as the session host,
with CLAUTOLISPCASEINSENSITIVEPATHS set to VALUE."
  (clautolisp.autolisp-runtime:reset-default-evaluation-context)
  (let* ((session (clautolisp.autolisp-runtime:evaluation-context-session
                   (clautolisp.autolisp-runtime:current-evaluation-context)))
         (mock (clautolisp.cador:make-cador)))
    (clautolisp.autolisp-builtins-core:apply-dialect-trust-sysvar-defaults
     mock :clautolisp)
    (clautolisp.autolisp-host:host-setvar
     mock "CLAUTOLISPCASEINSENSITIVEPATHS" value)
    (setf (clautolisp.autolisp-runtime.internal::runtime-session-host session)
          mock)
    (clautolisp.autolisp-builtins-core::clear-path-case-directory-cache)
    mock))

(defun %case-tree ()
  "A fresh temporary directory holding

      DIAL/SIGFIC.LSP
      A/b/C/deep.txt

Returns its namestring, with a trailing slash. Upper/lower case is
deliberately mixed ACROSS components so a multi-component mis-spelling
is exercised, not just a leaf one."
  (let* ((root (merge-pathnames
                (format nil "clautolisp-case-~36R/" (random (expt 2 48)))
                (uiop:temporary-directory))))
    (ensure-directories-exist (merge-pathnames "DIAL/" root))
    (ensure-directories-exist (merge-pathnames "A/b/C/" root))
    (with-open-file (s (merge-pathnames "DIAL/SIGFIC.LSP" root)
                       :direction :output :if-exists :supersede)
      (format s "(setq loaded-sigfic t)~%"))
    (with-open-file (s (merge-pathnames "A/b/C/deep.txt" root)
                       :direction :output :if-exists :supersede)
      (format s "deep~%"))
    (namestring root)))

(defun %case-sensitive-filesystem-p (directory)
  "Ask DIRECTORY's filesystem whether it distinguishes case, by probing a
file that exists under a known spelling through a different one. This is
a question about the mount, not about the operating system, so it is the
only honest way to ask it."
  (let ((upper (merge-pathnames "DIAL/SIGFIC.LSP" directory))
        (lower (merge-pathnames "dial/sigfic.lsp" directory)))
    (and (probe-file upper) (not (probe-file lower)))))

(defmacro %when-case-sensitive ((dir) &body body)
  "Run BODY only where the filesystem distinguishes case; elsewhere
assert the premise instead of asserting nothing, so a skipped run still
says why it was skipped."
  `(if (%case-sensitive-filesystem-p ,dir)
       (progn ,@body)
       (is (probe-file (merge-pathnames "dial/sigfic.lsp" ,dir))
           "this filesystem folds case itself, so the folding assertions ~
would prove nothing here")))

(defun %findfile (string)
  (let ((result (clautolisp.autolisp-builtins-core::builtin-findfile
                 (clautolisp.autolisp-runtime:make-autolisp-string string))))
    (and result (clautolisp.autolisp-runtime:autolisp-string-value result))))

;;; --- the sysvar ------------------------------------------------------

(test case-insensitive-paths-defaults-to-off
  ;; The default is not timidity: at 1 a program reaches files an exact
  ;; spelling would not have reached, so it must be switched on
  ;; deliberately.
  (let ((host (clautolisp.cador:make-cador)))
    (clautolisp.autolisp-builtins-core:apply-dialect-trust-sysvar-defaults
     host :clautolisp)
    (is (eql 0 (clautolisp.autolisp-builtins-core::%host-sysvar-integer
                host "CLAUTOLISPCASEINSENSITIVEPATHS")))))

(test case-insensitive-paths-seeded-from-the-environment
  ;; The environment variable carries the sysvar's exact name, with no
  ;; underscores -- the convention every sysvar-seeding variable follows
  ;; here (pjb, 2026-08-19), and what lets a CI job treat a whole corpus
  ;; without touching a line of it.
  (let ((host (clautolisp.cador:make-cador)))
    (clautolisp.autolisp-builtins-core:apply-dialect-trust-sysvar-defaults
     host :clautolisp
     :getenv (lambda (name)
               (when (string= name "CLAUTOLISPCASEINSENSITIVEPATHS") "1")))
    (is (eql 1 (clautolisp.autolisp-builtins-core::%host-sysvar-integer
                host "CLAUTOLISPCASEINSENSITIVEPATHS")))))

(test case-insensitive-paths-setvar-takes-effect-immediately
  ;; The resolver reads the sysvar per call, so a program can turn the
  ;; behaviour on for itself mid-run, as a sysvar should allow.
  (%case-host 0)
  (is (not (clautolisp.autolisp-builtins-core::%case-insensitive-paths-enabled-p)))
  (clautolisp.autolisp-host:host-setvar
   (clautolisp.autolisp-runtime.internal::runtime-session-host
    (clautolisp.autolisp-runtime:evaluation-context-session
     (clautolisp.autolisp-runtime:current-evaluation-context)))
   "CLAUTOLISPCASEINSENSITIVEPATHS" 1)
  (is (clautolisp.autolisp-builtins-core::%case-insensitive-paths-enabled-p)))

;;; --- resolution ------------------------------------------------------

(test case-insensitive-paths-off-leaves-a-miscased-path-unfound
  ;; The feature must not change what happens when it is off: this is the
  ;; failure the request describes, and at 0 it stays exactly that.
  (let ((dir (%case-tree)))
    (%case-host 0)
    (%when-case-sensitive (dir)
      (is (null (%findfile (concatenate 'string dir "dial/sigfic.lsp")))))))

(test case-insensitive-paths-on-finds-a-miscased-path
  (let ((dir (%case-tree)))
    (%case-host 1)
    (%when-case-sensitive (dir)
      (is (%findfile (concatenate 'string dir "dial/sigfic.lsp"))))))

(test case-insensitive-paths-findfile-returns-the-real-name
  ;; The request is explicit that normalising matters as much as
  ;; resolving: what findfile returns gets stored and reused, so handing
  ;; back the name as written would work once and fail on the next round.
  (let ((dir (%case-tree)))
    (%case-host 1)
    (%when-case-sensitive (dir)
      (let ((found (%findfile (concatenate 'string dir "dial/sigfic.lsp"))))
        (is (and found (search "DIAL/SIGFIC.LSP" found))
            "findfile returned ~S, which is not the real name on disk" found)
        ;; ... and the returned name must itself resolve, which is the
        ;; property "stored then reused" actually depends on.
        (is (probe-file found))))))

(test case-insensitive-paths-fold-every-component-not-just-the-leaf
  ;; a/B/c against A/b/C: each component is wrong in a different way, so
  ;; a resolver that folded only the last one would fail here.
  (let ((dir (%case-tree)))
    (%case-host 1)
    (%when-case-sensitive (dir)
      (let ((found (%findfile (concatenate 'string dir "a/B/c/DEEP.TXT"))))
        (is (and found (search "A/b/C/deep.txt" found))
            "multi-component fold returned ~S" found)))))

(test case-insensitive-paths-exact-match-wins-without-folding
  ;; Rule 1 of the request: an exact match wins, and it must not even
  ;; list the directory. Observable through the warning: an exact hit
  ;; folds nothing, so it says nothing.
  (let ((dir (%case-tree)))
    (%case-host 1)
    (let ((*error-output* (make-string-output-stream)))
      (is (%findfile (concatenate 'string dir "DIAL/SIGFIC.LSP")))
      (is (zerop (length (get-output-stream-string *error-output*)))))))

(test case-insensitive-paths-warn-names-the-real-spelling
  ;; The warning is what keeps this from being a carpet to sweep under:
  ;; the run proceeds AND the developer learns the path would fail on a
  ;; strict filesystem, and under which name it really lives.
  (let ((dir (%case-tree)))
    (%case-host 1)
    (%when-case-sensitive (dir)
      (let ((*error-output* (make-string-output-stream)))
        (%findfile (concatenate 'string dir "dial/sigfic.lsp"))
        (let ((output (get-output-stream-string *error-output*)))
          (is (search "path-case" output))
          (is (search "SIGFIC.LSP" output)
              "the warning must name the real spelling; got ~S" output))))))

;;; --- ambiguity -------------------------------------------------------

(test case-insensitive-paths-ambiguity-is-an-error-naming-the-candidates
  ;; Two entries differing only by case can coexist on a case-sensitive
  ;; filesystem. Choosing one silently would be worse than the failure
  ;; this feature removes -- the program would read a file nobody named.
  (let ((dir (%case-tree)))
    (%case-host 1)
    (%when-case-sensitive (dir)
      (with-open-file (s (merge-pathnames "twin.txt" dir)
                         :direction :output :if-exists :supersede)
        (format s "lower~%"))
      (with-open-file (s (merge-pathnames "TWIN.txt" dir)
                         :direction :output :if-exists :supersede)
        (format s "upper~%"))
      (clautolisp.autolisp-builtins-core::clear-path-case-directory-cache)
      (let ((message
              (handler-case
                  (progn (%findfile (concatenate 'string dir "Twin.txt")) nil)
                (error (e) (princ-to-string e)))))
        (is (not (null message))
            "an ambiguous fold must signal, not choose")
        (is (and (search "twin.txt" message) (search "TWIN.txt" message))
            "the error must name both candidates; got ~S" message)))))

;;; --- creation must not fold the leaf ---------------------------------

(test case-insensitive-paths-creation-keeps-the-name-as-written
  ;; The delicate half of the request. (open "Rapport.txt" "w") must
  ;; create Rapport.txt and must NOT land on a pre-existing RAPPORT.TXT,
  ;; which would overwrite a file the author never named.
  (let ((dir (%case-tree)))
    (%case-host 1)
    (%when-case-sensitive (dir)
      (with-open-file (s (merge-pathnames "RAPPORT.TXT" dir)
                         :direction :output :if-exists :supersede)
        (format s "original~%"))
      (clautolisp.autolisp-builtins-core::clear-path-case-directory-cache)
      (let ((stream (clautolisp.autolisp-builtins-core::builtin-open
                     (clautolisp.autolisp-runtime:make-autolisp-string
                      (concatenate 'string dir "Rapport.txt"))
                     (clautolisp.autolisp-runtime:make-autolisp-string "w"))))
        (is (not (null stream)))
        (clautolisp.autolisp-builtins-core::builtin-close stream))
      (is (probe-file (merge-pathnames "Rapport.txt" dir))
          "the file written must be the one that was named")
      (is (string= "original"
                   (with-open-file (s (merge-pathnames "RAPPORT.TXT" dir))
                     (read-line s)))
          "the pre-existing file differing only by case must be untouched"))))

(test case-insensitive-paths-creation-still-folds-the-directories
  ;; Creation takes the LEAF as written; the directories leading to it
  ;; are still resolved, which is what makes writing into DIAL/ work when
  ;; the program spelled it dial/.
  (let ((dir (%case-tree)))
    (%case-host 1)
    (%when-case-sensitive (dir)
      (let ((stream (clautolisp.autolisp-builtins-core::builtin-open
                     (clautolisp.autolisp-runtime:make-autolisp-string
                      (concatenate 'string dir "dial/Rapport.txt"))
                     (clautolisp.autolisp-runtime:make-autolisp-string "w"))))
        (is (not (null stream)))
        (clautolisp.autolisp-builtins-core::builtin-close stream))
      (is (probe-file (merge-pathnames "DIAL/Rapport.txt" dir))
          "the folded directory must be the one written into"))))

;;; --- the cache must not hide a file this run created -----------------

(test case-insensitive-paths-cache-self-heals-on-a-miss
  ;; The cache exists so a load loop does not re-read every parent
  ;; directory. It must not turn into a way of missing a file the same
  ;; run has just created, so a miss re-reads the directory once before
  ;; concluding.
  (let ((dir (%case-tree)))
    (%case-host 1)
    (%when-case-sensitive (dir)
      ;; populate the cache for DIR by resolving something else in it
      (%findfile (concatenate 'string dir "dial/sigfic.lsp"))
      (with-open-file (s (merge-pathnames "LATER.TXT" dir)
                         :direction :output :if-exists :supersede)
        (format s "later~%"))
      (is (%findfile (concatenate 'string dir "later.txt"))
          "a file created after the directory was cached must still be found"))))

;;; --- which dialects carry the sysvar ---------------------------------
;;;
;;; case-insensitive-paths-ignored-in-cad-dialects.issue. The feature was
;;; registered under the clautolisp dialect only, which put it exactly
;;; where it was LEAST needed: a --bricscad / --autocad run is how a
;;; corpus written for Windows is exercised, and that corpus is the one
;;; whose path spellings nobody ever checked. Under those dialects the
;;; sysvar did not exist, so neither setvar nor the environment had any
;;; purchase -- SCHMS+ set it to 1 under --dialect bricscad-v26 and
;;; nothing changed.

(defun %dialect-host (dialect &optional getenv)
  "A fresh MockHost with DIALECT's sysvar defaults applied."
  (let ((mock (clautolisp.cador:make-cador)))
    (if getenv
        (clautolisp.autolisp-builtins-core:apply-dialect-trust-sysvar-defaults
         mock dialect :getenv getenv)
        (clautolisp.autolisp-builtins-core:apply-dialect-trust-sysvar-defaults
         mock dialect))
    mock))

(defun %case-sysvar-present-p (host)
  (not (null (ignore-errors
              (clautolisp.autolisp-host:host-getvar
               host "CLAUTOLISPCASEINSENSITIVEPATHS")))))

(test case-insensitive-paths-sysvar-exists-in-every-dialect-but-strict
  "The emulation dialects are where the need arises, so the cell has to be
there for setvar and the environment to reach."
  (dolist (dialect '(:clautolisp :lax :autocad-2026 :bricscad-v26))
    (is (%case-sysvar-present-p (%dialect-host dialect))
        "CLAUTOLISPCASEINSENSITIVEPATHS should exist under ~S" dialect)))

(test case-insensitive-paths-sysvar-absent-in-strict
  "--strict exists to report what a portable engine would refuse, and a
path whose case does not match the disk is exactly that."
  (is (not (%case-sysvar-present-p (%dialect-host :strict)))))

(test case-insensitive-paths-default-stays-off-in-cad-dialects
  "pjb's ruling, and not an oversight: BricsCAD on Linux is not believed
to fold case on a case-sensitive filesystem, so folding by default would
be OUR invention rather than fidelity to the emulated engine."
  (dolist (dialect '(:autocad-2026 :bricscad-v26 :lax))
    (is (eql 0 (clautolisp.autolisp-builtins-core::%host-sysvar-integer
                (%dialect-host dialect) "CLAUTOLISPCASEINSENSITIVEPATHS"))
        "~S should default to 0" dialect)))

(test case-insensitive-paths-environment-reaches-the-cad-dialects
  "The exact invocation from the incident:
   CLAUTOLISPCASEINSENSITIVEPATHS=1 clautolisp --dialect bricscad-v26"
  (dolist (dialect '(:bricscad-v26 :autocad-2026 :lax))
    (let ((host (%dialect-host
                 dialect
                 (lambda (name)
                   (when (string= name "CLAUTOLISPCASEINSENSITIVEPATHS")
                     "1")))))
      (is (eql 1 (clautolisp.autolisp-builtins-core::%host-sysvar-integer
                  host "CLAUTOLISPCASEINSENSITIVEPATHS"))
          "the environment should reach ~S" dialect))))

(test case-insensitive-paths-environment-does-not-reach-strict
  (let ((host (%dialect-host
               :strict
               (lambda (name)
                 (when (string= name "CLAUTOLISPCASEINSENSITIVEPATHS") "1")))))
    (is (not (%case-sysvar-present-p host)))))

(test case-insensitive-paths-resolution-works-under-a-cad-dialect
  "The behaviour, not just the cell: the resolver reads the sysvar off the
host, so a bricscad-dialect session with it set must fold the case -- the
thing the issue reported as not happening."
  (let ((dir (%case-tree)))
    (clautolisp.autolisp-runtime:reset-default-evaluation-context)
    (let* ((session (clautolisp.autolisp-runtime:evaluation-context-session
                     (clautolisp.autolisp-runtime:current-evaluation-context)))
           (mock (%dialect-host :bricscad-v26)))
      (clautolisp.autolisp-host:host-setvar
       mock "CLAUTOLISPCASEINSENSITIVEPATHS" 1)
      (setf (clautolisp.autolisp-runtime.internal::runtime-session-host session)
            mock)
      (clautolisp.autolisp-builtins-core::clear-path-case-directory-cache))
    (%when-case-sensitive (dir)
      (is (%findfile (concatenate 'string dir "dial/sigfic.lsp"))
          "a bricscad-dialect session with the sysvar at 1 must fold"))))
