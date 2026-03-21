# autolisp-builtins-core Plan

## Purpose

This file tracks actionable work for the `autolisp-builtins-core` system.

## Current Status

- The first builtin registry exists.
- Initial builtins cover type and predicate behavior plus first Visual LISP symbol helpers.
- These builtins are installable as runtime `SUBR` objects.
- Builtin `SUBR` installation now wraps builtin failures into structured
  `autolisp-runtime-error` conditions instead of leaking raw Common Lisp errors.
- Special operators are explicitly out of scope for this system and belong to the evaluator phase.

## Builtin Tasks

- [x] Define an installable registry for the first builtin functions.
- [x] Implement `type`, `null`, `not`, `atom`, `vl-symbolp`, `vl-symbol-name`, and `vl-symbol-value`.
- [ ] Audit test coverage function-by-function for all currently implemented AutoLISP-facing functions.
- [x] Add the documented `boundp` semantics, including the visible `nil` result for both unbound and `nil`-bound symbols and the compatibility side effect that materializes an undefined symbol as `nil`.
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
- [x] Add the first file builtins: `open`, `close`, `read-line`, `read-char`, `write-line`, and `write-char`.
- [x] Make `open` honor an explicit encoding argument in the conservative portable cases already accepted by the implementation.
- [x] Replace the current conservative absolute-path-only file boundary with a first spec-derived pathname layer and explicit runtime path state for `open`, `findfile`, and `findtrustedfile`.
- [x] Add the next pathname/file helpers: `vl-directory-files`, `vl-file-directory-p`, `vl-filename-base`, `vl-filename-directory`, and `vl-filename-extension`.
- [x] Add the next file-system mutation/introspection helpers: `vl-file-delete`, `vl-file-rename`, `vl-file-size`, and `vl-mkdir`.
- [x] Add the next compatibility-sensitive file helpers: `vl-file-copy`, `vl-file-systime`, and `vl-filename-mktemp`.
- [x] Add the printer/output helpers that can target command output or file descriptors: `prin1`, `princ`, `print`, `terpri`, `prompt`, `vl-prin1-to-string`, and `vl-princ-to-string`.
- [x] Fill the remaining basic stream gap for `read-char` without a file descriptor by reading from standard input conservatively.
- [x] Implement the documented `read` entry point on top of the runtime reader mapping.
- [x] Add the `defun-q` compatibility accessors `defun-q-list-ref` and `defun-q-list-set` on top of the runtime compatibility-definition layer.
- [x] Tighten the current file layer for the documented compatibility-sensitive areas we can justify from the local spec draft, including `open` encodings, `vl-file-systime`, `vl-filename-mktemp`, and `vl-file-copy`.
- [x] Route builtin failures through structured AutoLISP-visible runtime errors with builtin-level metadata.
- [ ] Audit the completed file builtin family against real Autodesk/BricsCAD behavior for the remaining under-specified host-sensitive corners.
- [ ] Keep `load` and `autoload` out of `autolisp-builtins-core`; they belong to evaluator/runtime execution work even though they are file-adjacent.
- [ ] Keep the builtin inventory clearly separated from special operators as evaluator work expands.
