;; -*- coding:us-ascii -*-
;; Sonde catalogue : comportement des fonctions AutoLISP sur entrees limites,
;; par moteur. Chaque cas est une chaine lue par READ puis evaluee sous
;; vl-catch-all-apply ; on journalise le resultat (VALUE ou ERROR + message)
;; et ERRNO. Une ligne BEGIN precede chaque cas pour localiser un plantage.
;; Le script appelant definit *probe-dir* et *probe-start* avant le LOAD.

(if (not *probe-start*) (setq *probe-start* 0))
(setq *pcat-log* (strcat *probe-dir* "/catalogue-log.txt"))

(defun pcat-ascii (line / out c)
  ;; remplace tout caractere hors ASCII par \U+XXXX (clautolisp refuse
  ;; d'ecrire un caractere non representable dans l'encodage du fichier)
  (setq out "")
  (foreach c (vl-string->list line)
    (setq out (strcat out (if (and (>= c 32) (< c 127)) (chr c) (strcat "\\U+" (itoa c))))))
  out)

(defun pcat-write (line / f r)
  (setq f (open *pcat-log* "a"))
  (if f
    (progn
      (setq r (vl-catch-all-apply 'write-line (list line f)))
      (if (vl-catch-all-error-p r)
        (write-line (strcat (pcat-ascii line) " ; WRITE-LINE-ERROR " (pcat-ascii (vl-catch-all-error-message r))) f))
      (close f))))

(defun pcat-fix (sym src / r)
  (setq r (vl-catch-all-apply 'eval (list (read src))))
  (if (vl-catch-all-error-p r)
    (progn (pcat-write (strcat "FIXTURE " (vl-symbol-name sym) " ERROR " (vl-catch-all-error-message r))) (set sym nil))
    (set sym r)))

(defun pcat-fixtures ()
  (pcat-fix '*com* "(vl-load-com)")    ; sans lui, AutoCAD n'a ni vlax-curve-* ni vlax-*
  (pcat-fix '*doc* "(vla-get-activedocument (vlax-get-acad-object))")
  (pcat-fix '*blocks* "(vla-get-blocks *doc*)")
  (pcat-fix '*l* "(entmakex '((0 . \"LINE\") (10 0.0 0.0 0.0) (11 10.0 0.0 0.0)))")
  (pcat-fix '*a* "(entmakex '((0 . \"ARC\") (10 0.0 0.0 0.0) (40 . 10.0) (50 . 0.0) (51 . 1.5)))")
  (pcat-fix '*c* "(entmakex '((0 . \"CIRCLE\") (10 0.0 0.0 0.0) (40 . 5.0)))")
  (pcat-fix '*p* "(entmakex '((0 . \"LWPOLYLINE\") (100 . \"AcDbEntity\") (100 . \"AcDbPolyline\") (90 . 3) (70 . 0) (10 0.0 0.0) (10 10.0 0.0) (10 10.0 10.0)))")
  (pcat-fix '*pz* "(entmakex '((0 . \"LWPOLYLINE\") (100 . \"AcDbEntity\") (100 . \"AcDbPolyline\") (90 . 2) (70 . 0) (38 . 5.0) (10 0.0 0.0) (10 10.0 0.0)))")
  (pcat-fix '*t* "(entmakex '((0 . \"TEXT\") (10 0.0 0.0 0.0) (40 . 1.0) (1 . \"txt\")))")
  (pcat-fix '*dead* "(entmakex '((0 . \"LINE\") (10 0.0 0.0 0.0) (11 1.0 1.0 0.0)))")
  (pcat-fix '*deadok* "(entdel *dead*)")
  (pcat-fix '*lo* "(vlax-ename->vla-object *l*)")
  (pcat-fix '*ss* "(ssadd *l* (ssadd))")
  (pcat-fix '*empty-sa* "(vlax-make-safearray vlax-vbDouble '(0 . -1))"))

(setq *pcat-cases* '(
  ;; --- arithmetique
  "(/ 1 0)" "(/ 1.0 0)" "(/ 1 0.0)" "(/ 0 0)" "(/ 0.0 0.0)" "(rem 1 0)" "(rem 1.0 0.0)"
  "(sqrt -1)" "(sqrt -1.0)" "(log 0)" "(log -1)" "(log 0.0)" "(expt 0 -1)" "(expt 0.0 -1)"
  "(expt -8.0 (/ 1.0 3))" "(atan 0 0)" "(atan 0.0 0.0)" "(exp 1000)" "(exp -1000)" "(fix 1e20)"
  "(fix -1e20)" "(+ 2147483647 1)" "(* 65536 65536)" "(- -2147483648 1)" "(abs -2147483648)"
  "(1+ nil)" "(+ 1 nil)" "(+ 1 \"a\")" "(* \"a\" 1)" "(abs nil)" "(max)" "(min)" "(max 1 nil)"
  "(min nil 1)" "(gcd 0 0)" "(gcd 1.5 2)" "(lsh 1 40)" "(lsh 1 -40)" "(~ nil)" "(~ 1.5)"
  "(float nil)" "(boole 99 1 1)" "(minusp nil)" "(zerop nil)" "(numberp nil)" "(+)" "(-)" "(/)"
  "(/ 5)" "(/ 0)" "(cos 1e300)" "(sin nil)"
  ;; --- conversions
  "(itoa 1.5)" "(itoa nil)" "(atoi nil)" "(atoi \"abc\")" "(atoi \"12abc\")" "(atoi \"99999999999\")"
  "(atof nil)" "(atof \"x\")" "(atof \"1e999\")" "(rtos nil)" "(rtos 1.0 9)" "(rtos 1.0 2 -1)"
  "(rtos 1.0 2 99)" "(distof \"abc\")" "(distof nil)" "(distof \"1\" 9)" "(angtof \"abc\")"
  "(angtos nil)" "(angtos 1.0 9)" "(cvunit 1 \"inch\" \"nosuchunit\")" "(cvunit nil \"inch\" \"cm\")"
  ;; --- comparaisons
  "(< 1 \"a\")" "(< 'a 'b)" "(= nil)" "(<)" "(< nil 1)" "(> nil 1 \"a\")" "(>= 'a nil)"
  "(= 1 \"1\")" "(eq)" "(equal 1)" "(equal 1.0 1.05 nil)" "(equal 1.0 1.05 \"x\")"
  ;; --- chaines
  "(substr \"abc\" 0)" "(substr \"abc\" 5)" "(substr \"abc\" 2 -1)" "(substr \"abc\" 2 99)"
  "(substr nil 1)" "(substr \"abc\" nil)" "(strlen nil)" "(strlen)" "(strlen \"a\" nil)"
  "(strcat)" "(strcat nil)" "(strcat \"a\" 1)" "(strcase nil)" "(strcase \"a\" 1)"
  "(ascii \"\")" "(ascii nil)" "(chr 0)" "(chr 300)" "(chr -1)" "(chr 65.5)" "(chr nil)"
  "(vl-string-search nil \"a\")" "(vl-string-search \"a\" nil)" "(vl-string-search \"\" \"abc\")"
  "(vl-string-search \"a\" \"abc\" 99)" "(vl-string-search \"a\" \"abc\" -1)"
  "(vl-string-subst nil \"a\" \"b\")" "(vl-string-subst \"x\" \"\" \"abc\")"
  "(vl-string-translate \"ab\" \"x\" \"aabb\")" "(vl-string-trim nil \"a\")"
  "(vl-string-position 999 \"abc\")" "(vl-string-position nil \"abc\")"
  "(vl-string-elt \"abc\" 9)" "(vl-string-elt \"abc\" -1)" "(vl-string->list nil)"
  "(vl-list->string '(65 nil))" "(vl-list->string '(300))" "(wcmatch nil \"*\")"
  "(wcmatch \"a\" nil)" "(wcmatch \"a\" \"\")" "(wcmatch \"\" \"*\")" "(wcmatch \"a\" \"[\")"
  "(read \"\")" "(read \")\")" "(read \"(a\")" "(read \"a b\")" "(read \"'\")" "(read nil)"
  "(read \"1e999\")" "(read \"#\")" "(vl-prin1-to-string)" "(snvalid nil)" "(snvalid \"a*b\")"
  "(xstrcase nil)" "(vl-string-left-trim \"\" \"aa\")" "(vl-string-mismatch nil \"a\")"
  ;; --- listes
  "(car 1)" "(car \"a\")" "(cdr \"a\")" "(cadr '(1))" "(caddr 1)" "(nth -1 '(1 2))"
  "(nth 5 '(1 2))" "(nth nil '(1))" "(nth 1.5 '(1 2))" "(last nil)" "(last 1)" "(last '(1 . 2))"
  "(length 1)" "(length '(1 . 2))" "(length \"abc\")" "(reverse 1)" "(reverse '(1 . 2))"
  "(append 1 '(2))" "(append '(1) 2)" "(append '(1 . 2) '(3))" "(assoc 1 1)" "(assoc 1 '(1 2))"
  "(cons 1)" "(cons)" "(member 1 2)" "(vl-position 1 2)" "(mapcar '+ '(1 2) '(1))"
  "(mapcar 'car 1)" "(mapcar 'car '(1))" "(mapcar nil '(1))" "(apply '+ 1)" "(apply '+ '(1 . 2))"
  "(apply 'nosuchfn '(1))" "(vl-sort 1 '<)" "(vl-sort '(2 1 nil) '<)" "(vl-sort '(\"b\" 1) '<)"
  "(vl-sort-i '(2 1) nil)" "(vl-remove 1 2)" "(vl-remove-if 'numberp 1)" "(subst 1 2 3)"
  "(list)" "(vl-list* 1)" "(vl-list*)" "(acad_strlsort nil)" "(acad_strlsort '(1 2))"
  "(acad_strlsort '(\"b\" nil))" "(vl-every 'numberp 1)" "(vl-some 'numberp 1)"
  "(vl-member-if 'numberp 1)" "(vl-consp)" "(listp)" "(nth 0 nil)" "(car nil)" "(assoc nil nil)"
  "(foreach x 1 x)" "(foreach x '(1 . 2) x)" "(repeat -1 1)" "(repeat 1.5 1)" "(repeat nil 1)"
  "(while)" "(if)" "(cond (1))" "(cond)" "(progn)" "(and)" "(or)" "(quote)"
  ;; --- symboles / evaluation
  "(eval 'pcat-unbound-var)" "(eval '(pcat-unbound-fn))" "(pcat-unbound-fn 1)" 
  "(set 1 1)" "(set \"x\" 1)" "(boundp 1)" "(boundp nil)" "(type)" "(atoms-family 2)"
  "(vl-symbol-value nil)" "(vl-symbol-value 1)" "(vl-symbol-name \"x\")" "(vl-symbolp)"
  "((lambda (x) x))" "((lambda (x) x) 1 2)" "((lambda () 1) 1)" "(defun)" "(defun 1 () 1)"
  "(function 1)" "(function pcat-unbound-fn)" "(vl-acad-defun 'pcat-unbound-fn)" "(type pcat-unbound-fn)"
  "(setq)" "(setq a)" "(setq 1 2)" "(lambda)" "(eval)" "(apply)" "(vl-catch-all-apply nil nil)"
  "(vl-catch-all-apply 'pcat-unbound-fn nil)" "(vl-catch-all-error-message 1)"
  "(vl-catch-all-error-p)" "(vl-catch-all-apply 'car '(1))"
  ;; --- appel d'une fonction recue en parametre
  "((lambda (g) (g)) (function (lambda () 1)))" "((lambda (g) (g)) (lambda () 1))"
  "((lambda (g) (g)) '(lambda () 1))" "((lambda (g) (apply g nil)) (function (lambda () 1)))"
  "((lambda (g) (apply g nil)) '(lambda () 1))" "((lambda (g) (g)) 'pcat-write)" "((lambda (g) (g 1)) '1+)"
  "(mapcar (function (lambda (x) x)) '(1))" "(mapcar '(lambda (x) x) '(1))" "(mapcar (lambda (x) x) '(1))"
  ;; --- controle / sortie
  "(exit)" "(quit)" "(exit 1)" "(vl-exit-with-error \"x\")" "(vl-exit-with-value 1)"
  "(error \"pcat-message\")" "(error 'sym)" "(error)" "(*error* \"x\")" "(vl-bt)"
  ;; --- geometrie
  "(polar nil 0 1)" "(polar '(0 0) nil 1)" "(polar '(0 0) 0 nil)" "(polar '(0) 0 1)"
  "(distance '(0 0) '(1))" "(distance '(0 0) '(1 1 1))" "(distance '(0 0 5) '(0 0))"
  "(distance nil '(1 1))" "(angle '(0 0) '(0 0))" "(angle nil '(1 1))"
  "(inters '(0 0) '(1 0) '(0 1) '(1 1))" "(inters '(0 0) '(1 0) '(2 1) '(2 2))"
  "(inters '(0 0) '(1 0) '(2 1) '(2 2) nil)" "(inters '(0 0) '(0 0) '(0 1) '(1 1))"
  "(inters nil '(1 1) '(0 1) '(1 0))" "(trans '(0 0 0) 0 99)" "(trans nil 0 1)"
  "(trans '(0 0 0) 0 *t*)" "(osnap '(0 0) \"_bogus\")" "(osnap nil \"_end\")"
  "(textbox nil)" "(textbox '((1 . \"a\")))"
  ;; --- entites / tables / variables
  "(entget nil)" "(entget \"x\")" "(entget *dead*)" "(entdel nil)" "(entdel *dead*)"
  "(entnext nil)" "(entnext \"x\")" "(entlast 1)" "(entmake nil)" "(entmake '((0 . \"BOGUS\")))"
  "(entmake '((0 . \"LINE\")))" "(entmakex '((0 . \"LINE\") (10 0.0 0.0 0.0)))"
  "(entmakex (list '(0 . \"LINE\") (cons 10 nil) '(11 5.0 5.0 0.0)))"
  "(entmakex '((0 . \"LINE\") (10 0.0 0.0 0.0) (11 1.0 1.0 0.0) (8 . \"\")))"
  "(entmakex '((0 . \"LINE\") (10 0.0 0.0 0.0) (11 1.0 1.0 0.0) (62 . 999)))"
  "(entmakex '((0 . \"INSERT\") (2 . \"PCAT_NO_BLOCK\") (10 0.0 0.0 0.0)))"
  "(entmakex '((0 . \"CIRCLE\") (10 0.0 0.0 0.0) (40 . -1.0)))"
  "(entmakex '((0 . \"TEXT\") (10 0.0 0.0 0.0) (40 . 1.0) (1 . \"x\") (7 . \"PCAT_NO_STYLE\")))"
  "(entmod nil)" "(entmod '((0 . \"LINE\")))"
  "(entmod (subst '(8 . \"\") (assoc 8 (entget *l*)) (entget *l*)))"
  "(entmod (subst '(62 . 999) '(62 . 999) (append (entget *l*) '((62 . 999)))))"
  "(entmod (list (cons -1 *dead*) '(8 . \"0\")))" "(entupd nil)" "(entupd *dead*)"
  "(handent \"ZZZZZZ\")" "(handent nil)" "(handent \"\")" "(ssget \"X\" '((0 . \"PCATNOTYPE\")))"
  "(ssget \"BOGUS\")" "(ssname nil 0)" "(ssname *ss* 99)" "(ssname *ss* -1)" "(sslength nil)"
  "(ssadd 1)" "(ssadd *dead* (ssadd))" "(ssdel *t* *ss*)" "(ssmemb nil *ss*)"
  "(tblsearch \"LAYER\" nil)" "(tblsearch \"BOGUS\" \"0\")" "(tblsearch \"LAYER\" \"PCAT_NOPE\")"
  "(tblobjname \"LAYER\" \"PCAT_NOPE\")" "(tblnext \"BOGUS\")" "(dictsearch nil \"x\")"
  "(dictsearch (namedobjdict) nil)" "(dictsearch (namedobjdict) \"PCAT_NOPE\")"
  "(dictnext nil)" "(dictremove (namedobjdict) \"PCAT_NOPE\")" "(regapp nil)" "(regapp \"\")"
  "(regapp \"A B\")" "(getvar \"PCATNOSUCHVAR\")" "(getvar nil)" "(getvar 1)"
  "(setvar \"PCATNOSUCHVAR\" 1)" "(setvar \"OSMODE\" \"a\")" "(setvar \"OSMODE\" 99999)"
  "(setvar \"OSMODE\" -1)" "(setvar \"CLAYER\" \"PCAT_NOPE_LAYER\")" "(setvar \"DWGNAME\" \"x\")"
  "(setvar \"CECOLOR\" \"999\")" "(setvar \"LUPREC\" 99)" "(getenv nil)" "(getenv \"PCAT_NO_ENV\")"
  "(setenv nil \"x\")" "(getcfg nil)" "(getcfg \"Bogus/x\")"
  ;; --- vlax-curve
  "(vlax-curve-getPointAtParam *l* 25.0)" "(vlax-curve-getPointAtParam *l* -1.0)"
  "(vlax-curve-getPointAtDist *l* 25.0)" "(vlax-curve-getPointAtDist *l* -1.0)"
  "(vlax-curve-getParamAtPoint *l* '(5.0 3.0 0.0))" "(vlax-curve-getParamAtPoint *l* '(5.0 3.0))"
  "(vlax-curve-getDistAtPoint *l* '(5.0 3.0 0.0))" "(vlax-curve-getParamAtDist *l* 25.0)"
  "(vlax-curve-getDistAtParam *l* 25.0)" "(vlax-curve-getParamAtPoint *p* '(5.0 3.0 0.0))"
  "(vlax-curve-getDistAtPoint *p* '(5.0 3.0 0.0))" "(vlax-curve-getParamAtPoint *pz* '(5.0 3.0 0.0))"
  "(vlax-curve-getParamAtPoint *pz* '(5.0 0.0 0.0))" "(vlax-curve-getParamAtPoint *pz* '(5.0 0.0))"
  "(vlax-curve-getParamAtDist *p* 99.0)" "(vlax-curve-getPointAtParam *p* 5.0)"
  "(vlax-curve-getParamAtPoint *a* '(0.0 0.0 0.0))" "(vlax-curve-getParamAtDist *a* 99.0)"
  "(vlax-curve-getDistAtParam *a* 0.0)" "(vlax-curve-getDistAtParam *a* 3.0)"
  "(vlax-curve-getPointAtParam *a* 3.0)" "(vlax-curve-getParamAtDist *c* 99.0)"
  "(vlax-curve-getParamAtPoint *c* '(0.0 0.0 0.0))" "(vlax-curve-getClosestPointTo *l* nil)"
  "(vlax-curve-getClosestPointTo *l* '(20.0 5.0 0.0) T)" "(vlax-curve-getClosestPointTo *l* '(20.0 5.0))"
  "(vlax-curve-getFirstDeriv *l* 25.0)" "(vlax-curve-getSecondDeriv *l* 25.0)"
  "(vlax-curve-getEndParam *t*)" "(vlax-curve-getEndParam nil)" "(vlax-curve-getEndParam *dead*)"
  "(vlax-curve-getArea *l*)" "(vlax-curve-getArea *t*)" "(vlax-curve-isClosed *t*)"
  "(vlax-curve-getStartPoint *t*)" "(vlax-curve-getPointAtDist *l* nil)"
  "(vlax-curve-getParamAtPoint *l* nil)" "(vlax-curve-getEndParam 'x)"
  ;; --- command
  "(command \"_PCATNOSUCHCMD\")" "(command-s \"_PCATNOSUCHCMD\")" "(vl-cmdf \"_PCATNOSUCHCMD\")"
  "(command \"_LINE\" \"pas-un-point\" \"\")" "(command-s \"_LINE\" \"pas-un-point\" \"\")"
  "(vl-cmdf \"_LINE\" \"pas-un-point\" \"\")" "(command \"_LINE\" nil)" "(command-s \"_LINE\" '(0 0) nil)"
  "(command \"_LAYER\" \"_S\" \"PCAT_NOPE_LAYER\" \"\")" "(command-s \"_LAYER\" \"_S\" \"PCAT_NOPE_LAYER\" \"\")"
  "(command \"_CIRCLE\" '(0 0) -5)" "(command-s \"_CIRCLE\" '(0 0) -5)" "(vl-cmdf \"_CIRCLE\" '(0 0) -5)"
  "(command 1 2)" "(command-s)" "(command)" "(getvar \"CMDACTIVE\")"
  ;; --- ActiveX
  "(vla-item *blocks* \"PCAT_NO_BLOCK\")" "(vla-item *blocks* 99999)" "(vlax-ename->vla-object nil)"
  "(vlax-ename->vla-object *dead*)" "(vla-get-name nil)" "(vlax-get-property *lo* 'PcatBogus)"
  "(vlax-put-property *lo* 'Color \"red\")" "(vlax-invoke-method *lo* 'PcatBogus)"
  "(vla-get-effectivename *lo*)" "(vla-get-textstring *lo*)" "(vlax-property-available-p *lo* 'PcatBogus)"
  "(vlax-method-applicable-p *lo* 'PcatBogus)" "(vlax-variant-value nil)" "(vlax-variant-value 1)"
  "(vlax-safearray->list nil)" "(vlax-safearray->list *empty-sa*)" "(vlax-make-safearray vlax-vbDouble '(0 . -1))" "(vlax-make-safearray vlax-vbDouble '(0 . 0))" "(vlax-make-safearray vlax-vbDouble '(0 . -2))"
  "(vlax-make-variant nil)" "(vlax-ldata-get \"pcat\" \"nokey\")" "(vlax-ldata-get nil nil)"
  "(vlax-erased-p *lo*)" "(vlax-erased-p nil)" "(vlax-read-enabled-p nil)" "(vlax-get-acad-object 1)"
  "(vla-put-layer *lo* \"PCAT_NOPE_LAYER\")" "(vla-put-color *lo* 999)" "(vlax-release-object nil)"
  "(vlax-tmatrix nil)" "(vlax-3d-point nil)" "(vlax-3d-point '(1))" "(vla-get-blocks nil)"
  "(vla-add *blocks* (vlax-3d-point '(0 0 0)) \"\")" "(vlax-get *lo* 'PcatBogus)"
  "(vlax-invoke *lo* 'PcatBogus)" "(vlax-dump-object nil)" "(vla-getboundingbox *lo* 'a 'b)"
  ;; --- fichiers
  "(open nil \"r\")" "(open \"Z:/pcat/nonexistent/x.txt\" \"r\")" "(open \"pcat.txt\" \"z\")"
  "(open \"Z:/pcat/nonexistent/x.txt\" \"w\")" "(read-line nil)" "(read-char nil)" "(close nil)"
  "(write-line 1 nil)" "(write-line \"x\" 1)" "(findfile nil)" "(findfile \"\")"
  "(findfile \"pcat_nonexistent.lsp\")" "(load \"pcat_nonexistent_zz\")"
  "(load \"pcat_nonexistent_zz\" 'pcat-fail)" "(load nil)" "(vl-file-delete \"pcat_nonexistent\")"
  "(vl-file-delete nil)" "(vl-file-size \"pcat_nonexistent\")" "(vl-file-rename \"pcat_a\" \"pcat_b\")"
  "(vl-file-copy \"pcat_a\" \"pcat_b\")" "(vl-directory-files \"Z:/pcat/nonexistent\")"
  "(vl-directory-files nil nil)" "(vl-filename-base nil)" "(vl-filename-extension \"\")"
  "(vl-filename-directory nil)" "(vl-mkdir nil)" "(vl-file-directory-p nil)" "(vl-filename-mktemp nil nil nil)"
  ;; --- DCL (sans start_dialog)
  "(load_dialog \"pcat_nonexistent.dcl\")" "(load_dialog nil)" "(new_dialog \"pcat_nope\" 1)"
  "(new_dialog \"pcat_nope\" 99999)" "(set_tile \"x\" \"y\")" "(get_tile \"x\")" "(done_dialog)"
  "(unload_dialog 99999)" "(start_list \"x\")" "(add_list \"x\")" "(end_list)" "(mode_tile \"x\" 1)"
  "(action_tile \"x\" \"(princ)\")" "(get_attr \"x\" \"y\")" "(term_dialog)"
  ;; --- divers
  "(vl-registry-read \"HKEY_NOPE\\\\x\")" "(vl-registry-read nil)" "(startapp nil)"
  "(vl-propagate nil)" "(vl-bb-ref nil)" "(vl-doc-ref nil)" "(vlax-add-cmd nil nil)"
  "(arxload \"pcat_nonexistent\")" "(arxload \"pcat_nonexistent\" 'pcat-fail)" "(autoload nil nil)"
  "(menucmd nil)" "(menucmd \"Gbogus.ID_Nope=~\")" "(grtext -99 \"x\")" "(grdraw nil nil 1)"
  "(redraw *dead* 1)" "(alloc -1)" "(mem 1)" "(ver 1)" "(vl-get-resource \"pcat_nope\")"
  ;; --- ajout 2026-11-03 (en fin de liste pour garder les numeros) : bornes des entiers 32 bits
  "(- 2147483648)" "2147483648" "(type 2147483648)" "(type 2147483647)" "(- -2147483648)"
  "(- 0 -2147483648)" "(type -2147483648)" "(abs -2147483647)" "(- -2147483647 1)"
  "(type (- -2147483647 1))" "(* -1 -2147483648)" "(/ -2147483648 -1)" "(fix 2147483648.0)"
  "(fix 2147483647.0)" "(fix -2147483649.0)" "(1- -2147483648)" "(type (1- -2147483648))"
  "(atoi \"2147483648\")" "(itoa 2147483648)" "(rtos 2147483648 2 0)" "(rem 2147483648 7)"
  "(gcd 2147483648 6)" "(logand 2147483648 1)" "(lsh 1 31)" "(lsh 1 32)" "(~ 2147483647)"
  "(float 2147483648)" "(= 2147483648 2147483648.0)" "(eq 2147483648 2147483648)" "(numberp 2147483648)"
  ;; --- ajout 2026-11-03 : ecriture d'un caractere non representable dans l'encodage du fichier
  "(pcat-roundtrip (chr 233) nil)" "(pcat-roundtrip (chr 8364) nil)" "(pcat-roundtrip (chr 300) nil)"
  "(pcat-roundtrip (strcat \"a\" (chr 20013) \"b\") nil)" "(pcat-roundtrip (chr 300) \"utf8\")"
  "(pcat-roundtrip (chr 300) \"w,ccs=UTF-8\")" "(vl-prin1-to-string (chr 300))" "(vl-princ-to-string (chr 300))"
  "(strlen (chr 300))" "(ascii (chr 300))" "(vl-string->list (chr 8364))"
))

(defun pcat-roundtrip (str enc / path f w codes c)
  ;; ecrit STR (+ fin de ligne) avec (open path "w" [enc]) puis relit
  ;; le fichier en mode "r" et renvoie (resultat-write-line codes-relus)
  (setq path (strcat *probe-dir* "/roundtrip.txt"))
  (setq f (if enc
            (if (wcmatch enc "w,*") (open path enc) (open path "w" enc))
            (open path "w")))
  (setq w (vl-catch-all-apply 'write-line (list str f)))
  (close f)
  (setq w (if (vl-catch-all-error-p w) (list 'ERROR (vl-catch-all-error-message w)) w))
  (setq f (open path "r"))
  (while (setq c (read-char f)) (setq codes (cons c codes)))
  (close f)
  (list w (reverse codes)))

(defun pcat-printable (res / ty)
  ;; TYPE peut lui-meme echouer (clautolisp sur un entier hors plage)
  (setq ty (vl-catch-all-apply 'type (list res)))
  (cond ((vl-catch-all-error-p ty) (list 'TYPE-ERROR (vl-catch-all-error-message ty)))
        ((member ty '(ENAME VLA-OBJECT PICKSET)) ty)
        (t res)))

(defun pcat-run-case (i src / form res line)
  (pcat-write (strcat "BEGIN " (itoa i)))
  (vl-catch-all-apply (quote setvar) (list "ERRNO" 0))  ; ERRNO est en lecture seule sous clautolisp
  (setq form (vl-catch-all-apply 'read (list src)))
  (if (vl-catch-all-error-p form)
    (setq res (list 'READ-ERROR (vl-catch-all-error-message form)))
    (progn
      (setq res (vl-catch-all-apply 'eval (list form)))
      (setq res (if (vl-catch-all-error-p res)
                  (list 'ERROR (vl-catch-all-error-message res))
                  (list 'VALUE (pcat-printable res))))))
  ;; une commande restee active fausserait les cas suivants
  ;; (bit 1 seulement : le bit 4 signale le script en cours)
  (if (= 1 (logand (getvar "CMDACTIVE") 1)) (vl-catch-all-apply 'command-s nil))
  (pcat-write (strcat "CASE " (itoa i) " " src " => " (vl-prin1-to-string res)
                      " ; ERRNO=" (vl-prin1-to-string (getvar "ERRNO")))))

(defun c:PCAT (/ i)
  (pcat-fixtures)
  (pcat-write (strcat "=== PCAT " (vl-prin1-to-string (list (getvar "VENDORNAME") (getvar "ACADVER")
                                                            (getvar "PRODUCT") (getvar "LOCALE")))
                      " start=" (itoa *probe-start*)))
  (setq i 0)
  (foreach src *pcat-cases*
    (if (and (>= i *probe-start*) (/= src "")
             (not (member i *probe-skip*))
             (or (null *probe-only*) (member i *probe-only*)))
      (pcat-run-case i src))
    (setq i (1+ i)))
  (pcat-write "=== PCAT DONE")
  (princ))
(princ)
