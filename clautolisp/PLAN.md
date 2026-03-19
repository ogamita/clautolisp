# clautolisp Plan

## Purpose

This file is the canonical task tracker for the `clautolisp` implementation subproject.

The Org documents in `documentation/` remain the place for architecture and implementation rationale. Actionable work items should be tracked here.

## Current Status

- The implementation architecture is defined at a high level.
- The concrete runtime modules are not yet implemented.
- The reader remains the first substantive module to build.
- The first module directory now exists at `clautolisp/autolisp-reader/`.
- An initial reader specification has been drafted in `clautolisp/autolisp-reader/documentation/specification.org`.

## Foundation Tasks

- [ ] Fill in `clautolisp.asd` with real systems and dependencies.
- [ ] Establish the package and source-tree layout.
- [ ] Choose and integrate a test framework that works on SBCL and CCL.
- [ ] Add a CLI skeleton and build targets.

## Reader Tasks

- [ ] Reconcile the high-level development plan with the concrete `autolisp-reader` module naming.
- [ ] Define the public reader entry points and result object API.
- [ ] Implement the external-format-aware input boundary.
- [ ] Implement line-ending normalization.
- [ ] Implement tokenization for core AutoLISP syntax.
- [ ] Implement parsing for core forms.
- [ ] Add source-location tracking.
- [ ] Introduce initial dialect descriptors.

## Runtime Tasks

- [ ] Define the AutoLISP symbol abstraction.
- [ ] Define explicit environment objects for dynamic scope.
- [ ] Implement literal evaluation and symbol lookup.
- [ ] Implement core special forms.
- [ ] Implement lambda representation and application.
- [ ] Implement AutoLISP-visible error mapping.

## Builtins and Host Tasks

- [ ] Implement the first numeric, list, equality, string, and file-related builtins.
- [ ] Define the abstract host API.
- [ ] Build a deterministic mock host.
- [ ] Add snapshot and diff support for host-facing regression tests.

## Delivery Tasks

- [ ] Add SBCL and CCL smoke-test coverage.
- [ ] Add a standalone batch executable path for at least one implementation.
- [ ] Expand to real host adapters after the mock-host path is stable.
