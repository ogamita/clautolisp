;;;; probes/sources/probe-xdata.lsp
;;;;
;;;; Which XData group makes ENTMOD drop the payload?
;;;;
;;;; drawing-data-structures-parity: autolisp-front-end's drawing-data
;;;; probe attaches one payload (1000 1002{ 1003 1005"2A" 1040 1070 1071
;;;; 1002}) with ENTMOD, and on AutoCAD 2022 nothing reads back (pair count
;;;; 0) while BricsCAD and clautolisp read all 8. Two applications with a
;;;; bare 1000 each DO read back on AutoCAD. So one group of that payload is
;;;; refused -- the suspect being 1005 "2A", a handle that names no object.
;;;;
;;;; Each case: a fresh CIRCLE, ONE xdata variant attached by ENTMOD, then
;;;;   "<variant> entmod"   -- what ENTMOD returned (LIST / NIL / error)
;;;;   "<variant> pairs"    -- how many pairs (entget e (list app)) reads back
;;;; Values are portable: type names and counts, never enames.

(setq cad-probe--xd-app "CLAUTOLISP_XDP")

(defun cad-probe--xd-circle ()
  (entmakex (list '(0 . "CIRCLE") '(8 . "0") '(10 3.0 3.0 0.0) '(40 . 1.0))))

(defun cad-probe--xd-case (label pairs-fn / e r)
  ;; PAIRS-FN receives the fresh circle's ename (so a variant can point a
  ;; 1005 at a handle that EXISTS) and returns the app's pair list.
  (setq e (cad-probe--xd-circle))
  (cad-probe-capture "xdata" (strcat label " entmod")
    (function (lambda ()
      (setq r (entmod (append (entget e)
                              (list (list -3 (cons cad-probe--xd-app (pairs-fn e)))))))
      (if r (vl-symbol-name (type r)) "NIL"))))
  (cad-probe-capture "xdata" (strcat label " pairs")
    (function (lambda ( / x)
      (setq x (cdr (assoc -3 (entget e (list cad-probe--xd-app)))))
      (itoa (length (cdr (car x)))))))
  (entdel e))

(defun cad-probe-run-xdata-probes ()
  (regapp cad-probe--xd-app)
  (cad-probe--xd-case "1000 string"
    (function (lambda (e) (list '(1000 . "tag-string")))))
  (cad-probe--xd-case "1002 braces around a 1000"
    (function (lambda (e) (list '(1002 . "{") '(1000 . "in") '(1002 . "}")))))
  (cad-probe--xd-case "1003 layer 0"
    (function (lambda (e) (list '(1003 . "0")))))
  (cad-probe--xd-case "1003 layer that does not exist"
    (function (lambda (e) (list '(1003 . "NO_SUCH_LAYER_XDP")))))
  (cad-probe--xd-case "1005 handle 2A (names no object)"
    (function (lambda (e) (list '(1005 . "2A")))))
  (cad-probe--xd-case "1005 handle of the entity itself"
    (function (lambda (e) (list (cons 1005 (cdr (assoc 5 (entget e))))))))
  (cad-probe--xd-case "1040 real"
    (function (lambda (e) (list '(1040 . 1.5)))))
  (cad-probe--xd-case "1070 int16"
    (function (lambda (e) (list '(1070 . 42)))))
  (cad-probe--xd-case "1071 int32"
    (function (lambda (e) (list '(1071 . 100000)))))
  (cad-probe--xd-case "1010 point"
    (function (lambda (e) (list '(1010 1.0 2.0 0.0)))))
  ;; The drawing-data probe's payload, whole and without its 1005.
  (cad-probe--xd-case "drawing-data payload"
    (function (lambda (e)
      (list '(1000 . "tag-string") '(1002 . "{") '(1003 . "0") '(1005 . "2A")
            '(1040 . 1.5) '(1070 . 42) '(1071 . 100000) '(1002 . "}")))))
  (cad-probe--xd-case "drawing-data payload without 1005"
    (function (lambda (e)
      (list '(1000 . "tag-string") '(1002 . "{") '(1003 . "0")
            '(1040 . 1.5) '(1070 . 42) '(1071 . 100000) '(1002 . "}")))))
  (princ))
