# autolisp-runtime Plan

## Purpose

This file tracks actionable work for the `autolisp-runtime` system.

Architecture and design rationale belong in `documentation/design.org`.

## Current Status

- The initial runtime object model is being established.
- Literal reader objects can now be mapped to first runtime values.
- Symbol, namespace, and dynamic-frame structures now exist.
- A first evaluator slice now covers literal evaluation, symbol lookup, `quote`,
  `setq`, `progn`, `if`, `cond`, `and`, `or`, `while`, `repeat`, `foreach`,
  `lambda`, `function`, `defun`, and user-function calls.
- The evaluator now routes its own failures through an initial
  `autolisp-runtime-error` condition instead of exposing raw Common Lisp errors
  directly.

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
- [x] Define value-cell and function-cell semantics precisely. (2026-04-26: superseded by the single-cell rule below — AutoLISP is Lisp-1 and the runtime now models it that way.)
- [x] Collapse value-cell and function-cell into a single per-symbol binding cell so SETQ and DEFUN obey the AutoLISP Lisp-1 semantics confirmed by direct BricsCAD V26 probe and Bricsys defect SR44723. (2026-04-26: see autolisp-spec chapter 7, "Single-Cell Symbol Binding", and `results/bricscad/macos/20260426T155521Z-namespace/`. The runtime now uses one `binding-cell` struct per symbol per namespace; lookup-variable / lookup-function walk the same scope chain; lookup-function additionally requires the value to be a callable subr/usubr, otherwise the eval call dispatch surfaces :undefined-function.)
- [x] Define explicit namespace objects for document, blackboard, and separate-VLX contexts.
- [x] Define explicit environment objects for dynamic variable scope.
- [x] Define unbound markers and lookup/update operations.
- [x] Specify current-document and current-namespace entry semantics at the host boundary.
- [x] Add explicit runtime-session document registration plus conservative blackboard and propagation primitives for cross-document value state.
- [x] Add the first conservative function bridge between separate VLX namespaces and associated document namespaces.

## Runtime Semantics Tasks

- [x] Implement `read` and `read-from-string` style entry points on top of reader-to-runtime mapping.
- [x] Define initial runtime type designator behavior for `type`.
- [x] Define truthiness helpers and nil-handling utilities.
- [x] Introduce builtin-function and user-function runtime object shapes (`SUBR` and `USUBR`).
- [x] Clarify `boundp` semantics, especially the documented distinction between unbound symbols and symbols bound to `nil`.
- [x] Design the evaluator phase explicitly, including the boundary between ordinary builtin calls and special-operator evaluation.
- [x] Define the initial special-operator set and decide which forms can be modeled as macro-like expansions versus fundamental evaluator cases.
- [x] Define symbol lookup and update semantics for `setq`, `defun`, and `set-symbol-function` relative to dynamic frames and namespaces.
- [x] Implement the first evaluator special operators: `quote`, `setq`, `progn`, `if`, `cond`, `and`, `or`, `while`, `repeat`, `foreach`, `lambda`, `function`, `defun`, and `defun-q`.
- [x] Introduce an initial AutoLISP-visible runtime error condition for evaluator failures and wrapped host-Lisp errors.
- [x] Extend error mapping so builtin and host layers also preserve structured AutoLISP-visible error codes consistently.
- [x] Add a first runtime `load` entry point that reads and evaluates a file in an explicit evaluation context.
- [x] Add a first `*error*` hook path and runtime catch-all error object for the Visual LISP catch-all family.
- [x] Add the first session-level `ERRNO` tracking and the initial distinction between `exit`, `quit`, and namespace-exit bridges.
- [x] Make the active evaluation context dynamically visible during `SUBR` execution so namespace-sensitive builtins resolve against the current call context.
- [x] Refine the first evaluator call-error codes so invalid operators, invalid function objects, and wrapped `SUBR` host failures no longer collapse into generic runtime errors.
- [x] Separate non-local control transfer from trapped errors so `vl-catch-all-*` does not swallow `exit`, `quit`, or `vl-exit-*`.
- [x] Refine the first implementation-defined `ERRNO` mapping from a binary `0/1` result into a documented provisional compatibility table.
- [x] Separate provisional `ERRNO` classes for invalid-form failures, file/stream/path failures, and wrapped host-runtime failures.
- [ ] Refine that provisional `ERRNO` table against real Autodesk/BricsCAD evidence.
- [x] Refine `exit`, `quit`, and namespace-exit control transfer against real product command-loop behavior. (2026-04-26: BricsCAD V26 vendor pages confirm `exit` and `quit` are documented identically — same zero-arity signature, same effect, same abort-channel message `; error : quit / exit abort`. Phase-5 closure recorded; the historical hypothesis of a vendor-recognised semantic distinction is not supported by current evidence. The runtime treats them as alternative spellings of the same primitive.)
- [ ] Refine runtime session/document/blackboard propagation semantics against real Autodesk/BricsCAD namespace behavior.

## Integration Tasks

- [ ] Integrate the runtime object model with `autolisp-builtins-core`.
- [ ] Add runtime tests for additional spec-defined host-visible types.
- [x] Add evaluator-facing normalization helpers once special-operator work begins.
- [x] Define the explicit path-resolution state and boundary rules needed for the first file builtins.
- [x] Derive and support the first pathname-resolution layer justified by the current AutoLISP spec draft and compatibility corpus.
- [ ] Tighten pathname and host-file compatibility as the fuller evaluator/host model and product-level tests arrive.
- [x] Plumb the shared dialect descriptor through runtime sessions and add `run-autolisp-file` / `run-autolisp-string` entry points for the standalone evaluator. (2026-04-26: `runtime-session` carries a `dialect` slot, `current-evaluation-dialect` returns it from the active context, `derive-reader-options-for-dialect` builds reader options from the descriptor, and the new entry points install a fresh session under the chosen dialect before evaluating. Smoke-tested via `autolisp-runtime/tests/evaluator-tests.lisp`.)
