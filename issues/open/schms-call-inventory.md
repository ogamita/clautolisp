# Inventaire des fonctions AutoLISP/Visual-LISP appelées par SCHMS+

> But : cadrer le travail de compatibilité d'un moteur AutoLISP « headless » (clautolisp).
> Généré mécaniquement le 2026-07-24 (branche `test-sprint-21`).

## Méthode & portée

Scan de la totalité des fichiers `*.lsp`/`*.lisp` sous `src/schms` — **579 fichiers, 83 655 lignes** —
en excluant les sauvegardes (`*~`) et `.claude/worktrees/`. Les décomptes sont des **occurrences en
tête de liste** (`(fonction …)`) extraites mécaniquement sur tout l'arbre ; ils **incluent** les tests
et l'outillage `dev/` (p. ex. `dev/lisp/cherche_sources.lsp`, un scanner de sources, cite de nombreux
symboles comme *données*, ce qui gonfle légèrement quelques noms rares). Les fonctions passées comme
`'symbole` à `mapcar`/`apply` ne sont pas dans ces décomptes de tête et sont signalées au cas par cas.

Le cœur du moteur est dans `src-vlx/` (compilé en `SCHMSPLUS.VLX`) ; `CADRE/ DIAL/ LGV/ PN/ SX1/ SX2/
KVB/ …` sont les modules de commande par objet.

> ⚠️ **En une phrase, pour un moteur model-only :** ce code est **fortement interactif et piloté par DCL**.
> Il n'est **pas** model-only aujourd'hui — il suppose une session graphique AutoCAD/BricsCAD complète
> (boîtes de dialogue, `command`, saisie de points, sélection). Voir §7.

---

## 1. Mutation & accès aux entités

| Fonction | Nb | Sites représentatifs |
|---|---:|---|
| `entget` | 88 | `voies-identification.lsp:47` `(entget ename (list *schms_app*))` ; `mise_a_jour.lsp:1091` `(entget bloc (list *schms_app* "SCHMS"))` ; `BATQUAI.LSP:85` |
| `entlast` | 70 | idiome : créer via `command`, récupérer le résultat via `entlast` |
| `entsel` ⚠️ | 38 | **tous interactifs** avec invite — `AIGUILLE.LSP:69`, `CINOX.LSP:57`, `Ag_fic.lsp:13` |
| `handent` | 22 | `AIGUILLE.LSP:118` `(handent handle_voie_directe)` — handle→ename, non-interactif |
| `entnext` | 20 | parcours des attributs d'INSERT |
| `entmakex` | 11 | `dictionnaires.lsp:68` DICTIONARY ; `mise_a_jour.lsp:1057` XRECORD ; `generer-palette-rapport.lsp:339` LINE |
| `entdel` | 7 | |
| `entmod` | 6 | `voies-identification.lsp:54` réécriture XData ; `xdata_entites.lsp:37` `(entmod (append (entget …) (list liste_de)))` |
| `entmake` | 6 | `creation_blocs.lsp:69` paire BLOCK/ENDBLK ; `test-voie-chainage.lsp:123` CIRCLE |
| `entupd` | 1 | |
| `nentsel` ⚠️ | 1 | interactif |
| `nentselp` | 0 | **non utilisé** |
| `snvalid` | 1 | validation de nom de symbole |

