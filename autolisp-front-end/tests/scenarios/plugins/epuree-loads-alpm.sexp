(:name "epuree-loads-alpm"
 :description "On a real engine (clautolisp) the plug-in's actions run in front
of the user's: a stand-in alpm.lsp records that it was loaded, asked to
register the directory, then to load the system."
 :classification :clautolisp-only
 :argv ("--clautolisp" "--epuree" "--epuree-alpm" "alpm.lsp"
        "--epuree-path" "lisp" "-x" "(princ (mapcar 'car *alpm-calls*))")
 :setup-files
   (("alpm.lsp" "(setq *alpm-calls* nil)
(defun alpm-register-directory (dir recursive)
  (setq *alpm-calls* (append *alpm-calls* (list (list 'register dir recursive))))
  dir)
(defun alpm-load-system (name force)
  (setq *alpm-calls* (append *alpm-calls* (list (list 'load name force))))
  name)
"))
 :expected-exit 0
 :expected-stdout-includes ("(REGISTER LOAD)")
 :covers-options ("--clautolisp" "--epuree"))
