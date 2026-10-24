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

  ;; 10. The full HEADER ORDER of entget (cador-entget-owner-and-header-
  ;; layout): where -1 0 5 102 330 100 stand, for fresh objects of each
  ;; kind -- the earlier sections recorded which pointers exist, not
  ;; their order. Fresh entities: section 3 gave LINE an extension
  ;; dictionary.
  (cad-probe-capture "entget-pointers" "codes: fresh LINE in model space"
    (function (lambda ()
      (cad-probe--ep-codes
        (entget (entmakex '((0 . "LINE") (8 . "0") (10 0.0 0.0 0.0) (11 1.0 1.0 0.0))))))))
  (cad-probe-capture "entget-pointers" "codes: fresh CIRCLE in model space"
    (function (lambda ()
      (cad-probe--ep-codes
        (entget (entmakex '((0 . "CIRCLE") (8 . "0") (10 0.0 0.0 0.0) (40 . 1.0))))))))
  (cad-probe-capture "entget-pointers" "codes: fresh TEXT in model space"
    (function (lambda ()
      (cad-probe--ep-codes
        (entget (entmakex '((0 . "TEXT") (8 . "0") (10 0.0 0.0 0.0) (40 . 1.0) (1 . "t"))))))))
  (cad-probe-capture "entget-pointers" "codes: INSERT without attributes"
    (function (lambda ()
      (cad-probe--ep-codes
        (entget (entmakex (list '(0 . "INSERT") '(8 . "0") (cons 2 blk) '(10 9.0 9.0 0.0))))))))
  (cad-probe-capture "entget-pointers" "codes: INSERT with ATTRIB (section 4), type of entget"
    (function (lambda ( / d)
      (setq d (entget ins))
      (strcat (cad-probe--ep-kind d) " | " (if d (cad-probe--ep-codes d) "")))))
  (cad-probe-capture "entget-pointers" "codes: ATTRIB of the INSERT"
    (function (lambda () (cad-probe--ep-codes (entget (entnext ins))))))
  (cad-probe-capture "entget-pointers" "codes: (entget (tblobjname \"LAYER\" \"0\"))"
    (function (lambda () (cad-probe--ep-codes (entget (tblobjname "LAYER" "0"))))))
  (cad-probe-capture "entget-pointers" "codes: (entget (tblobjname \"BLOCK\" blk))"
    (function (lambda () (cad-probe--ep-codes (entget (tblobjname "BLOCK" blk))))))
  (cad-probe-capture "entget-pointers" "codes: (entget (tblobjname \"BLOCK\" \"*Model_Space\"))"
    (function (lambda ( / d)
      (setq d (entget (tblobjname "BLOCK" "*Model_Space")))
      (strcat (cad-probe--ep-codes d) " | 0=" (vl-prin1-to-string (cdr (assoc 0 d)))))))
  (cad-probe-capture "entget-pointers" "codes: LINE's 330 target = tblobjname *Model_Space?"
    (function (lambda ( / o m)
      (setq o (cdr (assoc 330 (entget (entmakex '((0 . "LINE") (8 . "0")
                                                  (10 0.0 0.0 0.0) (11 1.0 0.0 0.0)))))))
      (setq m (tblobjname "BLOCK" "*Model_Space"))
      (strcat "eq " (if (eq o m) "T" "NIL") " | "
              (cad-probe--ep-follow o) " | "
              (cad-probe--ep-codes (if o (entget o) nil))))))
  (cad-probe-capture "entget-pointers" "codes: (entget (namedobjdict))"
    (function (lambda () (cad-probe--ep-codes (entget nod)))))
  (cad-probe-capture "entget-pointers" "codes: fresh XRECORD, then after dictadd (entget)"
    (function (lambda ( / x k)
      (setq x (entmakex '((0 . "XRECORD") (100 . "AcDbXrecord") (1 . "z"))))
      (setq k (strcat "PRORD" tag))
      (strcat (cad-probe--ep-codes (entget x)) " | "
              (progn (dictadd nod k x) (cad-probe--ep-codes (entget x)))))))

  ;; 11. What the table records and the named-object dictionary POINT AT
  ;; (cador-entget-subclass-layout-and-record-pointers, items 3-5): section
  ;; 10 gave the codes; cador needs the objects behind them -- the TABLE a
  ;; record's 330 names, the layer's 390 / 347 targets, the default NOD
  ;; entries by NAME, the BLOCK entity vs its BLOCK_RECORD, and whether
  ;; handent reaches a table record by its handle.
  (cad-probe-capture "entget-pointers" "records: NOD entries name=target"
    (function (lambda ( / out d)
      (setq out "")
      (foreach p (entget nod)
        (if (= (car p) 3) (setq d (cdr p)))
        (if (and d (= (car p) 350))
          (setq out (strcat out d "=" (cad-probe--ep-follow (cdr p)) "; ")
                d nil)))
      out)))
  (cad-probe-capture "entget-pointers" "records: layer 0's 330 (TABLE): codes | 2 | 70"
    (function (lambda ( / tbl)
      (setq tbl (entget (cdr (assoc 330 (entget (tblobjname "LAYER" "0"))))))
      (strcat (cad-probe--ep-codes tbl)
              " | 2=" (vl-prin1-to-string (cdr (assoc 2 tbl)))
              " | 70=" (vl-prin1-to-string (cdr (assoc 70 tbl)))))))
  (cad-probe-capture "entget-pointers" "records: layer 0's 390 target: codes"
    (function (lambda ( / v)
      (setq v (cdr (assoc 390 (entget (tblobjname "LAYER" "0")))))
      (strcat (cad-probe--ep-follow v) " | "
              (if (= (type v) 'ENAME) (cad-probe--ep-codes (entget v)) "")))))
  (cad-probe-capture "entget-pointers" "records: layer 0's 347 target: codes | 1"
    (function (lambda ( / v d)
      (setq v (cdr (assoc 347 (entget (tblobjname "LAYER" "0")))))
      (setq d (if (= (type v) 'ENAME) (entget v) nil))
      (strcat (cad-probe--ep-follow v) " | " (cad-probe--ep-codes d)
              " | 1=" (vl-prin1-to-string (cdr (assoc 1 d)))))))
  (cad-probe-capture "entget-pointers" "records: handent of layer 0's handle eq tblobjname?"
    (function (lambda ( / r h)
      (setq r (tblobjname "LAYER" "0"))
      (setq h (cdr (assoc 5 (entget r))))
      (strcat "handle " (vl-prin1-to-string h) " | eq "
              (if (eq (handent h) r) "T" "NIL")))))
  (cad-probe-capture "entget-pointers" "records: BLOCK entity's 330: codes | entnext type"
    (function (lambda ( / b r n)
      (setq b (tblobjname "BLOCK" blk))
      (setq r (cdr (assoc 330 (entget b))))
      (setq n (entnext b))
      (strcat (cad-probe--ep-follow r) " | "
              (if (= (type r) 'ENAME) (cad-probe--ep-codes (entget r)) "")
              " | entnext " (cad-probe--ep-follow n)))))
  ;; 12. and 13. (below)
  (cad-probe-run-default-object-probes)
  (cad-probe-run-endblk-and-template-probes)
  (princ))

;;; 12. WHAT the default objects contain (deferred-nod-default-contents):
;;; every NOD entry the CAD made (the PRORD / PRPTR ones are this probe's,
;;; sections 2 and 10), each member of the sub-dictionaries two levels
;;; down, and the extension dictionaries ({ACAD_XDICTIONARY 360}) of the
;;; NOD, of layer 0, of *Model_Space's BLOCK_RECORD and of each symbol TABLE
;;; object. Values are dumped as CODE=VALUE, a pointer as <TYPE name> -- its
;;; (0 . TYPE) and its record name or dictionary key, never a handle, which
;;; differs between runs.

(defun cad-probe--ep-target-name (v d / o k)
  ;; A name for the object V (its entget D): a record's / TABLE's group 2,
  ;; else the key it is filed under in its owner dictionary, else nil.
  (cond ((= (type (cdr (assoc 2 d))) 'STR) (cdr (assoc 2 d)))
        ((and (setq o (cdr (assoc 330 d))) (= (type o) 'ENAME)
              (cad-probe--ep-dictionary-p o))
         (foreach m (cad-probe--ep-members o)
           (if (eq (cdr m) v) (setq k (car m))))
         k)))

(defun cad-probe--ep-val (v / d n)
  ;; A pointer as <TYPE name> (handles differ between runs), else the value.
  (cond ((= (type v) 'ENAME)
         (if (setq d (entget v))
           (strcat "<" (cdr (assoc 0 d))
                   (if (setq n (cad-probe--ep-target-name v d)) (strcat " " n) "")
                   ">")
           "<erased>"))
        (t (vl-prin1-to-string v))))

(defun cad-probe--ep-dump (data / out)
  ;; "0=\"DICTIONARY\" 5=\"1A\" 330=<DICTIONARY> 100=\"AcDbDictionary\" ..."
  (setq out "")
  (foreach p data
    (if (and (= (type p) 'LIST) (/= (car p) -1))
      (setq out (strcat out (if (= out "") "" " ")
                        (if (= (type (car p)) 'INT) (itoa (car p)) "?")
                        "=" (cad-probe--ep-val (cdr p))))))
  out)

(defun cad-probe--ep-dictionary-p (e / d)
  (and (= (type e) 'ENAME)
       (setq d (entget e))
       (member (cdr (assoc 0 d)) '("DICTIONARY" "ACDBDICTIONARYWDFLT"))))

(defun cad-probe--ep-members (dict / out k)
  ;; ((NAME . ENAME) ...) of DICT, in order.
  (foreach p (entget dict)
    (cond ((= (car p) 3) (setq k (cdr p)))
          ((and k (member (car p) '(350 360)))
           (setq out (cons (cons k (cdr p)) out) k nil))))
  (reverse out))

(defun cad-probe--ep-xdict (data / in x)
  ;; The extension dictionary of the object whose entget is DATA, or nil.
  (foreach p data
    (cond ((and (= (car p) 102) (= (cdr p) "{ACAD_XDICTIONARY")) (setq in t))
          ((and in (= (car p) 360) (null x)) (setq x (cdr p)))
          ((and (= (car p) 102) (= (cdr p) "}")) (setq in nil))))
  x)

(defun cad-probe--ep-dump-dictionary (label dict depth / members)
  ;; Capture LABEL's own dump and its member list, then each member's dump
  ;; (LABEL/NAME); a member dictionary is opened DEPTH more levels.
  (cad-probe-capture "entget-pointers" (strcat label ": dictionary")
    (function (lambda () (cad-probe--ep-dump (entget dict)))))
  (setq members (cad-probe--ep-members dict))
  (cad-probe-capture "entget-pointers" (strcat label ": members")
    (function (lambda ( / out)
      (setq out "")
      (foreach m members
        (setq out (strcat out (car m) "=" (cad-probe--ep-val (cdr m)) "; ")))
      (if (= out "") "none" out))))
  (foreach m members
    (if (and (cad-probe--ep-dictionary-p (cdr m)) (> depth 0))
      (cad-probe--ep-dump-dictionary (strcat label "/" (car m)) (cdr m) (1- depth))
      (progn
        (cad-probe-capture "entget-pointers" (strcat label "/" (car m))
          (function (lambda () (cad-probe--ep-dump (entget (cdr m))))))
        ;; the member's own extension dictionary, when it has one
        ;; (AutoCAD's Model layout, materials, table style)
        (if (and (> depth 0) (cad-probe--ep-xdict (entget (cdr m))))
          (cad-probe--ep-dump-dictionary
            (strcat label "/" (car m) " xdict")
            (cad-probe--ep-xdict (entget (cdr m))) (1- depth)))))))

(defun cad-probe--ep-dump-xdict (label data / x)
  (setq x (cad-probe--ep-xdict data))
  (if x
    (cad-probe--ep-dump-dictionary (strcat "xdict: " label) x 2)
    (cad-probe-capture "entget-pointers" (strcat "xdict: " label)
      (function (lambda () "none")))))

(defun cad-probe-run-default-object-probes ( / nod rec tbl)
  (setq nod (namedobjdict))
  ;; The NOD's entries the CAD made, two levels deep.
  (foreach m (cad-probe--ep-members nod)
    (if (not (wcmatch (car m) "PRORD*,PRPTR*"))
      (if (cad-probe--ep-dictionary-p (cdr m))
        (cad-probe--ep-dump-dictionary (strcat "defaults: " (car m)) (cdr m) 2)
        (cad-probe-capture "entget-pointers" (strcat "defaults: " (car m))
          (function (lambda () (cad-probe--ep-dump (entget (cdr m)))))))))
  ;; Extension dictionaries.
  (cad-probe--ep-dump-xdict "NOD" (entget nod))
  (cad-probe--ep-dump-xdict "layer 0" (entget (tblobjname "LAYER" "0")))
  ;; *Model_Space's BLOCK_RECORD (the BLOCK entity's 330) and its TABLE.
  (setq rec (cdr (assoc 330 (entget (tblobjname "BLOCK" "*Model_Space")))))
  (if (= (type rec) 'ENAME)
    (progn
      (cad-probe--ep-dump-xdict "*Model_Space BLOCK_RECORD" (entget rec))
      (setq tbl (cdr (assoc 330 (entget rec))))
      (if (= (type tbl) 'ENAME)
        (cad-probe--ep-dump-xdict "BLOCK_RECORD TABLE" (entget tbl)))))
  ;; The records' and BLOCKs' full values (section 11 gave their codes):
  ;; the layer's 348, the BLOCK's 71, the BLOCK_RECORD's 360 / 340 / BLKREFS
  ;; -- the probe's own block (section 4) has an INSERT.
  (cad-probe-capture "entget-pointers" "values: layer 0"
    (function (lambda () (cad-probe--ep-dump (entget (tblobjname "LAYER" "0"))))))
  (foreach name (list "*Model_Space" "*Paper_Space" blk)
    (if (and name (tblobjname "BLOCK" name))
      (progn
        (cad-probe-capture "entget-pointers" (strcat "values: BLOCK " name)
          (function (lambda () (cad-probe--ep-dump (entget (tblobjname "BLOCK" name))))))
        (cad-probe-capture "entget-pointers" (strcat "values: BLOCK_RECORD " name)
          (function (lambda ()
            (cad-probe--ep-dump
              (entget (cdr (assoc 330 (entget (tblobjname "BLOCK" name))))))))))))
  (foreach spec '(("LAYER" "0") ("LTYPE" "Continuous") ("STYLE" "Standard")
                  ("DIMSTYLE" "Standard") ("APPID" "ACAD") ("VPORT" "*Active"))
    (setq rec (tblobjname (car spec) (cadr spec)))
    (setq tbl (if rec (cdr (assoc 330 (entget rec)))))
    (if (= (type tbl) 'ENAME)
      (cad-probe--ep-dump-xdict (strcat (car spec) " TABLE") (entget tbl))))
  (princ))

;;; 13. ENDBLK (an empty block's -2 names it; does the walk of a block end on
;;; it?) and where the CAD keeps its templates (alfe-template-option: a
;;; probe run on a drawing of the CAD's own template, not empty.dwg).

(defun cad-probe-run-endblk-and-template-probes ()
  (cad-probe-capture "entget-pointers" "endblk: *Paper_Space -2"
    (function (lambda ( / e)
      (setq e (cdr (assoc -2 (entget (tblobjname "BLOCK" "*Paper_Space")))))
      (if e (cad-probe--ep-dump (entget e)) "no -2"))))
  (if blk
    (progn
      (cad-probe-capture "entget-pointers" "endblk: walk of the probe's block"
        (function (lambda ( / e out n)
          (setq e (cdr (assoc -2 (entget (tblobjname "BLOCK" blk)))) out "" n 0)
          (while (and e (< n 50))
            (setq out (strcat out (cdr (assoc 0 (entget e))) " ") e (entnext e) n (1+ n)))
          out)))
      (cad-probe-capture "entget-pointers" "endblk: the walk's last entry"
        (function (lambda ( / e last n)
          (setq e (cdr (assoc -2 (entget (tblobjname "BLOCK" blk)))) n 0)
          (while (and e (< n 50)) (setq last e e (entnext e) n (1+ n)))
          (if last (cad-probe--ep-dump (entget last)) "none"))))))
  (cad-probe-capture "entget-pointers" "type of a vl-catch-all-apply error"
    (function (lambda ()
      (vl-prin1-to-string (type (vl-catch-all-apply (quote /) (list 1 0)))))))
  (cad-probe-capture "entget-pointers" "templates: where"
    (function (lambda ( / out dir)
      (setq out "")
      (foreach v '("BASEFILE" "MEASUREINIT" "MEASUREMENT")
        (setq out (strcat out v "="
                          (vl-prin1-to-string (vl-catch-all-apply (quote getvar) (list v)))
                          " ")))
      (setq out (strcat out "QnewTemplate=" (vl-prin1-to-string (getenv "QnewTemplate")) " "))
      (vl-load-com)
      (setq dir (vl-catch-all-apply
                  (function (lambda ()
                    (vla-get-TemplateDwgPath
                      (vla-get-Files (vla-get-Preferences (vlax-get-acad-object))))))))
      (setq out (strcat out "TemplateDwgPath="
                        (if (vl-catch-all-error-p dir)
                          (vl-catch-all-error-message dir)
                          (vl-prin1-to-string dir))))
      (if (and (not (vl-catch-all-error-p dir)) (= (type dir) 'STR))
        (setq out (strcat out " files=" (vl-prin1-to-string (vl-directory-files dir "*.dwt" 1)))))
      out)))
  (princ))
