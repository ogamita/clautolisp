;;;; -*- mode:lisp; coding:utf-8 -*-
;;;;**************************************************************************
;;;;FILE:               pathname-mapping.lisp
;;;;LANGUAGE:           Common-Lisp
;;;;
;;;;DESCRIPTION
;;;;
;;;;    Cross-environment path / pathname mapping layer for clautolisp.
;;;;
;;;;    Implements the model of
;;;;    documentation/clautolisp-windows-pathname-mapping-spec.org:
;;;;    three frames of reference (build / run / user), a mount-table
;;;;    MAPPING-ENVIRONMENT model, and the two primitives MAP-IN /
;;;;    MAP-OUT pivoting through the canonical physical path (the native
;;;;    Windows drive-letter form, forward slashes).
;;;;
;;;;    On macOS / Linux (a single :POSIX environment) the whole layer
;;;;    short-circuits to the IDENTITY mapping — MAP-IN / MAP-OUT are
;;;;    no-ops — so existing behaviour is unchanged there.  The real work
;;;;    only happens on MS-Windows, where the build environment (what the
;;;;    host SBCL/CCL was compiled in) and the run environment (native /
;;;;    Cygwin / MSYS2 / WSL) can disagree about how the same physical
;;;;    files are named.
;;;;
;;;;    W0 (model + identity), W1 (build-frame recording), W2 (run-frame
;;;;    detection) and W3 (translation) of the spec's phase plan all live
;;;;    here.
;;;;
;;;;AUTHORS
;;;;    <PJB> Pascal J. Bourguignon <pjb@informatimago.com>
;;;;LICENSE
;;;;    AGPL3
;;;;**************************************************************************

