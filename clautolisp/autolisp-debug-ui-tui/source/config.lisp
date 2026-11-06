(in-package #:tui-core)

;;;; Configuration cascade (TUI module spec; pjb: "the configuration cascade
;;;; must match the interactor stacks"). A CONFIG is a named set of settings
;;;; (faces, key bindings, window layout, print-syntax parameters …) with a
;;;; PARENT config; resolving a setting walks the chain from the config up to the
;;;; root, so a config inherits its parents' settings and may override them.
;;;;
;;;; The config tree parallels the interactor stacks: each interactor names the
;;;; config it runs under, and the stack's configs form the cascade. E.g.
;;;;   sedit      : sedit.conf   -> lisp.conf
;;;;   debugger stack pane  : stack.conf   -> aldo.conf -> lisp.conf
;;;;   debugger source pane : navi.conf    -> aldo.conf -> lisp.conf
;;;;   debugger interactor  : aldo.conf    -> lisp.conf
;;;;   debugger inspect pane: inspect.conf -> aldo.conf -> lisp.conf
;;;;   standalone clal-inspect: inspector.conf -> lisp.conf   (no aldo here)
;;;; The distinct names (inspect vs inspector) encode the distinct cascades.
;;;;
;;;; Each config persists to a <name>.conf file (see READ-CONFIG / WRITE-CONFIG);
;;;; the cascade of files matches the cascade of configs. This layer is
;;;; clautolisp-independent — settings values are plain readable data.

(defstruct (config (:constructor %make-config) (:predicate config-p))
  (name "" :type string)
  (parent nil)                                   ; a CONFIG, or NIL for the root
  (settings (make-hash-table :test 'equal))      ; KEY -> VALUE, this config's own
  (dirty nil))

(defmethod print-object ((c config) stream)
  (print-unreadable-object (c stream :type t :identity t)
    (format stream "~S~@[ -> ~S~]" (config-name c)
            (and (config-parent c) (config-name (config-parent c))))))

(defvar *configs* (make-hash-table :test 'equal)
  "Registry: config name (string) -> CONFIG.")

(defun find-config (name)
  "The registered config named NAME (a name or a CONFIG), or NIL."
  (cond ((config-p name) name)
        (name (gethash (string-downcase (string name)) *configs*))))

(defun ensure-config (name &optional parent)
  "Find or create the config NAME (a name or a CONFIG). When creating, set its
PARENT (a CONFIG, a config name, or NIL); an existing config's parent is left
unchanged unless PARENT is supplied and differs."
  (when (config-p name)
    (when (and parent (not (eq (config-parent name)
                               (etypecase parent (null nil) (config parent)
                                          ((or string symbol) (ensure-config parent))))))
      (setf (config-parent name)
            (etypecase parent (config parent) ((or string symbol) (ensure-config parent)))))
    (return-from ensure-config name))
  (let* ((key (string-downcase (string name)))
         (existing (gethash key *configs*)))
    (flet ((as-config (p) (etypecase p
                            (null nil) (config p)
                            ((or string symbol) (ensure-config p)))))
      (cond
        (existing
         (when (and parent (not (eq (config-parent existing) (as-config parent))))
           (setf (config-parent existing) (as-config parent)))
         existing)
        (t (setf (gethash key *configs*)
                 (%make-config :name key :parent (as-config parent))))))))

(defun config-cascade (config)
  "The configs from CONFIG up to the root, innermost (CONFIG) first."
  (let ((c (if (config-p config) config (find-config config))) (out '()))
    (loop while c do (push c out) (setf c (config-parent c)))
    (nreverse out)))

(defun config-value (config key &optional default)
  "Resolve KEY through CONFIG's cascade (CONFIG, then its parent, …); return
DEFAULT when KEY is set nowhere in the chain. Secondary value is the CONFIG the
value came from (NIL for the default)."
  (let ((c (if (config-p config) config (find-config config))))
    (loop while c do
      (multiple-value-bind (v present) (gethash key (config-settings c))
        (when present (return-from config-value (values v c))))
      (setf c (config-parent c)))
    (values default nil)))

(defun config-set-value (config key value)
  "Set KEY to VALUE in CONFIG's OWN settings (creating CONFIG if named); marks it
dirty. Overrides — but does not change — any inherited value."
  (let ((c (if (config-p config) config (ensure-config config))))
    (setf (gethash key (config-settings c)) value
          (config-dirty c) t)
    value))

(defun config-unset (config key)
  "Remove KEY from CONFIG's own settings (reverting to the inherited value)."
  (let ((c (if (config-p config) config (find-config config))))
    (when c (remhash key (config-settings c)) (setf (config-dirty c) t)))
  nil)

(defun config-local-keys (config)
  "The keys set directly in CONFIG (not inherited)."
  (let ((c (if (config-p config) config (find-config config))))
    (and c (loop for k being the hash-keys of (config-settings c) collect k))))

(defun config-settings-alist (config)
  "CONFIG's own settings as an alist (KEY . VALUE), for persistence."
  (let ((c (if (config-p config) config (find-config config))))
    (and c (loop for k being the hash-keys of (config-settings c) using (hash-value v)
                 collect (cons k v)))))

(defun reset-configs ()
  "Drop the whole config registry (tests / a fresh session)."
  (clrhash *configs*))

(defun config-own-value (config key &optional default)
  "The value of KEY in CONFIG's OWN settings (not inherited), or DEFAULT."
  (let ((c (if (config-p config) config (find-config config))))
    (if c
        (multiple-value-bind (v present) (gethash key (config-settings c))
          (if present v default))
        default)))

;;; --- per-config faces and key bindings (resolved through the cascade) --
;;; The active interactor's config cascade decides a face's look and a key's
;;; binding: an innermost config's override shadows its parents', and the whole
;;; cascade shadows the built-in / global default. *ACTIVE-CONFIG* names the
;;; config in effect (a UI binds it to the active window's config).

(defvar *active-config* nil
  "The config whose cascade RESOLVE-FACE / EFFECTIVE-KEYMAP use by default:
 - a CONFIG or a config name — its static parent chain (CONFIG-CASCADE);
 - a LIST of CONFIGs and/or names — an explicit cascade, innermost first: the
   live interactor stack's configs (each activation's template config-name),
   which the UI binds so a template's cascade follows where it is stacked
   rather than a fixed parent chain (windows-and-interactor-templates.issue Q6);
 - NIL — the global defaults only.")

(defun config-cascade-for-names (names)
  "The cascade — a list of CONFIGs, innermost first — for NAMES (config names
and/or CONFIGs, innermost first), ensuring each exists. This is the LIVE
interactor stack's cascade (each activation contributes its template's
config-name), as opposed to CONFIG-CASCADE's static parent chain."
  (mapcar #'ensure-config names))

(defun %resolution-cascade (config)
  "Normalise CONFIG (the RESOLVE-FACE / EFFECTIVE-* argument, or *ACTIVE-CONFIG*)
to a cascade — a list of CONFIGs, innermost first: NIL is the empty cascade; a
list is an explicit cascade (CONFIG-CASCADE-FOR-NAMES); a CONFIG or a name is
its static parent chain."
  (cond ((null config) '())
        ((consp config) (config-cascade-for-names config))
        (t (config-cascade config))))

(defun set-config-face (config name params)
  "Override face NAME (a symbol) with PARAMS (a display-parameter plist) in
CONFIG's own settings. Returns NAME."
  (let* ((c (ensure-config config))
         (alist (remove name (config-own-value c :faces) :key #'car)))
    (config-set-value c :faces (acons name params alist))
    name))

(defun resolve-face (name &optional (config *active-config*))
  "The display parameters for face NAME, resolved through CONFIG's cascade
:FACES overrides (innermost first), falling back to the global face registry
(FACE-PARAMETERS). CONFIG may be a CONFIG, a name, a LIST of them (an explicit
live-stack cascade), or NIL (the global registry only)."
  (dolist (cfg (%resolution-cascade config))
    (let ((hit (assoc name (config-own-value cfg :faces))))
      (when hit (return-from resolve-face (cdr hit)))))
  (face-parameters name))

(defun config-bind (config key-string command)
  "Bind KEY-STRING to COMMAND in CONFIG's own :BINDINGS (replacing any binding of
the same key there). Returns KEY-STRING."
  (let* ((c (ensure-config config))
         (alist (remove key-string (config-own-value c :bindings)
                        :key #'car :test #'string=)))
    (config-set-value c :bindings (acons key-string command alist))
    key-string))

(defun config-unbind (config key-string)
  "Remove KEY-STRING from CONFIG's own :BINDINGS. Returns T if one was removed."
  (let* ((c (if (config-p config) config (find-config config)))
         (alist (and c (config-own-value c :bindings))))
    (when (and c (assoc key-string alist :test #'string=))
      (config-set-value c :bindings
                        (remove key-string alist :key #'car :test #'string=))
      t)))

(defun config-bindings (config)
  "CONFIG's OWN key bindings as an alist (KEY-STRING . COMMAND)."
  (config-own-value config :bindings))

(defun effective-keymap (config)
  "A keymap merging the :BINDINGS of CONFIG's whole cascade, applied root-first so
an innermost config's binding overrides its parents'. CONFIG may be a CONFIG, a
name, a LIST of them (an explicit live-stack cascade), or NIL."
  (let ((map (make-keymap)))
    (dolist (cfg (reverse (%resolution-cascade config)) map) ; root .. innermost
      (dolist (pair (config-own-value cfg :bindings))
        (keymap-bind map (parse-key-sequence (car pair)) (cdr pair))))))

(defun effective-binding (config key-string)
  "The command bound to KEY-STRING for CONFIG's cascade, or NIL (innermost wins).
CONFIG may be a CONFIG, a name, a LIST of them (an explicit live-stack cascade),
or NIL."
  (let (found)
    (dolist (cfg (%resolution-cascade config) found)     ; innermost .. root
      (let ((hit (assoc key-string (config-own-value cfg :bindings) :test #'string=)))
        (when hit (return-from effective-binding (cdr hit)))))))

;;; --- persistence: <name>.conf, cascading like the configs -------------

(defun write-config (config stream-or-path)
  "Write CONFIG's own settings (an alist of readable (KEY . VALUE) pairs) to
STREAM-OR-PATH; clears its dirty flag."
  (let ((c (if (config-p config) config (find-config config))))
    (flet ((emit (stream)
             (let ((*print-readably* nil) (*print-escape* t) (*print-circle* t))
               (prin1 (config-settings-alist c) stream)
               (terpri stream))))
      (if (streamp stream-or-path)
          (emit stream-or-path)
          (with-open-file (s stream-or-path :direction :output
                                            :if-exists :supersede
                                            :if-does-not-exist :create)
            (emit s))))
    (setf (config-dirty c) nil)
    c))

(defun read-config (config stream-or-path)
  "Populate CONFIG's own settings from STREAM-OR-PATH (an alist written by
WRITE-CONFIG). Missing files are ignored. Returns CONFIG."
  (let ((c (if (config-p config) config (ensure-config config))))
    (flet ((slurp (stream)
             (let ((*read-eval* nil))
               (let ((alist (read stream nil nil)))
                 (dolist (pair alist)
                   (setf (gethash (car pair) (config-settings c)) (cdr pair)))))))
      (cond ((streamp stream-or-path) (slurp stream-or-path))
            ((probe-file stream-or-path)
             (with-open-file (s stream-or-path) (slurp s)))))
    (setf (config-dirty c) nil)
    c))

;;; --- the standard config tree (matches the interactor stacks) ---------

(defun ensure-standard-configs ()
  "Create the standard debugger/UI config tree so the cascades pjb described
exist. Idempotent."
  (ensure-config "lisp")                 ; the base / Lisp REPL
  (ensure-config "repl"      "lisp")
  (ensure-config "aldo"      "lisp")     ; the debugger session
  (ensure-config "sedit"     "lisp")     ; standalone sedit: sedit -> lisp
  (ensure-config "inspector" "lisp")     ; standalone clal-inspect: inspector -> lisp
  (ensure-config "stack"     "aldo")     ; debugger panes: pane -> aldo -> lisp
  (ensure-config "navi"      "aldo")
  (ensure-config "inspect"   "aldo")
  (values))
