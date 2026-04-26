# clautolisp Plan

## Purpose

This file is the canonical task tracker for the `clautolisp` implementation subproject.

The Org documents in `documentation/` remain the place for architecture and implementation rationale. Actionable work items should be tracked here.

## Current Status

- The implementation architecture is defined at a high level.
- The `autolisp-reader` module is implemented and documented.
- The `autolisp-runtime` module now exists with an initial runtime object model and reader-to-runtime literal mapping.
- The `autolisp-builtins-core` module now exists with the first installable builtin-function registry.
- The runtime/evaluator and builtin layers now both expose a first structured
  `autolisp-runtime-error` path instead of leaking raw Common Lisp failures in
  ordinary execution.
- The `autolisp-file-compat` module now exists as the first dedicated compatibility-audit harness for file, stream, and printer behavior.
- The reader currently supports source spans, strict and lax token modes, line and block comments, concrete comment-preserving reading, external-format-aware file input, and explicit reader options.
- Reader tooling exists:
  - standalone `read-autolisp` executables for SBCL and CCL,
  - a `read-all-autolisp` batch wrapper,
  - FiveAM-based tests on SBCL and CCL,
  - GitLab CI and a dedicated CI container image.
- The reader has successfully read a real AutoLISP corpus of 663 `.lsp` files, 100583 lines, and 3508077 characters.
- The runtime and builtin layers now exist with a first evaluator, structured
  runtime errors, and a substantial portable test corpus.

## Foundation Tasks

- [x] Fill in `clautolisp.asd` with real systems and dependencies.
- [x] Establish the package and source-tree layout.
- [x] Choose and integrate a test framework that works on SBCL and CCL.
- [x] Add CLI-oriented tooling and build targets.
- [ ] Refresh the remaining architecture documents to use the concrete `autolisp-*` module names consistently.

## Reader Tasks

- [x] Define the public reader entry points and result object API.
- [x] Implement the external-format-aware input boundary.
- [x] Implement line-ending normalization.
- [x] Implement tokenization for core AutoLISP syntax.
- [x] Implement parsing for core forms.
- [x] Add source-location tracking.
- [x] Define the first reader-to-runtime handoff through the runtime literal mapping layer.
- [ ] Add syntax error diagnostics regression tests.
- [ ] Add file-based external-format and encoding corpus tests.
- [ ] Add executable conformance tests for strict versus lax behavior against real products.
- [ ] Introduce initial dialect descriptors that can later be shared with the runtime.

## Runtime Tasks

- [ ] Define the AutoLISP symbol abstraction.
- [x] Define the first AutoLISP symbol abstraction and interning layer.
- [x] Record the rule that symbols are name identities and that value/function cells belong to namespaces and frames instead of symbol objects.
- [x] Define explicit namespace objects for document, blackboard, and separate-VLX contexts.
- [x] Define explicit environment objects for dynamic scope.
- [x] Implement literal evaluation and symbol lookup on top of the runtime object model.
- [x] Design the evaluator phase, including explicit treatment of AutoLISP special operators.
- [x] Classify the initial special-operator set into macro-expandable cases versus evaluator-primitive cases.
- [x] Implement the first core special operators in the evaluator rather than in `autolisp-builtins-core`.
- [x] Implement lambda representation and application.
- [x] Implement the `function` special form for named and anonymous function designators.
- [x] Clarify and implement the documented `boundp` semantics.
- [x] Implement the `defun-q` compatibility path, including preserved list definitions and the first reflective accessors.
- [x] Implement a first AutoLISP-visible error mapping layer in the evaluator and builtin registry.
- [x] Specify and implement the first explicit host-entry semantics for current document and current namespace at evaluation entry.
- [x] Add a first runtime file-loading entry point that reads and evaluates forms in an explicit context.
- [x] Add the first `load` builtin wrapper, `*error*` hook path, and Visual LISP catch-all layer.
- [x] Add the first `autoload` builtin with deferred source-loading stubs.
- [x] Add the first session-level `ERRNO` tracking together with the initial `exit` / `quit` and namespace-exit control-transfer layer.
- [ ] Refine the implementation-defined error-code and control-transfer behavior against real product command-loop semantics.

## Builtins and Host Tasks

- [x] Implement the first core builtin registry for `type`, `null`, `not`, `atom`, `vl-symbolp`, `vl-symbol-name`, and `vl-symbol-value`.
- [x] Implement the first numeric, list, equality, string, and file-related builtin families, including the current file/stream/printer layer.
- [x] Audit the implemented builtin families against real product behavior, especially the host-sensitive file and printer corners. (2026-04-26: cross-checked against the BricsCAD V26 / macOS Phase-5 probe run at `autolisp-spec/results/bricscad/macos/20260426T122808Z/`. Implementation now reflects the tested findings — `or` / `and` return T or nil only (not the first non-nil value); `terpri` is zero-arity; `print` writes leading-newline + prin1-form + trailing-space (not a trailing newline); `atoi` and `atof` use strtol/strtod-style lex models with skip-leading-whitespace, optional sign, longest-decimal-digit prefix, trailing-junk truncation, and leading-zero-as-decimal. `atoi` rejects `0x`-prefix forms, returning 0. `atof` deliberately omits C99 hex-float syntax under the conservative clautolisp choice. The autolisp-file-compat scenarios for printer/stream sequences were updated for the corrected `terpri` arity and `print` framing.)
- [ ] Keep ordinary builtins and evaluator-owned special operators separated as the callable surface expands.
- [ ] Define the abstract host API.
- [x] Define explicit path-resolution state for relative AutoLISP pathnames instead of inheriting Common Lisp pathname merging.
- [x] Derive and implement the first pathname-resolution layer supported by the current local spec draft for `open`, `findfile`, and related helpers.
- [ ] Tighten pathname and file compatibility against the fuller spec corpus and real products.
- [x] Introduce a dedicated compatibility-audit subproject for file, stream, and printer behavior.
- [x] Add declarative scenario corpora, executable builtin scenarios, reporting, recursive scenario collection, tag filtering, and SBCL/CCL driver modes in `autolisp-file-compat`.
- [ ] Build a deterministic mock host.
- [ ] Add snapshot and diff support for host-facing regression tests.
- [ ] Add initial dialect and host-profile selection plumbing shared by reader and runtime.

## Delivery Tasks

- [x] Add SBCL and CCL smoke-test coverage for the reader subsystem.
- [x] Add standalone batch reader tooling for SBCL and CCL.
- [x] Add CI coverage for the current test suite.
- [ ] Add a standalone evaluator or batch execution path beyond reader-only tooling.
- [ ] Expand to real host adapters after the mock-host path is stable.
