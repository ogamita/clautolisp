# Vers un référentiel de qualité et de sécurité AutoLISP

Recherche complémentaire du **8 octobre 2026** : outils existants, forums
Autodesk/Bricsys/CADTutor, retours d'auteurs et méthode de qualification des
règles. Ce document accompagne le
[catalogue des validations à implémenter](catalogue-validations-autolisp.md).

## Résultat de la recherche

Les sources consultées n'ont pas permis d'identifier un référentiel AutoLISP
institutionnel, versionné et reconnu comparable à MISRA C/C++ ou CERT C. Ce
constat porte sur cette recherche, pas sur une preuve d'inexistence mondiale.
Il existe en revanche des vérificateurs de code et un corpus d'expérience
suffisant pour construire un référentiel de projet vérifiable.

La page [Vector indiquée](https://www.vector.com/en/business-unit/code-testing-and-verification/standards-and-compliance/coding-security/)
présente des référentiels pour C/C++ et leur contrôle par PC-lint Plus, ainsi
que des règles personnalisées. Elle n'annonce pas de prise en charge AutoLISP.
L'analogie utile est la démarche : contrats précis, analyse automatique,
exceptions justifiées et traçabilité. Les règles de mémoire ou de pointeurs de
C ne se transposent pas directement aux entités et valeurs AutoLISP.

## Outils et corpus repérés

Les capacités ci-dessous sont celles des documentations ou auteurs consultés.
Aucun de ces outils n'a été installé ni évalué sur les sources du projet pendant
cette recherche.

| Candidat | Ce qui est établi | Utilité et limite pour parser-lisp |
| --- | --- | --- |
| Visual LISP IDE, Check | Autodesk décrit des contrôles avant exécution : parenthèses, définitions et arguments. [Documentation][vlisp-check]. | Oracle complémentaire pour fixtures AutoCAD ; ce n'est pas un référentiel de sûreté ni une preuve de couverture de notre catalogue. |
| BLADE, Check Syntax & Variables | Bricsys documente analyse de syntaxe/variables et filtres ; Torsten Moses mentionne l'analyse des fonctions manquantes et dépendances. [Documentation][blade-doc], [forum dépendances][blade-deps], [forum diagnostic][blade-parens]. | Comparer diagnostics et faux positifs dans BricsCAD. Ni interface CI autonome ni couverture exhaustive établies par ces sources. |
| `@atlisp/lint` | README éditeur : règles de syntaxe, sécurité, conventions, complexité, analyse projet, JSON et hooks ; phase SBCL optionnelle. Version `0.2.25` constatée dans le registre npm. [Paquet][atlisp], [métadonnées][atlisp-registry]. | Candidat concret à évaluer ; plusieurs descriptions/corrections exigent une vérification sémantique. Voir ci-dessous. |
| Lee Mac Programming | Tutoriels et fonctions originales : erreurs, sélection, noms de blocs. [Erreurs][lee-error], [nom effectif][lee-name], [ssget][lee-ssget]. | Bon corpus d'exemples ; distinguer API documentée et comportement non documenté ou ancien. Ce n'est pas une norme. |
| Forums Autodesk, Bricsys, CADTutor | Cas rapportés avec code, environnement et réponses techniques. Sources dans la table de traçabilité suivante. | Transformer un incident en fixture ; ne pas généraliser une solution ponctuelle à toutes les versions. |
| `clautolisp` | Le dépôt présente un projet de spécification, une implémentation et des tests de conformité AutoLISP. [Dépôt de l'auteur][clautolisp]. | Piste complémentaire pour les contrats du langage ; ne pas présenter le projet comme une norme indépendante des éditeurs. Pas d'audit de conformité effectué ici. |

### Un linter existant n'est pas un oracle sémantique

Le README de `@atlisp/lint` annonce 84 règles de phase simple et propose des
corrections automatiques. Il contient notamment les transformations ci-dessous.
Elles doivent être **rejetées comme réécritures générales**, à partir des contrats
AutoLISP et de contre-exemples élémentaires, avant toute adoption de l'outil.
Il s'agit d'une revue de la documentation, pas d'un constat obtenu en exécutant
sa version publiée. [README éditeur][atlisp-registry].

| Proposition décrite | Contre-exemple / décision pour notre référentiel |
| --- | --- |
| Réduire un double `not` à un seul | `(not (not 7))` produit T, `(not 7)` nil : inversion du résultat. |
| Remplacer `(and x)` par `x` | Avec `x = 7`, le premier produit T, le second 7. Équivalence de vérité éventuelle, pas de valeur. [and][and-ref]. |
| Réduire `''x` à `'x` | Le premier conserve une forme citée, le second donne le symbole : valeurs différentes. [quote][quote-ref]. |
| Décrire `(quit)`/`(exit)` comme arrêt du processus CAO | Le contrat Autodesk décrit un abandon de l'application Lisp avec retour au prompt. Ne pas confondre avec une commande de fermeture de la CAO. [exit][exit-ref], [quit][quit-ref]. |

Les règles mentionnant `let`, `in-package` ou un registre de modules doivent
être rattachées à une bibliothèque/dialecte identifié. Un lecteur Common Lisp
ne démontre pas à lui seul la validité AutoLISP. Aucune correction automatique
ni validation SBCL ne sera adoptée sans tests différentiels du dialecte visé.

## Retours d'expérience transformés en règles

Les messages des forums restent des témoignages datés, même lorsqu'une réponse
est acceptée. La colonne « consolidation » indique le fondement supplémentaire
ou le travail restant. Les ID renvoient au catalogue, où figurent détection,
faux positifs et tests positifs/négatifs. Aucun exemple de forum n'est exécuté
ou recopié intégralement.

| Source primaire et contexte | Enseignement exploitable | Règle et consolidation |
| --- | --- | --- |
| [CADTutor, Osnap issues in code, juin 2020][forum-osnap] : Hsanon, réponses de dlanorh et pkenewell | Un point fourni à une commande peut subir les accrochages ; une instruction déplacée peut aussi devenir la condition de `while`. | CMD-007 et tests de contrôle de flux. Prévoir fixture OSMODE activé ; ne pas attribuer tous les échecs de cette discussion aux seuls accrochages. |
| [CADTutor, Getpoint and Object Snap Overrides, mars 2016][forum-osnap2] : broncos15, confirmation du demandeur | Le point acquis et le point effectivement utilisé par la commande peuvent différer. | CMD-007 : protection à chaque invite concernée, puis comparaison des coordonnées produites. |
| [CADTutor, Help with 1987 Balloon Lisp, décembre 2013][forum-text] | Le programme distingue les styles de texte à hauteur fixe. | CMD-008 ; confirmé par le contrat [TEXT][text-ref]. |
| [Autodesk, Insert common block, mars 2017][forum-entlast] | Vérifier la création avant d'exploser `entlast`, pour ne pas viser une entité antérieure. | DXF-007 ; contrat [entlast][entlast-ref]. Le simple changement d'identité reste insuffisant face à des effets concurrents. |
| [Autodesk, hatch, octobre 2015][forum-polyline] : réponse de ВeekeeCZ | Un traitement pour polylignes historiques ne convient pas directement à LWPOLYLINE. | DXF-009 ; confirmé par le schéma [LWPOLYLINE][lwpoly-ref]. |
| [Lee Mac, Effective Block Name][lee-name], fonction de l'auteur | Le nom de représentation d'un bloc dynamique peut être anonyme. | DXF-008 ; confirmé par [EffectiveName][effective-ref]. |
| [Lee Mac, Error Handling][lee-error], exemples de l'auteur | L'erreur peut intervenir avant la sauvegarde de tous les états ; le nettoyage doit le supporter. | ETAT-005 ; compléter ETAT-002/003 par injection d'erreur à chaque étape. |
| [CADTutor, visibility, septembre 2012][forum-visible] : réponse de Lee Mac | La sélection polygonale dépend de la vue dans les scénarios rapportés. | SEL-005 : REX à reproduire par produit/version, pas loi universelle déduite d'un forum. |
| [Bricsys, mismatched parens, août 2020][blade-parens] : diagnostic de Torsten Moses | L'erreur peut venir d'un fichier chargé ; distinguer initialisation de session et par dessin. | QUAL-002, PORT-006. Tester deux dessins ; règles de démarrage spécifiques à chaque moteur. |
| [Bricsys, Performance considerations, août 2022][forum-performance] : réponse de Torsten Moses | `command`/`command-s`/`vl-cmdf` ne doivent pas être considérés comme identiques dans leur évaluation. | CMD-004/PORT-005 ; confirmer par contrats et essais, ne pas promettre un gain de vitesse universel. |
| [Bricsys, error message on file open, août 2021][forum-error] | L'auteur du correctif distingue appels de commandes natives et fonctions C: Lisp personnalisées. | SYM-006/CMD-006 : résoudre la nature de la cible avant de suggérer une forme d'appel. |

### Limites à conserver explicitement

- La visibilité de `ssget` est une règle REX : tester vue, espace, mode de
  sélection, produit et version avant de l'activer comme avertissement stable.
- Le fil Bricsys sur les performances avance aussi un ordre d'évaluation précis
  pour `vl-cmdf`. Le catalogue retient seulement la préévaluation documentée ;
  l'ordre entre arguments reste un sujet de sonde, pas une règle promue ici.
- Une déclaration de style dans un outil n'est pas un contrat du langage.
  `assoc` sans `cdr`, une récursion, une fonction retournant nil ou un `entget`
  dans une boucle peuvent être parfaitement intentionnels.

## Structure proposée du référentiel de projet

Nom de travail : **Référentiel de validation AutoLISP/CAO**. Ce nom ne doit pas
être présenté comme une certification MISRA, AUTOSAR, CERT ou d'un éditeur.
L'organisation suivante est une proposition propre au projet.

Une règle devrait porter, en plus des colonnes du catalogue :

| Champ | Contenu attendu |
| --- | --- |
| Identité | ID stable, titre, version de règle, classe et historique des changements. |
| Exigence | Formulation précise, portée et préconditions ; obligation de projet distincte de sévérité du diagnostic. |
| Fondement | Source DOC (éditeur), REX (témoignage primaire), PROP (politique déduite), avec date/version et désaccords connus. |
| Risque | Effet possible : mauvais résultat, corruption d'état, perte de données, blocage, exécution inattendue ou maintenance. |
| Applicabilité | Produit, version, OS, édition, dépendances, mode batch/interactif, fonctions couvertes. |
| Vérifiabilité | Automatique, partielle ou revue humaine ; information nécessaire pour éviter une fausse certitude. |
| Validation | Exemple conforme/non conforme, cas inconnu, test de non-régression, sondes moteur et résultats datés. |
| Dérogation | Motif, portée, responsable, preuve compensatoire, échéance de révision ; jamais seulement « ignorer tous les warnings ». |
| État | Candidate → documentée → reproduite → implémentée → qualifiée pour une matrice de cibles donnée. |

DOC ne signifie pas « reproduite ». Un fait officiel peut dépendre du moteur,
et une recommandation interne doit encore justifier ses faux positifs.
REX ne signifie pas « faux » : c'est une source de cas de test, à consolider.

### Politique d'adoption proposée

- **Socle bloquant** : uniquement erreurs prouvées et règles qualifiées pour le
  profil de production. Syntaxe non comprise = analyse incomplète distincte.
- **Robustesse recommandée** : avertissements de flux, état CAO, entités,
  ressources et portabilité ; revue ou justification explicite.
- **Conventions facultatives** : nommage, longueur, présentation et complexité.
  Aucun seuil numérique ne devient une norme du langage.
- **Sécurité** : suivre origine des données et effets sensibles, plutôt
  qu'interdire sans distinction `eval`, `load` ou `startapp` légitimes.

Pour un parc existant : enregistrer un état initial des diagnostics, traiter
les nouveaux écarts séparément de la dette, conserver la configuration exacte
et réexaminer les suppressions devenues inutiles. Le rapport doit montrer les
fichiers analysés, ignorés et partiellement compris, ainsi que les règles non
applicables. Un rapport vide ne constitue pas une attestation de conformité.

### Évaluation des outils avant adoption

Comparer BLADE, VLISP, `@atlisp/lint` et parser-lisp sur un même corpus figé de
cas AutoLISP légaux/illégaux, avec profils et bibliothèques déclarés. Mesurer :
cas détectés, faux positifs, cas inconnus reconnus, stabilité, localisation,
facilité CI et conservation de la sémantique des corrections. Inclure les
contre-exemples `not`, `and`, `quote`, `exit`, les citations, les noms protégés,
les fichiers CP1252/UTF-8 et les appels indirects.

Cette comparaison est un travail à réaliser ; la recherche présente n'affirme
ni la supériorité d'un outil ni sa qualification pour un usage critique.

## Références

Les sources sont liées au plus près des constats ; les définitions suivantes
fixent les URL consultées. Le registre npm a été lu comme métadonnées et README,
sans installation ni exécution du paquet. La page HTML npm renvoyait HTTP 403
à l'ouverture directe ; la version a été vérifiée dans le registre.

[vlisp-check]: https://help.autodesk.com/cloudhelp/2026/CHS/AutoCAD-AutoLISP/files/GUID-DCBD88E0-F69D-4D45-B5D6-52FD4A7AB768.htm
[blade-doc]: https://developer.bricsys.com/bricscad/help/en_US/V23/DevRef/source/V12.htm
[blade-deps]: https://forum.bricsys.com/discussion/38207/descoder-project-all-files-in-a-directory
[blade-parens]: https://forum.bricsys.com/discussion/36193/newbie-how-to-request-finding-mismatched-parens-using-blade
[atlisp]: https://www.npmjs.com/package/@atlisp/lint
[atlisp-registry]: https://registry.npmjs.org/@atlisp%2Flint
[clautolisp]: https://github.com/ogamita/clautolisp
[lee-error]: https://www.lee-mac.com/errorhandling.html
[lee-name]: https://www.lee-mac.com/effectivename.html
[lee-ssget]: https://www.lee-mac.com/ssget.html
[and-ref]: https://help.autodesk.com/cloudhelp/2023/ENU/AutoCAD-AutoLISP-Reference/files/GUID-59FC3712-44E9-4D09-A611-5B153A26AE5E.htm
[quote-ref]: https://help.autodesk.com/cloudhelp/2025/ENU/AutoCAD-LT-AutoLISP-Reference/files/GUID-18F7E287-CB2F-4150-9A07-CE23C3F9E604.htm
[exit-ref]: https://help.autodesk.com/cloudhelp/2024/DEU/AutoCAD-LT-AutoLISP-Reference/files/GUID-677B9EC8-C35D-4736-AE59-1BDB12E540AF.htm
[quit-ref]: https://help.autodesk.com/cloudhelp/2016/RUS/AutoCAD-AutoLISP/files/GUID-E15E32AE-D1FB-41EC-B2C7-AFFD4095842C.htm
[forum-osnap]: https://www.cadtutor.net/forum/topic/70737-osnap-issues-in-code/
[forum-osnap2]: https://www.cadtutor.net/forum/topic/59732-getpoint-and-object-snap-overrides/
[forum-text]: https://www.cadtutor.net/forum/topic/49627-help-with-1987-balloon-lisp/
[text-ref]: https://help.autodesk.com/view/ACD/2026/ENU/?caas=caas%2Fdocumentation%2FCIV3D%2F2014%2FENU%2FfilesACD%2FGUID-D1C664DD-63D9-467E-8EC1-2F5A1777A924-htm.html
[forum-entlast]: https://forums.autodesk.com/t5/visual-lisp-autolisp-and-general/insert-common-block/td-p/6920548
[entlast-ref]: https://help.autodesk.com/cloudhelp/2023/ENU/AutoCAD-AutoLISP-Reference/files/GUID-75DBA9B2-034B-4377-A4E2-21D37B298D86.htm
[forum-polyline]: https://forums.autodesk.com/t5/visual-lisp-autolisp-and-general/hatch/td-p/5877353
[lwpoly-ref]: https://help.autodesk.com/cloudhelp/2024/ENU/AutoCAD-DXF/files/GUID-748FC305-F3F2-4F74-825A-61F04D757A50.htm
[effective-ref]: https://help.autodesk.com/cloudhelp/2022/ENU/AutoCAD-ActiveX-Reference/files/GUID-A87607A4-D7F9-40B3-94B5-B9D88011DEB5.htm
[forum-visible]: https://www.cadtutor.net/forum/topic/41309-visibility/
[forum-performance]: https://forum.bricsys.com/discussion/37756/performance-considerations
[forum-error]: https://forum.bricsys.com/discussion/36810/error-message-on-file-open
