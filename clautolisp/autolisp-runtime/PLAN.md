# autolisp-runtime Plan

## Purpose

This file tracks actionable work for the `autolisp-runtime` system.

Architecture and design rationale belong in `documentation/design.org`.

## Current Status

- The initial runtime object model is being established.
- Literal reader objects can now be mapped to first runtime values.
- Symbol, environment, evaluator, and builtin execution semantics remain future work.

## Core Type Tasks

- [x] Define the initial Common Lisp representation strategy for AutoLISP values.
- [x] Keep AutoLISP symbols distinct from Common Lisp symbols.
- [x] Define wrapper structures for strings and host-managed runtime objects.
- [x] Define reader-to-runtime mapping for literals and quoted forms.
- [x] Record the design rule that AutoLISP pathnames remain strings while path resolution stays in explicit runtime / host state.
- [ ] Decide which source metadata, if any, survives into runtime objects.

## Symbol and Environment Tasks

- [x] Introduce an AutoLISP symbol structure and interning layer.
- [x] Record the design rule that symbols are name identities and that value/function cells belong to namespaces and frames, not to symbols.
- [ ] Define value-cell and function-cell semantics precisely.
- [ ] Define explicit namespace objects for document, blackboard, and separate-VLX contexts.
- [ ] Define explicit environment objects for dynamic variable scope.
- [ ] Define unbound markers and lookup/update operations.
- [ ] Specify current-document and current-namespace entry semantics at the host boundary.

## Runtime Semantics Tasks

- [x] Implement `read` and `read-from-string` style entry points on top of reader-to-runtime mapping.
- [x] Define initial runtime type designator behavior for `type`.
- [x] Define truthiness helpers and nil-handling utilities.
- [x] Introduce builtin-function and user-function runtime object shapes (`SUBR` and `USUBR`).
- [ ] Clarify `boundp` semantics, especially the documented distinction between unbound symbols and symbols bound to `nil`.
- [ ] Design the evaluator phase explicitly, including the boundary between ordinary builtin calls and special-operator evaluation.
- [ ] Define the initial special-operator set and decide which forms can be modeled as macro-like expansions versus fundamental evaluator cases.
- [ ] Define symbol lookup and update semantics for `setq`, `defun`, and `set-symbol-function` relative to dynamic frames and namespaces.

## Integration Tasks

- [ ] Integrate the runtime object model with `autolisp-builtins-core`.
- [ ] Add runtime tests for additional spec-defined host-visible types.
- [ ] Add evaluator-facing normalization helpers once special-operator work begins.
- [x] Define the explicit path-resolution state and boundary rules needed for the first file builtins.
- [x] Derive and support the first pathname-resolution layer justified by the current AutoLISP spec draft and compatibility corpus.
- [ ] Tighten pathname and host-file compatibility as the fuller evaluator/host model and product-level tests arrive.
