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
  de cette forme). Mécanisme retenu : caractère d'échappement `!` en
  tête de ligne obligatoire pour une méta-commande (qui occupe alors
  toute la ligne) ; `!!` en tête annule l'échappement et délivre la
  ligne telle quelle (moins un `!`) comme saisie AutoLISP ordinaire.
  Une ligne n'est donc jamais scindée en deux flux — chaque console a
  juste une file d'attente de lignes passe-plat (pas un tampon de
  caractères) pour le cas où son thread n'est pas encore en train de
  lire au moment où la ligne arrive. Voir §§ « Classification des
  lignes et tamponnage » et « Modèle d'exécution » de la spec.

## État d'avancement
(À tenir à jour à chaque session — noter ici la phase en cours parmi
les 8 listées dans la spec, ce qui est fait, ce qui reste, et toute
divergence assumée par rapport à la spec.)

- Phase courante : 1 (modèle d'arbre CLOS minimal) — pas encore démarrée.

## Conventions de code héritées de clautolisp
- Common Lisp, style du dépôt existant (voir fichiers déjà présents
  sous `~/works/sncf-reseau/src/clautolisp/autolisp-front-end/`).
- `princ`/`prin1`/`print` sont déjà shadowés dans clautolisp pour
  coller à la sémantique AutoLISP — en tenir compte si `dump-node`
  s'appuie dessus, ne pas les re-shadower par accident dans le paquet
  `cadtui`.