**Notes clautolisp :** `entget` a deux formes — simple, et la **forme filtrée XData** `(entget ename (list "APP" …))`.
`entmod` sert au round-trip XData (`entget` → `append` d'un `(-3 (app . data))` → `entmod`). Aucun `nentselp` ;
l'unique `nentsel` et tous les `entsel` sont interactifs.

---

## 2. Jeux de sélection

| Fonction | Nb | Notes / sites |
|---|---:|---|
| `ssget` | 69 | ventilation modes/filtres ci-dessous |
| `sslength` | 29 | idiome de boucle à rebours |
| `ssname` | 27 | `modif_lot.lsp:11` `(ssname js (setq i (1- i)))` |
| `ssadd` | 12 | |
| `sssetfirst` | 10 | ⚠️ surbrillance graphique — `(sssetfirst nil ss)` |

`ssdel`, `ssmemb`, `ssnamex`, `ssgetfirst` — **non utilisés**.

### Chaînes de mode `ssget`

| Mode | Nb | Sens | Interactif ? |
|---|---:|---|---|
| `"x"` / `"X"` | 35 | balayage filtré de toute la BD | **Non** (model-only ✔) |
| `"_X"` | 6 | balayage filtré de toute la BD | Non ✔ |
| `"_I"` | 9 | jeu implicite (pickfirst) | ⚠️ Oui |
| `"_C"` | 6 | fenêtre capturante (2 points) | ⚠️ Oui |
| `(ssget)` sans mode | ~6 | pointage interactif | ⚠️ Oui |
| `(ssget p1)` point | 2 | pointage à un point | ⚠️ Oui |

Les **balayages non-interactifs `"X"`/`"_X"` sont les importants** pour un moteur headless — ils pilotent tout le traitement de masse.

### Codes de groupe DXF utilisés dans les filtres `ssget`

| Code | Usage | Exemple |
|---|---|---|
| `0` | type d'entité, `"INSERT"` | `PIECE25B.LSP:12` `'((0 . "INSERT")(2 . "P25BFOND"))` |
| `2` | nom de bloc (souvent calculé) | `POSTE.LSP:577` `(cons 2 (nom_bloc_textes))` |
| `8` | nom de calque | `Trace-ft.lsp:14` `'((8 . "FORMAT"))` ; `suivi_modifs.lsp:312` liste de calques jointe par virgules |
| `-3` | **filtre application XData** | `selection.lsp:77` `(list '(0 . "INSERT") (list -3 (list *schms_app*)))` ; `mise_a_jour.lsp:1252` `'((0 . "INSERT") (-3 ("SCHMS")))` |
| `-4` | opérateur relationnel | `MEMO_PK.LSP:33` `'((-4 . "<OR")(2 . "KILOM")(2 . "HM")(-4 . "OR>"))` |

Les filtres `-3` + `-4 "<OR"/"OR>"` sont les plus délicats à supporter et sont exercés en production.

---

## 3. Structures de données du dessin (dictionnaires, tables, XData, XRecords)

### Dictionnaires d'objets nommés & XRecords

| Fonction | Nb | Sites |
|---|---:|---|
| `dictsearch` | 11 | `dictionnaires.lsp:26`, `plateforme.lsp:45` |
| `namedobjdict` | 7 | `dictionnaires.lsp:62` |
| `dictadd` | 7 | `dictionnaires.lsp:70`, `:80` |
| `dictremove` | 2 | `dictionnaires.lsp:64` |
| `dictnext` | 0 | non utilisé |

**Idiome XRecord** (deux variantes — liste DXF & ActiveX) :
- DXF : `entmakex '((0 . "XRECORD") (100 . "AcDbXrecord") …))` puis `dictadd` — `mise_a_jour.lsp:1057`, `dictionnaires.lsp:72`.
- ActiveX : `vla-setXRecordData` avec `vlax-make-safearray` de paires type/valeur — `schmsx-testdata-versions.lsp:40`.
- Codes de groupe des dictionnaires lus : `-1` (ename), `3` (clé), `350` (id xrecord), `100` (sous-classe), `102` (bloc réacteurs).

### Tables de symboles

| Fonction | Nb | Tables utilisées |
|---|---:|---|
| `tblsearch` | 37 | `"BLOCK"` (17), `"LAYER"` (12), `"LTYPE"` (8), `"STYLE"` (3) |
| `tblnext` | 4 | mêmes tables (itération) |
| `tblobjname` | 1 | |

Pas de `tblobjnext`. Tables nécessaires : **BLOCK, LAYER, LTYPE, STYLE** uniquement.

### XData / `regapp`

- `regapp` (3 sites) : `(regapp "SCHMS")` `xdata_entites.lsp:1037` et `(regapp *schms_app*)` `xdata_entites.lsp:45`, `voies-identification.lsp:13`.
- **Deux noms d'application coexistent** (migration legacy) : `*schms_app*` = **`"SCHMSPLUS"`** (courant, défini
  `xdata_entites.lsp:12`) et le littéral **`"SCHMS"`** (legacy, lu en `mise_a_jour.lsp:1271` `(entget ent '("SCHMS"))`).
  Le moteur doit supporter **plusieurs noms d'application dans un même `entget`/`ssget -3`**.

