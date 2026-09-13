(in-package #:clautolisp.cadtui)

;;;; Localisation of the interaction language (Phase 7).
;;;;
;;;; The spec (§Localisation) fixes the architecture: the §5 parser works ONLY
;;;; on canonical English tokens (a Phase-2 decision); localisation is a LEXICAL
;;;; pre-pass applied to a meta-command line BEFORE syntactic analysis — one
;;;; locale = one token-local -> token-international table, never a grammar
;;;; duplicated per language. A dictionary is DATA (an alist per category), not
;;;; code: adding a language is adding a table, never touching the parser or the
;;;; CLOS tree. Translation is bidirectional and programmatic (getcname-style),
;;;; with an identity fallback (an unknown token passes through), so a partial
;;;; dictionary coexists. A token prefixed with _ forces the international form
;;;; (the AutoCAD convention, spec §Principe général), whatever the locale.
;;;;
;;;; SCOPE (headless): the interaction-language dictionaries (verbs + argument
;;;; keywords / role names / option names). The THREE CAD-command dictionaries
;;;; (command names, in-command option keywords, keyboard aliases) are populated
;;;; from live CAD runners per the filed sub-issues (issues/open/cadtui-locale-*).
;;;; The Lisp language itself is never localised (defun/setq/command stay
;;;; English) — the pre-pass only ever runs on an escaped meta-command line.

;;; --- The dictionary registry --------------------------------------

(defvar *locale-dictionaries* (make-hash-table :test 'equal)
  "Maps a locale string (e.g. \"fr_FR\") to a plist CATEGORY => alist of
(international-string . local-string). Categories used by the interaction
pre-pass: :verb and :keyword (argument keywords, role names, option names).")

(defvar *current-locale* "en"
  "The active locale string. \"en\" is the canonical international form: no
translation is applied under it (the identity locale).")

(defun register-locale-dictionary (locale category alist)
  "Record ALIST (of (international . local) pairs) as LOCALE's CATEGORY table.
Returns LOCALE. Re-registering a (locale, category) replaces its table."
  (let ((plist (gethash locale *locale-dictionaries*)))
    (setf (getf plist category) alist
          (gethash locale *locale-dictionaries*) plist))
  locale)

(defun %locale-alist (locale category)
  (getf (gethash locale *locale-dictionaries*) category))

(defun %locale-known-p (locale)
  "True when LOCALE has any registered dictionary (or is the identity \"en\")."
  (or (string-equal locale "en")
      (nth-value 1 (gethash locale *locale-dictionaries*))))

;;; --- Bidirectional name lookup (getcname-style) -------------------

(defun local-name (international locale category)
  "The LOCALE-local form of the INTERNATIONAL token in CATEGORY, or INTERNATIONAL
unchanged when the dictionary has no entry (identity fallback, spec)."
  (or (cdr (assoc international (%locale-alist locale category) :test #'string-equal))
      international))

(defun international-name (any locale category)
  "The canonical international form of ANY token in CATEGORY under LOCALE: the
reverse-lookup of a local form, or ANY unchanged (it is already international, or
unknown). The inverse of LOCAL-NAME."
  (or (car (rassoc any (%locale-alist locale category) :test #'string-equal))
      any))

;;; --- Locale selection (CLI > LC_ALL > LANG > en) ------------------

(defun %normalise-locale (s)
  "Strip an encoding/modifier suffix: \"fr_FR.UTF-8@euro\" => \"fr_FR\"; NIL or an
empty string => NIL."
  (when (and s (plusp (length s)))
    (let* ((at (position #\@ s))
           (s (subseq s 0 at))
           (dot (position #\. s))
           (s (subseq s 0 dot)))
      (and (plusp (length s)) s))))

(defun %candidate-chain (locale)
  "The region-then-language fallback chain, e.g. \"fr_CA\" => (\"fr_CA\" \"fr\")."
  (let ((us (position #\_ locale)))
    (if us (list locale (subseq locale 0 us)) (list locale))))

(defun resolve-locale (&key cli lc-all lang)
  "Resolve the active locale from CLI > LC_ALL > LANG (each normalised), with a
region->language partial fallback and a final fallback to \"en\". Warns (never
fails) when a requested locale has no dictionary at all."
  (let ((requested (or (%normalise-locale cli)
                       (%normalise-locale lc-all)
                       (%normalise-locale lang))))
    (if (null requested)
        "en"
        (or (find-if #'%locale-known-p (%candidate-chain requested))
            (progn
              (warn "cadtui: no dictionary for locale ~S; using en." requested)
              "en")))))

(defun set-current-locale (locale)
  "Set *CURRENT-LOCALE* to LOCALE (resolved to a known one). Returns the locale
actually selected."
  (setf *current-locale* (resolve-locale :cli locale)))

(defun init-locale-from-environment (&key cli)
  "Initialise the active locale from an optional CLI override then LC_ALL/LANG
in the environment. Returns the selected locale."
  (setf *current-locale*
        (resolve-locale :cli cli
                        :lc-all (uiop:getenv "LC_ALL")
                        :lang (uiop:getenv "LANG"))))

;;; --- The lexical pre-pass -----------------------------------------

(defun %translate-token (token locale)
  "Canonicalise one interaction TOKEN under LOCALE: a leading _ forces the
international form (drop the _, no lookup); otherwise reverse-look it up in the
verb table, then the keyword table; identity when unknown."
  (if (and (plusp (length token)) (char= (char token 0) #\_))
      (subseq token 1)
      (let ((as-verb (international-name token locale :verb)))
        (if (string= as-verb token)
            (international-name token locale :keyword)
            as-verb))))

(defun localise-meta-line (line &optional (locale *current-locale*))
  "Rewrite a meta-command LINE from LOCALE into canonical English: every
identifier token (a maximal run of letters/digits/-/_) is canonicalised via
%TRANSLATE-TOKEN; punctuation, numbers, paths and \"...\" string literals pass
through untouched. Under \"en\" LINE is returned unchanged. This is the spec's
lexical pre-pass; the parser only ever sees canonical English."
  (if (string-equal locale "en")
      line
      (with-output-to-string (out)
        (let ((i 0) (n (length line)) (in-string nil))
          (loop while (< i n) do
            (let ((ch (char line i)))
              (cond
                (in-string
                 (write-char ch out)
                 (when (char= ch #\") (setf in-string nil))
                 (incf i))
                ((char= ch #\")
                 (setf in-string t) (write-char ch out) (incf i))
                ;; a token starts on a letter or an underscore (the force sigil).
                ((or (alpha-char-p ch) (char= ch #\_))
                 (let ((start i))
                   (loop while (and (< i n)
                                    (let ((c (char line i)))
                                      (or (alphanumericp c)
                                          (char= c #\-) (char= c #\_))))
                         do (incf i))
                   (write-string (%translate-token (subseq line start i) locale)
                                 out)))
                (t (write-char ch out) (incf i)))))))))

;;; --- The interaction-language dictionaries (data) -----------------
;;;
;;; fr_FR is the reference dictionary (spec §5.2/§5.3 write the fr_FR view);
;;; de_DE / es_ES carry the spec's worked example plus a few, proving that a
;;; PARTIAL dictionary coexists (missing entries fall back to international).

(register-locale-dictionary
 "fr_FR" :verb
 '(("activate" . "activer") ("dump" . "lister") ("page" . "page")
   ("next" . "suivant") ("previous" . "precedent") ("help" . "aide")
   ("select" . "selectionner") ("add-selection" . "ajouter-selection")
   ("remove-selection" . "retirer-selection") ("input" . "saisir")
   ("close" . "fermer") ("zoom" . "zoom") ("pan" . "panoramique")
   ("key" . "touche") ("click" . "clic") ("dclick" . "double-clic")
   ("right-click" . "clic-droit") ("drag" . "glisser")
   ("cancel-command" . "annuler-commande") ("locale" . "locale")))

(register-locale-dictionary
 "fr_FR" :keyword
 '(("drawing" . "dessin") ("drawings" . "dessins")
   ("entity" . "entite") ("entities" . "entites")
   ("grip" . "poignee") ("grips" . "poignees")
   ("menu" . "menu") ("menus" . "menus")
   ("item" . "element") ("items" . "elements")
   ("button" . "bouton") ("buttons" . "boutons")
   ("band" . "bandeau") ("bands" . "bandeaux")
   ("cad-view" . "vue-cad") ("console" . "console")
   ("dialog" . "dialogue") ("dialogs" . "dialogues")
   ("tile" . "tuile") ("tiles" . "tuiles")
   ("alert" . "alerte") ("alerts" . "alertes")
   ("ribbon-tab" . "onglet") ("ribbon-panel" . "panneau")
   ("active-drawing" . "dessin-actif") ("application" . "application")
   ("menu-bar" . "barre-menu") ("separator" . "separateur")
   ("depth" . "profondeur") ("size" . "taille")
   ("window" . "fenetre") ("factor" . "facteur")))

(register-locale-dictionary
 "de_DE" :verb '(("activate" . "aktivieren") ("close" . "schliessen")
                 ("dump" . "auflisten") ("locale" . "locale")))
(register-locale-dictionary
 "de_DE" :keyword '(("drawing" . "Zeichnung") ("drawings" . "Zeichnungen")
                    ("entity" . "Objekt") ("cad-view" . "cad-ansicht")))

(register-locale-dictionary
 "es_ES" :verb '(("activate" . "activar") ("close" . "cerrar")
                 ("dump" . "listar") ("locale" . "locale")))
(register-locale-dictionary
 "es_ES" :keyword '(("drawing" . "dibujo") ("drawings" . "dibujos")
                    ("entity" . "entidad") ("cad-view" . "vista-cad")))
