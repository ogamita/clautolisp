;;;; -*- mode:lisp;coding:utf-8 -*-
;;;;**************************************************************************
;;;;FILE:               dbgsim.lisp
;;;;LANGUAGE:           Common-Lisp
;;;;SYSTEM:             Common-Lisp
;;;;USER-INTERFACE:     terminal (TUI experiment)
;;;;DESCRIPTION
;;;;
;;;;    A simulator for the clautolisp debugger TUI, exploring how a
;;;;    sedit-like structural editor can be used to display a (read-only)
;;;;    source form, navigate it as a *lisp form* (not a raw sexp), and set
;;;;    breakpoints on its poll-points.
;;;;
;;;;    See clautolisp/documentation/clautolisp-debugger-tui-spec.org.
;;;;
;;;;    Model
;;;;    -----
;;;;    A poll-point is an *evaluable* position in the source form: the whole
;;;;    form, and recursively every sub-expression that is evaluated.  The
;;;;    operator name of a call, the symbol naming a special operator, a
;;;;    lambda list, a variable name, a quoted datum and the grouping list of
;;;;    a COND clause are NOT poll-points; navigation skips them.  Which
;;;;    positions are evaluated is decided per special operator by a rule in
;;;;    *SPECIAL-FORMS* (DEFUN, DEFUN-Q, LAMBDA, SETQ, FOREACH, COND, QUOTE,
;;;;    FUNCTION, IF, PROGN, WHILE, REPEAT, AND, OR); everything else is
;;;;    treated as a function call: skip the operator, evaluate the arguments.
;;;;    SETQ skips its target symbols, DEFUN/LAMBDA skip the lambda list, and
;;;;    QUOTE descends into AutoLISP's '(lambda ...) anonymous-function idiom.
;;;;
;;;;    Every poll-point gets a stable number (ppN, pre-order).  A breakpoint
;;;;    is just a flag on a poll-point (at most one per poll-point), so the
;;;;    breakpoint's identity *is* its poll-point number.  Each poll-point may
;;;;    carry a condition, a pre-expression and a post-expression.
;;;;
;;;;    The instrumented code (each poll-point wrapped in a poll-point
;;;;    dispatch, conceptually (CLAL-BREAK ppN <subexpr>)) is never displayed;
;;;;    here we don't actually instrument, we just keep the poll-point table.
;;;;
;;;;    Display
;;;;    -------
;;;;    The form is pretty-printed; every poll-point is decorated with its
;;;;    number and, when relevant, a status glyph (current poll-point, enabled
;;;;    / disabled breakpoint) and the selection brackets.  Four presentation
;;;;    modes are available (configurable in *DECORATIONS*): :UNICODE, :ASCII,
;;;;    :COLOR (white-on-black ANSI colours) and :ATTR (bold / underline /
;;;;    invert).  Switch with the `mode' command.
;;;;
;;;;AUTHORS
;;;;    <PJB> Pascal J. Bourguignon <pjb@informatimago.com>
;;;;MODIFICATIONS
;;;;    2026-06-27 <PJB> Created.
;;;;LEGAL
;;;;    AGPL3
;;;;    Copyright Pascal J. Bourguignon 2026 - 2026
;;;;**************************************************************************
(eval-when (:compile-toplevel :load-toplevel :execute)
  (setf *readtable* (copy-readtable nil)))
(defpackage "COM.INFORMATIMAGO.SMALL-CL-PGMS.SEDIT.DBGSIM"
  (:use "COMMON-LISP")
  (:export "DBGSIM" "*DEFAULT-FORM*" "*DECORATIONS*"))
(in-package "COM.INFORMATIMAGO.SMALL-CL-PGMS.SEDIT.DBGSIM")

(eval-when (:compile-toplevel :load-toplevel :execute)
  (when (= char-code-limit 1114112)
    (pushnew :unicode *features*)))

;;;---------------------------------------------------------------------------
;;; Poll-points
;;;---------------------------------------------------------------------------

(defstruct (pp (:constructor make-pp))
  number          ; stable id (ppN), pre-order
  path            ; list of indices from the root form
  form            ; the source sub-expression (read-only)
  parent          ; parent pp, or NIL for the root
  children        ; list of child pp (the evaluated subforms)
  ;; debugging state:
  breakpoint      ; NIL | :ENABLED | :DISABLED
  condition       ; NIL or a form
  pre             ; NIL or a form (pre-expression)
  post)           ; NIL or a form (post-expression)


;;;---------------------------------------------------------------------------
;;; Special-operator navigation rules
;;;
;;; A rule receives the (proper-list) form and returns the list of *relative
;;; paths* (each a list of indices from the form) to its directly-evaluated
;;; sub-forms.  Most rules return single-index paths; COND returns two-index
;;; paths, skipping the clause grouping list.
;;;---------------------------------------------------------------------------

(defvar *special-forms* (make-hash-table :test 'eq))

(defun proper-list-p (x)
  (and (listp x)
       (loop :for c := x :then (cdr c)
             :do (cond ((null c) (return t))
                       ((atom c) (return nil))))))

(defun deref (form rel)
  "Follow the relative index path REL inside FORM."
  (if (null rel) form (deref (nth (first rel) form) (rest rel))))

(defmacro define-form-rule (name (form) &body body)
  `(setf (gethash ',name *special-forms*)
         (lambda (,form) (declare (ignorable ,form)) ,@body)))

