---
title: "TN003 — Valeurs fonctions en AutoLISP"
subtitle: "Utiliser `function` et `apply` pour un code portable"
author: "Pascal Bourguignon"
date: 2026-05-22
lang: fr
---

# TN003 — Valeurs fonctions en AutoLISP

## 1. Contexte

AutoLISP est historiquement décrit comme un **Lisp-1 à portée dynamique** (héritage XLISP) :
un symbole ne possède qu'une seule cellule, consultée aussi bien lorsqu'il est évalué comme
variable que lorsqu'il apparaît en tête de forme d'appel. Conséquence théorique : un
paramètre de fonction devrait pouvoir être appelé directement comme une fonction, puisqu'il
masque (par portée dynamique) toute liaison globale du même nom.

En pratique, les implémentations divergent sur ce point précis :

- **AutoCAD 2022** émet un avertissement (« parameter used as a function ») et peut
  refuser de traiter le paramètre comme fonction appelable.
- **BricsCAD** ignore silencieusement la liaison locale du paramètre quand celui-ci est
  utilisé en position de tête d'appel : le symbole est résolu à la valeur globale du
  même nom, et un troisième argument anonyme (lambda) passé via `function` est purement
  ignoré.

Pour produire du code AutoLISP **portable** entre AutoCAD et BricsCAD, il faut donc, en
dépit du statut nominal de Lisp-1, **traiter les fonctions comme dans un Lisp-2** :

- obtenir explicitement une valeur fonction avec `function`,
- l'appeler explicitement avec `apply`.

## 2. Obtenir une valeur fonction : `function`

La documentation officielle Autodesk pour le formulaire spécial `function` indique :

