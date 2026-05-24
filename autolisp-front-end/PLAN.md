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

- Subproject skeleton in place. Phase 0 (alfe-skeleton +
  alfe-backend-interface + alfe-cli) has landed: ASDF systems,
  `*alfe-version*` (`tools/alfe/source/version.lisp`), the SBCL/CCL
  executable build (`make build-alfe-sbcl`, `make build-alfe-ccl`),
  the abstract backend protocol (`source/backend.lisp`), the echo
  mock backend (`source/backend-echo.lisp`), and the full CLI
  (`source/cli.lisp`) with the option grammar from
  `documentation/alfe--specifications.org`.
- Phase 1 (alfe-backend-clautolisp) has landed: the in-process
  variant binds `clautolisp.autolisp-runtime` directly and tees
  live stdout/stderr into `WORKDIR/output.txt` / `errors.txt`;
  the subprocess variant fork-execs `clautolisp-sbcl` with the
  resolved CLI flags via `uiop:run-program`. `--clautolisp -x
  '(+ 1 2)'` end-to-end prints 3 and exits 0.
- Phase 2 (alfe-file-protocol) has landed: the `alfe.protocol.file`
  package implements the file-IPC driver shared by the upcoming
  CAD backends — atomic publish-by-rename, status polling with
  backoff, incremental stdout/stderr draining with per-channel
  offsets, line-to-form reader on top of the clautolisp parser,
  PING/SHUTDOWN/INTERRUPT control sender, optional heartbeat
  reader, and a pure-CL `run-common.lsp` emitter that populates
  every `*AUTOLISP-*` global the spec calls for (in both hyphen
  and underscore spellings so the upstream `autolisp-remote-io.lsp`
  runtime is reused verbatim).
- Phase 3 (alfe-backend-bricscad + alfe-backend-autocad) has
  landed: per-platform binary discovery, batch-mode run.scr
  emitters, AppleScript launcher for macOS BricsCAD automation,
  VBScript bridge emitters for Windows COM on both CADs (with the
  spec's WaitQuiescent / GetAcadState / SendCommand handshake
  preserved), platform gating for AutoCAD on non-Windows hosts
  (clean exit 3 with a "not distributed" message), and a
  protocol-driven `eval-plan` that issues every action through
  the file-IPC channel and waits for the runtime's `DONE N` reply.
  Real-CAD smoke tests are deferred behind `BRICSCAD_SMOKE=1` /
  `AUTOCAD_SMOKE=1` env opts.
- Phase 4 (alfe-conformance) has landed: declarative `.sexp`
  scenarios under `tests/scenarios/{cli,actions,encoding,
  clautolisp,bricscad,autocad}/` are walked by the
  `alfe.conformance` runner, which drives each through alfe's
  in-process CLI with captured stdout/stderr and compares to the
  scenario's expectations. 26 scenarios cover every alfe CLI
  option in the spec (asserted by `scripts/check-spec-coverage.lisp`,
  which scans the spec for option names and refuses to exit zero
  on any uncovered one). Standalone runner exposed via
  `make conformance`; coverage gate exposed via
  `make check-spec-coverage`. Parity tests against the legacy bash
  wrapper are gated behind `$AUTOLISP_LEGACY`; not exercised in CI.
- Specification copied from upstream `autolisp-script` and updated
  to reflect the alfe ↔ clautolisp ↔ CAD architecture and the
  file-IPC rationale for the CAD backends.
- Implementation plan + per-area issues under `../issues/open/`.

## Version-bump rule

Every change that touches source under this subproject must bump the
DEVELOP counter in `tools/alfe/source/version.lisp`. The convention
mirrors the clautolisp rule documented in
`../clautolisp/tools/clautolisp/source/version.lisp` and in the
user-scope MEMORY.md note `clautolisp_version_bump.md`.

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
