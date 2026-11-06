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
                              ;; APPLY, not (pairs-fn e): AutoCAD refuses to
                              ;; call a variable holding a (function ...) value
                              ;; ("fonction incorrecte", 2026-10-03).
                              (list (list -3 (cons cad-probe--xd-app
                                                   (apply pairs-fn (list e))))))))
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
  (cad-probe-run-xdsize-probes)
  (princ))

;;; XDSIZE / XDROOM byte accounting (xdroom-xdsize-not-implemented).
;;; clautolisp's per-group byte table is PROVISIONAL; these cases MEASURE
;;; the vendor's. Each "xdsize <case>" isolates one group code by sizing
;;; the application with and without it (the difference is that group's
;;; cost); "xdsize header" is the bare application, "xdsize header +1 char"
;;; shows whether the header grows with the name. "xdroom fresh" is the
;;; budget; "xdroom after" the room left once a known payload is attached.

(defun cad-probe--xs (label xd)
  (cad-probe-capture "xdsize" label
    (function (lambda ( / r)
      (setq r (vl-catch-all-apply 'xdsize (list xd)))
      (cond ((vl-catch-all-error-p r) (strcat "ERROR errno=" (itoa (getvar "ERRNO"))))
            ((null r) "NIL")
            (t (itoa r)))))))

(defun cad-probe-run-xdsize-probes ( / app app2 e)
  (setq app cad-probe--xd-app
        app2 (strcat cad-probe--xd-app "X"))
  (regapp app2)
  (cad-probe--xs "header" (list (list app)))
  (cad-probe--xs "header +1 char" (list (list app2)))
  (cad-probe--xs "-3 sentinel form" (list -3 (list app)))
  (cad-probe--xs "1000 empty string" (list (list app '(1000 . ""))))
  (cad-probe--xs "1000 3 chars" (list (list app '(1000 . "abc"))))
  (cad-probe--xs "1000 10 chars" (list (list app '(1000 . "abcdefghij"))))
  (cad-probe--xs "1000 non-ASCII 1 char" (list (list app (cons 1000 (chr 233)))))
  (cad-probe--xs "1002 brace pair" (list (list app '(1002 . "{") '(1002 . "}"))))
  (cad-probe--xs "1003 layer 0" (list (list app '(1003 . "0"))))
  (cad-probe--xs "1004 binary 4 bytes" (list (list app '(1004 . "DEADBEEF"))))
  (cad-probe--xs "1005 handle 1 char" (list (list app '(1005 . "1"))))
  (cad-probe--xs "1005 handle 2 chars" (list (list app '(1005 . "2A"))))
  (cad-probe--xs "1010 point" (list (list app '(1010 1.0 2.0 3.0))))
  (cad-probe--xs "1011 world position" (list (list app '(1011 1.0 2.0 3.0))))
  (cad-probe--xs "1040 real" (list (list app '(1040 . 1.5))))
  (cad-probe--xs "1041 distance" (list (list app '(1041 . 1.5))))
  (cad-probe--xs "1042 scale" (list (list app '(1042 . 1.5))))
  (cad-probe--xs "1070 int16" (list (list app '(1070 . 42))))
  (cad-probe--xs "1071 int32" (list (list app '(1071 . 100000))))
  (cad-probe--xs "two applications" (list (list app '(1000 . "abc")) (list app2 '(1040 . 1.5))))
  (cad-probe--xs "documented example"
    (list -3 (list app '(1000 . "SUITOFARMOR") '(1002 . "{") '(1040 . 0.0)
                   '(1040 . 1.0) '(1002 . "}"))))
  ;; errors: unregistered application, unknown code, unbalanced brace
  (cad-probe--xs "error unregistered app" (list (list "CLAUTOLISP_NOT_REGISTERED" '(1000 . "x"))))
  (cad-probe--xs "error unknown code 1099" (list (list app '(1099 . 1))))
  (cad-probe--xs "error unbalanced brace" (list (list app '(1002 . "{"))))
  ;; xdroom: budget, then room left after a known payload
  (setq e (cad-probe--xd-circle))
  (cad-probe-capture "xdroom" "fresh circle"
    (function (lambda () (itoa (xdroom e)))))
  (entmod (append (entget e)
                  (list (list -3 (list app '(1000 . "abc") '(1070 . 1) '(1040 . 1.5))))))
  (cad-probe-capture "xdroom" "after 1000 abc + 1070 + 1040"
    (function (lambda () (itoa (xdroom e)))))
  (cad-probe-capture "xdroom" "xdsize of that xdata"
    (function (lambda () (itoa (xdsize (assoc -3 (entget e (list app))))))))
  (entdel e))
