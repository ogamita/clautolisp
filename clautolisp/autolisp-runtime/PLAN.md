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
- [ ] Decide which source metadata, if any, survives into runtime objects.

## Symbol and Environment Tasks

- [x] Introduce an AutoLISP symbol structure and interning layer.
- [ ] Define value-cell and function-cell semantics precisely.
- [ ] Define explicit environment objects for dynamic scope.
- [ ] Define unbound markers and lookup/update operations.

## Runtime Semantics Tasks

- [ ] Implement `read` and `read-from-string` on top of reader-to-runtime mapping.
- [ ] Define runtime type designator behavior for `type`.
- [ ] Define truthiness helpers and nil-handling utilities.
- [ ] Introduce user-function and builtin-function runtime objects.

## Integration Tasks

- [ ] Integrate the runtime object model with `autolisp-builtins-core`.
- [ ] Add runtime tests for additional spec-defined host-visible types.
- [ ] Add evaluator-facing normalization helpers once special forms begin.
