# Mémoire projet — cadtui (clautolisp)

## Contexte
`cadtui` est un sous-système de `clautolisp` (implémentation d'AutoLISP
en Common Lisp, dépôt `gitlab.com/ogamita/clautolisp`, copie locale
`~/works/sncf-reseau/src/clautolisp/`). Objectif : simuler l'interface
utilisateur complète d'un CAD façon AutoCAD/BricsCAD (menus, bandeaux,
fenêtres de dessin MDI, vue CAD avec entités et poignées, alertes,
dialogues DCL, console) sous forme d'une arborescence d'objets
interrogeable et pilotable au clavier — pour permettre le test
interactif et scriptable de dialogues DCL et, plus généralement, de
toute commande CAD, sans GUI réel.

La spécification complète et normative est dans
`documentation/cadtui-specifications.org` (à la racine du sous-projet cadtui).
**Toujours relire ce fichier avant de modifier
l'architecture** : il contient l'arborescence des objets d'interface,
le modèle CLOS, la grammaire du langage d'interaction, le format de
dump/pagination, et la roadmap de phases.

## Décisions figées (ne pas rediscuter sans raison forte)

- Deux modes d'hébergement : `--host cador` (arbre réduit à
  `/application/console`, comportement actuel de clautolisp) et
  `--host cadtui` (arbre complet). `cador` est un cas particulier de
  `cadtui`, pas un code séparé.
- Discipline d'entrée : une ligne = un ordre, exécuté immédiatement,
  jamais modal. Toute interaction (clic, double-clic, sélection,
  activation de fenêtre, dump, saisie) passe par un petit langage
  textuel `verbe(arguments)` — voir §5 de la spec pour le répertoire
  complet des verbes.
- Toute ligne qui n'est PAS de la forme `verbe(...)` reconnue est un
  passe-plat : argument de la commande CAD active, sinon expression
  Lisp si elle commence par `(`, sinon nom de commande CAD. C'est le
  même mécanisme pour la console et pour la ligne de commande d'une
  fenêtre de dessin — ne pas dupliquer cette logique.
- Adressage des objets : chemins absolus (`/application/dessins[2]/...`),
  clés stables par nœud, et références relatives à un dump antérieur
  (`D<n>.<clé>`) qui restent valides même après changement de fenêtre
  active — l'adressage ne dépend jamais du focus courant.
- Le modèle d'arbre (classes CLOS `ui-node` et sous-classes) est
  strictement indépendant du rendu. Le rendu texte (dump structuré) est
  le seul backend de la phase 1 ; un backend curses éventuel (phase 7)
  doit réutiliser le même interpréteur de langage d'interaction sans le
  modifier.
- Pagination et filtre spatial 2D sont necessaires dès qu'on touche aux
  entités de la vue CAD (dessins réalistes : 5000+ entités) — ne pas
  écrire de `dump` non paginé sur des listes potentiellement longues.
- Consoles : une console (flux + zone-saisie + espace de noms Lisp)
  par dessin, PLUS une console d'application distincte à la racine de
  l'arbre, active tant qu'aucun dessin n'est actif. Espaces de noms
  strictement isolés entre consoles par défaut (comportement documenté
  d'AutoCAD, via son mécanisme explicite de « tableau noir » pour le
  partage volontaire) — ne pas reproduire le partage implicite/bugué
  observé dans BricsCAD (variable globale d'un dessin qui fuite vers un
  autre). `touche(f2)` et la cible de saisie implicite résolvent vers
  la console du dessin actif s'il y en a un, sinon vers la console
  d'application — jamais une console unique partagée.
- Racine de l'arbre nommée `application` (pas `écran`, ambigu avec les
  moniteurs physiques) — chemin `/application`, classe `ui-application`.
