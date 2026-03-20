# autolisp-file-compat Plan

## Purpose

This file tracks actionable work for the `autolisp-file-compat` system.

Architecture and rationale belong in `documentation/design.org`.

## Current Status

- The module is being introduced as a dedicated compatibility-audit subsystem.
- A first local runner captures file artifacts and compares bytes, text, and
  line structure under controlled encoding and newline settings.
- Declarative scenario files, a command-line driver, machine-readable reports,
  and SBCL/CCL runner modes now exist.
- The scenario corpus now supports recursive directory collection, tag-based
  filtering, and aggregate summary reporting.

## Foundation Tasks

- [x] Create the `autolisp-file-compat` ASDF system and module layout.
- [x] Record the initial design for scenario-driven compatibility auditing.
- [x] Implement a first local compatibility runner API with artifact capture.
- [x] Implement byte, text, and line comparison helpers.

## Runner Tasks

- [x] Add a declarative scenario corpus format.
- [x] Add JSON or s-expression report emission for machine-readable audit runs.
- [x] Add a command-line driver for batch compatibility runs.
- [x] Add runner adapters for SBCL and CCL host-specific comparison modes.
- [ ] Add product-runner adapters for real CAD environments.

## Scenario Tasks

- [x] Add newline and encoding matrix scenarios.
- [ ] Add pathname-resolution and search-path scenarios.
- [ ] Add file-mutation scenarios for copy, rename, delete, size, and temp-file behavior.
- [ ] Add printer/read-back scenarios for `prin1`, `princ`, `print`, and `read`.
- [x] Classify scenarios by expected status: portable, implementation-sensitive, host-sensitive, or unknown.

## Integration Tasks

- [ ] Integrate the compatibility harness with CI in a non-product local mode.
- [ ] Use the harness to audit the current file builtin family against real products.
