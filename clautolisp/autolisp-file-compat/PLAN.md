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
- The harness now supports executable builtin scenarios with temporary
  workspaces, setup fixtures, path-state controls, and runtime-value
  expectations.
- Builtin scenarios now also support multi-step execution with step-local
  bindings and result references, so the corpus can exercise file-descriptor
  workflows such as `open`/`write-line`/`read-line`/`close`.
- The builtin corpus now covers pathname lookup, directory listing, file
  mutation, temp-file generation, size queries, stream/file-descriptor
  behavior, and printer/read-back behavior on both SBCL and CCL.
- The stream corpus now also covers negative open-for-read behavior, explicit
  `OPEN` encoding arguments, and printer-to-`READ` file roundtrips.
- The stream and printer corpus now also covers unsupported encoding failures
  and line-by-line validation of file-targeted printer output.

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
- [x] Add pathname-resolution and search-path scenarios.
- [x] Add file-mutation scenarios for copy, rename, and delete behavior.
- [x] Add printer/read-back scenarios for string-printing and `read`.
- [x] Add multi-step stream scenarios for file-descriptor operations.
- [x] Add file-targeted printer scenarios using multi-step execution.
- [x] Add stream scenarios for explicit encodings and open failure cases.
- [x] Add printer-to-reader roundtrip scenarios through temporary files.
- [x] Add stream scenarios for unsupported encoding designators.
- [x] Add line-by-line read-back validation for file-targeted printer output.
- [ ] Extend file-mutation coverage to rename edge cases and more failure modes.
- [x] Classify scenarios by expected status: portable, implementation-sensitive, host-sensitive, or unknown.

## Integration Tasks

- [ ] Integrate the compatibility harness with CI in a non-product local mode.
- [ ] Use the harness to audit the current file builtin family against real products.