- Localisation : deux vocabulaires localisables (commandes CAD, verbes
  et mots-clés des méta-commandes du langage d'interaction), chacun sur
  le modèle AutoCAD (forme internationale anglaise + préfixe `_` pour
  la forcer, traduction bidirectionnelle façon `getcname`, dictionnaire
  = fichier de données pas du code). Le parseur du langage
  d'interaction doit être écrit en tokens canoniques anglais dès la
  phase 2 ; la localisation est une passe lexicale AVANT l'analyse
  syntaxique, jamais une grammaire dupliquée par langue. Trois
  dictionnaires distincts pour les commandes CAD (noms de commande,
  mots-clés d'option, alias clavier) — ne pas les confondre, ils ont
  des règles de préfixage différentes.
- Modèle d'exécution : chaque dessin a deux threads (AutoLISP +
  débogueur, ce dernier généralement en attente) ; un seul thread actif
  dans toute l'application à la fois ; changer de dessin actif suspend
  les deux threads du précédent sans les tuer.
- Désambiguïsation méta-commande / saisie AutoLISP : PAS de
  reconnaissance par syntaxe (`identifiant(args)` est ambigu — un
  `read-line` AutoLISP en cours peut légitimement attendre une ligne
  de cette forme). Mécanisme retenu : caractère d'échappement `=` en
  tête de ligne obligatoire pour une méta-commande (qui occupe alors
  toute la ligne) ; `==` en tête annule l'échappement et délivre la
  ligne telle quelle (moins un `=`) comme saisie AutoLISP ordinaire.

  Le caractère est `=` et non `!` (décision pjb, 2026-08-15) : `!` est
  l'échappement SHELL de tous les interactors (issue `bang`), et `,`
  introduit les commandes clautolisp. Répartition des débuts de ligne
  dans la console cadtui — `(` expression Lisp, `,` commande
  clautolisp, `!` shell, `=` méta-commande cadtui, `.` `-` `_` ou rien
  commande CAD. Écartés au passage : `@` est le préfixe des
  COORDONNÉES RELATIVES d'AutoCAD (`@10,5`) et `#` celui des absolues —
  les deux saisies les plus courantes d'une ligne de commande CAD.

  La console cadtui est un INTERACTOR au sens du cadre existant
  (`INTERACTOR-LOOP`), pas un lecteur de lignes ad hoc : conséquence
  voulue, on peut passer d'un interactor à l'autre, la console
  s'empilant et se dépilant comme aldo ou sedit. La classification des
  lignes est donc le *reader* de cet interactor, et le caractère
  d'échappement est un réglage d'interactor empilé (comme `lisp.conf`
  sous `aldo.conf`), pas une variable globale.
  Une ligne n'est donc jamais scindée en deux flux — chaque console a
  juste une file d'attente de lignes passe-plat (pas un tampon de
  caractères) pour le cas où son thread n'est pas encore en train de
  lire au moment où la ligne arrive. Voir §§ « Classification des
  lignes et tamponnage » et « Modèle d'exécution » de la spec.

## État d'avancement
(À tenir à jour à chaque session — noter ici la phase en cours parmi
les 8 listées dans la spec, ce qui est fait, ce qui reste, et toute
divergence assumée par rapport à la spec.)

- Phase 1 (modèle d'arbre CLOS minimal) : **FAIT** (2026-09-13). Système
  `clautolisp/cadtui` : `ui-node` + sous-classes, `add-child`, `dump-node` +
  `make-application-tree`/`make-cador-tree`, `find-node`/`resolve-target`
  (chemins absolus). MRs !209/!210/!211. clautolisp 2.2.34.
- Phase 2 (interpréteur du langage) : **EN COURS**. Décision pjb (2026-09-13,
  précise la note « anglais » figée ci-dessous) : les tokens canoniques —
  verbes, mots-clés de méta-commande ET rôles/mots-clés d'adressage — sont en
  ANGLAIS ; les autres langues ne sont disponibles que selon la locale courante
  (LANG=fr_FR → tokens français, de_DE → allemands…), via une passe lexicale
  Phase 7. Conséquence : le vocabulaire FRANÇAIS livré en Phase 1 (rôles
  :dessin/:entite/:vue-cad…, `dessins[]`, `dessin-actif`) a été re-canonicalisé
  en anglais (:drawing/:entity/:cad-view…, `drawings[]`, `active-drawing`) avant
  de bâtir le parseur — la spec §5.2/§5.3 reste la vue fr_FR.
- Phase 2 (interpréteur du langage) : **FAIT** (2026-09-13). classify.lisp
  (classificateur de lignes / échappement `=`/`==`), parser.lisp (parseur
  `verbe(args)` en tokens anglais canoniques), dump.lisp (registre de dumps
  D<n> + pagination `dump-list`/`dump-page`) + address.lisp (`D<n>.cle` et clé
  nue dans le dernier dump), dispatch.lisp (`interpret-line` pur + table de
  verbes : dump/page/next/previous/help COMPLETS ; activate/select/input/close/
  zoom/pan/key/click PARTIELS sur l'arbre ; dclick/right-click/drag/
  cancel-command en attente Phase 4/5). MRs !213–!218.
- Phase 3 (intégration DCL) : **FAIT** (2026-09-13). cadtui installe son propre
  =dcl-renderer= dans le point d'extension =*dcl-renderer*= du runtime
  autolisp-dcl (jamais forké) ; ses callbacks reflètent le modèle dcl-dialog /
  dcl-tile en nœuds ui-dialog / ui-tile (dcl-bridge.lisp). Les verbes
  input/click/close déclenchent les callbacks action_tile via
  dcl-runtime-fire-action / done_dialog. start_dialog modal est piloté sans
  thread par une file d'événements pré-remplie (dispatch %drain-cadtui-dcl-
  events + run-fn), l'analogue headless du stdin pré-alimenté. cadtui dépend
  désormais de autolisp-dcl (pas de cycle). MRs !219–!221.
