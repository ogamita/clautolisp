;;;; plugins/epuree/epuree.lisp — the EPUREE plug-in for alfe.
;;;;
;;;; EPUREE is an AutoLISP emulation of the public EPURE API
;;;; (~/works/sncf-reseau/src/epuree), for BricsCAD on macOS and Linux and
;;;; for tests. It is packaged as the ALPM system `epuree' (epuree.alpm at
;;;; the root of its repository). This plug-in puts the loading of that
;;;; system, and its initialization, in front of the action plan, on every
;;;; backend. Loading the system only defines; (epuree-initialize) is what
;;;; acts on the host -- the path and environment shims, the bundle root --
;;;; and (alpm-load-system "epuree" nil) followed by it is equivalent to
;;;; (load "load_epuree").
;;;;
;;;; Specified by documentation/alfe--specifications.org, chapter "EPUREE",
;;;; and issues/closed/alfe-plugin-epuree.issue.

(defpackage #:alfe.plugin.epuree
  (:use #:cl #:alfe.plugin)
  (:import-from #:alfe.error
                #:cli-error))

(in-package #:alfe.plugin.epuree)

(define-plugin "epuree"
  :version "1.2.0"
  :description "Load and initialize the EPUREE emulation of the EPURE API (ALPM system epuree) before the plan runs."
  :options ((:flag   "--epuree" :activates t :env "AUTOLISP_EPUREE"
                     :doc "Load EPUREE before anything else.")
            (:repeat "--epuree-path" :key :paths :arg "DIR" :env "EPUREE_PATH"
                     :doc "Directory (searched recursively) registered with ALPM as holding epuree.alpm; repeatable.")
            (:value  "--epuree-alpm" :key :alpm :arg "FILE" :env "ALPM_LSP"
                     :doc "The alpm.lsp to load (default: looked for in the usual places).")))

(defun forward-slashes (string)
  (substitute #\/ #\\ string))

(defun absolute (string)
  "STRING as an absolute native path with forward slashes. The engine
evaluates the load, and a CAD's working directory is not alfe's."
  (forward-slashes
   (uiop:native-namestring
    (uiop:ensure-absolute-pathname string (uiop:getcwd)))))

(defvar *alpm-candidates-function* 'alpm-candidates
  "Function of no argument returning where alpm.lsp is looked for when it
was not named. A variable so that the tests can say where NOT to look.")

(defun alpm-candidates ()
  "Where alpm.lsp is looked for when it was not named: every installation
prefix the running executable can belong to, then ALPM's own default prefix
and the usual ones."
  (append
   (mapcar (lambda (prefix)
             (uiop:native-namestring
              (merge-pathnames "share/autolisp/alpm.lsp" prefix)))
           (ignore-errors
            (uiop:symbol-call :alfe.backend.cad-common :installation-prefixes)))
   (list "/opt/local/share/autolisp/alpm.lsp"
         "/usr/local/share/autolisp/alpm.lsp"
         (namestring (merge-pathnames ".local/share/autolisp/alpm.lsp"
                                      (user-homedir-pathname))))))

(defun alpm-lsp ()
  "The alpm.lsp to load: the one named (--epuree-alpm, $ALPM_LSP), which must
exist, else the first of the usual places that does."
  (let ((named (plugin-option :alpm)))
    (cond
      (named
       ;; A file the user named that is not there: EX_NOINPUT.
       (unless (probe-file named)
         (error 'cli-error
                :option "--epuree-alpm"
                :message (format nil "alpm.lsp not found: ~A" named)
                :status clautolisp.sysexits:+ex-noinput+))
       named)
      (t
       ;; A support file that is not installed: EX_UNAVAILABLE.
       (let ((candidates (funcall *alpm-candidates-function*)))
         (or (find-if #'probe-file candidates)
             (error 'cli-error
                    :option "--epuree-alpm"
                    :message (format nil "alpm.lsp not found (looked in ~{~A~^, ~}); pass --epuree-alpm FILE or set $ALPM_LSP"
                                     candidates)
                    :status clautolisp.sysexits:+ex-unavailable+)))))))

(defvar *epuree-share-candidates-function* 'epuree-share-candidates
  "Function of no argument returning the directories where an installed
EPUREE may live. A variable so that the tests can say where to look.")

(defun epuree-share-candidates ()
  "PREFIX/share/epuree/ for every installation prefix the running executable
can belong to, then for the usual prefixes -- the places alpm.lsp is looked
for, with share/epuree/ instead of share/autolisp/."
  (mapcar (lambda (prefix) (merge-pathnames "share/epuree/" prefix))
          (append
           (ignore-errors
            (uiop:symbol-call :alfe.backend.cad-common :installation-prefixes))
           (list #P"/opt/local/" #P"/usr/local/"
                 (merge-pathnames ".local/" (user-homedir-pathname))))))

(defun trusted-epuree-paths ()
  "The TRUSTEDPATHS entries for the installed EPUREE directories: each one
that exists, with the subfolder marker (\\... on MS-Windows, /... elsewhere),
without duplicates."
  (let ((separator (if (uiop:os-windows-p) "\\" "/")))
    (remove-duplicates
     (mapcar (lambda (directory)
               (concatenate 'string
                            (string-right-trim "/\\" (uiop:native-namestring directory))
                            separator "..."))
             (remove-if-not #'uiop:directory-exists-p
                            (funcall *epuree-share-candidates-function*)))
     :test #'string-equal :from-end t)))

(defun trust-form (entry)
  "An AutoLISP form appending ENTRY to TRUSTEDPATHS unless it is already
there. TRUSTEDPATHS is read-only on BricsCAD V26 (admin-configured): the
SETVAR is caught, so a refusal leaves the run to SECURELOAD rather than
failing it."
  (format nil "((lambda (entry / trusted) (setq trusted (cond ((getvar \"TRUSTEDPATHS\")) (\"\"))) (if (not (vl-string-search (strcase entry) (strcase trusted))) (vl-catch-all-apply 'setvar (list \"TRUSTEDPATHS\" (if (= trusted \"\") entry (strcat trusted \";\" entry))))) entry) ~A)"
          (autolisp-string-literal entry)))

(defun eval-form (control &rest arguments)
  (alfe.backend:action-eval (apply #'format nil control arguments)))

(define-plugin-hook "epuree" :plan (ctx plan)
  ;; Five kinds of action in front of everything (init files included),
  ;; evaluated by the engine itself: trust the installed EPUREE directories,
  ;; load ALPM, tell it where epuree.alpm is, load the system, initialize it.
  ;; A failure fails the run before the user's script starts.
  (append
   (mapcar (lambda (entry) (alfe.backend:action-eval (trust-form entry)))
           (trusted-epuree-paths))
   (list (eval-form "(load ~A)" (autolisp-string-literal (absolute (alpm-lsp)))))
   (mapcar (lambda (directory)
             (eval-form "(alpm-register-directory ~A T)"
                        (autolisp-string-literal (absolute directory))))
           (plugin-option :paths))
   (list (eval-form "(alpm-load-system \"epuree\" nil)")
         (eval-form "(epuree-initialize)"))
   plan))