(defun indices-from (form start &optional (step 1))
  (loop :for i :from start :below (length form) :by step :collect (list i)))

;;; --- Operators that skip a name and/or a parameter list --------------------

;; (defun name lambda-list . body)      -- skip DEFUN, name and lambda list.
(define-form-rule defun    (form) (indices-from form 3))
;; (defun-q name lambda-list . body)    -- like DEFUN (body is quoted, same shape).
(define-form-rule defun-q  (form) (indices-from form 3))
;; (lambda lambda-list . body)          -- skip LAMBDA and the lambda list.
(define-form-rule lambda   (form) (indices-from form 2))

;;; --- Operators with non-evaluated operand positions -----------------------

;; (setq sym1 val1 sym2 val2 ...)       -- the symbols are not evaluated; the
;;                                         value positions (even indices) are.
(define-form-rule setq     (form) (indices-from form 2 2))
;; (foreach var listexpr . body)        -- skip FOREACH and the loop variable.
(define-form-rule foreach  (form) (indices-from form 2))
;; (cond (test . body) ...)             -- skip COND and each clause grouping list.
(define-form-rule cond     (form)
  (loop :for ci :from 1 :below (length form)
        :for clause := (nth ci form)
        :when (proper-list-p clause)
          :append (loop :for ei :from 0 :below (length clause)
                        :collect (list ci ei))))