- Phase 4 (consoles + threads) : **FAIT** (2026-09-13). Chaque console de dessin
  a un scheduled-context isolé (namespace par-document) sur le scheduler cador-2
  + une file park-mailbox (type-ahead) ; console-runtime.lisp : make-console-
  context, console-read-line (lecture bloquante park-aware), la boucle read-eval
  (règles §5.6 : ( = Lisp dans le namespace isolé, sinon commande CAD stand-in),
  activate-drawing-document (le switch pilote le document courant runtime). La
  console est un INTERACTOR (console-interactor.lisp : *cadtui-console*, reader =
  classify-line sur l'échappement de l'état d'activation, s'empile comme
  aldo/sedit). cadtui dépend désormais de autolisp-interactor (pas de cycle).
  MRs !222–!226. Aucun second scheduler ni appel bordeaux-threads dans cadtui.
  REFINEMENT DIFFÉRÉ (plan slice 5) : brancher le producteur de start_dialog sur
  la console vivante (la file DCL pré-remplie de la Phase 3 fonctionne déjà) —
  petit, non bloquant, à reprendre au besoin.
- Phase 5 (vue CAD + entités + pagination spatiale) : **EN COURS**.
  - Slice 1 **FAIT** : dépendance clautolisp/drawing, slot drawing de ui-cad-view,
    cad-view.lisp (struct viewport + viewport-bounds, entity-bounding-box,
    %bbox-intersects-p, entity->ui-entity), attributs de dump ui-grip. MR !227.
    clautolisp 2.2.49.
  - Slice 2 **FAIT** : viewport (fenetre-visualisation) réellement câblée aux
    verbes zoom/pan. zoom(window: (x1 y1 x2 y2)) fixe les bornes du monde visible ;
    zoom(factor: f) échelle en place autour du centre (met à jour viewport-scale) ;
    pan(dx, dy) translate les bornes ; dump(...) ne mute JAMAIS la viewport.
    Accesseur ui-viewport exporté. MR !228. clautolisp 2.2.50 / alfe 2.2.58.
  - Slice 3 **FAIT** : dump-entities (cad-view.lisp) — itère les VALEURS d'entités
    (pas de matérialisation en masse), cull spatial via %bbox-intersects-p contre
    la fenêtre explicite `window:` ou, à défaut, les bornes de la viewport ou, à
    défaut, aucune ; pagine ; ne matérialise en ui-entity QUE la page affichée
    (mirror paresseux : remplace les enfants du cad-view). Un slot `provider`
    (fonction (page page-size)->(values page-nodes total)) est posé sur
    dump-descriptor ; dump-page re-lit via le provider quand il existe (sinon via
    les enfants statiques). MR !229. clautolisp 2.2.51 / alfe 2.2.59.
  - Slice 4 **FAIT** : (a) le verbe `dump` route vers dump-entities dès qu'on
    demande les entités — chemin se terminant par `/entities`, ou mot-clé
    positionnel `:entities` — en honorant `window:`/`page:`/`size:` ; (b)
    adressage pointé général : chaîne pointée relative à la racine
    (`drawings[1].cad-view.entities[1].grips[2]`) et chaîne pointée relative au
    dernier dump (`2A.2` = entité puis poignée). Désambiguïsation des clés
    pointées : le dernier-dump essaie d'abord la clé ENTIÈRE (donc `plan.dwg`
    reste une clé, jamais scindée) ; la chaîne racine ne se déclenche que sans
    `:` (l'adressage role:cle à clé pointée reste un segment unique ou un
    /chemin absolu — limitation assumée, documentée). MR !230.
    clautolisp 2.2.52 / alfe 2.2.60.
  - Slice 5 optionnel (bbox blocs/textes) DÉLIBÉRÉMENT DIFFÉRÉ : l'extent réel
    d'un INSERT/TEXT dépend de la table de blocs / du rendu de police, non
    disponible headless ; le facteur d'approximation serait arbitraire (non
    fondé sur la spec). entity-bounding-box reste l'approximation sur la
    géométrie propre (points 10-13), déjà documentée dans cad-view.lisp. Phase 5
    sinon COMPLÈTE.
