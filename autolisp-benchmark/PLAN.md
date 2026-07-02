# autolisp-benchmark Plan

## Purpose

This file is the canonical task tracker for the `autolisp-benchmark`
subproject.

The Org documents in `documentation/` hold the rationale, the timing
model, and the per-class workload design. Actionable work items belong
here.

## What this subproject is

A pure-AutoLISP benchmark suite that measures the speed of an AutoLISP
engine across several operation classes, and prints comparable numbers
regardless of which engine ran it. The same source is loaded into:

- `clautolisp` (directly, or via `alfe --clautolisp`),
- BricsCAD (via `alfe --bricscad`),
- AutoCAD (via `alfe --autocad`),

on the *same hardware*, so the reported throughput can be compared
across implementations.

## Operation classes (one workload each)

| Class          | File                          | Exercises |
|----------------|-------------------------------|-----------|
| arithmetic     | `benchmarks/arithmetic.lsp`   | int/float arithmetic, transcendentals, comparisons |
| lists          | `benchmarks/lists.lsp`        | cons/list/append, reverse/nth/member, assoc, mapcar |
| strings        | `benchmarks/strings.lsp`      | strcat/substr/strcase, number<->string, wcmatch |
| serialization  | `benchmarks/serialization.lsp`| `vl-prin1-to-string` + `read` round-trip |
| file-io        | `benchmarks/file-io.lsp`      | open/write-line/read-line/close on a scratch file |
| entity         | `benchmarks/entity.lsp`       | entmake/entlast/entget/entmod/entdel cycle |
| memory-gc      | `benchmarks/memory-gc.lsp`    | allocation churn + explicit `(gc)` |

## Timing model

- Each workload is a function `(fn REPS)` that performs REPS units of
  work in a tight loop, so per-call dispatch cost is amortised away.
- The engine calibrates a batch size (>= ~50 ms/call), then runs the
  workload repeatedly until ~`*bench-seconds*` (default 5.0) seconds
  have elapsed, counting iterations.
- Reported per class: iterations, iterations/second, microseconds/
  iteration. Reported overall: total iterations, total time,
  aggregate iterations/second.
- The clock is `(getvar "MILLISECS")` when live, else `(getvar
  "DATE")` scaled to milliseconds. See `harness/timer.lsp`.

## Current Status

- Harness implemented: `timer.lsp`, `bench.lsp`, `manifest.lsp`,
  `run.lsp`.
- Seven workloads implemented and running on clautolisp (1.3.x).
- Wired into the top-level Makefile (`build` / `documentation` /
  `test` / `install`). `make -C autolisp-benchmark test` is a fast
  smoke run; `make -C autolisp-benchmark run` is the full measurement.
- Relies on the clautolisp live-timer sysvars present in the 1.3.x line
  (MILLISECS/DATE/CDATE/TDUSRTIMER/TDINDWG).

## Backlog

- Optional: write a machine-readable (s-expression) result file per
  run, mirroring autolisp-test's `report.sexp`, so runs across engines
  can be diffed by a tool rather than by eye.
- Optional: a `compare` helper that ingests two result files and prints
  a clautolisp-vs-CAD ratio table.
- Once `issues/open/entmakex-returns-list.issue` is fixed, the entity
  workload can drop the `(entlast)` step and call `(entmakex)`
  directly (a micro-optimisation; the current path is already
  portable).
- Consider a `command`/`vl-cmdf`-based CAD workload once clautolisp
  implements `COMMAND` (currently deferred), to benchmark the
  command-loop path in addition to the entity-primitive path.
- vlisp-compile / `.fas` comparison: deferred. clautolisp has no
  compile step (`vlisp-compile` is a stub and `.fas`/`.vlx` loads are
  rejected), so a loaded-source-vs-compiled-fas axis only applies to
  real AutoCAD/BricsCAD. When run there, add sibling targets that
  `vlisp-compile` the workloads at each optimisation level and load the
  `.fas`, then re-run — comparing interpreted vs compiled and across
  optimisation settings. Tracked here rather than implemented because
  it cannot be exercised on clautolisp.
