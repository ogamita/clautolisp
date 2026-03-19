# autolisp-builtins-core Plan

## Purpose

This file tracks actionable work for the `autolisp-builtins-core` system.

## Current Status

- The first builtin registry exists.
- Initial builtins cover type and predicate behavior plus first Visual LISP symbol helpers.
- These builtins are installable as runtime `SUBR` objects.
- Special operators are explicitly out of scope for this system and belong to the evaluator phase.

## Builtin Tasks

- [x] Define an installable registry for the first builtin functions.
- [x] Implement `type`, `null`, `not`, `atom`, `vl-symbolp`, `vl-symbol-name`, and `vl-symbol-value`.
- [ ] Audit test coverage function-by-function for all currently implemented AutoLISP-facing functions.
- [x] Add an initial `boundp` implementation, while keeping the deeper unbound-versus-bound-to-`nil` semantics explicitly open.
- [x] Add first list builtins such as `car`, `cdr`, `cons`, and `list`.
- [x] Extend the core data/list layer with `append`, `assoc`, `length`, `nth`, and `reverse`.
- [x] Extend the list/alist layer with `last`, `member`, and `subst`.
- [x] Add the next ordinary list predicates and constructors: `listp`, `vl-consp`, and `vl-list*`.
- [x] Add an initial numeric/equality predicate batch: `numberp`, `=`, `/=`, `zerop`, and `minusp`.
- [x] Add the next numeric batch: `<`, `<=`, `>`, `>=`, `abs`, `fix`, and `float`.
- [x] Add the basic arithmetic operators `+`, `-`, `*`, and `/`.
- [x] Add the next arithmetic helpers: `1+`, `1-`, `max`, and `min`.
- [x] Add integer arithmetic helpers `rem` and `gcd`.
- [x] Add integer arithmetic and bitwise helpers `lcm`, `~`, `logand`, `logior`, and `lsh`.
- [x] Add the first string builtins: `strcat`, `strlen`, `substr`, `ascii`, and `chr`.
- [ ] Add first file builtins.
- [ ] Keep the builtin inventory clearly separated from special operators as evaluator work expands.
