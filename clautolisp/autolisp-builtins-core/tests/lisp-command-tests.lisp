(in-package #:clautolisp.autolisp-builtins-core.tests)

(in-suite autolisp-builtins-core-suite)

;;;; LISP commands run by COMMAND (alref Phase 4; pjb 2026-10-03: for an
;;;; add-on command, loading the vendor's own code is good enough). A C:
;;;; function registered with VLAX-ADD-CMD is a command COMMAND can run, and
;;;; the rest of COMMAND's input feeds its get* / entsel / ssget calls --
;;;; how AutoCAD ran 3darray.lsp (job 16915676646).

(defun %lisp-command-setup ()
  (setup-mock-evaluation-context)
  (clautolisp.autolisp-builtins-core:install-core-builtins))

(defun %circle-centres ()
  (%eval-here "(progn (setq out nil e (entnext))
                 (while e
                   (if (= (cdr (assoc 0 (entget e))) \"CIRCLE\")
                     (setq out (cons (cdr (assoc 10 (entget e))) out)))
                   (setq e (entnext e)))
                 (reverse out))"))

(defun %as-doubles (point)
  (mapcar (lambda (x) (coerce x 'double-float)) point))

(test lisp-command-reads-command-input-through-get-functions
  (%lisp-command-setup)
  (%eval-here "(defun c:twocircles (/ n r p)
                 (initget \"Small Large\")
                 (setq n (getkword \"Size [Small/Large]: \"))
                 (setq r (if (= n \"Large\") 2.0 1.0))
                 (setq p (getpoint \"Centre: \"))
                 (command \"_.CIRCLE\" p r)
                 (setq p (getpoint \"Second centre: \"))
                 (command \"_.CIRCLE\" p (* 2 r))
                 (princ))")
  ;; Not a command until registered.
  (%eval-here "(command \"twocircles\" \"_L\" \"1,1\" \"5,5\")")
  (is (null (%circle-centres)))
  (%eval-here "(vlax-add-cmd \"twocircles\" 'c:twocircles)")
  ;; "_L" is the language-independent abbreviation of Large; points typed
  ;; with commas or given as lists.
  (%eval-here "(command \"twocircles\" \"_L\" \"1,1\" '(5.0 5.0 0.0))")
  (let ((centres (%circle-centres)))
    (is (= 2 (length centres)))
    (is (equal '(1.0d0 1.0d0 0.0d0) (%as-doubles (first centres))))
    (is (equal '(5.0d0 5.0d0 0.0d0) (%as-doubles (second centres)))))
  ;; Input the command does not consume goes on as further commands.
  (%eval-here "(command \"twocircles\" \"_S\" \"10,0\" \"20,0\" \"_.CIRCLE\" \"30,0\" \"1\")")
  (is (= 5 (length (%circle-centres)))))

(test lisp-command-selects-with-ssget-and-entsel
  (%lisp-command-setup)
  (%eval-here "(command \"_.CIRCLE\" \"0,0\" \"1\")")
  (%eval-here "(setq a (entlast))")
  (%eval-here "(command \"_.CIRCLE\" \"5,0\" \"1\")")
  (%eval-here "(setq b (entlast))")
  (%eval-here "(defun c:countsel (/ ss pick)
                 (setq ss (ssget))
                 (setq pick (entsel \"Pick: \"))
                 (setq *counted* (list (if ss (sslength ss) 0)
                                       (if pick (car pick)))))")
  (%eval-here "(vlax-add-cmd \"countsel\" 'c:countsel)")
  ;; ssget takes objects up to RETURN; entsel an (ename point) pick.
  (%eval-here "(command \"countsel\" a b \"\" (list b '(6.0 0.0 0.0)))")
  (let ((counted (%eval-here "*counted*"))
        (b (%eval-here "b")))
    (is (eql 2 (first counted)))
    (is (eq b (second counted))))
  ;; entsel by a point on an object.
  (%eval-here "(command \"countsel\" a \"\" \"6,0\")")
  (is (eq (%eval-here "b") (second (%eval-here "*counted*")))))
