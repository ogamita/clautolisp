;;;; -*- mode:lisp;coding:utf-8 -*-
;;;;**************************************************************************
;;;;FILE:               sedit2.lisp
;;;;LANGUAGE:           Common-Lisp
;;;;SYSTEM:             Common-Lisp
;;;;USER-INTERFACE:     NONE
;;;;DESCRIPTION
;;;;
;;;;    A simple sexp editor.  (Version 2.)
;;;;
;;;;    It is invoked as (sedit sexp), and returns the modified sexp.
;;;;    (The sexp is modified destructively).
;;;;
;;;;     (sedit (copy-tree '(an example)))
;;;;
;;;;    At each interaction loop, it prints the whole sexp, showing the selected
;;;;    sub-sexp, and query a command. Use the help command to get the list of
;;;;    commands.  The commands are:
;;;;
;;;;     q quit                to return the modified sexp from sedit.
;;;;     i in                  to enter inside the selected list.
;;;;     o out                 to select the list containing the selection.
;;;;     f forward n next      to select the sexp following the selection (or out).
;;;;     b backward p previous to select the sexp preceding the selection (or out).
;;;;     s insert              to insert a new sexp before the selection.
;;;;     r replace             to replace the selection with a new sexp.
;;;;     a add                 to add a new sexp after the selection.
;;;;     x cut                 to cut the selection into the *clipboard*.
;;;;     c copy                to copy the selection into the *clipboard*.
;;;;     y paste               to paste the *clipboard* replacing the selection.
;;;;     l enlist              to wrap the selection in a new list.
;;;;     e splice              to splice the selected list into its parent.
;;;;     u slurp               to extend the selection with the following sexp.
;;;;     v barf                to expel the last element out of the selection.
;;;;     g eval                to evaluate the selection (printing its values).
;;;;     w save               to save the edited sexp to a file.
;;;;     d load               to load a sexp from a file.
;;;;     h help                to print the list of commands.
;;;;
;;;;    Version 2 adds the structural-editing commands (enlist, splice, slurp,
;;;;    barf) on top of version 1; this file merges back version 1's command
;;;;    table, bindings, help, eval, save and load (see sedit.lisp).
;;;;
;;;;    Notice: it uses the unicode characters LEFT_BLACK_LENTICULAR_BRACKET
;;;;    and RIGHT_BLACK_LENTICULAR_BRACKET to show the selected sub-sexp.
;;;;    This could be changed easily modifying the SELECTION PRINT-OBJECT method.
;;;;
;;;;AUTHORS
;;;;    <PJB> Pascal J. Bourguignon <pjb@informatimago.com>
;;;;MODIFICATIONS
;;;;    2026-06-26 <PJB> Completed: fixed the command-reading package bug and the
;;;;                     display (print (first root), not the wrapper); added EOF
;;;;                     handling; merged in the command table, bindings, help,
;;;;                     eval, save and load from sedit.lisp.
;;;;    2010-09-08 <PJB> Created.
;;;;BUGS
;;;;LEGAL
;;;;    AGPL3
;;;;
;;;;    Copyright Pascal J. Bourguignon 2010 - 2016
;;;;
;;;;    This program is free software: you can redistribute it and/or modify
;;;;    it under the terms of the GNU Affero General Public License as published by
;;;;    the Free Software Foundation, either version 3 of the License, or
;;;;    (at your option) any later version.
;;;;
;;;;    This program is distributed in the hope that it will be useful,
;;;;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;;;    GNU Affero General Public License for more details.
;;;;
;;;;    You should have received a copy of the GNU Affero General Public License
;;;;    along with this program.  If not, see <http://www.gnu.org/licenses/>
;;;;**************************************************************************
(eval-when (:compile-toplevel :load-toplevel :execute)
  (setf *readtable* (copy-readtable nil)))
(defpackage "COM.INFORMATIMAGO.SMALL-CL-PGMS.SEDIT.2"
  (:use "COMMON-LISP")
  (:export "SEDIT"))
(in-package "COM.INFORMATIMAGO.SMALL-CL-PGMS.SEDIT.2")

(eval-when (:compile-toplevel :load-toplevel :execute)
  (when (= char-code-limit 1114112)
    (pushnew :unicode *features*)))


(defstruct selection
  parent-list
  sexp)

(defmethod print-object ((selection selection) stream)
  (format stream #+unicode " 【~S】 "
                 #-unicode " [~S] "
                 (selection-sexp selection))
  selection)



(defvar *clipboard* nil)


(defun find-cell (object list)
  (cond
    ((eq (car list) object)       list)
    ((null (cdr list))            nil)
    ((and (atom (cdr list))
          (eq (cdr list) object)) list)
    (t                            (find-cell object (cdr list)))))


(defun unselect (selection)
  (let ((cell (find-cell selection (selection-parent-list selection))))
    (when cell
      (if (eq (car cell) selection)
          (setf (car cell) (selection-sexp selection))
          (setf (cdr cell) (selection-sexp selection))))))

(defun nth-cdr (n list)
  (cond
    ((not (plusp n))   list)
    ((atom list)       list)
    (t (nth-cdr (1- n) (cdr list)))))

(defun select (selection parent index)
  (cond
    ((atom parent)
     (error "Cannot select from an atom."))
    (t
     (let ((cell (nth-cdr index parent)))
       (cond
         ((null cell) (error "cannot select so far"))
         ((atom cell) (setf (selection-parent-list selection) parent
                            (selection-sexp selection) cell
                            (cdr (nth-cdr (1- index) parent)) selection))
         (t           (setf (selection-parent-list selection) parent
                            (selection-sexp selection) (car cell)
                            (car cell) selection)))))))


(defun sedit-find-object (sexp object)
  "Return the cons cell of SEXP where the OBJECT is."
  (cond
    ((atom sexp)      nil)
    ((eq sexp object) nil)
    ((or (eq (car sexp) object)
         (eq (cdr sexp) object)) sexp)
    (t (or (sedit-find-object (car sexp) object)
           (sedit-find-object (cdr sexp) object)))))

(defun unselected-sexp (list selection)
  "Return a copy of the LIST sexp with the SELECTION placeholder removed."
  (cond
    ((consp list)
     (cons (unselected-sexp (car list) selection)
           (unselected-sexp (cdr list) selection)))
    ((eq list selection)
     (unselected-sexp (selection-sexp selection) selection))
    (t
     list)))

(defmacro reporting-errors (&body body)
  `(handler-case
       (progn ,@body)
     (simple-condition  (err)
       (format *error-output* "~&~A:~%~?~&"
               (class-name (class-of err))
               (simple-condition-format-control   err)
               (simple-condition-format-arguments err))
       (finish-output *error-output*))
     (condition (err)
       (format *error-output* "~&~A:~%~A~%"
               (class-name (class-of err))
               err)
       (finish-output *error-output*))))


(defun sedit-in (root selection)
  "When a non-empty list is selected, change the selection to the first element of the list."
  (declare (ignore root))
  (if (atom (selection-sexp selection))
      (progn (princ "Cannot enter an atom.") (terpri))
      (progn
        (unselect selection)
        (select selection (selection-sexp selection) 0))))

(defun sedit-out (root selection)
  "Change the selection to the parent list of the current selection."
  (let ((gparent (sedit-find-object root (selection-parent-list selection))))
    (when gparent
     (unselect selection)
     (select selection gparent 0))))

(defun sedit-forward (root selection)
  "Change the selection to the element following the current selection, or the parent if it's the last."
  (let ((index (position selection (selection-parent-list selection))))
    (if (or (null index)
            (<= (length (selection-parent-list selection))  (1+ index)))
        (sedit-out root selection)
        (progn (unselect selection)
               (select selection (selection-parent-list selection) (1+ index))))))

(defun sedit-backward (root selection)
  "Change the selection to the element preceeding the current selection, or the parent if it's the first."
  (let ((index (position selection (selection-parent-list selection))))
    (if (or (null index) (<= index 0))
        (sedit-out root selection)
        (progn (unselect selection)
               (select selection (selection-parent-list selection) (1- index))))))


(defun sedit-enlist (root selection)
  "Put the selection in a new list."
  (declare (ignore root))
  (setf (selection-sexp selection) (list (selection-sexp selection))))

(defun ensure-list (x)
  (if (listp x) x (list x)))

(defun sedit-splice (root selection)
  "Splice the elements of the selection in the parent."
  (let* ((parent   (selection-parent-list selection))
         (selected (selection-sexp selection))
         (index    (position selection parent)))
    (sedit-out root selection)
    (setf (selection-sexp selection)
          (append (subseq parent 0 index)
                  (ensure-list selected)
                  (subseq parent (1+ index))))))

(defun sedit-slurp (root selection)
  "Append to the selection the element following it."
  (declare (ignore root))
  (let ((index (position selection (selection-parent-list selection))))
    (when (and index
               (< (1+ index) (length (selection-parent-list selection))))
      (setf (selection-sexp selection)
            (append (ensure-list (selection-sexp selection))
                    (list (pop (cdr (nth-cdr index (selection-parent-list selection))))))))))

(defun sedit-barf (root selection)
  "Split out the last element of the selection."
  (declare (ignore root))
  (let ((index (position selection (selection-parent-list selection))))
    (when (and index (consp (selection-sexp selection)))
      (let ((barfed (first (last (selection-sexp selection)))))
        (setf (selection-sexp selection) (butlast (selection-sexp selection)))
        (insert barfed (selection-parent-list selection) :after selection)))))

(defun sedit-cut (root selection)
  "Save the selection to the *CLIPBOARD*, and remove it."
  (setf *clipboard* (selection-sexp selection))
  (let ((gparent (sedit-find-object root (selection-parent-list selection))))
    (if (eq (car gparent) (selection-parent-list selection))
        (setf (car gparent) (delete selection (selection-parent-list selection)))
        (setf (cdr gparent) (delete selection (selection-parent-list selection))))
    (select selection gparent 0)))

(defun sedit-copy (root selection)
  "Save the selection to the *CLIPBOARD*."
  (declare (ignore root))
  (setf *clipboard* (copy-tree (selection-sexp selection))))

(defun sedit-paste (root selection)
  "Replace the selection by the contents of teh *CLIPBOARD*."
  (declare (ignore root))
  (setf (selection-sexp selection) (copy-tree *clipboard*)))

(defun sedit-replace (root selection)
  "Replace the selection by the expression input by the user."
  (declare (ignore root))
  (princ "replacement sexp: " *query-io*)
  (setf (selection-sexp selection) (read *query-io*)))

(defun insert (object list where reference)
  (ecase where
    ((:before)
     (cond
       ((null list) (error "Cannot insert in an empty list."))
       ((eq (car list) reference)
        (setf (cdr list) (cons (car list) (cdr list))
              (car list) object))
       (t (insert object (cdr list) where reference))))
    ((:after)
     (cond
       ((null list) (error "Cannot insert in an empty list."))
       ((eq (car list) reference)
        (push object (cdr list)))
       (t (insert object (cdr list) where reference))))))

(defun sedit-insert (root selection)
  "Insert the expression input by the user before the selection."
  (princ "sexp to be inserted before: " *query-io*)
  (let ((new-sexp (read *query-io*)))
    (if (eq (first (selection-parent-list selection)) selection)
        (let ((gparent (sedit-find-object root (selection-parent-list selection))))
          (setf (selection-parent-list selection)
                (if (eq (car gparent) (selection-parent-list selection))
                    (setf (car gparent) (cons new-sexp (selection-parent-list selection)))
                    (setf (cdr gparent) (cons new-sexp (selection-parent-list selection))))))
        (insert new-sexp (selection-parent-list selection) :before selection))))

(defun sedit-add (root selection)
  "Insert the expression input by the user after the selection."
  (declare (ignore root))
  (princ "sexp to be inserted after: " *query-io*)
  (finish-output *query-io*)
  (let ((new-sexp (read *query-io*)))
    (insert new-sexp (selection-parent-list selection) :after selection)))


(defun sedit-eval (root selection)
  "Evaluate the selection, and print the resulting values."
  (declare (ignore root))
  (let ((sexp (selection-sexp selection)))
    (reporting-errors
      (format *query-io* "~& --> ~{~S~^ ;~%     ~}~%"
              (let ((*package*   *package*)
                    (*readtable* *readtable*))
                (multiple-value-list (eval sexp)))))
    (finish-output *query-io*)))

(defun sedit-save (root selection)
  "Save the edited sexp (without the selection) to a file."
  (princ "Save buffer to file: " *query-io*)
  (finish-output *query-io*)
  (let ((path (read-line *query-io*)))
    (with-open-file (out path :direction :output
                              :if-does-not-exist :create
                              :if-exists :supersede)
      (pprint (unselected-sexp (first root) selection) out)
      (terpri out))))

(defun sedit-load (root selection)
  "Load a sexp from a file, replacing the buffer contents."
  (princ "Load file: " *query-io*)
  (finish-output *query-io*)
  (let ((new (with-open-file (inp (read-line *query-io*) :direction :input)
               (read inp))))
    (unselect selection)
    (setf (first root) new)
    (select selection root 0)))

(defun sedit-quit (root selection)
  "Return the modified sexp from SEDIT."
  (declare (ignore selection))
  (throw 'gazongue (first root)))


;;; Command table and bindings (ported from sedit.lisp).
;;; Each entry is (SHORT LONG FUNCTION HELP); FUNCTION takes (ROOT SELECTION).

(defparameter *command-map*
  '((q quit     sedit-quit     "return the modified sexp from sedit.")
    (i in       sedit-in       "enter inside the selected list.")
    (o out      sedit-out      "select the list containing the selection.")
    (f forward  sedit-forward  "select the sexp following the selection (or out).")
    (n next     sedit-forward  "select the sexp following the selection (or out).")
    (b backward sedit-backward "select the sexp preceding the selection (or out).")
    (p previous sedit-backward "select the sexp preceding the selection (or out).")
    (s insert   sedit-insert   "insert a new sexp before the selection.")
    (r replace  sedit-replace  "replace the selection with a new sexp.")
    (a add      sedit-add      "add a new sexp after the selection.")
    (x cut      sedit-cut      "cut the selection into the *clipboard*.")
    (c copy     sedit-copy     "copy the selection into the *clipboard*.")
    (y paste    sedit-paste    "paste the *clipboard* replacing the selection.")
    (l enlist   sedit-enlist   "wrap the selection in a new list.")
    (e splice   sedit-splice   "splice the selected list into its parent.")
    (u slurp    sedit-slurp    "extend the selection with the following sexp.")
    (v barf     sedit-barf     "expel the last element out of the selection.")
    (g eval     sedit-eval     "evaluate the selection.")
    (w save     sedit-save     "save the edited sexp to a file.")
    (d load     sedit-load     "load a sexp from a file.")
    (h help     sedit-help     "print this help.")))

(defvar *bindings* (make-hash-table))

(defun bind (command function)
  (setf (gethash command *bindings*) function))

(defun unbind (command)
  (remhash command *bindings*))

(defun binding (command)
  (gethash command *bindings*))

(defun add-command (short long function help)
  (setf *command-map* (append *command-map*
                              (list (list short long function help))))
  (bind short function)
  (bind long function))

(defun sedit-help (root selection)
  (declare (ignore root selection))
  (format *query-io* "~:{~A) ~10A ~*~A~%~}" *command-map*)
  (finish-output *query-io*))

(defun initialize-bindings ()
  (clrhash *bindings*)
  (loop :for (short long function) :in *command-map*
        :do (bind short function)
            (bind long  function)))


(defun sedit (&optional sexp)
  "Edit the SEXP; return the new sexp."
  (terpri)
  (princ "Sexp Editor:")
  (terpri)
  (initialize-bindings)
  (let* ((root      (list sexp))
         (selection (make-selection))
         (eof       (list :eof)))
    (select selection root 0)
    (unwind-protect
         (catch 'gazongue
           (loop
             (reporting-errors
               (pprint (first root) *query-io*)
               (terpri *query-io*)
               (princ "> " *query-io*)
               (finish-output *query-io*)
               (let* ((command (let ((*package* (load-time-value
                                                 (find-package
                                                  "COM.INFORMATIMAGO.SMALL-CL-PGMS.SEDIT.2"))))
                                 (read *query-io* nil eof)))
                      (function (and (not (eq command eof))
                                     (binding command))))
                 (cond
                   ((eq command eof) (sedit-quit root selection))
                   (function         (funcall function root selection))
                   (t
                    (format *query-io*
                            "~%Please use one of these commands:~%~
                             ~:{~<~%~1,40:;~A (~A)~>~^, ~}.~2%"
                            *command-map*)
                    (finish-output *query-io*)))))))
      (unselect selection))
    (first root)))

;;;; THE END ;;;;
