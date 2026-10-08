(in-package #:clautolisp.cadtui.tests)

(in-suite cadtui-suite)

;;;; Phase 7: localisation — the LANG-gated lexical pre-pass.

(defun %muffled (thunk)
  "Run THUNK with warnings muffled (unknown-locale fallback warns by design)."
  (handler-bind ((warning #'muffle-warning)) (funcall thunk)))

(test local-and-international-names-are-bidirectional
  (is (string= "activer" (local-name "activate" "fr_FR" :verb)))
  (is (string= "activate" (international-name "activer" "fr_FR" :verb)))
  (is (string= "dessin" (local-name "drawing" "fr_FR" :keyword)))
  (is (string= "drawing" (international-name "dessin" "fr_FR" :keyword)))
  ;; identity fallback: unknown token / unknown locale passes through.
  (is (string= "wibble" (local-name "wibble" "fr_FR" :verb)))
  (is (string= "activate" (international-name "activate" "fr_FR" :verb)))
  (is (string= "activate" (local-name "activate" "xx_XX" :verb))))

(test resolve-locale-precedence-and-fallback
  (is (string= "fr_FR" (resolve-locale :cli "fr_FR" :lc-all "de_DE" :lang "es_ES")))
  (is (string= "de_DE" (resolve-locale :lc-all "de_DE" :lang "es_ES")))
  (is (string= "es_ES" (resolve-locale :lang "es_ES")))
  (is (string= "en" (resolve-locale)))
  ;; encoding/modifier is stripped.
  (is (string= "fr_FR" (resolve-locale :lang "fr_FR.UTF-8@euro")))
  ;; region -> language partial fallback (fr_CA has no dict, fr_FR does... but
  ;; the chain is fr_CA -> fr; fr is unregistered, so this one falls to en).
  (is (string= "en" (%muffled (lambda () (resolve-locale :cli "zz_ZZ")))))
  ;; a registered language-only locale is honoured via the chain.
  (register-locale-dictionary "fr" :verb '(("activate" . "activer")))
  (is (string= "fr" (resolve-locale :cli "fr_CA"))))

(test localise-meta-line-canonicalises-tokens
  ;; the spec's worked equivalence: fr/de/es all canonicalise to English.
  (is (string= "activate(drawing(\"Dessin1.dwg\"))"
               (localise-meta-line "activer(dessin(\"Dessin1.dwg\"))" "fr_FR")))
  (is (string= "activate(drawing(\"Dessin1.dwg\"))"
               (localise-meta-line "aktivieren(Zeichnung(\"Dessin1.dwg\"))" "de_DE")))
  (is (string= "activate(drawing(\"Dessin1.dwg\"))"
               (localise-meta-line "activar(dibujo(\"Dessin1.dwg\"))" "es_ES")))
  ;; string literals are never translated (dessin inside quotes stays).
  (is (string= "dump(drawing:\"le dessin\")"
               (localise-meta-line "lister(dessin:\"le dessin\")" "fr_FR")))
  ;; role[i] and option keywords translate; numbers/punctuation pass through.
  (is (string= "dump(drawings[2], size: 3)"
               (localise-meta-line "lister(dessins[2], taille: 3)" "fr_FR")))
  ;; en is the identity locale.
  (is (string= "activate(drawings[1])"
               (localise-meta-line "activate(drawings[1])" "en"))))

(test underscore-forces-the-international-form
  ;; _activate always works, even under fr_FR (the _ is dropped, no lookup).
  (is (string= "activate(drawings[2])"
               (localise-meta-line "_activate(drawings[2])" "fr_FR")))
  ;; a plain international token still passes through under a locale.
  (is (string= "activate(drawings[2])"
               (localise-meta-line "activate(drawings[2])" "fr_FR"))))

(test interpret-line-honours-the-active-locale
  (let ((app (make-application-tree))
        (d1 (make-instance 'ui-drawing :key "a.dwg"))
        (d2 (make-instance 'ui-drawing :key "b.dwg")))
    (add-child app d1)
    (add-child app d2)
    (let ((*current-locale* "fr_FR"))
      (let ((r (interpret-line "=activer(dessins[2])" app)))
        (is (eq :ok (command-result-status r)))
        ;; drawings[1] (active-drawing) is now b.dwg.
        (is (eq d2 (resolve-target app "drawings[1]")))))))

(test cad-command-category-is-a-first-class-dictionary
  ;; the three CAD dictionaries (command / option-keyword / alias) are separate
  ;; categories on the same generic engine (spec "Trois dictionnaires distincts").
  ;; a throwaway locale distinct from the unknown-locale ("zz_ZZ") the fallback
  ;; tests rely on staying unregistered.
  (register-locale-dictionary "zz_CMD" :command '(("_LINE" . "LIGNE_ZZ")))
  (is (string= "LIGNE_ZZ" (local-name "_LINE" "zz_CMD" :command)))
  (is (string= "_LINE" (international-name "LIGNE_ZZ" "zz_CMD" :command)))
  ;; a missing command falls back to the international form.
  (is (string= "_ERASE" (local-name "_ERASE" "zz_CMD" :command))))

(test fr-command-dictionary-carries-real-harvested-names
  ;; the shipped fr_FR command.sexp is the getcname harvest off a French
  ;; BricsCAD (107 commands). Assert ASCII-stable entries both ways.
  (is (string= "LIGNE"   (local-name "_LINE" "fr_FR" :command)))
  (is (string= "OUVRIR"  (local-name "_OPEN" "fr_FR" :command)))
  (is (string= "EFFACER" (local-name "_ERASE" "fr_FR" :command)))
  (is (string= "CALQUE"  (local-name "_LAYER" "fr_FR" :command)))
  (is (string= "_LINE"   (international-name "LIGNE" "fr_FR" :command)))
  ;; a command not in the dictionary falls back to the international form.
  (is (string= "_FOOBARBAZ" (local-name "_FOOBARBAZ" "fr_FR" :command))))

(test fr-alias-dictionary-carries-real-harvested-aliases
  ;; the shipped fr_FR alias.sexp is the .pgp harvest off a French AutoCAD
  ;; (acad.pgp): keyboard alias -> localised command name.
  (is (string= "LIGNE" (local-name "L" "fr_FR" :alias)))
  (is (string= "ZOOM"  (local-name "Z" "fr_FR" :alias)))
  (is (string= "COPIER" (local-name "CP" "fr_FR" :alias)))
  ;; an unknown alias falls back to itself (never _-prefixed — aliases are local).
  (is (string= "ZZQ" (local-name "ZZQ" "fr_FR" :alias))))

(test locale-data-loads-from-the-shipped-sexp-tree
  ;; the dictionaries are DATA files (spec §Format des dictionnaires): the loader
  ;; reads cadtui/data/locale/<locale>/<category>.sexp, and the shipped fr_FR
  ;; verb dictionary is present (baked in at build; re-loadable at runtime).
  (let ((dir (asdf:system-relative-pathname "clautolisp/cadtui"
                                            "cadtui/data/locale/")))
    (is (plusp (load-locale-data-from-directory dir))))
  (is (string= "activer" (local-name "activate" "fr_FR" :verb)))
  (is (string= "dessin" (local-name "drawing" "fr_FR" :keyword))))

(test locale-verb-switches-the-active-locale
  (let ((*current-locale* "en"))
    (let ((r (interpret-line "=locale(fr_FR)" (make-application-tree))))
      (is (eq :ok (command-result-status r)))
      (is (string= "fr_FR" *current-locale*))
      (is (string= "fr_FR" (command-result-data r))))
    ;; an unknown locale falls back to en (warning muffled).
    (%muffled
     (lambda ()
       (interpret-line "=locale(zz_ZZ)" (make-application-tree))))
    (is (string= "en" *current-locale*))))

;;;; The :option-keyword dictionary (cadtui-locale-option-keywords.issue): the
;;;; fr_FR harvest off a French AutoCAD 2022 and a French BricsCAD V25, paired
;;;; with the vendors' English command references, PER PRODUCT.

(test option-keyword-abbreviation-reads-the-prompt-capitals
  (is (string= "N"   (option-keyword-abbreviation "aNnuler")))
  (is (string= "AN"  (option-keyword-abbreviation "ANgle")))
  (is (string= "O"   (option-keyword-abbreviation "mOde")))
  (is (string= "R"   (option-keyword-abbreviation "zoom aRrière")))
  (is (string= "PA"  (option-keyword-abbreviation "PAramètres raccord...")))
  ;; a parenthesised all-capitals abbreviation wins over the word's capitals.
  (is (string= "ET"  (option-keyword-abbreviation "étendu (ET)")))
  (is (string= "?"   (option-keyword-abbreviation "sélectionner les options (?)")))
  ;; a lower-case parenthesis is not an abbreviation.
  (is (string= "É"   (option-keyword-abbreviation "Échelle (nx/nxp)")))
  ;; no capital: the keyword must be typed whole.
  (is (string= "nx"  (option-keyword-abbreviation "nx"))))

(test fr-option-keywords-resolve-per-product-autocad
  ;; AutoCAD 2022 fr: OFFSET [Par/Effacer/Calque], CHAMFER [aNnuler/.../mUltiple].
  (is (string= "Through" (international-option-keyword "_OFFSET" "Par" "fr_FR" :product :autocad)))
  (is (string= "Erase"   (international-option-keyword "_OFFSET" "effacer" "fr_FR" :product :autocad)))
  (is (string= "Layer"   (international-option-keyword "OFFSET" "Calque" "fr_FR" :product :autocad)))
  (is (string= "Undo"    (international-option-keyword "_CHAMFER" "aNnuler" "fr_FR" :product :autocad)))
  (is (string= "Distance" (international-option-keyword "_CHAMFER" "Ecart" "fr_FR" :product :autocad)))
  (is (string= "Trim"    (international-option-keyword "_FILLET" "Ajuster" "fr_FR" :product :autocad)))
  (is (string= "Mode"    (international-option-keyword "_TRIM" "mOde" "fr_FR" :product :autocad)))
  ;; abbreviations: the capitals of the local keyword.
  (is (string= "Undo"     (international-option-keyword "_CHAMFER" "N" "fr_FR" :product :autocad)))
  (is (string= "Angle"    (international-option-keyword "_CHAMFER" "an" "fr_FR" :product :autocad)))
  (is (string= "Trim"     (international-option-keyword "_CHAMFER" "AJ" "fr_FR" :product :autocad)))
  (is (string= "Multiple" (international-option-keyword "_FILLET" "U" "fr_FR" :product :autocad)))
  ;; and the other way.
  (is (string= "Par"      (local-option-keyword "_OFFSET" "Through" "fr_FR" :product :autocad)))
  (is (string= "mUltiple" (local-option-keyword "_CHAMFER" "multiple" "fr_FR" :product :autocad))))

(test fr-option-keywords-resolve-per-product-bricscad
  ;; BricsCAD V25 fr: OFFSET [Passer par le point/Effacer/Calque].
  (is (string= "Through point"
               (international-option-keyword "_OFFSET" "Passer par le point" "fr_FR" :product :bricscad)))
  (is (string= "Through point"
               (international-option-keyword "_OFFSET" "P" "fr_FR" :product :bricscad)))
  (is (string= "Square"  (international-option-keyword "_RECTANG" "CA" "fr_FR" :product :bricscad)))
  (is (string= "Chamfer" (international-option-keyword "_RECTANG" "C" "fr_FR" :product :bricscad)))
  (is (string= "Extents" (international-option-keyword "_ZOOM" "ET" "fr_FR" :product :bricscad)))
  (is (string= "Out"     (international-option-keyword "_ZOOM" "R" "fr_FR" :product :bricscad)))
  (is (string= "fillet Settings"
               (international-option-keyword "_FILLET" "PA" "fr_FR" :product :bricscad)))
  (is (string= "Polyline" (international-option-keyword "_FILLET" "P" "fr_FR" :product :bricscad)))
  (is (string= "Passer par le point"
               (local-option-keyword "_OFFSET" "Through point" "fr_FR" :product :bricscad)))
  ;; a dialect name folds onto its product.
  (is (string= "Through point"
               (international-option-keyword "_OFFSET" "P" "fr_FR" :product :bricscad-v25)))
  (is (string= "Through"
               (international-option-keyword "_OFFSET" "P" "fr_FR" :product :autocad-2022))))

(test fr-option-keywords-differ-between-products
  ;; the two products' keyword sets differ (OFFSET's Through is a BricsCAD
  ;; Through point; the capitals of MODE swap): the dictionary is per product.
  (is (string= "Par" (local-option-keyword "_OFFSET" "Through" "fr_FR" :product :autocad)))
  (is (string= "Through" (local-option-keyword "_OFFSET" "Through" "fr_FR" :product :bricscad)))
  (is (string= "mOde" (local-option-keyword "_TRIM" "Mode" "fr_FR" :product :autocad)))
  (is (string= "Mode" (local-option-keyword "_TRIM" "mOde" "fr_FR" :product :bricscad)))
  ;; AutoCAD's CHAMFER Distance is Ecart, BricsCAD's is Distance.
  (is (string= "Ecart" (local-option-keyword "_CHAMFER" "Distance" "fr_FR" :product :autocad)))
  (is (string= "Distance" (local-option-keyword "_CHAMFER" "Distance" "fr_FR" :product :bricscad))))

;; LENGTHEN, harvested 2026-10-08 (AutoCAD job 17026576122, BricsCAD job
;; 17026576124): the two products' first prompts differ too.
(test fr-option-keywords-lengthen-per-product
  ;; AutoCAD 2022 fr: [DIfférence/Pourcentage/TOtal/DYnamique].
  (is (string= "Delta"   (international-option-keyword "_LENGTHEN" "DIfférence" "fr_FR" :product :autocad)))
  (is (string= "Delta"   (international-option-keyword "_LENGTHEN" "DI" "fr_FR" :product :autocad)))
  (is (string= "Percent" (international-option-keyword "_LENGTHEN" "P" "fr_FR" :product :autocad)))
  (is (string= "Total"   (international-option-keyword "_LENGTHEN" "to" "fr_FR" :product :autocad)))
  (is (string= "Dynamic" (international-option-keyword "_LENGTHEN" "DY" "fr_FR" :product :autocad)))
  (is (string= "TOtal"   (local-option-keyword "_LENGTHEN" "Total" "fr_FR" :product :autocad)))
  ;; BricsCAD V25 fr: [DYnamique/Incrément/Pourcentage/Total] -- no Delta.
  (is (string= "Increment" (international-option-keyword "_LENGTHEN" "I" "fr_FR" :product :bricscad)))
  (is (string= "Total"     (international-option-keyword "_LENGTHEN" "T" "fr_FR" :product :bricscad)))
  (is (string= "DYnamic"   (international-option-keyword "_LENGTHEN" "DY" "fr_FR" :product :bricscad)))
  (is (string= "Pourcentage" (local-option-keyword "_LENGTHEN" "Percent" "fr_FR" :product :bricscad)))
  ;; PLINE and BREAK offer no keyword at their first prompt on AutoCAD: identity.
  (is (string= "Par" (international-option-keyword "_BREAK" "Par" "fr_FR" :product :autocad))))

(test option-keywords-fall-back-and-force-the-international-form
  ;; _ forces the international form, canonicalised against the dictionary.
  (is (string= "Undo"  (international-option-keyword "_CHAMFER" "_undo" "fr_FR" :product :autocad)))
  (is (string= "Bogus" (international-option-keyword "_CHAMFER" "_Bogus" "fr_FR" :product :autocad)))
  ;; unknown keyword / command / locale: identity.
  (is (string= "Zzz"   (international-option-keyword "_CHAMFER" "Zzz" "fr_FR" :product :autocad)))
  (is (string= "Par"   (international-option-keyword "_PLINE" "Par" "fr_FR" :product :autocad)))
  (is (string= "Through" (local-option-keyword "_OFFSET" "Through" "xx_XX" :product :autocad)))
  ;; the "(?)" keyword is left to measure: not in the dictionary.
  (is (string= "?" (international-option-keyword "_TRIM" "?" "fr_FR" :product :bricscad))))
