;;;; probes/sources/probe-entget-pointers.lsp
;;;;
;;;; What TYPE does ENTGET give the DXF POINTER group codes?
;;;;
;;;; issues/closed/cador-entget-pointer-codes-are-handle-strings.issue:
;;;; under the clautolisp cador host, SCHMS stopped on
;;;;     ENTGET expects an ENAME, got "41"
;;;; because cador returned every pointer group (330 owner, 350/360
;;;; dictionary entries, ...) as a handle STRING. The DXF reference types
;;;; 330-339 soft-pointer, 340-349 hard-pointer, 350-359 soft-owner,
;;;; 360-369 hard-owner, 390-399 plot-style hard pointer and 480-481
;;;; hard-pointer handles as object IDs, which AutoLISP sees as ENAMES;
;;;; 5 / 105 (the object's own handle), 320-329 ("arbitrary object
;;;; handles") and the xdata 1005 stay strings. clautolisp 2.3.7 follows
;;;; that reading; this probe MEASURES it, together with the corners the
;;;; fix had to decide without evidence:
;;;;
;;;;   - the null pointer: (330 . ?) of the named-object dictionary;
;;;;   - a pointer to an ERASED object (ename kept? entget nil?);
;;;;   - 320-329 written through entmakex: string or ename on read-back?
;;;;   - a handle STRING given to entmakex in a pointer code: accepted?
;;;;   - the XRECORD read-back layout: AutoCAD inserts (280 . 1) after
;;;;     (100 . "AcDbXrecord")? (SCHMS's decoder skips it positionally:
;;;;     "Nom de classe attendu" when it is absent.) With and without the
;;;;     100 marker in the entmakex data.
;;;;
;;;; Pointer types are recorded as "<code>:<TYPE>" lists, layouts as the
;;;; list of group codes -- portable values, never raw enames (except the
;;;; null-pointer case, where the printed ename IS the answer).
;;;;
;;;; Every case runs under vl-catch-all-apply (cad-probe-capture); the
;;;; ActiveX cases (extension dictionary) record `error' on accoreconsole.

(defun cad-probe--ep-kind (x)
  (if x (vl-symbol-name (type x)) "NIL"))

(defun cad-probe--ep-pointer-code-p (c)
  (and (= (type c) 'INT)
       (or (and (>= c 320) (<= c 369))
           (and (>= c 390) (<= c 399))
           (and (>= c 480) (<= c 481))
           (= c 5) (= c 105))))

(defun cad-probe--ep-pointer-types (data / out)
  ;; "330:ENAME 350:ENAME ..." for every pointer-ish pair of DATA.
  (setq out "")
  (foreach p data
    (if (and (= (type p) 'LIST) (cad-probe--ep-pointer-code-p (car p)))
      (setq out (strcat out (if (= out "") "" " ")
                        (itoa (car p)) ":" (cad-probe--ep-kind (cdr p))))))
  (if (= out "") "none" out))

(defun cad-probe--ep-codes (data / out)
  ;; The group codes of DATA, in order: "-1 0 5 102 330 102 330 100 280 1".
  (setq out "")
  (foreach p data
    (if (= (type p) 'LIST)
      (setq out (strcat out (if (= out "") "" " ")
                        (if (= (type (car p)) 'INT) (itoa (car p)) "?")))))
  out)

(defun cad-probe--ep-follow (v / d)
  ;; What (entget V) gives: the target's (0 . TYPE), "NIL", or the error.
  (cond ((null v) "pointer absent")
        ((/= (type v) 'ENAME) (strcat "not an ename: " (cad-probe--ep-kind v)))
        ((setq d (entget v)) (strcat "entget -> " (cdr (assoc 0 d))))
        (t "entget -> NIL")))

(defun cad-probe--ep-tag ()
  (itoa (rem (fix (* 86400000.0 (- (getvar "DATE") (fix (getvar "DATE"))))) 100000000)))

(defun cad-probe-run-entget-pointer-probes ( / line nod tag blk ins att xr xr2 xr3 gone)
  (setq tag (cad-probe--ep-tag))
  (setq line (entmakex '((0 . "LINE") (8 . "0") (10 0.0 0.0 0.0) (11 1.0 1.0 0.0))))

  ;; 1. A LINE in model space: its owner (the *Model_Space block record).
  (cad-probe-capture "entget-pointers" "LINE in model space: pointer types"
    (function (lambda () (cad-probe--ep-pointer-types (entget line)))))
  (cad-probe-capture "entget-pointers" "LINE in model space: (entget (cdr (assoc 330 ...)))"
    (function (lambda () (cad-probe--ep-follow (cdr (assoc 330 (entget line)))))))

  ;; 2. The named-object dictionary.
  (setq nod (namedobjdict))
  (cad-probe-capture "entget-pointers" "(entget (namedobjdict)): pointer types"
    (function (lambda () (cad-probe--ep-pointer-types (entget nod)))))
  (cad-probe-capture "entget-pointers" "(entget (namedobjdict)): 330 printed (null pointer?)"
    (function (lambda () (vl-prin1-to-string (assoc 330 (entget nod))))))
  (cad-probe-capture "entget-pointers" "(entget (namedobjdict)): (entget 330)"
    (function (lambda () (cad-probe--ep-follow (cdr (assoc 330 (entget nod)))))))
  (cad-probe-capture "entget-pointers" "(entget (namedobjdict)): (entget first 350)"
    (function (lambda () (cad-probe--ep-follow (cdr (assoc 350 (entget nod)))))))
  (cad-probe-capture "entget-pointers" "(entget (namedobjdict)): (entget first 360)"
    (function (lambda () (cad-probe--ep-follow (cdr (assoc 360 (entget nod)))))))
  (cad-probe-capture "entget-pointers" "dictnext of the NOD: pointer types"
    (function (lambda () (cad-probe--ep-pointer-types (dictnext nod t)))))

  ;; 3. An extension dictionary (ActiveX; accoreconsole records an error).
  (cad-probe-capture "entget-pointers" "LINE with an extension dictionary: pointer types"
    (function (lambda ()
      (vl-load-com)
      (vla-GetExtensionDictionary (vlax-ename->vla-object line))
      (cad-probe--ep-pointer-types (entget line)))))
  (cad-probe-capture "entget-pointers" "LINE with an extension dictionary: (entget 360)"
    (function (lambda () (cad-probe--ep-follow (cdr (assoc 360 (entget line)))))))

  ;; 4. An INSERT with an ATTRIB.
  (setq blk (strcat "PRPTR" tag))
  (cad-probe-capture "entget-pointers" "block with an ATTDEF defined"
    (function (lambda ()
      (entmake (list '(0 . "BLOCK") (cons 2 blk) '(70 . 2) '(10 0.0 0.0 0.0)))
      (entmake '((0 . "LINE") (8 . "0") (10 0.0 0.0 0.0) (11 1.0 0.0 0.0)))
      (entmake '((0 . "ATTDEF") (8 . "0") (10 0.0 0.0 0.0) (40 . 1.0) (1 . "v")
                 (3 . "Prompt") (2 . "TAG") (70 . 0)))
      (cad-probe--ep-kind (entmake '((0 . "ENDBLK")))))))
  (cad-probe-capture "entget-pointers" "INSERT with ATTRIB created"
    (function (lambda ()
      (setq ins (entmakex (list '(0 . "INSERT") '(8 . "0") (cons 2 blk) '(66 . 1)
                                '(10 5.0 5.0 0.0))))
      (setq att (entmakex '((0 . "ATTRIB") (8 . "0") (10 5.0 5.0 0.0) (40 . 1.0)
                            (1 . "v") (2 . "TAG") (70 . 0))))
      (entmakex '((0 . "SEQEND") (8 . "0")))
      (strcat (cad-probe--ep-kind ins) " " (cad-probe--ep-kind att)))))
  (cad-probe-capture "entget-pointers" "INSERT: pointer types"
    (function (lambda () (cad-probe--ep-pointer-types (entget ins)))))
  (cad-probe-capture "entget-pointers" "ATTRIB of the INSERT: pointer types"
    (function (lambda () (cad-probe--ep-pointer-types (entget (entnext ins))))))
  (cad-probe-capture "entget-pointers" "ATTRIB of the INSERT: (entget 330)"
    (function (lambda () (cad-probe--ep-follow (cdr (assoc 330 (entget (entnext ins))))))))
  (cad-probe-capture "entget-pointers" "(tblsearch \"BLOCK\" blk): pointer types"
    (function (lambda () (cad-probe--ep-pointer-types (tblsearch "BLOCK" blk)))))
  (cad-probe-capture "entget-pointers" "(entget (tblobjname \"BLOCK\" blk)): pointer types"
    (function (lambda () (cad-probe--ep-pointer-types (entget (tblobjname "BLOCK" blk))))))

  ;; 5. Symbol-table records: layer 0 (390 plot style, 347 material, 348 ...).
  (cad-probe-capture "entget-pointers" "(entget (tblobjname \"LAYER\" \"0\")): pointer types"
    (function (lambda () (cad-probe--ep-pointer-types (entget (tblobjname "LAYER" "0"))))))
  (cad-probe-capture "entget-pointers" "(entget (tblobjname \"LAYER\" \"0\")): (entget 330)"
    (function (lambda () (cad-probe--ep-follow (cdr (assoc 330 (entget (tblobjname "LAYER" "0"))))))))
  (cad-probe-capture "entget-pointers" "(entget (tblobjname \"LAYER\" \"0\")): (entget 390)"
    (function (lambda () (cad-probe--ep-follow (cdr (assoc 390 (entget (tblobjname "LAYER" "0"))))))))
  (cad-probe-capture "entget-pointers" "(entget (tblobjname \"LAYER\" \"0\")): (entget 347)"
    (function (lambda () (cad-probe--ep-follow (cdr (assoc 347 (entget (tblobjname "LAYER" "0"))))))))
  (cad-probe-capture "entget-pointers" "(tblsearch \"LAYER\" \"0\"): pointer types"
    (function (lambda () (cad-probe--ep-pointer-types (tblsearch "LAYER" "0")))))
  (cad-probe-capture "entget-pointers" "(tblnext \"LAYER\" T): pointer types"
    (function (lambda () (cad-probe--ep-pointer-types (tblnext "LAYER" t)))))
  (cad-probe-capture "entget-pointers" "(tblsearch \"STYLE\" \"Standard\"): pointer types"
    (function (lambda () (cad-probe--ep-pointer-types (tblsearch "STYLE" "Standard")))))

  ;; 6. XRECORD layout (the SCHMS "Nom de classe attendu" question).
  (cad-probe-capture "entget-pointers" "XRECORD with 100 marker: entmakex"
    (function (lambda ()
      (setq xr (entmakex '((0 . "XRECORD") (100 . "AcDbXrecord") (1 . "Classe") (70 . 1))))
      (cad-probe--ep-kind xr))))
  (cad-probe-capture "entget-pointers" "XRECORD with 100 marker: entget codes"
    (function (lambda () (cad-probe--ep-codes (entget xr)))))
  (cad-probe-capture "entget-pointers" "XRECORD with 100 marker: the pair after the marker"
    (function (lambda ()
      (vl-prin1-to-string (cadr (member '(100 . "AcDbXrecord") (entget xr)))))))
  (cad-probe-capture "entget-pointers" "XRECORD with 100 marker: dictadd + dictsearch codes"
    (function (lambda ()
      (dictadd nod (strcat "PRPTR" tag) xr)
      (cad-probe--ep-codes (dictsearch nod (strcat "PRPTR" tag))))))
  (cad-probe-capture "entget-pointers" "XRECORD in the NOD: pointer types"
    (function (lambda () (cad-probe--ep-pointer-types (entget xr)))))
  (cad-probe-capture "entget-pointers" "XRECORD in the NOD: (entget 330)"
    (function (lambda () (cad-probe--ep-follow (cdr (assoc 330 (entget xr)))))))
  (cad-probe-capture "entget-pointers" "XRECORD without 100 marker: entmakex"
    (function (lambda ()
      (setq xr2 (entmakex '((0 . "XRECORD") (1 . "Classe") (70 . 1))))
      (cad-probe--ep-kind xr2))))
  (cad-probe-capture "entget-pointers" "XRECORD without 100 marker: entget codes"
    (function (lambda () (cad-probe--ep-codes (entget xr2)))))
  (cad-probe-capture "entget-pointers" "XRECORD with explicit (280 . 0): entget codes and 280"
    (function (lambda ( / x)
      (setq x (entmakex '((0 . "XRECORD") (100 . "AcDbXrecord") (280 . 0) (1 . "a"))))
      (strcat (cad-probe--ep-codes (entget x)) " | "
              (vl-prin1-to-string (assoc 280 (entget x)))))))

  ;; 7. Pointers WRITTEN through entmakex: ename vs handle string, 320.
  (cad-probe-capture "entget-pointers" "XRECORD (340 . <ename>): read-back types"
    (function (lambda ()
      (setq xr3 (entmakex (list '(0 . "XRECORD") '(100 . "AcDbXrecord")
                                (cons 340 line) (cons 320 (cdr (assoc 5 (entget line)))))))
      (cad-probe--ep-pointer-types (entget xr3)))))
  (cad-probe-capture "entget-pointers" "XRECORD (340 . <handle string>): entmakex result"
    (function (lambda ()
      (cad-probe--ep-kind
        (entmakex (list '(0 . "XRECORD") '(100 . "AcDbXrecord")
                        (cons 340 (cdr (assoc 5 (entget line))))))))))
  (cad-probe-capture "entget-pointers" "XRECORD (340 . <handle string>): read-back types"
    (function (lambda ( / x)
      (setq x (entmakex (list '(0 . "XRECORD") '(100 . "AcDbXrecord")
                              (cons 340 (cdr (assoc 5 (entget line)))))))
      (if x (cad-probe--ep-pointer-types (entget x)) "entmakex refused"))))
  (cad-probe-capture "entget-pointers" "XRECORD (320 . <ename>): entmakex + read-back"
    (function (lambda ( / x)
      (setq x (entmakex (list '(0 . "XRECORD") '(100 . "AcDbXrecord") (cons 320 line))))
      (if x (cad-probe--ep-pointer-types (entget x)) "entmakex refused"))))

  ;; 8. A pointer to an ERASED object.
  (cad-probe-capture "entget-pointers" "340 to an erased LINE: read-back"
    (function (lambda ()
      (setq gone (entmakex '((0 . "LINE") (8 . "0") (10 0.0 0.0 0.0) (11 2.0 2.0 0.0))))
      (setq xr3 (entmakex (list '(0 . "XRECORD") '(100 . "AcDbXrecord") (cons 340 gone))))
      (entdel gone)
      (strcat (cad-probe--ep-pointer-types (entget xr3)) " | "
              (cad-probe--ep-follow (cdr (assoc 340 (entget xr3))))
              " | eq " (if (eq gone (cdr (assoc 340 (entget xr3)))) "T" "NIL")))))

  ;; 9. entmod round trip of a pointer with an ename and with a string.
  (cad-probe-capture "entget-pointers" "entmod XRECORD 340 := handle string"
    (function (lambda ( / d)
      (setq d (entget xr3))
      (setq d (subst (cons 340 (cdr (assoc 5 (entget line)))) (assoc 340 d) d))
      (strcat (cad-probe--ep-kind (entmod d)) " | "
              (cad-probe--ep-pointer-types (entget xr3))))))

  (cad-probe-capture "entget-pointers" "xdata 1005 stays a string"
    (function (lambda ( / app)
      (setq app "CLAUTOLISP_EPP")
      (regapp app)
      (entmod (append (entget line)
                      (list (list -3 (list app (cons 1005 (cdr (assoc 5 (entget line)))))))))
      (cad-probe--ep-kind (cdr (assoc 1005 (cdr (car (cdr (assoc -3 (entget line (list app))))))))))))
  (princ))