> *« The `function` function is identical to the `quote` function, except it tells the
> Visual LISP compiler to link and optimize the argument as if it were a built-in
> function or defun. »*
>
> — [AutoLISP Reference, *function*](https://help.autodesk.com/cloudhelp/2022/ENU/AutoCAD-AutoLISP-Reference/files/GUID-CF7E5870-561F-42DB-B134-CCD41EF93A25.htm)

Sémantiquement, `(function foo)` est donc équivalent à `(quote foo)` (avec un indice
d'optimisation pour le compilateur Visual LISP) : la forme retourne soit le **symbole**
`foo` (résolu dynamiquement à l'appel), soit l'**expression lambda** lorsqu'on l'applique
à une lambda anonyme.

```lisp
(defun foo (arg) (list 'result arg))

(setq voo (function foo))                       ; voo détient une valeur fonction
(setq lam (function (lambda (x) (* x 2))))      ; lambda anonyme capturée
```

**Convention** : utiliser `function` (et non `quote`) pour tout argument destiné à être
appelé comme une fonction. Cela documente l'intention et permet au compilateur de
Visual LISP de lier et d'optimiser l'argument.

## 3. Appeler une valeur fonction : `apply`

La documentation officielle Autodesk pour `apply` indique :

> *« The `apply` function passes a list of arguments to, and executes, a specified
> function. The function argument can be either a symbol identifying a `defun`, or a
> lambda expression. »*
>
> — [AutoLISP Reference, *apply*](https://help.autodesk.com/cloudhelp/2023/ENU/AutoCAD-AutoLISP-Reference/files/GUID-0574ADA0-0950-456A-9330-A2518421536E.htm)

Syntaxe :

```
(apply 'function list)
```

Exemples :

```lisp
(apply voo (list 42))           ; => (RESULT 42)
(apply lam (list 21))           ; => 42
(apply '+ '(1 2 3))             ; => 6
(apply 'strcat '("a" "b" "c"))  ; => "abc"
```

**Convention** : pour appeler une fonction détenue dans une *variable* (paramètre formel,
variable locale, slot de structure), toujours passer par `apply`. Ne jamais écrire
`(v arg)` lorsque `v` est une variable censée contenir une fonction — cette forme n'est
pas portable.

## 4. Règle pratique synthétique

| Objectif                                              | Forme portable                              |
|-------------------------------------------------------|---------------------------------------------|
| Définir une fonction nommée                           | `(defun foo (x) ...)`                       |
| Obtenir la valeur fonction d'un nom                   | `(function foo)`                            |
| Stocker une valeur fonction                           | `(setq v (function foo))`                   |
| Lambda anonyme comme valeur                           | `(function (lambda (x) ...))`               |
| Appeler une valeur fonction détenue par une variable  | `(apply v (list arg1 arg2 ...))`            |
| Passer une fonction en paramètre                      | passer `(function foo)`, appeler via `apply`|

**À éviter** (extension BricsCAD, invalide sous AutoCAD 2022) :

```lisp
(defun funny-fun (object good-name)
  (good-name object))           ; ← appel direct d'un paramètre : NON portable
```

**À écrire** à la place :

```lisp
(defun funny-fun (object good-name)
  (apply good-name (list object)))
```

## 5. Exemple complet portable

L'exemple suivant illustre les trois cas typiques de passage de fonction :

- passage du symbole quoté `'good-name` (extension BricsCAD, **non portable** — commenté),
- passage de la valeur du symbole `good-name` (extension BricsCAD, **non portable** — commenté),
- passage de `(function good-name)` — **portable**,
- passage d'une lambda anonyme via `(function (lambda ...))` — **portable**.

```lisp
(defun good-name (object)
  (list 'good-name object))

(defun funny-fun (object good-name)
  (apply good-name (list object)))

(defun doit-in-object (/ object good-name)
  (setq object 33)
  (defun good-name (object)
    (list 'in-object object))
  (defun doit ()
    (list
     ;; extension bricscad, invalid in autocad 2022:
     ;;   (funny-fun object 'good-name)
     ;; extension bricscad, invalid in autocad 2022:
     ;;   (funny-fun object good-name)
     (funny-fun object (function good-name))
     (funny-fun object (function (lambda (object) (list 'expected object))))))
  (doit))

(defun test ()
  (list
   (list
    ;; extension bricscad, invalid in autocad 2022:
    ;;   (funny-fun object 'good-name)
    ;; extension bricscad, invalid in autocad 2022:
    ;;   (funny-fun object good-name)
    (funny-fun 42 (function good-name))
    (funny-fun 42 (function (lambda (object) (list 'expected object)))))
   (doit-in-object)))
```

Résultat attendu (et obtenu, BricsCAD comme AutoCAD) :

```
autolisp> (test)
(((GOOD-NAME 42) (EXPECTED 42))
 ((IN-OBJECT 33) (EXPECTED 33)))
```

L'analyse de chaque cellule :

- `(GOOD-NAME 42)` : `(function good-name)` retourne le symbole `good-name`, résolu
  dynamiquement à l'appel ; au niveau supérieur de `test`, c'est la définition globale
  qui est trouvée.
- `(EXPECTED 42)` : la lambda anonyme est passée et appelée via `apply`.
- `(IN-OBJECT 33)` : dans `doit`, en portée dynamique, `good-name` désigne la
  redéfinition locale faite par `(defun good-name ...)` à l'intérieur de
  `doit-in-object`. La résolution **tardive** du symbole opérée par `function` capture
  cette nouvelle liaison.
- `(EXPECTED 33)` : la lambda anonyme appelée via `apply`, sur l'argument courant
  `object = 33`.

## 6. Pourquoi `function` plutôt que `quote` ?

Sémantiquement équivalents pour le sens du code, `function` apporte deux avantages :

1. **Documentation d'intention** : le lecteur du code sait que l'argument est destiné à
   être appelé.
2. **Optimisation** : la documentation Autodesk précise que le compilateur Visual LISP
   *« lie et optimise l'argument comme s'il s'agissait d'une fonction native ou d'un
   defun »*. Pour une lambda, cela peut représenter un gain notable en code compilé
   (FAS/VLX).

Source : *« Since lambda expressions are defined at run-time, the Visual LISP compiler
cannot optimise these expressions during compilation, as is possible with built-in
AutoLISP functions or named functions defined with defun. […] by using `function`, the
compiler is instructed to optimise the lambda function during compilation to yield
similar performance to built-in or named functions during evaluation »* —
[Lee Mac, *The Apostrophe and the Quote Function*](https://www.lee-mac.com/quote.html).

## 7. Pourquoi `apply` plutôt qu'un appel direct ?

L'appel direct `(v arg)` lorsqu `v` est une variable repose sur la *résolution unique*
des symboles (Lisp-1 à portée dynamique) — c'est ce que stipule la sémantique nominale
d'AutoLISP, confirmée par Autodesk sur son forum :

> *« AutoLISP is actually a Lisp-1 […]. You can use functions as parameters just like
> any other values, without any special quotation and call them directly, without
> FUNCALL. »*
>
> — [Autodesk Community, *Passing and calling functions*](https://forums.autodesk.com/t5/visual-lisp-autolisp-and-general/passing-and-calling-functions-higher-order-functions-support/td-p/2463166)

Mais **les implémentations actuelles ne le respectent pas uniformément** :

- AutoCAD 2022 émet un avertissement sur les paramètres utilisés en position de tête
  d'appel.
- BricsCAD ignore la liaison du paramètre et résout `(good-name object)` vers la
  définition globale, indépendamment de ce qui a été passé en argument — y compris
  lorsqu'une lambda anonyme a été passée, qui devient alors complètement
  inaccessible.

Conséquence pratique : **toujours passer par `apply`** pour appeler une fonction
détenue dans une variable. C'est la seule forme dont la sémantique soit *à la fois*
spécifiée *et* identique entre les deux dialectes.

## 8. Citations de la documentation

- *`function`* — *« The function function is identical to the quote function, except
  it tells the Visual LISP compiler to link and optimize the argument as if it were a
  built-in function or defun. »* — AutoLISP Reference, Autodesk 2022.

- *`apply`* — *« The apply function passes a list of arguments to, and executes, a
  specified function. The function argument can be either a symbol identifying a
  defun, or a lambda expression. »* — AutoLISP Reference, Autodesk 2023.

- *`defun`* — *« Never use the name of a built-in function or symbol for the `sym`
  argument to defun, as this overwrites the original definition and makes the
  built-in function or symbol inaccessible. »* — AutoLISP Reference, Autodesk 2022.
  (Confirme que `defun` opère sur la même cellule que `setq` : un seul espace de
  noms.)

- *Portée* — *« AutoLISP language is a very much simplified LISP with no macro, no
  lexical scoping and no object-oriented interface; the language is dynamically
  scoped »* — *Implementation of the AutoLisp simulator*, P. Péteri.

- *Ombrage* — *« If a variable name is added to the local variables list of a
  function, the global variable with the same name is ignored. AutoLISP has no
  concept of global or local variables per se, it just emulates the effect of it
  using shadowing. »* — Lee Mac / AfraLISP.

## 9. Références

### Documentation Autodesk officielle

- [`function` (AutoLISP/Visual LISP IDE) — 2022](https://help.autodesk.com/cloudhelp/2022/ENU/AutoCAD-AutoLISP-Reference/files/GUID-CF7E5870-561F-42DB-B134-CCD41EF93A25.htm)
- [`defun` (AutoLISP) — 2022](https://help.autodesk.com/cloudhelp/2022/ENU/AutoCAD-AutoLISP-Reference/files/GUID-5269529D-A013-4AB4-AAB7-DBA1C7CA73EB.htm)
- [`apply` (AutoLISP) — 2023](https://help.autodesk.com/cloudhelp/2023/ENU/AutoCAD-AutoLISP-Reference/files/GUID-0574ADA0-0950-456A-9330-A2518421536E.htm)
- [`lambda` (AutoLISP) — 2023](https://help.autodesk.com/cloudhelp/2023/ENU/AutoCAD-AutoLISP-Reference/files/GUID-3B8BB020-1E1A-4FA3-B7B3-B5B20BA04CD9.htm)
- [Passing Parameters to Functions (AutoLISP) — 2024 FRA](https://help.autodesk.com/cloudhelp/2024/FRA/AutoCAD-AutoLISP-Tutorials/files/GUID-E204B037-D6DF-4DDC-9061-E1A2F6E1FA62.htm)
- [AutoCAD 2013 AutoLISP Developer's Guide (PDF)](https://docs.autodesk.com/ACDMAC/2013/ENU/PDFs/acdmac_2013_autolisp_developers_guide.pdf)

### Forums Autodesk

- [Passing and calling functions (higher order functions support?)](https://forums.autodesk.com/t5/visual-lisp-autolisp-and-general/passing-and-calling-functions-higher-order-functions-support/td-p/2463166)
- [Pass a function to a function](https://forums.autodesk.com/t5/visual-lisp-autolisp-and-general/pass-a-function-to-a-function/td-p/1715733)

### Documentation BricsCAD

- [Lisp — BricsCAD Lite & Pro (Bricsys Help Center)](https://help.bricsys.com/en-us/document/bricscad/customization/lisp)
- [BricsCAD V25 LISP Functions — Developer Reference](https://developer.bricsys.com/bricscad/help/en_US/V25/DevRef/source/BricsCADLISPFunctions.htm)

### Articles et tutoriels

- [Lee Mac — *The Apostrophe and the Quote Function*](https://www.lee-mac.com/quote.html)
- [Lee Mac — *Localising Variables*](https://lee-mac.com/localising.html)
- [Lee Mac — *Mapcar & Lambda*](https://www.lee-mac.com/mapcarlambda.html)
- [AfraLISP — *The Define Function (defun)*](https://www.afralisp.net/autolisp/tutorials/the-define-function.php)
- [AfraLISP — *Mapcar and Lambda*](https://www.afralisp.net/autolisp/tutorials/mapcar-and-lambda.php)
- [P. Péteri — *Implementation of the AutoLisp simulator*](http://www.hexahedron.hu/personal/peteri/autolisp/simulator/implement.html)

---

*TN003 — Valeurs fonctions en AutoLISP, 2026-05-22.*
