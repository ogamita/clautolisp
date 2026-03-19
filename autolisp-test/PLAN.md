# autolisp-test Plan

## Purpose

This file is the canonical task tracker for the `autolisp-test` subproject.

The Org documents in `documentation/` remain the place for test-suite rationale, projection strategy, and design notes. Actionable work items should be tracked here.

## Current Status

- The subproject structure exists.
- The development approach is defined.
- The harness and first conformance corpus are not yet implemented.

## Inventory and Mapping Tasks

- [ ] Extract the operator and function inventory from the current AutoLISP draft specification.
- [ ] Mark each item as shared-with-CL, AutoLISP-specific, or host-specific.
- [ ] Build the projection table against `ansi-tests` families.
- [ ] Record semantic mismatches that require rewrites instead of direct projection.

## Harness Tasks

- [ ] Define the `autolisp-test` package and ASDF system.
- [ ] Implement a `deftest`-style registration macro.
- [ ] Add metadata properties to test entries.
- [ ] Add selective execution by language area and operator.
- [ ] Add expected-failure overlays.
- [ ] Define a textual report format.
- [ ] Define the implementation descriptor with implementation, version, host profile, and dialect flags.

## First Corpus Tasks

- [ ] Implement the first projected tests for `if`.
- [ ] Implement the first projected tests for `cond`.
- [ ] Implement the first projected tests for `and`.
- [ ] Implement the first projected tests for `or`.
- [ ] Implement the first projected tests for `quote`.
- [ ] Implement the first projected tests for `progn`.
- [ ] Implement the first projected tests for `setq`.
- [ ] Implement the first projected tests for `cons`, `car`, `cdr`, and `list`.
- [ ] Add explicit evaluation-order tests.
- [ ] Add AutoLISP-visible expected-error tests.

## AutoLISP-Specific Tasks

- [ ] Add coverage for `defun-q`.
- [ ] Add coverage for `defun-q-list-ref`.
- [ ] Add coverage for `defun-q-list-set`.
- [ ] Add coverage for `repeat`, `foreach`, and `while`.
- [ ] Add coverage for `function` and AutoLISP lambda usage.
- [ ] Add coverage for `*error*` and `vl-catch-all-*`.

## Matrix Tasks

- [ ] Define the normalized report schema.
- [ ] Add host-profile fixtures.
- [ ] Add expected-failure overlays per implementation, version, and profile.
- [ ] Archive probe results from real AutoCAD and BricsCAD releases.