;; (quote datum)                        -- nothing evaluated, EXCEPT AutoLISP's
;;   '(lambda ...) idiom: a quoted lambda is an anonymous function whose body
;;   IS evaluated when applied, so we descend into it.
(define-form-rule quote    (form)
  (if (and (= (length form) 2)
           (consp (second form))
           (eq (first (second form)) 'lambda))
      (list (list 1))
      '()))
;; (function arg)                       -- a function designator; descend only
;;   when it is a (lambda ...) form, otherwise nothing is evaluated.
(define-form-rule function (form)
  (if (and (>= (length form) 2) (consp (second form)))
      (list (list 1))
      '()))

;;; --- Operators that evaluate every operand (listed for completeness; their
;;;     poll-points are exactly the default CALL-RULE's, but naming them keeps
;;;     the table an explicit catalogue of the language's special operators) --

;; (if test then [else]) (progn . body) (while test . body) (repeat n . body)
;; (and . exprs) (or . exprs)           -- skip the operator, evaluate the rest.
(define-form-rule if       (form) (indices-from form 1))
(define-form-rule progn    (form) (indices-from form 1))
(define-form-rule while    (form) (indices-from form 1))
(define-form-rule repeat   (form) (indices-from form 1))
(define-form-rule and      (form) (indices-from form 1))
(define-form-rule or       (form) (indices-from form 1))

(defun call-rule (form)
  "Default: a function call.  Skip the operator, evaluate the arguments."
  (indices-from form 1))

(defun eval-child-rel-paths (form)
  "The relative paths of the directly-evaluated sub-forms of FORM."
  (if (and (proper-list-p form) form)
      (let* ((head (car form))
             (rule (and (symbolp head) (gethash head *special-forms*))))
        (if rule (funcall rule form) (call-rule form)))
      '()))


;;;---------------------------------------------------------------------------
;;; Building the poll-point tree
;;;---------------------------------------------------------------------------

(defvar *root-pp*     nil "The poll-point of the whole form.")
(defvar *pp-vector*   nil "Poll-points indexed by (1- number).")
(defvar *pp-by-path*  nil "Hash path -> pp.")

(defun build-pp-tree (form path parent)
  (let ((pp (make-pp :number (1+ (fill-pointer *pp-vector*))
                     :path path :form form :parent parent)))
    (vector-push-extend pp *pp-vector*)
    (setf (gethash path *pp-by-path*) pp)
    (setf (pp-children pp)
          (loop :for rel :in (eval-child-rel-paths form)
                :for cpath := (append path rel)
                :collect (build-pp-tree (deref form rel) cpath pp)))
    pp))

(defun pp-by-number (n)
  (when (and (integerp n) (<= 1 n (fill-pointer *pp-vector*)))
    (aref *pp-vector* (1- n))))


;;;---------------------------------------------------------------------------
;;; Decorated tree (what gets pretty-printed)
;;;
;;; A DECO-NODE wraps a poll-point's sub-expression.  Its INNER slot holds the
;;; sub-expression with its own poll-point sub-forms recursively wrapped, and
;;; every non-poll-point position left as raw data.  Building it once and
;;; reading the dynamic selection / current-pp / mode at print time means a
;;; navigation step only moves a pointer; no rewrapping.
;;;---------------------------------------------------------------------------

(defstruct (deco-node (:constructor make-deco-node (pp inner)))
  pp inner)

(defvar *deco-root* nil)

(defun wrap (form path)
  (let ((inner (if (proper-list-p form)
                   (loop :for i :from 0 :for child :in form
                         :collect (wrap child (append path (list i))))
                   form))
        (pp (gethash path *pp-by-path*)))
    (if pp (make-deco-node pp inner) inner)))


;;;---------------------------------------------------------------------------
;;; Presentation modes / decorations
;;;---------------------------------------------------------------------------

(defstruct deco
  number-style          ; :CIRCLED | :BRACKETED
  kind                  ; :GLYPH | :SGR
  ;; :GLYPH mode -----------------------------------------------------------
  current-glyph disabled-glyph enabled-glyph
  sel-open sel-close
  ;; :SGR mode -------------------------------------------------------------
  current-sgr disabled-sgr enabled-sgr sel-sgr)

(defparameter *decorations*
  (let ((h (make-hash-table :test 'eq)))
    (setf (gethash :unicode h)
          (make-deco :number-style :circled :kind :glyph
                     :current-glyph "⏵" :disabled-glyph "⏯" :enabled-glyph "⏸"
                     :sel-open "【" :sel-close "】"))
    (setf (gethash :ascii h)
          (make-deco :number-style :bracketed :kind :glyph
                     :current-glyph ">" :disabled-glyph "_" :enabled-glyph "^"
                     :sel-open "[" :sel-close "]"))
    ;; white-on-black theme: red / blue / cyan, selection = invert
    (setf (gethash :color h)
          (make-deco :number-style :circled :kind :sgr
                     :current-sgr '("31") :disabled-sgr '("34")
                     :enabled-sgr '("36") :sel-sgr '("7")))
    ;; attributes only: bold / underline / invert, selection = bold+invert
    (setf (gethash :attr h)
          (make-deco :number-style :circled :kind :sgr
                     :current-sgr '("1") :disabled-sgr '("4")
                     :enabled-sgr '("7") :sel-sgr '("1" "7")))
    h)
  "Mode keyword -> DECO.  Tweak to taste; `mode' switches *MODE* among these.")

(defvar *mode* :unicode)

(defun current-deco () (gethash *mode* *decorations*))

(defun render-number (n style)
  (if (and (eq style :circled) (<= 1 n 20))
      (string (code-char (+ #x2460 (1- n))))   ; ①..⑳
      (format nil "<~D>" n)))

(defun sgr (params) (format nil "~C[~{~A~^;~}m" #\Escape params))
(defun sgr-reset ()  (format nil "~C[0m" #\Escape))

(defun status-glyph (deco current? bp)
  (concatenate 'string
               (if current? (deco-current-glyph deco) "")
               (case bp
                 (:enabled  (deco-enabled-glyph deco))
                 (:disabled (deco-disabled-glyph deco))
                 (t ""))))

(defun status-sgr (deco current? bp)
  (append (if current? (deco-current-sgr deco) '())
          (case bp
            (:enabled  (deco-enabled-sgr deco))
            (:disabled (deco-disabled-sgr deco))
            (t '()))))

(defun decoration (deco number current? bp selected?)
  "Return two strings (OPEN CLOSE) wrapping a poll-point's printed form."
  (let ((num (render-number number (deco-number-style deco))))
    (ecase (deco-kind deco)
      (:glyph
       (values (concatenate 'string
                            (if selected? (deco-sel-open deco) "")
                            num
                            (status-glyph deco current? bp))
               (if selected? (deco-sel-close deco) "")))
      (:sgr
       (let ((params (append (status-sgr deco current? bp)
                             (if selected? (deco-sel-sgr deco) '()))))
         (values (concatenate 'string num (if params (sgr params) ""))
                 (if params (sgr-reset) "")))))))


;;;---------------------------------------------------------------------------
;;; Printing
;;;---------------------------------------------------------------------------

(defvar *selection* nil "The selected pp.")
(defvar *current*   nil "The current poll-point (the one calling the debugger).")

(defmethod print-object ((node deco-node) stream)
  (let ((pp    (deco-node-pp node))
        (inner (deco-node-inner node))
        (deco  (current-deco)))
    (multiple-value-bind (open close)
        (decoration deco (pp-number pp)
                    (eq pp *current*) (pp-breakpoint pp) (eq pp *selection*))
      (cond
        ;; (quote X) -> 'X  (keep the AutoLISP/Lisp reader abbreviation).
        ((and (consp inner) (eq (first inner) 'quote)
              (consp (cdr inner)) (null (cddr inner)))
         (princ open stream)
         (write-char #\' stream)
         (write (second inner) :stream stream)
         (princ close stream))
        ((consp inner)
          (pprint-logical-block (stream inner
                                 :prefix (concatenate 'string open "(")
                                 :suffix (concatenate 'string ")" close))
            (pprint-exit-if-list-exhausted)
            (loop
              (write (pprint-pop) :stream stream)
              (pprint-exit-if-list-exhausted)
              (write-char #\Space stream)
              (pprint-newline :fill stream))))
        (t
         (princ open stream)
         (write inner :stream stream)
         (princ close stream)))))
  node)


;;;---------------------------------------------------------------------------
;;; Session state and setup
;;;---------------------------------------------------------------------------

(defparameter *default-form*
  '(defun sum-positives (n lst / acc)
    (setq acc 0)
    (foreach x lst
      (if (> x n)
          (progn
            (print x)
            (setq acc (+ acc x)))
          (cond ((= x 0) (print "zero"))
                ((< x 0) (print "negative"))
                (t       (print "small")))))
    acc)
  "A sample form exercising DEFUN (with a `/ acc' local), SETQ, FOREACH,
IF, PROGN, COND and calls.  Note how the `(n lst / acc)' lambda list and
the SETQ target symbols carry no poll-point number.")

(defun setup (form)
  (setf *pp-vector*  (make-array 16 :adjustable t :fill-pointer 0)
        *pp-by-path* (make-hash-table :test 'equal)
        *root-pp*    (build-pp-tree form '() nil)
        *deco-root*  (wrap form '())
        *selection*  *root-pp*
        *current*    *root-pp*))


;;;---------------------------------------------------------------------------
;;; Navigation (over the poll-point tree)
;;;---------------------------------------------------------------------------

(defun siblings (pp)
  (if (pp-parent pp) (pp-children (pp-parent pp)) (list pp)))

(defun cmd-in (args)
  (declare (ignore args))
  (let ((c (first (pp-children *selection*))))
    (if c (setf *selection* c) (note "Already at a leaf sub-expression."))))

(defun cmd-out (args)
  (declare (ignore args))
  (let ((p (pp-parent *selection*)))
    (if p (setf *selection* p) (note "Already at the whole form."))))

(defun cmd-forward (args)
  (declare (ignore args))
  (let* ((sibs (siblings *selection*))
         (i    (position *selection* sibs)))
    (if (and i (< (1+ i) (length sibs)))
        (setf *selection* (nth (1+ i) sibs))
        (cmd-out nil))))

(defun cmd-backward (args)
  (declare (ignore args))
  (let* ((sibs (siblings *selection*))
         (i    (position *selection* sibs)))
    (if (and i (plusp i))
        (setf *selection* (nth (1- i) sibs))
        (cmd-out nil))))

(defun cmd-jump (args)
  "Bare number N, or `select N': move the selection to poll-point N."
  (let ((pp (pp-by-number (first args))))
    (if pp (setf *selection* pp)
        (note "No poll-point ~A." (first args)))))


;;;---------------------------------------------------------------------------
;;; Breakpoint / annotation commands
;;;
;;; All accept an optional leading poll-point number; without it they act on
;;; the current selection.  So `break', `break 7', `condition (> x 0)' and
;;; `condition 7 (> x 0)' are all valid.
;;;---------------------------------------------------------------------------

(defun target-and-rest (args)
  "Values: the targeted pp, and the remaining args."
  (if (integerp (first args))
      (values (pp-by-number (first args)) (rest args))
      (values *selection* args)))

(defmacro with-target ((pp rest args) &body body)
  `(multiple-value-bind (,pp ,rest) (target-and-rest ,args)
     (declare (ignorable ,rest))
     (if ,pp (progn ,@body) (note "No such poll-point."))))

(defun cmd-break   (args) (with-target (pp r args) (setf (pp-breakpoint pp) :enabled)
                            (note "Breakpoint set at pp~D." (pp-number pp))))
(defun cmd-clear   (args) (with-target (pp r args) (setf (pp-breakpoint pp) nil)
                            (note "Breakpoint cleared at pp~D." (pp-number pp))))
(defun cmd-enable  (args) (with-target (pp r args) (setf (pp-breakpoint pp) :enabled)))
(defun cmd-disable (args) (with-target (pp r args) (setf (pp-breakpoint pp) :disabled)))
(defun cmd-condition (args) (with-target (pp r args) (setf (pp-condition pp) (first r))))
(defun cmd-pre       (args) (with-target (pp r args) (setf (pp-pre pp) (first r))))
(defun cmd-post      (args) (with-target (pp r args) (setf (pp-post pp) (first r))))

(defun cmd-current (args)
  "Set the current poll-point (simulating re-entry into the debugger)."
  (let ((pp (pp-by-number (first args))))
    (if pp (setf *current* pp *selection* pp)
        (note "No poll-point ~A." (first args)))))


;;;---------------------------------------------------------------------------
;;; Mode, listing, help, quit
;;;---------------------------------------------------------------------------

(defun cmd-mode (args)
  (let* ((name (and args (string-upcase (string (first args)))))
         (mode (cond ((null name) nil)
                     ((member name '("UNICODE" "U") :test 'string=)        :unicode)
                     ((member name '("ASCII" "A") :test 'string=)          :ascii)
                     ((member name '("COLOR" "COLOUR" "COLORS" "C") :test 'string=) :color)
                     ((member name '("ATTR" "ATTRIBUTES" "BUI") :test 'string=)     :attr))))
    (cond ((null name)
           (note "Modes: unicode, ascii, color, attr (current: ~(~A~))." *mode*))
          (mode (setf *mode* mode) (note "Mode: ~(~A~)." mode))
          (t    (note "Unknown mode ~A." (first args))))))

(defun cmd-list (args)
  (declare (ignore args))
  (format *query-io* "~&Poll-points:~%")
  (let ((*package* (load-time-value
                    (find-package "COM.INFORMATIMAGO.SMALL-CL-PGMS.SEDIT.DBGSIM"))))
  (loop :for pp :across *pp-vector*
        :do (format *query-io* "  pp~2D~A ~A~@[ cond ~S~]~@[ pre ~S~]~@[ post ~S~]  ~A~%"
                    (pp-number pp)
                    (cond ((eq pp *current*) " *") ((eq pp *selection*) " .") (t "  "))
                    (case (pp-breakpoint pp)
                      (:enabled "[bp]") (:disabled "[bp-disabled]") (t "    "))
                    (pp-condition pp) (pp-pre pp) (pp-post pp)
                    (let ((*print-pretty* nil) (*print-length* 4) (*print-level* 2))
                      (prin1-to-string (pp-form pp))))))
  (finish-output *query-io*))

(defun cmd-quit (args) (declare (ignore args)) (throw 'dbgsim-quit nil))


;;;---------------------------------------------------------------------------
;;; Command table and dispatch
;;;---------------------------------------------------------------------------

(defparameter *command-map*
  ;; (keys... function "help")
  '(((i in)              cmd-in        "select the first sub-expression (in/down).")
    ((o out u up)        cmd-out       "select the parent form (out/up).")
    ((f forward)         cmd-forward   "select the next sibling sub-expression (or out).")
    ((n next)            cmd-forward   "select the next sibling sub-expression (or out).")
    ((b backward)        cmd-backward  "select the previous sibling (or out).")
    ((p previous)        cmd-backward  "select the previous sibling (or out).")
    ((N)                 cmd-jump      "a bare number jumps the selection to poll-point N.")
    ((select)            cmd-jump      "select N: jump the selection to poll-point N.")
    ((break bp)          cmd-break     "break [N]: set a breakpoint (enabled).")
    ((clear delete)      cmd-clear     "clear [N]: remove the breakpoint.")
    ((enable)            cmd-enable    "enable [N]: enable the breakpoint.")
    ((disable)           cmd-disable   "disable [N]: disable the breakpoint.")
    ((condition)         cmd-condition "condition [N] [FORM]: set/clear the condition.")
    ((pre)               cmd-pre       "pre [N] [FORM]: set/clear the pre-expression.")
    ((post)              cmd-post      "post [N] [FORM]: set/clear the post-expression.")
    ((current)           cmd-current   "current N: make pp N the current poll-point.")
    ((mode m)            cmd-mode      "mode [unicode|ascii|color|attr]: switch display.")
    ((list ls)           cmd-list      "list all poll-points and their state.")
    ((help h ?)          cmd-help      "print this help.")
    ((quit q)            cmd-quit      "leave the simulator.")))

(defvar *bindings* (make-hash-table :test 'eq))

(defun initialize-bindings ()
  (clrhash *bindings*)
  (loop :for (keys function) :in *command-map*
        :do (dolist (k keys) (setf (gethash k *bindings*) function))))

(defun cmd-help (args)
  (declare (ignore args))
  (format *query-io* "~&Commands:~%")
  (loop :for (keys nil help) :in *command-map*
        :do (format *query-io* "  ~12A ~A~%"
                    (format nil "~{~(~A~)~^ ~}" keys) help))
  (finish-output *query-io*))

(defvar *note* nil "Transient one-line message shown under the form.")

(defun note (control &rest args)
  (setf *note* (apply #'format nil control args)))

(defun read-tokens (line)
  "Read all the forms in LINE (in this package), returning them as a list."
  (let ((*package*   (load-time-value
                      (find-package "COM.INFORMATIMAGO.SMALL-CL-PGMS.SEDIT.DBGSIM")))
        (*read-eval* nil)
        (tokens '())
        (pos 0)
        (len (length line)))
    (loop
      (multiple-value-bind (obj newpos)
          (handler-case (read-from-string line nil '#1=#:eof :start pos)
            (error () (values '#1# len)))
        (when (eq obj '#1#) (return))
        (push obj tokens)
        (setf pos newpos)
        (when (>= pos len) (return))))
    (nreverse tokens)))

(defun dispatch (tokens)
  (let ((cmd (first tokens)))
    (cond
      ((null tokens))                                   ; empty line: just redisplay
      ((integerp cmd) (cmd-jump tokens))
      ((symbolp cmd)
       (let ((function (gethash cmd *bindings*)))
         (if function
             (funcall function (rest tokens))
             (note "Unknown command ~A.  Type help." cmd))))
      (t (note "Unknown command.")))))


;;;---------------------------------------------------------------------------
;;; The display and the loop
;;;---------------------------------------------------------------------------

(defun show-poll-point-info ()
  (let ((pp *selection*))
    (format *query-io* "~&~%selection: pp~D~:[~;  (current poll-point)~]  breakpoint: ~A~
                        ~@[  condition: ~S~]~@[  pre: ~S~]~@[  post: ~S~]~%"
            (pp-number pp) (eq pp *current*)
            (case (pp-breakpoint pp) (:enabled "enabled") (:disabled "disabled") (t "none"))
            (pp-condition pp) (pp-pre pp) (pp-post pp))))

(defun show ()
  (let ((*print-pretty*       t)
        (*print-right-margin* 72)
        (*print-escape*       t)
        (*print-readably*     nil)
        ;; Print the form's symbols unqualified (the simulated form lives in
        ;; this package); a real debugger would use the form's home package.
        (*package*            (load-time-value
                               (find-package
                                "COM.INFORMATIMAGO.SMALL-CL-PGMS.SEDIT.DBGSIM"))))
    (terpri *query-io*)
    (write *deco-root* :stream *query-io*)
    (terpri *query-io*)
    (show-poll-point-info)
    (when *note* (format *query-io* "~&[~A]~%" *note*) (setf *note* nil))
    (finish-output *query-io*)))

(defun banner ()
  (format *query-io* "~&clautolisp debugger TUI simulator (sedit-based).~%~
                      Navigate: in out forward backward (or a bare poll-point number).~%~
                      Breakpoints: break / clear / enable / disable / condition / pre / post.~%~
                      Display: mode unicode|ascii|color|attr.   help, quit.~%")
  (finish-output *query-io*))

(defun dbgsim (&optional (form *default-form*))
  "Run the debugger-TUI simulator on FORM (read-only)."
  (initialize-bindings)
  (setup form)
  (banner)
  (catch 'dbgsim-quit
    (loop
      (show)
      (princ "dbg> " *query-io*)
      (finish-output *query-io*)
      (let ((line (read-line *query-io* nil :eof)))
        (when (eq line :eof) (throw 'dbgsim-quit nil))
        (handler-case (dispatch (read-tokens line))
          (error (e) (note "Error: ~A" e))))))
  (values))

;;;; THE END ;;;;
