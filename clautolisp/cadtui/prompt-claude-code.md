# Prompt à donner à Claude Code pour démarrer l'implémentation de cadtui

Tu travailles dans le dépôt `clautolisp` (implémentation d'AutoLISP en
Common Lisp). Lis d'abord entièrement `cadtui/documentation/cadtui-specifications.org` : c'est la
spécification normative d'un nouveau sous-système, `cadtui`, qui
représente l'interface utilisateur d'un CAD (menus, bandeaux, fenêtres
de dessin, vue CAD avec entités/poignées, alertes, dialogues DCL,
console) comme une arborescence d'objets dumpable et pilotable par un
petit langage textuel d'interaction, en remplacement de la souris —
pour permettre le test interactif de dialogues DCL et de commandes CAD
sans GUI réel.

Lis aussi le `CLAUDE.md` associé (mémoire du projet) et mets-le à jour
à chaque session significative (état d'avancement, décisions prises).

Objectif de cette première session : implémenter la **phase 1** de la
roadmap (§ "Roadmap d'implémentation" de la spec) :

1. Crée le paquet/système ASDF `cadtui` (ou le nom déjà en usage dans
   le dépôt s'il existe une convention — regarde comment
   `autolisp-front-end` est structuré et suis la même convention).
2. Implémente les classes CLOS décrites au § "Modèle de données" de la
   spec (`ui-node` et ses sous-classes minimales : au moins
   `ui-application`, `ui-console`, et de quoi représenter une hiérarchie
   générique — les sous-classes plus spécifiques (`ui-entity`,
   `ui-dialog`...) peuvent rester des stubs pour l'instant).
3. Implémente `dump-node` (format générique décrit au § "Dump : format
   et pagination" — sans te préoccuper encore de la pagination réelle
   sur des grandes listes, juste le format d'une ligne et
   l'indentation hiérarchique), `find-node` et `resolve-target` (chemin
   absolu `/application/...` uniquement pour l'instant — les références
   `D<n>.clé` peuvent attendre la phase 2 avec l'interpréteur).
4. Écris des tests (framework déjà utilisé dans le dépôt si possible,
   sinon `fiveam` ou équivalent standard) qui construisent un petit
   arbre à la main (application → console, plus une ou deux branches
   fictives) et vérifient le format de `dump-node` et la résolution de
   chemins par `resolve-target`.
5. Ne touche pas encore à l'interpréteur du langage d'interaction (§5
   de la spec), ni à l'intégration DCL, ni au routage `--host
   cador`/`--host cadtui` — ce sont les phases suivantes.

Contraintes :

- Respecte le style Lisp déjà en usage dans le dépôt (regarde le code
  existant avant d'écrire quoi que ce soit).
- N'introduis aucune dépendance externe non déjà utilisée dans le
  dépôt sans le signaler explicitement et demander confirmation avant
  de l'ajouter au système ASDF.
- À la fin de la session, mets à jour la section "État d'avancement"
  de `CLAUDE.md` avec ce qui a été fait, ce qui reste pour clore la
  phase 1, et toute divergence assumée par rapport à la spec (avec la
  raison).
- Si un point de la spec te semble sous-spécifié ou ambigu au moment de
  l'implémenter, note-le dans `CLAUDE.md` sous une section "Questions
  ouvertes" plutôt que de trancher silencieusement.

Commence par un résumé en 5-10 lignes de ton plan avant d'écrire du
code.
