# CI job durations — what to expect

Indicative figures, **measured**, to answer "is this pipeline slow or is it
stuck?" and "can I fit this run in the time I have?". Companion to
[`documentation/self-hosted-runners.md`](../../documentation/self-hosted-runners.md),
which describes the machines and their tags.

Method: median of the successful runs of each job across the pipelines of
2026-08-14/15 (n given per row). Treat these as orders of magnitude, not
budgets: they belong to the machines below and will drift with them.

## The machines these figures come from

| runner | tags | hardware |
|---|---|---|
| poseidon | `linux,amd64,docker` | always-on Debian server, rootless docker |
| PF5S26B(T) | `windows,amd64,shell` + `cad` | AMD Ryzen 5 230 (12 threads, 3.5 GHz), 14 GB RAM, MSYS2/MINGW64 on Windows 10.0-26200 |
| thalassa | `macos,arm64,shell` + `cad` | Apple Silicon T6030, 12 cores, 36 GB RAM, Darwin 25.5 |

Two consequences worth keeping in mind when reading the tables:

- the Windows box is a **laptop**, sometimes on battery, and it is the only
  machine carrying the `cad` tag that is usually up (thalassa is
  intermittent). It is the scarce resource, not the slow one — its CPU is
  fine;
- 12 threads and 14 GB are ample for one job and thin for several, which is
  part of why the CAD runner is configured `concurrency = 1` rather than
  fanning out.

## Linux lanes (poseidon, always on, run in parallel)

| job | median | range | n |
|---|---|---|---|
| `documentation` | 231 s | 219–318 | 10 |
| `test:autolisp-test:sbcl` | 174 s | 167–180 | 10 |
| `test:alfe:sbcl` | 101 s | 96–106 | 10 |
| `test:clautolisp:sbcl` | 99 s | 96–242 | 10 |
| `build:alfe:sbcl` | 99 s | 91–104 | 10 |
| `encoding:experiment:clautolisp:linux` | 97 s | 94–107 | 10 |
| `test:alfe:spec-coverage` | 94 s | 89–101 | 10 |
| `test:alfe:conformance` | 93 s | 89–101 | 10 |
| `build:clautolisp-ci-image` | 73 s | 69–92 | 4 |
| `test:clautolisp:ccl` | 26 s | 25–29 | 10 |
| `test:alfe:ccl` | 23 s | 22–27 | 10 |
| `test:clautolisp:file-compat:sbcl` | 16 s | 14–17 | 10 |
| `test:clautolisp:file-compat:ccl` | 16 s | 14–20 | 10 |
| `detect:runners` | 9 s | 8–10 | 10 |

These run concurrently, so **wall clock ≈ the longest job**, not the sum:
about **4–5 minutes** for a full green pipeline. `documentation` is the
critical path; `build:clautolisp-ci-image` only runs when its inputs change.

Note CCL is 4× faster than SBCL on the same suites — it is not doing less
work, it compiles less aggressively.

## Native Windows lanes (no CAD)

| job | median | range | n |
|---|---|---|---|
| `test:autolisp-test:windows` | 137 s | 126–177 | 4 |
| `test:clautolisp:windows` | 92 s | 76–105 | 4 |
| `test:alfe:windows` | 62 s | 45–82 | 4 |
| `build:alfe:windows` | 55 s | 47–65 | 4 |
| `conformance:pathname-mapping:windows` | 10 s | 8–39 | 4 |
| `verify:vl-registry:windows` | 10 s | 9–33 | 4 |

## CAD jobs — the ones that matter for planning

These carry the `cad` tag and run on a runner configured `concurrency = 1`,
so they **serialise**. Wall clock is the SUM, not the max.

| job | median | n |
|---|---|---|
| `encoding:experiment:bricscad:windows` | 1158 s (19 min) | 1 |
| `pathname:probe:bricscad:windows` | 223 s | 1 |
| `vendor:probes:bricscad` | 115 s | 1 |
| `vendor:probes:autocad` | 79 s | 1 |
| `encoding:experiment:autocad:windows` | 54 s | 1 |
| `verify:bricscad-hidden-ui:windows` | 45 s | 1 |
| `pathname:probe:autocad:windows` | 41 s | 1 |
| `harvest:sysvars:bricscad:windows` | 34 s | 1 |

**A full CAD sweep is therefore ≈ 30 minutes of exclusive runner time**, and
`encoding:experiment:bricscad:windows` alone is two thirds of it. If you have
a limited window, cancel the jobs you do not need rather than hoping: they
queue, they do not parallelise.

## Two things that bite

**Every push queues a whole CAD sweep.** A push to a branch with an open MR
creates a pipeline, whose native child creates *all* the CAD jobs. Three
pushes in an afternoon put ~24 CAD jobs on a runner that processes one at a
time. When the CAD machine is on battery, batch the pushes.

**A wedged CAD job denies the runner.** CAD jobs are capped at `timeout: 30m`
(set on the gate templates in `.gitlab/native.yml`) for exactly this reason —
without it the ceiling is the project default and one hung BricsCAD held the
runner for 32 minutes on 2026-08-14, with 70 CAD jobs queued behind it. The
30m figure is chosen from the table above: ~55% headroom over the real
outlier. See `issues/open/cad-runner-wedged-by-modal-dialog.issue`.

## Refreshing these numbers

```sh
glab api "/projects/ogamita%2Fclautolisp/pipelines/<id>/jobs?per_page=100" \
  | python3 -c 'import json,sys; [print(f"{j[\"duration\"] or 0:8.0f}s {j[\"status\"]:8} {j[\"name\"]}") for j in json.load(sys.stdin)]'
```

Native and CAD jobs live in the **child** pipeline (`native:pipeline`), not
the parent; get its id from `…/pipelines/<parent>/bridges`.

Machine facts came from `~claude/windows-runner.info` and
`~claude/macos-runner.info` (pjb, 2026-08-15): `uname -a` plus
`/proc/cpuinfo` + `/proc/meminfo` on Windows, `hostinfo` on macOS. Re-take
them the same way if a runner is replaced — a duration without the machine
that produced it is half a fact.
