# clautolisp Plan

## Purpose

This file is the canonical task tracker for the `clautolisp` implementation subproject.

The Org documents in `documentation/` remain the place for architecture and implementation rationale. Actionable work items should be tracked here.

## Current Status

- The implementation architecture is defined at a high level.
- The `autolisp-reader` module is implemented and documented.
- The `autolisp-runtime` module now exists with an initial runtime object model and reader-to-runtime literal mapping.
- The `autolisp-builtins-core` module now exists with the first installable builtin-function registry.
- The reader currently supports source spans, strict and lax token modes, line and block comments, concrete comment-preserving reading, external-format-aware file input, and explicit reader options.
- Reader tooling exists:
  - standalone `read-autolisp` executables for SBCL and CCL,
  - a `read-all-autolisp` batch wrapper,
  - FiveAM-based tests on SBCL and CCL,
  - GitLab CI and a dedicated CI container image.
- The reader has successfully read a real AutoLISP corpus of 663 `.lsp` files, 100583 lines, and 3508077 characters.
- The runtime, builtin libraries, host layer, and standalone evaluator are still to be built.

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
- [ ] Define the handoff format from reader objects to later runtime objects.
- [ ] Add syntax error diagnostics regression tests.
- [ ] Add file-based external-format and encoding corpus tests.
- [ ] Add executable conformance tests for strict versus lax behavior against real products.
- [ ] Introduce initial dialect descriptors that can later be shared with the runtime.

## Runtime Tasks

- [ ] Define the AutoLISP symbol abstraction.
- [x] Define the first AutoLISP symbol abstraction and interning layer.
- [ ] Define explicit environment objects for dynamic scope.
- [ ] Implement literal evaluation and symbol lookup on top of the runtime object model.
- [ ] Design the evaluator phase, including explicit treatment of AutoLISP special operators.
- [ ] Classify the initial special-operator set into macro-expandable cases versus evaluator-primitive cases.
- [ ] Implement the first core special operators in the evaluator rather than in `autolisp-builtins-core`.
- [ ] Implement lambda representation and application.
- [ ] Implement AutoLISP-visible error mapping.

## Builtins and Host Tasks

- [x] Implement the first core builtin registry for `type`, `null`, `not`, `atom`, `vl-symbolp`, `vl-symbol-name`, and `vl-symbol-value`.
- [ ] Implement the first numeric, list, equality, string, and file-related builtins beyond the current predicate/introspection set.
- [ ] Keep ordinary builtins and evaluator-owned special operators separated as the callable surface expands.
- [ ] Define the abstract host API.
- [ ] Build a deterministic mock host.
- [ ] Add snapshot and diff support for host-facing regression tests.
- [ ] Add initial dialect and host-profile selection plumbing shared by reader and runtime.

## Delivery Tasks

- [x] Add SBCL and CCL smoke-test coverage for the reader subsystem.
- [x] Add standalone batch reader tooling for SBCL and CCL.
- [x] Add CI coverage for the current test suite.
- [ ] Add a standalone evaluator or batch execution path beyond reader-only tooling.
- [ ] Expand to real host adapters after the mock-host path is stable.