(defpackage #:clautolisp.pathname-mapping
  (:use #:cl)
  (:nicknames #:clal-pathmap)
  (:export
   ;; Environment model (spec §4.1)
   #:mapping-environment
   #:make-mapping-environment
   #:mapping-environment-p
   #:menv-kind
   #:menv-separator
   #:menv-drive-style
   #:menv-drive-mount-prefix
   #:menv-mount-table
   #:menv-home
   #:menv-probe
   #:mount-entry
   #:make-mount-entry
   #:mount-frame-prefix
   #:mount-canonical-prefix
   #:identity-environment-p
   #:identity-environment
   ;; Live instances (spec §4.1)
   #:*build-environment*
   #:*run-environment*
   #:build-environment
   #:run-environment
   ;; Detection (spec §5)
   #:classify-environment-kind
   #:standard-mount-table
   #:standard-drive-mount-prefix
   #:make-environment-for-kind
   #:detect-build-environment
   #:detect-run-environment
   #:record-build-environment
   #:initialize-run-environment
   #:describe-mapping-environments
   ;; Translation (spec §4.2, §6)
   #:to-canonical
   #:from-canonical
   #:map-in-namestring
   #:map-out-namestring
   #:map-in
   #:map-out
   ;; Conditions (spec §6 unmappable path)
   #:unmappable-path
   #:unmappable-path-path
   #:unmappable-path-environment))

(in-package #:clautolisp.pathname-mapping)

;;; ------------------------------------------------------------------
;;; Data model (spec §4.1)
;;; ------------------------------------------------------------------

(defstruct (mount-entry (:conc-name mount-))
  ;; A prefix as seen in some POSIX-rooted environment's own path syntax
  ;; (separators already normalised to #\/), and the equivalent canonical
  ;; physical prefix (native drive-letter form).  Longest-prefix-wins.
  (frame-prefix     "" :type string)
  (canonical-prefix "" :type string))

(defstruct (mapping-environment (:conc-name menv-))
  ;; :posix :native-windows :cygwin :msys2 :wsl
  (kind :posix)
  ;; Separator used when rendering a path in this environment's frame.
  (separator #\/ :type character)
  ;; :drive-letter (native Windows: paths already look like C:/...) or
  ;; :posix-mount (unix-rooted: drives reachable under DRIVE-MOUNT-PREFIX)
  ;; or :none (the identity :posix environment).
  (drive-style :none)
  ;; For :posix-mount environments, the prefix under which drive letters
  ;; appear: "/mnt/" (wsl), "/cygdrive/" (cygwin), "/" (msys2).
  (drive-mount-prefix nil)
  ;; Ordered list of explicit MOUNT-ENTRYs (root remaps, /etc/fstab
  ;; entries).  Longest canonical/frame prefix wins regardless of order.
  (mount-table '() :type list)
  ;; Home directory expressed in THIS environment's own frame syntax
  ;; (e.g. "C:/Users/pjb" native, "/home/pjb" msys2).  NIL if unknown.
  (home nil)
  ;; Free-form plist of probe evidence recorded at detection time
  ;; (uname, MSYSTEM, truename of "/", ...) — debug only.
  (probe '() :type list))

(defun identity-environment ()
  "The trivial single-frame environment used on macOS / Linux."
  (make-mapping-environment :kind :posix :drive-style :none :separator #\/))

(defun identity-environment-p (env)
  "True when ENV is the trivial identity (:POSIX) environment.  Note that
WSL is *not* identity (spec §1.1 trap): a WSL host opens /mnt/<letter>/…
physical paths, so it is a :POSIX-MOUNT environment, not identity."
  (eq (menv-kind env) :posix))

;;; ------------------------------------------------------------------
;;; String helpers
;;; ------------------------------------------------------------------

(defun normalize-separators (string)
  "Fold backslashes to forward slashes (spec §6 mixed separators)."
  (substitute #\/ #\\ string))

(defun render-separators (string separator)
  (if (char= separator #\/)
      string
      (substitute separator #\/ string)))

(defun unc-path-p (s)
  "A UNC path //server/share/… — preserved as a distinct root (spec §6)."
  (and (>= (length s) 2) (char= (char s 0) #\/) (char= (char s 1) #\/)))

(defun drive-path-p (s)
  "A native drive path C:/… or bare C:."
  (and (>= (length s) 2)
       (alpha-char-p (char s 0))
       (char= (char s 1) #\:)))

(defun absolute-posix-p (s)
  (and (>= (length s) 1) (char= (char s 0) #\/)))

(defun home-relative-p (s)
  (and (>= (length s) 1) (char= (char s 0) #\~)))

(defun canonicalize-drive (s)
  "Render a drive path in canonical form: upper-case drive letter, a
slash after the colon, forward slashes throughout.  C:foo (drive-relative)
is treated as C:/foo."
  (let* ((letter (char-upcase (char s 0)))
         (rest   (subseq s 2)))
    (when (and (plusp (length rest)) (char= (char rest 0) #\/))
      (setf rest (subseq rest 1)))
    (format nil "~C:/~A" letter rest)))

(defun expand-home (s env)
  "Replace a leading ~ / ~/ with ENV's home (spec §6)."
  (let ((home (menv-home env)))
    (unless home
      (unmappable s env))
    (cond
      ((string= s "~") home)
      ((and (>= (length s) 2) (char= (char s 1) #\/))
       (concatenate 'string (string-right-trim "/" home) (subseq s 1)))
      (t s))))

;;; Split a POSIX drive path PREFIX+letter[/rest].  Returns (values LETTER
;;; REST) or NIL when S is not PREFIX + a single drive letter.
(defun posix-drive-split (s prefix)
  (let ((plen (length prefix)))
    (when (and (>= (length s) (1+ plen))
               (string= prefix (subseq s 0 plen))
               (alpha-char-p (char s plen))
               (or (= (length s) (1+ plen))
                   (char= (char s (1+ plen)) #\/)))
      (values (char s plen)
              (if (> (length s) (1+ plen))
                  (subseq s (+ 2 plen))       ; skip letter and its slash
                  "")))))

;;; ------------------------------------------------------------------
;;; Conditions (spec §6: an unmappable path is an explicit error, never a
;;; silent wrong-file open).
;;; ------------------------------------------------------------------

(define-condition unmappable-path (error)
  ((path        :initarg :path        :reader unmappable-path-path)
   (environment :initarg :environment :reader unmappable-path-environment))
  (:report (lambda (c stream)
             (format stream "Path ~S has no mount entry in the ~A environment."
                     (unmappable-path-path c)
                     (menv-kind (unmappable-path-environment c))))))

(defun unmappable (path env)
  (error 'unmappable-path :path path :environment env))

;;; ------------------------------------------------------------------
;;; Translation core (spec §4, §6).  Canonical physical path = native
;;; Windows drive-letter form (C:/…, forward slashes) or //server/… UNC.
;;; ------------------------------------------------------------------

(defun to-canonical (string env)
  "Parse STRING, expressed in ENV's frame, into the canonical physical
path.  Relative paths (and, in the identity environment, everything) are
returned unchanged for the caller to merge against the canonical cwd."
  (let ((s (normalize-separators string)))
    (cond
      ((identity-environment-p env) s)
      ((unc-path-p s) s)
      ((drive-path-p s) (canonicalize-drive s))     ; already-canonical (spec §6)
      ((home-relative-p s) (to-canonical (expand-home s env) env))
      ((absolute-posix-p s) (posix->canonical s env))
      (t s))))                                        ; relative: leave as-is

(defun posix->canonical (s env)
  (let ((prefix (menv-drive-mount-prefix env)))
    ;; 1. drive mount:  /mnt/c/… -> C:/…   (longest-specific first)
    (when prefix
      (multiple-value-bind (letter rest) (posix-drive-split s prefix)
        (when letter
          (return-from posix->canonical
            (format nil "~C:/~A" (char-upcase letter) rest)))))
    ;; 2. explicit mount table (root remaps like msys2 / -> C:/msys64/)
    (let ((entry (longest-frame-match s (menv-mount-table env))))
      (when entry
        (return-from posix->canonical
          (concatenate 'string (mount-canonical-prefix entry)
                       (subseq s (length (mount-frame-prefix entry)))))))
    ;; 3. no mount entry: unmappable (spec §6)
    (unmappable s env)))

(defun from-canonical (canonical env)
  "Render the CANONICAL physical path as a path string in ENV's frame."
  (let ((c (normalize-separators canonical)))
    (cond
      ((identity-environment-p env) c)
      ((unc-path-p c) (render-separators c (menv-separator env)))
      ((drive-path-p c)
       (render-separators (canonical->frame (canonicalize-drive c) env)
                          (menv-separator env)))
      ;; A relative / already-frame path: pass through.
      (t (render-separators c (menv-separator env))))))

(defun canonical->frame (canonical env)
  (ecase (menv-drive-style env)
    (:none canonical)
    (:drive-letter canonical)                         ; native: C:/… stays
    (:posix-mount
     ;; 1. explicit mount table (longest canonical prefix wins) — this
     ;; makes C:/msys64/… render as /… before the generic drive rule.
     (let ((entry (longest-canonical-match canonical (menv-mount-table env))))
       (when entry
         (return-from canonical->frame
           (concatenate 'string (mount-frame-prefix entry)
                        (subseq canonical (length (mount-canonical-prefix entry)))))))
     ;; 2. generic drive mount:  C:/… -> /mnt/c/… (or /c/…, /cygdrive/c/…)
     (let ((prefix (menv-drive-mount-prefix env)))
       (when (and prefix (drive-path-p canonical))
         (let ((letter (char-downcase (char canonical 0)))
               (rest   (subseq canonical 3)))          ; after "C:/"
           (return-from canonical->frame
             (if (zerop (length rest))
                 (format nil "~A~C" prefix letter)
                 (format nil "~A~C/~A" prefix letter rest))))))
     ;; 3. unmappable
     (unmappable canonical env))))

(defun longest-frame-match (s table)
  (let ((best nil) (best-len -1))
    (dolist (e table best)
      (let ((p (mount-frame-prefix e)))
        (when (and (>= (length s) (length p))
                   (string= p (subseq s 0 (length p)))
                   (> (length p) best-len))
          (setf best e best-len (length p)))))))

(defun longest-canonical-match (canonical table)
  (let ((best nil) (best-len -1))
    (dolist (e table best)
      (let ((p (mount-canonical-prefix e)))
        (when (and (>= (length canonical) (length p))
                   (string= p (subseq canonical 0 (length p)))
                   (> (length p) best-len))
          (setf best e best-len (length p)))))))

;;; ------------------------------------------------------------------
;;; The two primitives (spec §4.2)
;;; ------------------------------------------------------------------

(defvar *build-environment*)
(defvar *run-environment*)

(defun %mount-tables-equal-p (ta tb)
  "Element-wise structural equality of two mount-tables.  MOUNT-ENTRY is a
struct, so EQUAL on the raw lists would compare by identity and miss two
logically-identical tables built from distinct instances (the common case
when the run and build frames are detected separately)."
  (and (= (length ta) (length tb))
       (every (lambda (x y)
                (and (string= (mount-frame-prefix x)     (mount-frame-prefix y))
                     (string= (mount-canonical-prefix x) (mount-canonical-prefix y))))
              ta tb)))

(defun environments-equal-p (a b)
  "True when A and B describe the SAME frame, so a path expressed in one is
already exactly what the other's host expects — map-in/map-out must then be
a STRICT identity, with NO canonical round-trip.

This is the case that the plain IDENTITY-ENVIRONMENT-P (:posix-only) guard
misses: a CL that renders native drive-letter paths from *inside* a
POSIX-style shell — a mingw SBCL launched under MSYS2, whose (truename \"/\")
is \"C:/\" — has build-frame == run-frame, yet neither is :posix. Without
this guard map-in would rewrite an already-correct C:/… into the MSYS2
mount form /c/…, handing the mingw CL a namestring it cannot open (this
broke LOAD/OPEN of absolute paths on the Windows/MSYS2 runner). When the
two frames are equal there is by definition nothing to translate.

Conservative: any structural difference (or an un-comparable mount-table)
falls through to the normal translation path, which is always the safe
choice."
  (or (eq a b)
      (and (eq    (menv-kind a)               (menv-kind b))
           (eql   (menv-separator a)          (menv-separator b))
           (eq    (menv-drive-style a)        (menv-drive-style b))
           (equal (menv-drive-mount-prefix a) (menv-drive-mount-prefix b))
           (equal (menv-home a)               (menv-home b))
           (%mount-tables-equal-p (menv-mount-table a) (menv-mount-table b)))))

(defun map-in-namestring (string &key
                                   (run   (run-environment))
                                   (build (build-environment)))
  "User/run-frame STRING -> physical path string the BUILD host can open.
Identity (returns STRING unchanged) when both frames are :POSIX, or when the
run and build frames are the SAME environment (nothing to translate)."
  (if (or (and (identity-environment-p run) (identity-environment-p build))
          (environments-equal-p run build))
      string
      (from-canonical (to-canonical string run) build)))

(defun map-out-namestring (string &key
                                    (run   (run-environment))
                                    (build (build-environment)))
  "Physical BUILD-frame STRING -> path string in the user/run frame.
Identity when both frames are :POSIX, or when the run and build frames are
the SAME environment (nothing to translate)."
  (if (or (and (identity-environment-p run) (identity-environment-p build))
          (environments-equal-p run build))
      string
      (from-canonical (to-canonical string build) run)))

(defun map-in (string &key (run (run-environment)) (build (build-environment)))
  "MAP-IN (string) -> pathname (spec §4.2): parse in the user/run frame,
render a CL pathname in the build frame for the host to open."
  (pathname (map-in-namestring string :run run :build build)))

(defun map-out (pathname-or-string &key
                                     (run (run-environment))
                                     (build (build-environment)))
  "MAP-OUT (pathname-or-string) -> string (spec §4.2)."
  (let ((s (if (stringp pathname-or-string)
               pathname-or-string
               (namestring pathname-or-string))))
    (map-out-namestring s :run run :build build)))

;;; ------------------------------------------------------------------
;;; Detection (spec §5)
;;; ------------------------------------------------------------------

(defun classify-environment-kind
    (&key msystem ostype uname-o proc-version osrelease os-windows-p)
  "Pure classifier: return the environment kind from the given probe
inputs.  Independent of UIOP:OS-WINDOWS-P alone precisely because WSL
reports Linux (spec §1.1 / §5.2)."
  (flet ((has (hay needle)
           (and hay needle
                (search (string-downcase needle) (string-downcase hay)))))
    (cond
      ((or (has proc-version "microsoft") (has proc-version "wsl")
           (has osrelease "microsoft") (has osrelease "wsl"))
       :wsl)
      ((or (and msystem (plusp (length msystem)))
           (has ostype "msys")
           (has uname-o "msys"))
       :msys2)
      ((or (has ostype "cygwin") (has uname-o "cygwin"))
       :cygwin)
      (os-windows-p :native-windows)
      (t :posix))))

(defun standard-drive-mount-prefix (kind)
  (ecase kind
    (:wsl "/mnt/")
    (:cygwin "/cygdrive/")
    (:msys2 "/")
    ((:native-windows :posix) nil)))

(defun standard-mount-table (kind &key install-root)
  "The default explicit mount table for KIND.  INSTALL-ROOT, when given,
maps the POSIX root / of a cygwin/msys2 install back to its canonical
physical location (e.g. C:/msys64/)."
  (ecase kind
    ((:wsl :native-windows :posix) '())
    ((:cygwin :msys2)
     (when install-root
       (list (make-mount-entry :frame-prefix "/"
                               :canonical-prefix install-root))))))

(defun make-environment-for-kind
    (kind &key home install-root separator mount-table probe)
  "Construct a MAPPING-ENVIRONMENT for KIND with the standard drive-mount
prefix and mount table.  Used both by detection and (with explicit
arguments) by the conformance harness / tests to build synthetic frames."
  (let ((sep (or separator (if (eq kind :native-windows) #\/ #\/))))
    (make-mapping-environment
     :kind kind
     :separator sep
     :drive-style (ecase kind
                    (:posix :none)
                    (:native-windows :drive-letter)
                    ((:cygwin :msys2 :wsl) :posix-mount))
     :drive-mount-prefix (standard-drive-mount-prefix kind)
     :mount-table (or mount-table
                      (standard-mount-table kind :install-root install-root))
     :home home
     :probe probe)))

(defun %read-first-line (path)
  (ignore-errors
   (with-open-file (in path :if-does-not-exist nil)
     (when in (read-line in nil nil)))))

(defun %detect-inputs ()
  "Gather the real detection inputs from the live process."
  (list :msystem (uiop:getenv "MSYSTEM")
        :ostype (uiop:getenv "OSTYPE")
        :uname-o (ignore-errors
                  (string-trim '(#\Space #\Newline #\Return)
                               (uiop:run-program '("uname" "-o")
                                                 :output :string
                                                 :ignore-error-status t)))
        :proc-version (%read-first-line #P"/proc/version")
        :osrelease (%read-first-line #P"/proc/sys/kernel/osrelease")
        :os-windows-p (uiop:os-windows-p)))

(defun %detect-home ()
  (ignore-errors (namestring (user-homedir-pathname))))

(defun %detect-environment (probe-tag)
  (let* ((inputs (%detect-inputs))
         (kind (apply #'classify-environment-kind inputs))
         (root-truename (ignore-errors (namestring (truename #P"/")))))
    (make-environment-for-kind
     kind
     :home (%detect-home)
     :probe (list* :tag probe-tag :root-truename root-truename inputs))))

(defun detect-build-environment ()
  "Detect the environment SBCL/CCL is being BUILT in.  Called at file load
time so the result is captured into the dumped image (spec §5.1)."
  (%detect-environment :build))

(defun detect-run-environment ()
  "Detect the active runtime environment at process start (spec §5.2)."
  (%detect-environment :run))

;;; W1 — build-frame recording.  This form runs when the compiled runtime
;;; is LOADED, which during a build is inside the build environment; the
;;; value is then frozen into the dumped image.  On a fresh (non-image)
;;; load — e.g. `make test` — it simply reflects the current host, which
;;; on Linux/macOS is the identity environment.
(setf *build-environment* (detect-build-environment))
;; The run environment defaults to the build environment until the tool's
;; startup re-detects it (INITIALIZE-RUN-ENVIRONMENT); on a fresh load both
;; are the same host anyway.
(setf *run-environment* *build-environment*)

(defun build-environment () *build-environment*)
(defun run-environment () *run-environment*)

(defun record-build-environment (&optional (env (detect-build-environment)))
  "Force the build-frame descriptor (W1 accessor / test hook)."
  (setf *build-environment* env))

(defun initialize-run-environment (&optional (env (detect-run-environment)))
  "Classify and install the run-frame descriptor at startup (spec §4.3,
§5.2).  On :POSIX this is the identity environment, so the whole mapping
layer short-circuits and nothing changes."
  (setf *run-environment* env))

(defun describe-mapping-environments (&optional (stream *standard-output*))
  "Debug dump of the recorded build/run frames (spec §5.1 inspection)."
  (flet ((describe1 (label env)
           (format stream "~&~A: kind=~S drive-style=~S drive-mount-prefix=~S~%~
                            ~4Thome=~S mount-table=~S~%~4Tprobe=~S~%"
                   label (menv-kind env) (menv-drive-style env)
                   (menv-drive-mount-prefix env) (menv-home env)
                   (menv-mount-table env) (menv-probe env))))
    (describe1 "build-environment" *build-environment*)
    (describe1 "run-environment" *run-environment*))
  (values))
