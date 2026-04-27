;;;; autolisp-test/harness/platform-detect.lsp
;;;;
;;;; Auto-detect the implementation, version, platform, and runtime
;;;; extensions of the AutoLISP environment running this harness.
;;;; Pure AutoLISP. Loaded after rt.lsp and profiles.lsp.
;;;;
;;;; Returns an "implementation descriptor" alist with keys:
;;;;   IMPL          - symbol: clautolisp | autocad | bricscad | unknown
;;;;   IMPL-NAME     - string, vendor-reported product name
;;;;   VERSION       - string, vendor-reported version
;;;;   PLATFORMS     - list of symbols, subset of (windows linux macos)
;;;;   RUNTIMES      - list of symbols, subset of *autolisp-test-runtime-tags*
;;;;   PROFILE-TARGET- the profile the implementation aims at; defaults
;;;;                   to the symbol matching IMPL when known, otherwise
;;;;                   STRICT.

(defun autolisp-test--subr-bound-p (name / sym)
  "True iff NAME (a symbol) is bound to a SUBR / USUBR / EXSUBR / SUBRF.
Tests built-in availability without invoking the function. The set of
function-type symbols varies across implementations (clautolisp uses
SUBR / USUBR; AutoCAD / BricsCAD also expose EXSUBR and SUBRF for some
foreign and external entry points)."
  (and (boundp name)
       (member (type (eval name))
               '(subr usubr exsubr subrf))))

(defun autolisp-test--safe-getvar (name / catcher)
  "Return (getvar NAME) or nil if the call fails or the function is
not available. NAME is a string."
  (cond ((not (autolisp-test--subr-bound-p 'getvar)) nil)
        ((autolisp-test--catch-all-available-p)
         (setq catcher
               (vl-catch-all-apply '(lambda (n) (getvar n)) (list name)))
         (if (vl-catch-all-error-p catcher) nil catcher))
        (T (getvar name))))

(defun autolisp-test--safe-getenv (name / catcher)
  (cond ((not (autolisp-test--subr-bound-p 'getenv)) nil)
        ((autolisp-test--catch-all-available-p)
         (setq catcher
               (vl-catch-all-apply '(lambda (n) (getenv n)) (list name)))
         (if (vl-catch-all-error-p catcher) nil catcher))
        (T (getenv name))))

(defun autolisp-test--detect-impl (/ product)
  "Return one of (clautolisp autocad bricscad unknown). The detection
order is: vendor-specific markers, then product variable, then a
final unknown fallback."
  (cond
    ;; clautolisp installs *clautolisp-version* as an upper-case
    ;; symbol when it is present. The detection is opt-in so other
    ;; implementations are not affected.
    ((boundp '*clautolisp-version*) 'clautolisp)
    ;; BricsCAD reports "BricsCAD" as the PRODUCT system variable.
    ;; AutoCAD reports a string starting with "AutoCAD".
    (T (setq product (autolisp-test--safe-getvar "PRODUCT"))
       (cond ((null product) 'unknown)
             ((and (eq (type product) 'str)
                   (vl-string-search "BricsCAD" product)) 'bricscad)
             ((and (eq (type product) 'str)
                   (vl-string-search "AutoCAD" product)) 'autocad)
             (T 'unknown)))))

(defun autolisp-test--detect-version (/ s)
  (cond
    ((boundp '*clautolisp-version*) (eval '*clautolisp-version*))
    (T (setq s (autolisp-test--safe-getvar "ACADVER"))
       (if s s "unknown"))))

(defun autolisp-test--detect-platforms (/ os platforms uname)
  (setq platforms nil)
  (setq os (autolisp-test--safe-getenv "OS"))
  (cond
    ((and (eq (type os) 'str)
          (vl-string-search "Windows" os))
     (setq platforms (cons 'windows platforms)))
    (T
     ;; Fall back to OSTYPE / shell heuristics.
     (setq uname (autolisp-test--safe-getenv "OSTYPE"))
     (cond
       ((and (eq (type uname) 'str)
             (vl-string-search "darwin" (strcase uname T)))
        (setq platforms (cons 'macos platforms)))
       ((and (eq (type uname) 'str)
             (vl-string-search "linux" (strcase uname T)))
        (setq platforms (cons 'linux platforms)))
       (T
        ;; Last resort: try (getvar "PLATFORM") which BricsCAD
        ;; populates with a vendor string.
        (setq os (autolisp-test--safe-getvar "PLATFORM"))
        (cond
          ((and (eq (type os) 'str)
                (vl-string-search "Windows" os))
           (setq platforms (cons 'windows platforms)))
          ((and (eq (type os) 'str)
                (vl-string-search "Mac" os))
           (setq platforms (cons 'macos platforms)))
          ((and (eq (type os) 'str)
                (vl-string-search "Linux" os))
           (setq platforms (cons 'linux platforms))))))))
  platforms)

(defun autolisp-test--detect-runtimes (/ rt)
  (setq rt nil)
  (if (autolisp-test--subr-bound-p 'vlax-create-object)
      (setq rt (cons 'com (cons 'vlax rt))))
  (if (autolisp-test--subr-bound-p 'vla-get-application)
      (setq rt (cons 'vla rt)))
  (if (autolisp-test--subr-bound-p 'vlax-curve-getpointatdist)
      (setq rt (cons 'vlax-curve rt)))
  (if (autolisp-test--subr-bound-p 'vlr-object-reactor)
      (setq rt (cons 'vlr rt)))
  (if (autolisp-test--subr-bound-p 'arxload)
      (setq rt (cons 'arx rt)))
  (if (autolisp-test--subr-bound-p 'brxload)
      (setq rt (cons 'brx rt)))
  (if (autolisp-test--subr-bound-p 'entget)
      (setq rt (cons 'objectdbx rt)))
  (if (autolisp-test--subr-bound-p 'load_dialog)
      (setq rt (cons 'dcl rt)))
  (if (autolisp-test--subr-bound-p 'grdraw)
      (setq rt (cons 'graphics rt)))
  (if (autolisp-test--subr-bound-p 'getpoint)
      (setq rt (cons 'user-input rt)))
  (if (or (autolisp-test--subr-bound-p 'acet-file-copy)
          (autolisp-test--subr-bound-p 'acet-str-format))
      (setq rt (cons 'express-tools rt)))
  (if (autolisp-test--subr-bound-p 'dos_alert)
      (setq rt (cons 'doslib rt)))
  rt)

(defun autolisp-test--default-profile-target (impl)
  (cond ((eq impl 'autocad)    'autocad)
        ((eq impl 'bricscad)   'bricscad)
        (T                     'strict)))

(defun autolisp-test-detect-implementation (/ impl)
  "Build the implementation descriptor for the running environment."
  (setq impl (autolisp-test--detect-impl))
  (list (cons 'impl impl)
        (cons 'impl-name
              (cond ((eq impl 'clautolisp) "clautolisp")
                    ((eq impl 'autocad)    "AutoCAD")
                    ((eq impl 'bricscad)   "BricsCAD")
                    (T (or (autolisp-test--safe-getvar "PRODUCT")
                           "unknown"))))
        (cons 'version (autolisp-test--detect-version))
        (cons 'platforms (autolisp-test--detect-platforms))
        (cons 'runtimes  (autolisp-test--detect-runtimes))
        (cons 'profile-target
              (autolisp-test--default-profile-target impl))))

(princ "[autolisp-test] platform-detect.lsp loaded.\n")
(princ)