- Phase 6 (barre de menus + bandeaux depuis une description type CUIX/MNU) :
  **FAIT** (2026-09-13). menu-band.lisp : DSL de données (listes à tête
  mot-clé, libellés string, tokens anglais) — (:menu-bar (:menu LABEL (:item
  LABEL :action A :state S) | (:menu ...) | (:separator))*), (:band LABEL
  [:style :toolbar|:ribbon] boutons | onglets>panneaux>boutons). build-menu-bar
  / build-band / install-menu-bar / add-band ; clé = libellé, action = nom de
  commande CAD (string) ou fonction Lisp (closure/symbole). Erreurs de
  description → ui-description-error. Le verbe click EXÉCUTE désormais une
  action fonction Lisp (funcall, :ok + valeur en data) ; un nom de commande CAD
  string reste un stand-in :not-yet (il faut le runtime console actif).
  MR !231. clautolisp 2.2.53 / alfe 2.2.61.
- Phase 7 (localisation) : **FAIT** headless (2026-09-13). locale.lisp : registre
  de dictionnaires par (locale, catégorie) ; local-name/international-name
  bidirectionnels (style getcname, repli identité) ; resolve-locale
  (CLI>LC_ALL>LANG>en, normalisation .UTF-8@euro, repli région→langue, warn si
  inconnu) ; localise-meta-line = passe LEXICALE (retokenise la ligne, traduit
  chaque identifiant via la table inverse, laisse ponctuation/chemins/littéraux
  "..." intacts, préfixe _ force l'international) branchée dans interpret-line
  AVANT parse (identité sous en). Verbe locale(fr_FR) pour basculer à chaud +
  init-locale-from-environment. Dictionnaires d'interaction fr_FR (complet-ish),
  de_DE/es_ES (partiels, prouvent le repli). MR !232. clautolisp 2.2.54 /
  alfe 2.2.62.
  RESTE Phase 7 (hors scope headless) : (a) les 3 dictionnaires de COMMANDES CAD
  (noms, mots-clés d'option, alias clavier) par locale/plate-forme — nécessitent
  les runners macOS/Windows (issues/open/cadtui-locale-*) ; (b) le drapeau CLI
  --locale/--lang dans autolisp-cli (l'API + LANG/LC_ALL + le verbe locale()
  fonctionnent déjà ; le câblage du flag CLI est un petit ajout cross-module
  différé).
- Phase 7 — dictionnaires DONNÉES + loader (issue cadtui-locale-data-format-and-
  loader) : **FAIT** (2026-09-13, runners reconnectés). Les dictionnaires sont
  désormais des FICHIERS de données sous cadtui/data/locale/<locale>/
  <catégorie>.sexp (une alist (international . local) par fichier, le nom =
  catégorie : verb/keyword pour l'interaction ; command/option-keyword/alias pour
  les commandes CAD). locale.lisp : macro %embed-locale-tree qui LIT l'arbre au
  COMPILE et le bake dans le fasl (aucune dépendance fichier à l'exécution) +
  load-locale-data-from-directory pour recharger un drop ultérieur. Les 3
  catégories CAD sont de vrais dictionnaires (moteur générique) ; entrée absente
  → repli international. MR !234. (Note dette ASDF : éditer un .sexp ne
  recompile pas locale.lisp automatiquement — rebuild propre en CI ; en dev,
  toucher locale.lisp ou :force.) NB BricsCAD des runners = install FRANÇAIS
  (getcname y donne les vrais noms fr_FR) ; getcname est un stub nil côté
  clautolisp (donc --clautolisp = dry-run mécanique seulement).
- Phase 7 — sonde getcname + convertisseur (issue cadtui-locale-probe-getcname) :
  **MACHINERIE FAITE** (MR !235). getcname-probe.lsp (scenario alfe) + scripts
  run-getcname-probe.{sh,ps1} + jobs SOFT cad dans .gitlab/native.yml (BricsCAD
  macOS+Windows, AutoCAD+AcCoreConsole Windows, artefacts dist/getcname/) +
  convertisseur scripts/cadtui-getcname-to-sexp.py (garde les lignes VALUE dont
  l'aller-retour boucle → command.sexp). Validé sur --clautolisp (143 lignes
  ABSENT bien formées + DONE). Le harvest fr_FR autoritatif tourne sur le runner
  français ; l'artefact converti REMPLACE command.sexp.
- Phase 7 — dictionnaire fr_FR de COMMANDES CAD : **FAIT — HARVEST AUTORITATIF
  BRICSCAD + AUTOCAD (fusionné)** (MR !237 BricsCAD, MR !238 +AutoCAD).
  data/locale/fr_FR/command.sexp = 118 commandes, UNION de deux mesures getcname :
  BricsCAD FRANÇAIS (BRICSCAD 26.0, macOS, job getcname:probe:bricscad:macos) et
  AutoCAD FRANÇAIS (acad 24.1s, Windows, job getcname:probe:autocad:windows,
  pipeline 2845115733 → enfant 2845116121). Le convertisseur fusionne N artefacts
  (le PREMIER gagne un conflit de valeur ; chaque éditeur apporte ses commandes
  propres) : appelé autocad d'abord (éditeur de référence). UNE seule divergence
  de valeur : _STRETCH = ETIRER (AutoCAD, retenu) vs ÉTIRER (BricsCAD, notée dans
  l'en-tête). _VPORTS rejeté (l'aller-retour AutoCAD l'aliase vers _VIEWPORTS).
  Le convertisseur détecte l'encodage : BricsCAD sort de l'UTF-8 propre, AutoCAD
  de l'UTF-16 (voire un BOM UTF-8 collé à un corps UTF-16LE par PowerShell) — il
  récupère les deux. Le loader lit les .sexp en UTF-8 forcé (noms accentués).
  Les commandes IDENTITY (français = anglais, ex. ARC/ZOOM) ne sont pas stockées :
  repli sur la forme internationale (le préfixe _ la force toujours). RESTE : les
  alias .pgp (P3, dans default.pgp) ; les mots-clés d'option (P3) ; le drapeau CLI
  --locale/--lang. (Note : le wrapper run-getcname-probe.ps1 pourrait décoder
  l'UTF-16 AutoCAD avant d'écrire — non bloquant, le convertisseur l'absorbe.)
- Phase 8 (backend de rendu visuel, OPTIONNEL) : **FAIT** (seam testable,
  2026-09-13). render.lisp : *screen-renderer* (indirection de backend) +
  text-screen-renderer headless déterministe (en-tête, ligne de menus, liste des
  dessins avec l'actif marqué *, détail du dessin actif : bandeaux, vue-cad
  count+viewport, invite console ; sinon console d'application) + render-screen /
  render-screen-to-string + ui-step (pilote UNE ligne via interpret-line INCHANGÉ
  puis re-rend). Le vrai backend curses (widgets sur tui-core, gaté hors de
  l'image de test comme l'UI ncurses du débogueur) est un drop-in sur
  *screen-renderer* — non fait, faible valeur/non testable dans la lane standard.
  MR !233. clautolisp 2.2.55 / alfe 2.2.63.

## MODULE cadtui : COMPLET (scope headless)
Phases 1-8 livrées et vertes (34+ suites, Fail:0). Restent, hors scope headless
et explicitement différés (non bloquants pour l'usage principal — test
scriptable de dialogues DCL et commandes CAD sans GUI) :
- Phase 7 : les 3 dictionnaires de COMMANDES CAD par locale/plate-forme
  (issues/open/cadtui-locale-*) — nécessitent les runners macOS/Windows.
- Phase 7 : le drapeau CLI --locale/--lang dans autolisp-cli (petit ajout
  cross-module ; l'API + LANG/LC_ALL + le verbe locale() marchent déjà).
- Phase 5 slice 5 : bbox blocs/textes (extent non fondé headless).
- Phase 4 slice 5 : brancher la console vivante comme producteur de start_dialog.
- Phase 8 : le backend curses concret (widgets), drop-in sur *screen-renderer*.

## Conventions de code héritées de clautolisp
- Common Lisp, style du dépôt existant (voir fichiers déjà présents
  sous `~/works/sncf-reseau/src/clautolisp/autolisp-front-end/`).
- `princ`/`prin1`/`print` sont déjà shadowés dans clautolisp pour
  coller à la sémantique AutoLISP — en tenir compte si `dump-node`
  s'appuie dessus, ne pas les re-shadower par accident dans le paquet
  `cadtui`.
