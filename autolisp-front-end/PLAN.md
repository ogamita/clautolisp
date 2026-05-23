# autolisp-front-end Plan

This file is the canonical task tracker for the `autolisp-front-end`
subproject. Detailed rationale and ticket-by-ticket scope live under
`../issues/open/alfe-*.issue` and the master `../issues/open/alfe.plan`.

## Purpose

Rewrite the historical bash `autolisp-script` wrapper in Common Lisp,
on top of the `clautolisp/autolisp-*` modules, producing a single
`alfe` executable that drives:

- in-process clautolisp (default),
- subprocess clautolisp (isolation),
- BricsCAD via file-IPC protocol,
- AutoCAD via file-IPC protocol.

## Current status

- Subproject skeleton present (this file, `README.org`, `Makefile`,
  `documentation/alfe--specifications.org`, empty `source/`,
  `tools/alfe/`, `tests/`).
- Specification copied from upstream `autolisp-script` and updated
  to reflect the alfe ↔ clautolisp ↔ CAD architecture and the
  file-IPC rationale for the CAD backends.
- Implementation plan + per-area issues under `../issues/open/`.

## Ticket index

See `../issues/open/alfe.plan` for the master plan and the
`alfe-*.issue` tickets it indexes:

- `alfe-skeleton.issue`          — subproject layout, ASDF systems,
                                   executable build, version policy.
- `alfe-cli.issue`               — argument parsing, action sequencing,
                                   exit codes, --interactive.
- `alfe-backend-interface.issue` — abstract backend protocol
                                   (start / eval / read-output /
                                   shutdown, conditions, status).
- `alfe-backend-clautolisp.issue`— in-process + subprocess clautolisp
                                   backends.
- `alfe-file-protocol.issue`     — file-IPC protocol driver
                                   (CAD-side runtime port + alfe-side
                                   atomic write / status polling /
                                   line-to-form reader).
- `alfe-backend-bricscad.issue`  — BricsCAD driver (macOS batch,
                                   Linux batch, Windows COM).
- `alfe-backend-autocad.issue`   — AutoCAD driver (Windows COM,
                                   accoreconsole batch).
- `alfe-conformance.issue`       — scenario corpus, parity tests
                                   against the bash wrapper, spec
                                   maintenance.

## Out of scope (V1)

- A GUI front-end. `alfe` is CLI-only; GUI work lives in
  `clautolisp/tools/clautolisp-gui-qt` (DCL) and the OpenDCL plan.
- EPURE and other user-specific plugin features. The hooks in the
  spec stay documented but their implementation is deferred until a
  plugin model is settled.
- `vlisp-compile` parity outside `--autocad --mode automation` on
  Windows. Unchanged from the legacy wrapper.
