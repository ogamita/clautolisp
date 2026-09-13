;;;; cadtui fr_FR — CAD command-name dictionary (:command category).
;;;;
;;;; Alist (international-name . fr_FR-name). The international (canonical
;;;; English) name is _-prefixed; a leading _ always forces it whatever the
;;;; locale (AutoCAD convention, spec §Localisation). A missing command falls
;;;; back to the international form.
;;;;
;;;; PROVENANCE: a DOC-VERIFIED SEED, not (yet) a getcname measurement. Each
;;;; French name below was read from the official BricsCAD fr-fr command
;;;; reference (help.bricsys.com/fr-fr/document/command-reference/<l>/<name>-
;;;; command — the English name is the URL, the French name the page title),
;;;; cross-checked with the autolisp-spec getcname examples (_STRETCH<->ETIRER,
;;;; _LINE<->LIGNE, _OPEN<->OUVRIR). Verified 2026-09-13.
;;;;
;;;; This is the common-command seed the sibling getcname probe
;;;; (scripts/run-getcname-probe.*, converter cadtui-getcname-to-sexp.py)
;;;; SUPERSEDES with a full, round-trip-verified harvest off the runners'
;;;; French BricsCAD — re-running the converter overwrites this file. AutoCAD
;;;; French names largely coincide but are a separate measurement.
(("_LINE"       . "LIGNE")
 ("_CIRCLE"     . "CERCLE")
 ("_ARC"        . "ARC")
 ("_RECTANG"    . "RECTANG")
 ("_HATCH"      . "HACHURES")
 ("_ERASE"      . "EFFACER")
 ("_MOVE"       . "DEPLACER")
 ("_COPY"       . "COPIER")
 ("_ROTATE"     . "ROTATION")
 ("_SCALE"      . "ECHELLE")
 ("_MIRROR"     . "MIROIR")
 ("_OFFSET"     . "DECALER")
 ("_TRIM"       . "AJUSTER")
 ("_EXTEND"     . "PROLONGE")
 ("_FILLET"     . "RACCORD")
 ("_CHAMFER"    . "CHANFREIN")
 ("_STRETCH"    . "ETIRER")
 ("_BREAK"      . "COUPURE")
 ("_EXPLODE"    . "DECOMPOS")
 ("_INSERT"     . "INSERER")
 ("_ZOOM"       . "ZOOM")
 ("_LAYER"      . "CALQUE")
 ("_PLOT"       . "TRACEUR")
 ("_OPEN"       . "OUVRIR")
 ("_UNDO"       . "ANNULER")
 ("_DIMALIGNED" . "COTALI"))
