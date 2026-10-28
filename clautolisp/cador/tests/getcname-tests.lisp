(in-package #:clautolisp.cador.tests)

(in-suite cador-suite)

;;;; GETCNAME, as measured on French installs by the getcname probe
;;;; (2026-10-26: AutoCAD 2022 job 17460836644, BricsCAD V25 Windows
;;;; 17460836643). cadtui-locale-probe-getcname.

(defparameter *getcname-measured*
  ;; input  AutoCAD 2022  BricsCAD V25   (NIL: nil)
  `(("_LINE" "LIGNE" "LIGNE") ("_line" "LIGNE" "LIGNE") ("_Line" "LIGNE" "LIGNE")
    ("LIGNE" "_LINE" "_LINE") ("ligne" "_LINE" "_LINE")
    ("LINE" nil nil) ("line" nil nil) ("_LIGNE" nil nil)
    ("STRETCH" nil nil) ("ETIRER" "_STRETCH" "_STRETCH") ("_ETIRER" nil nil)
    (,(concatenate 'string (string (code-char 201)) "TIRER") "_STRETCH" nil)
    ("_ZOOM" "ZOOM" "ZOOM") ("ZOOM" "_ZOOM" "_ZOOM")
    ("'ZOOM" "_ZOOM" nil) ("'_ZOOM" "_ZOOM" nil) ("_'ZOOM" "ZOOM" nil)
    (".LINE" nil nil) ("_.LINE" "LIGNE" nil) ("._LINE" nil nil) (".LIGNE" "_LINE" nil)
    ("NOSUCHCMD" nil nil) ("_NOSUCHCMD" nil nil) ("" nil nil) ("_" nil nil)
    ("GETCNAMEPROBE" nil nil) ("_GETCNAMEPROBE" nil nil)
    ("_3DORBIT" "ORBITE3D" nil) ("3DORBIT" nil nil)
    ;; each product's own command set
    ("_RECTANG" nil "RECTANG") ("_BLEND" "FUSIONNER" nil)))

(test getcname-follows-each-product-under-fr-fr
  (loop for (input autocad bricscad) in *getcname-measured*
        do (is (equal autocad (clautolisp.cador::cador-getcname input :autocad "fr_FR"))
               "AutoCAD ~S" input)
           (is (equal bricscad (clautolisp.cador::cador-getcname input :bricscad "fr_FR"))
               "BricsCAD ~S" input)))

(test getcname-bricscad-v26-spells-stretch-with-its-accent
  ;; getcname probe, BricsCAD V26 macOS (job 17538633594): "_STRETCH" ->
  ;; "ÉTIRER" there, "ETIRER" on V25 (the table's)
  (let ((e-acute (concatenate 'string (string (code-char 201)) "TIRER")))
    (is (equal e-acute (clautolisp.cador::cador-getcname "_STRETCH" :bricscad "fr_FR" 26)))
    (is (equal "_STRETCH" (clautolisp.cador::cador-getcname e-acute :bricscad "fr_FR" 26)))
    (is (null (clautolisp.cador::cador-getcname "ETIRER" :bricscad "fr_FR" 26)))
    (is (equal "ETIRER" (clautolisp.cador::cador-getcname "_STRETCH" :bricscad "fr_FR" 25)))
    (is (equal "ETIRER" (clautolisp.cador::cador-getcname "_STRETCH" :bricscad "fr_FR")))
    ;; the other commands as the table has them
    (is (equal "LIGNE" (clautolisp.cador::cador-getcname "_LINE" :bricscad "fr_FR" 26)))))

(test getcname-under-a-locale-without-a-table-is-the-identity
  (dolist (locale '(nil "en_US" "C"))
    (is (equal "LINE" (clautolisp.cador::cador-getcname "_LINE" :autocad locale)))
    (is (equal "_LINE" (clautolisp.cador::cador-getcname "line" :autocad locale)))
    (is (null (clautolisp.cador::cador-getcname "LIGNE" :autocad locale))))
  ;; a language finds its territory's table
  (is (equal "LIGNE" (clautolisp.cador::cador-getcname "_LINE" :bricscad "fr"))))

(test getcname-builtin-takes-a-string
  ;; (getcname 1) / (getcname nil): bad argument type on both products
  (fiveam:signals error (clautolisp.autolisp-builtins-core::builtin-getcname 1))
  (fiveam:signals error (clautolisp.autolisp-builtins-core::builtin-getcname nil)))
