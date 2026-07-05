;;;; clautolisp/autolisp-sedit/source/session.lisp
;;;;
;;;; The sedit session, REPL source recording, storage, and the filesystem level
;;;; (sedit spec §2, §3, §5.7–§5.9). This is the model the AutoLISP clal-sedit
;;;; builtin and the interactive command loop (Phase 5) drive: it resolves what
;;;; to edit, recalls recorded definitions, computes the returned object per the
;;;; §2 table, and reads/writes files and directories. File I/O uses UIOP.

(in-package #:clautolisp.sedit)

;;; --- REPL source recording (§3) -------------------------------------------

(defstruct (recording (:constructor make-recording ()))
  ;; the definition dictionary: upper-case NAME string -> its defining form
  (definitions (make-hash-table :test 'equal))
  ;; the ordered session log — ALL top-level forms, most-recent first
  (log '() :type list))

(defvar *sedit-recording* nil
  "The process-wide REPL source recording (spec §3), created on first use. The
interactive REPL records each top-level form it evaluates here, and
`clal-sedit 'NAME' recalls a name's defining form from it.")

(defun sedit-recording ()
  "The current REPL source recording, creating it on first use."
  (or *sedit-recording* (setf *sedit-recording* (make-recording))))

(defun record-source (source &optional file)
  "Record the top-level forms of the SOURCE text of one REPL turn into the
process recording (spec §3), parsed losslessly. FILE names their origin.
Convenience over PARSE-SOURCE + RECORD-FORM; returns the recording."
  (let ((recording (sedit-recording)))
    (dolist (form (file-node-children (parse-source source :file file)) recording)
      (unless (comment-node-p form)
        (record-form recording form)))))

(defun %atom-name-string (node)
  "The upper-case name a symbol/string atom NODE denotes, or NIL."
  (and (atom-node-p node)
       (let ((v (atom-node-value node)))
         (cond ((null v) nil)
               ((symbolp v) (string-upcase (symbol-name v)))
               ((stringp v) (string-upcase v))
               (t nil)))))

(defun %name-key (name)
  "Canonical dictionary key for NAME (a string / symbol): its upper-case name."
  (string-upcase (typecase name
                   (symbol (symbol-name name))
                   (string name)
                   (t (princ-to-string name)))))

(defun definition-name (tree)
  "The name a definition form binds — the NAME in (defun NAME …), (defun-q NAME …)
or (setq NAME …) — as an upper-case string, or NIL when TREE binds no name."
  (when (list-node-p tree)
    (let ((children (remove-if #'comment-node-p (list-node-children tree))))
      (when (>= (length children) 2)
        (let ((op (%atom-name-string (first children))))
          (when (member op '("DEFUN" "DEFUN-Q" "SETQ") :test #'equal)
            (%atom-name-string (second children))))))))

(defun record-form (recording tree)
  "Record top-level form TREE (spec §3): append it to the session log, and — when
it is a definition (setq/defun/defun-q) — (re)bind its name in the definition
dictionary. Returns TREE."
  (push tree (recording-log recording))
  (let ((name (definition-name tree)))
    (when name (setf (gethash name (recording-definitions recording)) tree)))
  tree)

(defun recorded-definition (recording name)
  "The recorded form defining NAME (string/symbol, case-insensitive), or NIL."
  (gethash (%name-key name) (recording-definitions recording)))

(defun recording-forms (recording)
  "The session log in evaluation order (oldest first)."
  (reverse (recording-log recording)))

(defun session-source (recording)
  "The forms that replay the session (spec §3): the log in order, but each defined
name kept only at its LAST (re-)definition's position; non-definitions kept as-is."
  (let ((forms (recording-forms recording))
        (last-pos (make-hash-table :test 'equal)))
    (loop for f in forms for i from 0
          for name = (definition-name f)
          when name do (setf (gethash name last-pos) i))
    (loop for f in forms for i from 0
          for name = (definition-name f)
          when (or (null name) (= i (gethash name last-pos)))
            collect f)))

;;; --- storage: read/write files, list directories (§2.3–§2.4, §5.7–§5.9) ---

(defun %open-file-node (path)
  "PATH read into an adorned file-node — parsed with verbatim text when it exists,
else a new empty file-node backing PATH."
  (if (probe-file path)
      (parse-source (uiop:read-file-string path) :file (namestring path))
      (make-file-node (namestring path) '())))

(defun sedit-load (path)
  "Read PATH into an adorned file-node (spec §5.7 load). Re-installing its
definitions into a running system is the caller's concern."
  (%open-file-node path))

(defun sedit-save (node path &key (if-exists :supersede))
  "Write NODE's source (UNPARSE) to PATH (spec §5.8 save). IF-EXISTS is the
CL disposition (:supersede overwrites, :error refuses). Returns the namestring."
  (with-open-file (s path :direction :output :if-exists if-exists
                          :if-does-not-exist :create :external-format :utf-8)
    (write-string (unparse node) s))
  (namestring (truename path)))

(defun %dir-display-name (dir-pathname)
  "The last directory component of DIR-PATHNAME as a name, e.g. \"src\"."
  (car (last (pathname-directory dir-pathname))))

(defun read-directory (path)
  "A dir-node listing PATH (spec §2.4/§5.9): the '..' pseudo-entry, then its
sub-directories (as shallow dir-nodes), then its files (as unloaded file-nodes).
Descend into a file with SEDIT-LOAD."
  (let* ((dir (uiop:ensure-directory-pathname path))
         (subdirs (uiop:subdirectories dir))
         (files (uiop:directory-files dir))
         (entries (list* (make-dir-node ".." '())
                         (append
                          (mapcar (lambda (d) (make-dir-node (%dir-display-name d) '())) subdirs)
                          (mapcar (lambda (f) (make-file-node (file-namestring f) '())) files)))))
    (make-dir-node (namestring dir) entries)))

;;; Filesystem mutations (§5.9): act on disk immediately (storage-backed).

(defun sedit-fs-new-file (dir-path name)
  "Create an empty file NAME under DIR-PATH (spec §5.9 new); return its namestring."
  (let ((path (merge-pathnames name (uiop:ensure-directory-pathname dir-path))))
    (with-open-file (s path :direction :output :if-does-not-exist :create :if-exists :error)
      (declare (ignore s)))
    (namestring path)))

(defun sedit-fs-rename (path new-name)
  "Rename the entry at PATH to NEW-NAME in the same directory (spec §5.9 rename);
return the new namestring."
  (let ((new (merge-pathnames new-name (uiop:pathname-directory-pathname path))))
    (rename-file path new)
    (namestring new)))

(defun sedit-fs-delete (path)
  "Delete the file, or empty directory, at PATH (spec §5.9 delete). Returns T."
  (if (uiop:directory-exists-p path)
      (uiop:delete-empty-directory (uiop:ensure-directory-pathname path))
      (delete-file path))
  t)

;;; --- save-on-leave policy (§5.8) ------------------------------------------

(defvar *auto-saving* :disable
  "The `set sedit auto-saving' policy (§5.8): :sexp (save on leaving a modified
sexp or file), :file (save on leaving a modified file), or :disable (never —
the UI asks on leave).")

(defun should-auto-save-p (leaving &optional (setting *auto-saving*))
  "Whether leaving a modified LEAVING (:sexp or :file) auto-saves under SETTING
(§5.8)."
  (ecase setting
    (:sexp t)
    (:file (eq leaving :file))
    (:disable nil)))

;;; --- the session and its §2 result ----------------------------------------

(defvar *clal-sedit-initial-form* nil
  "The form clal-sedit started editing (spec §2).")
(defvar *clal-sedit-last-result* nil
  "The form clal-sedit last returned (spec §2).")

(defstruct (sedit-session (:constructor %make-sedit-session (state origin initial)))
  state        ; the sedit-state (loc + clip + mode + undo)
  origin       ; :standalone | (:symbol NAME) | (:file PATH) | (:dir PATH)
  initial)     ; the initial root node

(defun %directory-path-p (path)
  "True when PATH names a directory — it exists as one, or ends in a separator."
  (or (uiop:directory-exists-p path)
      (let ((s (namestring path)))
        (and (plusp (length s)) (char= #\/ (char s (1- (length s))))))))

(defun %first-child-loc (branch)
  "A location selecting BRANCH's first child, or BRANCH itself when it is empty."
  (or (loc-down (node->loc branch)) (node->loc branch)))

(defun %resolve-open (object recording)
  "Resolve OBJECT to (values ROOT ORIGIN INITIAL-LOC) for SEDIT-OPEN (spec §2)."
  (cond
    ((null object)
     (let ((root (make-atom-node nil))) (values root :standalone (node->loc root))))
    ((node-p object)
     (values object :standalone (node->loc object)))
    ((symbolp object)                           ; a name: recall its recorded form
     (let ((tree (and recording (recorded-definition recording object))))
       (if tree
           (values tree (list :symbol (%name-key object)) (node->loc tree))
           (let ((root (make-atom-node nil)))    ; not recorded: start stand-alone
             (values root (list :symbol (%name-key object)) (node->loc root))))))
    ((stringp object)                           ; a path: directory or file
     (if (%directory-path-p object)
         (let ((dir (read-directory object)))
           (values dir (list :dir object) (%first-child-loc dir)))
         (let ((file (%open-file-node object)))
           (values file (list :file object) (%first-child-loc file)))))
    (t (error "sedit-open: cannot edit ~S" object))))

(defun sedit-open (object &key recording)
  "Start a sedit session on OBJECT (spec §2): NIL (a stand-alone nil), a node
(edit it), a symbol/name (recall its recorded definition from RECORDING), a
file-path string (edit the file, its first top-level form selected), or a
directory-path string (browse it, first entry selected). Returns a sedit-session
and sets *clal-sedit-initial-form*."
  (multiple-value-bind (root origin loc) (%resolve-open object recording)
    (setf *clal-sedit-initial-form* root)
    (%make-sedit-session (make-sedit-state loc) origin root)))

(defun sedit-result-node (loc)
  "The whole top-level form the selection at LOC is in (spec §2 result table):
ascend out of nested lists, stopping at the file/dir boundary or the root."
  (let ((l loc))
    (loop for ctx = (loc-ctx l)
          while (and ctx (list-node-p (ctx-parent ctx)))
          do (setf l (loc-up l)))
    (loc-focus l)))

(defun session-result (session)
  "The object clal-sedit returns from SESSION (spec §2): the whole top-level form
the final selection is in. Records it in *clal-sedit-last-result* and returns it."
  (setf *clal-sedit-last-result*
        (sedit-result-node (sedit-state-loc (sedit-session-state session)))))
