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