**Codes de groupe du codec XData** (l'ensemble complet que `entget`/`entmod` doivent préserver),
centralisés dans `xdata_codec.lsp` & `xdata_entites.lsp` :

| Code | Type | Nb |
|---|---|---:|
| `1000` | chaîne | 64 |
| `1002` | chaîne de contrôle `{`/`}` (listes imbriquées) | 4 |
| `1003` | nom de calque | 2 |
| `1005` | handle | 3 |
| `1040` | réel | 3 |
| `1070` | entier 16 bits | 8 |
| `1071` | entier 32 bits (long) | 3 |

L'imbrication `{ … }` via `1002` est utilisée — le codec round-trip des données structurées, donc l'imbrication
d'accolades doit être fidèle.

---

## 4. Variables système (`getvar` / `setvar`)

`getvar` tête 136 ; `setvar` 269. Noms touchés :

**`setvar` (écrits)** — `OSMODE` (143 ⚠️ accrochage), `ORTHOMODE` (19), `CLAYER` (19), `CELTSCALE` (17),
`SNAPANG` (17), `CMDECHO` (15), `DIMZIN` (4), `CECOLOR` (4), `ATTREQ` (4), `TEXTSTYLE` (3), `LTSCALE` (3),
`LASTPOINT` (3), `BLIPMODE` (3), `LOGFILEMODE` (2), `LIMCHECK` (2), `ATTDIA` (2), `WIPEOUTFRAME`, `SNAPBASE`,
`OFFSETDIST`, `MEASUREMENT`, `HIGHLIGHT`, `FLATLAND`, `CELTYPE`.

**`getvar` (lus)** — `VENDORNAME` (22), `MILLISECS` (16, chrono), `LASTPOINT` (12), `DWGNAME` (8), `CLAYER` (7),
`VIEWSIZE` (6), `OFFSETDIST` (5), `LTSCALE` (5), `VIEWCTR` (4), `SCREENSIZE` (4 ⚠️ graphique), `ACADVER` (4),
`TEXTSTYLE` (3), `OSMODE` (3), `CDATE` (3), `UNDOCTL`, `LOGFILEPATH/NAME/MODE`, `DWGPREFIX` (aussi forme
symbole-quotée `'DWGPREFIX` ×3), `DIMZIN`, `CMDECHO`, `ATTREQ`, `APERTURE`, `WORLDUCS`, `VSMAX`, `TILEMODE`,
`TEMPPREFIX`, `SNAPANG`, `PERIMETER`, `MEASUREMENT`, `LIMCHECK`, `LASTANGLE`, `CVPORT`, `CMDACTIVE`, `ATTDIA`.

Sous-ensemble pertinent model-only (doit renvoyer des valeurs saines en headless) : `CLAYER, CELTSCALE,
LTSCALE, TEXTSTYLE, DIMZIN, ACADVER, DWGNAME/DWGPREFIX, CDATE/MILLISECS, LASTPOINT, MEASUREMENT`.
Graphiques uniquement (`SCREENSIZE, VIEWSIZE, VIEWCTR, VSMAX, CVPORT, APERTURE, OSMODE, BLIPMODE, HIGHLIGHT`) —
peuvent être stubés.

---

## 5. Chaînes / listes / maths / conversion

**Chaînes :** `strcat` (1012), `strcase` (138), `substr` (115), `strlen` (64) ; `itoa` (341), `atoi` (175),
`atof` (32), `rtos` (95), `angtos` (14), `distof` (15), `angtof` (1) ; `ascii` (4), `chr` (27), `wcmatch` (38).
Utils VLISP : `vl-string-search` (7), `vl-string-subst` (6), `vl-string-translate` (11), `vl-string-position` (8),
`vl-string-trim`/`-left-`/`-right-` (4/1/1), `vl-string->list` (19), `vl-list->string` (12),
`vl-prin1-to-string` (711 — primitive de sérialisation dominante), `vl-princ-to-string` (66).

**Listes :** `cons` (1427), `assoc` (1960 — le pilier), `list` (1639), `car/cdr/cadr` (1017/3094/429),
`append` (120), `member` (123), `subst` (67), `nth` (167), `mapcar` (338), `apply` (50), `reverse` (101),
`last` (20), `length` (114). VLISP : `vl-sort` (24), `vl-remove` (17), `vl-remove-if`/`-if-not` (11/4),
`vl-member-if`/`-if-not` (5/1), `vl-position` (5), `vl-some` (2), `vl-every` (7), `vl-list*` (51),
`vl-catch-all-apply`/`-error-p`/`-error-message` (66/54/21).

**Maths/géométrie :** `polar` (252), `angle` (61), `distance` (72), `abs` (43), `sin/cos/tan/atan` (54/56/?/8),
`fix` (99), `float` (16), `min/max` (79/71), `rem` (12), `sqrt` (2), `expt` (1), `inters` (5), `textbox` (34).

**`acad_strlsort` (7) — le point chaud du comparateur imbriqué :**
- Dans un comparateur `vl-sort` : `rapport-verification.lsp:216` `(= (car (acad_strlsort (list a b))) a)` — ce prédicat
  est le comparateur passé à `vl-sort` en `rapport-verification.lsp:520`.
- Même motif : `verification-integrite.lsp:15` & `:28`.
- Il existe un **test de non-régression dédié à `acad_strlsort` ré-entré depuis un `vl-sort` en cours** :
  `dev/lisp/test-sorts-imbriques.lsp:93` → le `vl-sort` doit être ré-entrant vis-à-vis de `acad_strlsort`.
- `vl-sort` avec comparateurs numériques `(function <)` : `sig.lsp:261`, `CINOX.LSP:206` ; avec extracteurs
  de clé lambda : `dictionnaires.lsp:205`.

⚠️ À noter : `vl-sort` **dédoublonne les clés égales** — le code pré-décore délibérément les instances avec des
libellés uniques pour éviter de perdre des voies identiques (`rapport-verification.lsp:488`). Le `vl-sort`
doit reproduire la sémantique de dédoublonnage sur clé égale.

---

## 6. Fichiers / divers / ActiveX

**E/S fichiers :** `open` (32), `close` (32), `read-line` (27), `write-line` (56), `read-char` (8),
`write-char` (14), `findfile` (30), `load` (74), `arxload` (1), `getenv` (19), `startapp` (3, ⚠️ lance un shell —
`"SHELL"` aussi via `command`). Système de fichiers VLISP : `vl-directory-files` (5), `vl-file-delete` (4),
`vl-file-systime` (4), `vl-file-directory-p` (4), `vl-file-size` (3), `vl-filename-directory`/`-base`/`-mktemp`
(5/3/2), `vl-registry-read`/`-write` (1/1). Blackboard : `vl-bb-ref`/`vl-bb-set` (4/4). `vl-load-com` (9),
`vl-doc-export`/`vl-acad-defun` (8/2).

**Modèle objet ActiveX VLA/VLAX/VLR (volumineux — à signaler pour headless) :** ~120 noms `vla-*`/`vlax-*`
distincts. Les plus lourds : `vla-put-textstring` (188), `vla-get-layer` (170), `vla-get-insertionpoint` (169),
`vla-get-rotation` (154), `vla-put-textalignmentpoint/height/alignment` (126/126/125), `vla-rotate` (87),
`vlax-ename->vla-object` (78), `vlax-safearray->list` (203), `vlax-variant-value` (196), `vlax-3d-point` (21),
`vlax-curve-*` (getpointatparam/getstartpoint/getendpoint/getparamatpoint/getclosestpointto/getfirstderiv/
getdistatparam — requêtes géométriques), `vlax-invoke`/`vlax-get`/`vlax-put`. Cycle de vie objet :
`vlax-release-object`, `vlax-erased-p`, `vla-startundomark`/`vla-endundomark`. **Réacteurs :**
`vlr-command-reactor` (2), `vlr-acdb-reactor` (1) — `reactors.lsp` ⚠️ événementiel, session uniquement.

Les fonctions `vlax-curve-*` sont celles dont un moteur model-only a le plus besoin (géométrie pure sur les
entités) — p. ex. `pk_geo.lsp`, `voies-chainage.lsp` (calculs de chaînage).

---

## 7. ⚠️ Dépendances interactives / session graphique (bloquants model-only)

Section critique pour la cible headless. Le code suppose un éditeur vivant partout.

| Préoccupation | Fonction(s) | Nb | Notes |
|---|---|---:|---|
| **Tube de commandes AutoCAD** | `command` / `command-s` | 585 / 37 | Pilote *toute* la création de géométrie — voir liste ci-dessous |
| **Boîtes DCL** | `load_dialog`,`new_dialog`,`start_dialog`,`done_dialog`,`action_tile`,`set_tile`,`mode_tile`,`get_tile`,`start_list`/`add_list`/`end_list`,`*_image`,`*_tile` | 170,202,180,654,863,465,301,55,… | **Les modules de commande sont DCL-first.** `action_tile` (863) + `done_dialog` (654) dominent tout le code. Model-only nécessitera de stuber entièrement ces primitives ou de refactorer les commandes. |
| **Invites point / valeur** | `getpoint` (170), `getstring` (26), `getreal` (16), `getangle` (16), `getkword` (14), `getdist` (9), `getint` (7), `getcorner` (3), `initget` (19) | | toutes bloquent sur saisie utilisateur |
| **Sélection au pointeur** | `entsel` (38), `nentsel` (1), `ssget` sans-mode/`_I`/`_C`/point (~23) | | voir §2 |
| **Écran / graphisme** | `osnap` (21), `redraw` (4), `grvecs` (4), `grread` (4), `graphscr` (2), `textscr` (3), `textpage` (1), `menucmd` (2), `sssetfirst` (10) | | pure UI |
| **Messages utilisateur** | `alert` (149), `prompt` (159), `princ` (635), `terpri` (1) | | `alert` ouvre une boîte modale |
| **Dialogue fichier** | `getfiled` (2) | | |
| **Transformations de coordonnées** | `trans` (52) | | nécessite contexte SCU/vue pour certains drapeaux |

**Commandes AutoCAD invoquées via `command`** (tête) : `._LINE` (81), `._TEXT` (74), `._PLINE` (70),
`._LAYER` (48), `._LINETYPE` (44), `._INSERT` (22), `._ERASE` (11), `._CIRCLE` (10), `SHELL` (10 ⚠️ shell),
`._MIRROR` (9), `._MTEXT` (8), `._DONUT` (5), `ZOOM` (4), `._WIPEOUT` (4), `._BROWSER` (4 ⚠️), `._BREAK` (4),
`._ARC` (4), `._SOLID` (3), `._MOVE` (3), `PEDIT` (2), plus `RESOL`, `SCU`, `SAUVEGRD` (commandes maison).
**La géométrie est créée en pilotant ces commandes, pas par `entmake`** dans la plupart des modules — un moteur
model-only doit soit implémenter ces commandes en headless, soit ces modules doivent être portés vers `entmake`.

---

## 8. Matrice type d'entité / codes de groupe

### Créées (`entmake`/`entmakex`, ou via `command`)

| Type DXF | Comment | Codes de groupe écrits | Site |
|---|---|---|---|
| `LINE` | entmakex / `._LINE` | 0,8,10,11 | `generer-palette-rapport.lsp:339` |
| `LWPOLYLINE` | entmake / `._PLINE` | 0,8,90,70,10(×n),40,41,42(bulge),43 | via `vla-addlightweightpolyline` aussi |
| `POLYLINE`+`VERTEX`+`SEQEND` | entmake | 0,8,10,70 | |
| `TEXT` | entmake / `._TEXT` | 0,1,7(style),8,10,11,40,50,72,73 | |
| `MTEXT` | `._MTEXT` / `vla-addmtext` | 0,1,10,40,71 | |
| `CIRCLE` | entmake / `._CIRCLE` | 0,8,10,40 | `creation_blocs.lsp`, `test-voie-chainage.lsp:123` |
| `ARC` | `._ARC` | 0,8,10,40,50,51 | |
| `ELLIPSE` | entmake | 0,10,11,40,41 | |
| `SPLINE` | entmake / `vla-*` | 0,10,… | |
| `SOLID` | `._SOLID` | 0,8,10,11,12,13 | |
| `INSERT` (réf. bloc) | `._INSERT`/`-INSERT`/`vla-insertblock` | 0,2(nom),8,10,41,42,43,50,66(attribs),210 | objet dominant ; `2` = nom de bloc calculé |
| `BLOCK`/`ENDBLK` | paire entmake | 0,8,70,10,2 | `creation_blocs.lsp:69` |
| `DICTIONARY` | entmakex | 0,100 | `dictionnaires.lsp:68` |
| `XRECORD` | entmakex / `vla-setXRecordData` | 0,100,1/300 + codes XData | `mise_a_jour.lsp:1057` |
| `WIPEOUT` | `._WIPEOUT` | — | |
| `DONUT`→`LWPOLYLINE` | `._DONUT` | | |

### Lues (`entget` + `assoc`)

Codes DXF accédés via `(assoc N …)` sur l'arbre, du plus fréquent au moins : **`10`** (point d'insertion/sommet, 27),
**`0`** (type, 21), **`5`** (handle, 16), **`1`** (texte/valeur chaîne, 11), **`-1`** (ename, 8), **`50`** (rotation, 6),
**`2`** (nom bloc/attribut, 6), **`11`** (point d'alignement/2e point, 5), **`-3`** (XData, 5), `42/41` (bulge/échelle, 3+3),
`66` (attributs-suivent, 2), `43` (2), `210` (extrusion, 2), `-2` (2), `51` (1), `40` (1), `3` (1). Constante symbolique
`*AUTOCAD_DXF_CODE_CALQUE*` = **8** (calque) définie en `identifier_non_schms.lsp:25`.

Types d'entité comparés en lecture/égalité (littéraux chaîne) : `INSERT` (14), `BLOCK` (18), `POINT` (13),
`LWPOLYLINE` (11), `REGION` (10), `POLYLINE` (7), `LINE` (7), `XRECORD` (6), `TEXT` (5), `SPLINE` (4), `ARC` (4),
`ELLIPSE` (3), `DICTIONARY` (3), `SEQEND` (2), `SOLID/HATCH/ENDBLK/CIRCLE/ATTRIB` (1 chacun). **INSERT + ses
attributs (via `66`/parcours `entnext`) est le motif de lecture central** — la plupart des objets SCHMS sont des
références de bloc attribuées portant des XData.

---

## Priorités pour l'audit de compatibilité clautolisp

1. **Doivent être fidèles & ré-entrants :** la plomberie de listes DXF `assoc`/`cons`, le round-trip XData
   `entget`/`entmod` avec **listes de filtres multi-application** (`"SCHMS"` + `"SCHMSPLUS"`), le codec XData
   `1000/1002/1005/1040/1070/1071` y compris l'imbrication d'accolades `1002`, `ssget "X"` avec filtres
   `0/2/8/-3/-4(<OR/OR>)`, `vl-sort` **dédoublonnage-sur-clé-égale** + **ré-entrance `acad_strlsort`**
   (testée dans `test-sorts-imbriques.lsp`), la géométrie `vlax-curve-*`.
2. **Dictionnaires/XRecords :** `namedobjdict`/`dictsearch`/`dictadd`/`dictremove` + chemin XRECORD `entmakex`
   (le chemin liste-DXF, pas le chemin ActiveX `vla-setXRecordData`, est le portable).
3. **Tables de symboles :** seulement BLOCK/LAYER/LTYPE/STYLE via `tblsearch`/`tblnext`/`tblobjname`.
4. **Écart model-only (large) :** `command`/`command-s` (622 appels créant de la géométrie), toute la couche DCL
   (`action_tile`/`done_dialog`/…), et toutes les invites `get*`/`entsel`/`alert`/`grread` sont liées à la session.
   Soit implémenter des équivalents `command` headless (LINE/TEXT/PLINE/LAYER/LINETYPE/INSERT/ERASE/CIRCLE/ARC/
   MTEXT/DONUT/WIPEOUT/SOLID/MIRROR/MOVE/BREAK/PEDIT), soit porter ces modules vers `entmake`. `SHELL`/`._BROWSER`/
   `startapp` lancent des processus externes et devraient être des no-ops en headless.

---

## Builtins-used checklist (330 distinct, 47,563 calls)

> Tick each once verified present & behaviour-correct in clautolisp. Counts = head-of-list call occurrences across the 579-file tree (tests + dev/ tooling included). This is the **complete set the code depends on**; it is not filtered against clautolisp's current coverage — that intersection is the audit.

### Core language / control flow (portable — should already work)

- [ ] `setq` — 8537
- [ ] `if` — 4577
- [ ] `defun` — 3094
- [ ] `lambda` — 2520
- [ ] `and` — 953
- [ ] `progn` — 939
- [ ] `cond` — 834
- [ ] `function` — 709
- [ ] `null` — 506
- [ ] `not` — 419
- [ ] `foreach` — 376
- [ ] `mapcar` — 338
- [ ] `or` — 324
- [ ] `while` — 319
- [ ] `exit` — 209
- [ ] `repeat` — 76
- [ ] `type` — 63
- [ ] `apply` — 50
- [ ] `listp` — 35
- [ ] `set` — 33
- [ ] `eval` — 17
- [ ] `boundp` — 16
- [ ] `atom` — 4
- [ ] `quote` — 2
- [ ] `quit` — 1

### List / cons manipulation

- [ ] `cdr` — 2173
- [ ] `assoc` — 1960
- [ ] `list` — 1639
- [ ] `cons` — 1427
- [ ] `car` — 1017
- [ ] `cadr` — 429
- [ ] `nth` — 167
- [ ] `caddr` — 141
- [ ] `member` — 123
- [ ] `append` — 120
- [ ] `length` — 114
- [ ] `reverse` — 101
- [ ] `subst` — 67
- [ ] `caar` — 24
- [ ] `cdar` — 20
- [ ] `last` — 20
- [ ] `cddr` — 14
- [ ] `cadddr` — 12

### String & conversion

- [ ] `strcat` — 1012
- [ ] `itoa` — 341
- [ ] `atoi` — 175
- [ ] `strcase` — 138
- [ ] `substr` — 115
- [ ] `rtos` — 95
- [ ] `strlen` — 64
- [ ] `read` — 47
- [ ] `wcmatch` — 38
- [ ] `atof` — 32
- [ ] `chr` — 27
- [ ] `distof` — 15
- [ ] `angtos` — 14
- [ ] `ascii` — 4
- [ ] `angtof` — 1

### Math / geometry

- [ ] `polar` — 252
- [ ] `fix` — 99
- [ ] `min` — 79
- [ ] `distance` — 72
- [ ] `max` — 71
- [ ] `angle` — 61
- [ ] `cos` — 56
- [ ] `sin` — 54
- [ ] `trans` — 52
- [ ] `abs` — 43
- [ ] `textbox` — 34
- [ ] `numberp` — 33
- [ ] `float` — 16
- [ ] `rem` — 12
- [ ] `atan` — 8
- [ ] `zerop` — 5
- [ ] `inters` — 5
- [ ] `sqrt` — 2
- [ ] `expt` — 1

### Entity mutation & access

- [ ] `entget` — 88
- [ ] `entlast` — 70
- [ ] `entsel` — 38
- [ ] `handent` — 22
- [ ] `entnext` — 20
- [ ] `entmakex` — 11
- [ ] `entdel` — 7
- [ ] `entmod` — 6
- [ ] `entmake` — 6
- [ ] `entupd` — 1
- [ ] `nentsel` — 1
- [ ] `snvalid` — 1

### Selection sets

- [ ] `ssget` — 69
- [ ] `sslength` — 29
- [ ] `ssname` — 27
- [ ] `ssadd` — 12
- [ ] `sssetfirst` — 10

### Dictionaries / symbol tables / app registration

- [ ] `tblsearch` — 37
- [ ] `dictsearch` — 11
- [ ] `namedobjdict` — 7
- [ ] `dictadd` — 7
- [ ] `tblnext` — 4
- [ ] `regapp` — 3
- [ ] `dictremove` — 2
- [ ] `tblobjname` — 1

### System vars / environment / files

- [ ] `setvar` — 269
- [ ] `getvar` — 136
- [ ] `load` — 74
- [ ] `write-line` — 56
- [ ] `open` — 32
- [ ] `close` — 32
- [ ] `findfile` — 30
- [ ] `read-line` — 27
- [ ] `getenv` — 19
- [ ] `write-char` — 14
- [ ] `read-char` — 8
- [ ] `startapp` — 3
- [ ] `arxload` — 1

### I/O & messaging

- [ ] `princ` — 635
- [ ] `prompt` — 159
- [ ] `alert` — 149
- [ ] `print` — 21
- [ ] `prin1` — 7
- [ ] `terpri` — 1

### DCL dialog layer (graphical — stub for model-only)

- [ ] `action_tile` — 863
- [ ] `done_dialog` — 654
- [ ] `set_tile` — 465
- [ ] `unload_dialog` — 327
- [ ] `mode_tile` — 301
- [ ] `new_dialog` — 202
- [ ] `start_dialog` — 180
- [ ] `load_dialog` — 170
- [ ] `get_tile` — 55
- [ ] `vector_image` — 19
- [ ] `start_list` — 18
- [ ] `end_list` — 18
- [ ] `start_image` — 15
- [ ] `end_image` — 15
- [ ] `dimx_tile` — 15
- [ ] `dimy_tile` — 15
- [ ] `fill_image` — 13
- [ ] `slide_image` — 11
- [ ] `add_list` — 2

### Interactive prompts / graphics (graphical — stub for model-only)

- [ ] `command` — 585
- [ ] `getpoint` — 170
- [ ] `command-s` — 37
- [ ] `getstring` — 26
- [ ] `osnap` — 21
- [ ] `initget` — 19
- [ ] `getreal` — 16
- [ ] `getangle` — 16
- [ ] `getkword` — 14
- [ ] `getdist` — 9
- [ ] `getint` — 7
- [ ] `redraw` — 4
- [ ] `grread` — 4
- [ ] `grvecs` — 4
- [ ] `getcorner` — 3
- [ ] `textscr` — 3
- [ ] `getfiled` — 2
- [ ] `graphscr` — 2
- [ ] `menucmd` — 2
- [ ] `textpage` — 1

### VLISP utilities `vl-*` (mostly portable — strings, lists, files, catch-all)

- [ ] `vl-prin1-to-string` — 711
- [ ] `vl-symbol-value` — 127
- [ ] `vl-symbol-name` — 106
- [ ] `vl-catch-all-apply` — 66
- [ ] `vl-princ-to-string` — 66
- [ ] `vl-catch-all-error-p` — 54
- [ ] `vl-list*` — 51
- [ ] `vl-sort` — 24
- [ ] `vl-catch-all-error-message` — 21
- [ ] `vl-string->list` — 19
- [ ] `vl-remove` — 17
- [ ] `vl-list->string` — 12
- [ ] `vl-remove-if` — 11
- [ ] `vl-string-translate` — 11
- [ ] `vl-load-com` — 9
- [ ] `vl-bt` — 8
- [ ] `vl-doc-export` — 8
- [ ] `vl-string-position` — 8
- [ ] `vl-every` — 7
- [ ] `vl-string-search` — 7
- [ ] `vl-string-subst` — 6
- [ ] `vl-directory-files` — 5
- [ ] `vl-filename-directory` — 5
- [ ] `vl-member-if` — 5
- [ ] `vl-position` — 5
- [ ] `vl-bb-ref` — 4
- [ ] `vl-bb-set` — 4
- [ ] `vl-file-delete` — 4
- [ ] `vl-file-directory-p` — 4
- [ ] `vl-file-systime` — 4
- [ ] `vl-remove-if-not` — 4
- [ ] `vl-string-trim` — 4
- [ ] `vl-consp` — 3
- [ ] `vl-file-size` — 3
- [ ] `vl-filename-base` — 3
- [ ] `vl-acad-defun` — 2
- [ ] `vl-filename-mktemp` — 2
- [ ] `vl-some` — 2
- [ ] `vl-member-if-not` — 1
- [ ] `vl-registry-read` — 1
- [ ] `vl-registry-write` — 1
- [ ] `vl-string-left-trim` — 1
- [ ] `vl-string-right-trim` — 1
- [ ] `vl-symbolp` — 1

### ActiveX object model `vla-*` (graphical/session — needs COM or emulation)

- [ ] `vla-put-textstring` — 188
- [ ] `vla-get-layer` — 170
- [ ] `vla-get-insertionpoint` — 169
- [ ] `vla-get-rotation` — 154
- [ ] `vla-put-height` — 126
- [ ] `vla-put-textalignmentpoint` — 126
- [ ] `vla-put-alignment` — 125
- [ ] `vla-rotate` — 87
- [ ] `vla-item` — 18
- [ ] `vla-get-blocks` — 14
- [ ] `vla-delete` — 9
- [ ] `vla-get-handle` — 8
- [ ] `vla-get-effectivename` — 7
- [ ] `vla-copy` — 6
- [ ] `vla-get-name` — 6
- [ ] `vla-get-objectname` — 6
- [ ] `vla-getbulge` — 6
- [ ] `vla-put-insertionpoint` — 6
- [ ] `vla-put-layer` — 6
- [ ] `vla-getboundingbox` — 5
- [ ] `vla-put-color` — 5
- [ ] `vla-put-explodable` — 5
- [ ] `vla-add` — 4
- [ ] `vla-get-layers` — 4
- [ ] `vla-get-modelspace` — 4
- [ ] `vla-move` — 4
- [ ] `vla-put-lineweight` — 4
- [ ] `vla-get-documents` — 3
- [ ] `vla-get-fullname` — 3
- [ ] `vla-get-ownerid` — 3
- [ ] `vla-getinterfaceobject` — 3
- [ ] `vla-objectidtoobject` — 3
- [ ] `vla-saveas` — 3
- [ ] `vla-activate` — 2
- [ ] `vla-endundomark` — 2
- [ ] `vla-get-activedocument` — 2
- [ ] `vla-get-alignment` — 2
- [ ] `vla-get-elevation` — 2
- [ ] `vla-get-propertyname` — 2
- [ ] `vla-get-textalignmentpoint` — 2
- [ ] `vla-get-textstring` — 2
- [ ] `vla-get-value` — 2
- [ ] `vla-getwidth` — 2
- [ ] `vla-intersectwith` — 2
- [ ] `vla-object` — 2
- [ ] `vla-put-name` — 2
- [ ] `vla-put-stylename` — 2
- [ ] `vla-regen` — 2
- [ ] `vla-save` — 2
- [ ] `vla-setbulge` — 2
- [ ] `vla-setwidth` — 2
- [ ] `vla-setxrecorddata` — 2
- [ ] `vla-zoomcenter` — 2
- [ ] `vla-addattribute` — 1
- [ ] `vla-addhatch` — 1
- [ ] `vla-addlightweightpolyline` — 1
- [ ] `vla-addobject` — 1
- [ ] `vla-addvertex` — 1
- [ ] `vla-appendouterloop` — 1
- [ ] `vla-erase` — 1
- [ ] `vla-evaluate` — 1
- [ ] `vla-get-count` — 1
- [ ] `vla-get-height` — 1
- [ ] `vla-get-isdynamicblock` — 1
- [ ] `vla-get-mtextattribute` — 1
- [ ] `vla-get-readonly` — 1
- [ ] `vla-get-tagstring` — 1
- [ ] `vla-get-truecolor` — 1
- [ ] `vla-getextensiondictionary` — 1
- [ ] `vla-insertblock` — 1
- [ ] `vla-movebelow` — 1
- [ ] `vla-open` — 1
- [ ] `vla-put-closed` — 1
- [ ] `vla-put-layeron` — 1
- [ ] `vla-put-mode` — 1
- [ ] `vla-put-mtextattribute` — 1
- [ ] `vla-put-truecolor` — 1
- [ ] `vla-put-value` — 1
- [ ] `vla-startundomark` — 1
- [ ] `vla-update` — 1
- [ ] `vla-updatemtextattribute` — 1

### ActiveX support `vlax-*` (safearray/variant/curve/object — curve fns are geometry, rest is COM)

- [ ] `vlax-safearray->list` — 203
- [ ] `vlax-variant-value` — 196
- [ ] `vlax-ename->vla-object` — 78
- [ ] `vlax-3d-point` — 21
- [ ] `vlax-curve-getstartpoint` — 20
- [ ] `vlax-curve-getpointatparam` — 19
- [ ] `vlax-curve-getendpoint` — 15
- [ ] `vlax-vla-object->ename` — 14
- [ ] `vlax-invoke` — 13
- [ ] `vlax-curve-getparamatpoint` — 12
- [ ] `vlax-get-acad-object` — 12
- [ ] `vlax-curve-getclosestpointto` — 11
- [ ] `vlax-property-available-p` — 8
- [ ] `vlax-curve-getendparam` — 7
- [ ] `vlax-for` — 7
- [ ] `vlax-get` — 6
- [ ] `vlax-make-safearray` — 6
- [ ] `vlax-erased-p` — 5
- [ ] `vlax-object-released-p` — 5
- [ ] `vlax-release-object` — 5
- [ ] `vlax-get-property` — 4
- [ ] `vlax-make-variant` — 4
- [ ] `vlax-safearray-get-u-bound` — 4
- [ ] `vlax-safearray-put-element` — 4
- [ ] `vlax-curve-getfirstderiv` — 3
- [ ] `vlax-invoke-method` — 3
- [ ] `vlax-put` — 3
- [ ] `vlax-curve-getdistatparam` — 2
- [ ] `vlax-curve-getstartparam` — 2
- [ ] `vlax-method-applicable-p` — 2
- [ ] `vlax-safearray-fill` — 2
- [ ] `vlax-variant-type` — 2
- [ ] `vlax-create-object` — 1
- [ ] `vlax-curve-getpointatdist` — 1
- [ ] `vlax-dump-object` — 1
- [ ] `vlax-safearray-get-element` — 1
- [ ] `vlax-safearray-get-l-bound` — 1

### Reactors `vlr-*` (event-driven — session only)

- [ ] `vlr-command-reactor` — 2
- [ ] `vlr-*-reactor` — 1
- [ ] `vlr-acdb-reactor` — 1

### Other `acad_*` / misc

- [ ] `acet-ui-progress` — 10
- [ ] `acad_strlsort` — 7
- [ ] `minusp` — 3
- [ ] `acad_helpdlg` — 1
- [ ] `acet-ui-pickdir` — 1

