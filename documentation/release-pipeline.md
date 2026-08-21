# Release pipeline — job taxonomy, platform split, and artefacts

Status: DESIGN (agreed 2026-08-21). Supersedes the ad-hoc split between
`.github/workflows/release.yml` and the `release`/`collect`/`deploy` stages of
`.gitlab-ci.yml`. Companion specs: `windows-package-spec.md` (Windows
packaging internals), `self-hosted-runners.md` (runner tags),
`poseidon-deploy.md` (the rrsync deploy account).

This document is the contract the CI is implemented against. When CI and this
doc disagree, fix the one that is wrong on purpose and note it here.

## 1. Three reasons a CI job exists — do not conflate them

Every job serves exactly one of these, and each has its own execution policy:

1. **Probe / benchmark** — extract one piece of information from a real
   environment (e.g. how a given AutoCAD/BricsCAD version behaves, or a perf
   number). **One-shot, on-demand.** Once the information is captured, the job
   is not re-run — *unless* a new CAD version/config must be probed. Policy:
   **manual**, launched deliberately, parameterised by `--cad` and a specific
   platform tag set. Never gates anything.

2. **Validation / non-regression** — the ordinary per-push / per-MR pipeline
   that proves the current project(s) (clautolisp, alfe, and the attendant
   tools/libraries) still work. We *want* breadth (many OS × many CL
   implementation × C compilers for native libs like libredwg — note the SBCL
   variations across OSes), but we **accept that a macOS or Windows runner may
   be offline**: then the pipeline validates on Linux / one arch (poseidon)
   only, and a regression found later on another platform is fixed forward with
   a new MR. Policy: **GitLab, on every push/MR**; Linux-on-poseidon is the
   guaranteed baseline; macOS/Windows are best-effort and **never block**.
   **Do not run these on GitHub** — they would burn our monthly GitHub minutes
   for no gain.

3. **Release build** — produce the shippable artefacts, validated on **every
   platform we include in the release**. Policy: run **where the platform is
   actually available**, see §3.

> The same physical suite (e.g. the clautolisp tests) may be invoked under
> reason 2 (push CI) and reason 3 (release gating); they are different *jobs*
> with different rules, not one job reused.

## 2. The "a runner may be absent" rule

macOS (pjb's workstation) is *generally* available; the Windows PC is
*temporary/intermittent*; the Linux baseline (poseidon) is *always* on.
Consequences:

- Non-regression (reason 2) tolerates an absent macOS/Windows runner (§1.2).
- A **probe** (reason 1) that an active branch still needs is made
  **mandatory on that branch** — it must run and succeed to yield the probe
  result. Once the probe is settled (no longer being modified) and the branch
  is being prepared into an MR, the probe job is **disallowed** (or parked in
  the manual lane, to re-run later against another CAD version/config). So an
  absent runner at MR time never blocks the MR, and for many issues the absent
  platform is simply irrelevant to validating that MR.
- Release (reason 3) removes the intermittency for the one platform we don't
  own long-term (**Windows → GitHub**, §3).

## 3. Release build topology (on a `release-*` tag)

Build each platform where it is available; assemble and publish from poseidon.

| Component  | Platform      | Built on                         | Format       |
|------------|---------------|----------------------------------|--------------|
| binaries   | linux x86-64  | poseidon (GitLab)                | `.tar.bz2`   |
| libraries  | linux x86-64  | poseidon (GitLab)                | `.tar.bz2`   |
| binaries   | macOS arm64   | pjb workstation (GitLab)         | `.tar.bz2`   |
| libraries  | macOS arm64   | pjb workstation (GitLab)         | `.tar.bz2`   |
| binaries   | windows x86-64| **GitHub Actions**               | `.zip`       |
| libraries  | windows x86-64| **GitHub Actions**               | `.zip`       |
| documentation | (any linux)| poseidon (GitLab)               | `.tar.bz2` **and** `.zip` |
| sources    | (layout-free) | poseidon (GitLab)                | `.tar.bz2` **and** `.zip` |
| **all**    | —             | poseidon (assemble)              | `.tar.bz2` **and** `.zip` |

Rationale for Windows → GitHub: the only Windows dependencies are SBCL and
compiling libredwg; a GitHub-hosted `windows-latest` runner is always
available, so a release never waits on the temporary Windows laptop. GitHub is
a **builder only** here — it does not publish (§5).

Format rule (restating the table): **linux/macOS artefacts are `.tar.bz2`;
Windows artefacts are `.zip`** (GitHub emits `.zip` natively; if any Windows
piece is ever built elsewhere it is repacked to `.zip`). **`documentation` and
the combined `all` archive exist in BOTH `.tar.bz2` and `.zip`**; `sources`
already ships both.

### Assemble (poseidon)

A single poseidon job (extends today's `collect:release`):

1. `gh` (authenticated as informatimago on poseidon) downloads GitHub's
   Windows `.zip` artefacts for this tag's workflow run
   (`gh run download`, keyed to the tag — avoids creating a GitHub Release we
   don't want; see §5).
2. `make collect-artefacts` unions the per-target linux/macOS `.tar.bz2` into
   the combined `binaries`/`libraries` tarballs, passes through docs+sources
   (both formats), and drops in the Windows `.zip` as-is.
3. Build the combined **`clautolisp-<ver>-all.tar.bz2`** and
   **`clautolisp-<ver>-all.zip`** (each contains the four component archives).

### Publish (poseidon) — targets chosen 2026-08-21

- **GitLab Release** on the tag (release-cli / API), the four component
  archives + `all.*` attached.
- **poseidon web download area** — rsync the same set into a downloadable dir
  on the poseidon site (same rrsync-restricted deploy pattern as
  `deploy:documentation` → `poseidon-deploy.md`).

Explicitly **not** publish targets: GitHub Release (GitHub is builder-only) and
the Forgejo forge (may revisit later).

## 4. Manual / on-demand lanes

Make these **manual** (`when: manual`, `allow_failure: true`, non-blocking) —
they are reason-1 probes/benchmarks or dev-time experiments, not gates:

- `benchmark:bricscad:macos`, `benchmark:bricscad:windows`,
  `benchmark:autocad:windows` (the CAD suite)
- `benchmark:clautolisp:{linux,macos,windows}`
- `pathname:probe:*`, `encoding:experiment:*`, `native:pipeline`
- `pages` (benchmark report) becomes manual too (it only has meaning once a
  benchmark was deliberately run)

Keep **automatic** because it is cheap and feeds gating: `detect:runners`.

Removed from these jobs: the `on-release-mandatory` rule — a release must not
depend on a probe/benchmark having run.

## 5. GitHub ↔ poseidon handoff

GitHub uploads the Windows artefacts as **workflow artifacts** (not a GitHub
Release). poseidon retrieves them in the assemble job with `gh run download`
scoped to the tag's run. This keeps the canonical publish surface on GitLab +
the poseidon web area while still using GitHub purely as the always-available
Windows builder. (`gh` was authenticated on poseidon as `informatimago` for
exactly this.)

## 6. Concrete change map (current → target)

**`.github/workflows/release.yml`** — today builds sources + documentation +
a 6-target binaries matrix, then a `collect` job attaches everything to a
GitHub Release. Target: **strip it to the Windows lane only**
(`windows-latest`, x86-64; arm64 optional/experimental): install SBCL, compile
libredwg, `make release-programs` + `release-libraries`, repack to `.zip`,
`upload-artifact`. Drop the sources/documentation jobs and the non-Windows
matrix rows; drop the GitHub-Release `collect` step. (Windows packaging is
currently a **stub** on both forges — this is net-new work per
`windows-package-spec.md`.)

**`.gitlab-ci.yml`** —
- `release:linux:x86-64`, `release:darwin:arm64`: keep (`.tar.bz2`).
- `release:linux:arm64`, `release:linux:arm32`: keep as experimental/manual
  (qemu; not in the shipped set unless promoted) — TBD with pjb.
- `release:windows:x86-64` (stub): **remove** from the release stage (GitHub
  owns the Windows release build).
- `release:documentation`: also emit `.zip`.
- Add **assemble** (extends `collect:release`): `gh run download` + extended
  `collect-artefacts` + `all.{tar.bz2,zip}`.
- Add **publish**: GitLab Release + poseidon web rsync.
- Benchmark/probe/experiment lanes → manual (§4).

**`Makefile`** —
- `release-documentation`: emit `.zip` alongside `.tar.bz2`.
- `collect-artefacts`: consume the Windows `.zip`; emit dual-format docs; emit
  `clautolisp-<ver>-all.tar.bz2` and `-all.zip`.
- Possibly a driver target `assemble-release` (gh download + collect + all).

## 7. Open items / net-new work

- Windows packaging is a **stub** — real SBCL image + `libdwg.dll` + zip layout
  per `windows-package-spec.md` must be implemented on the GitHub Windows lane.
- Confirm the `gh run download` selector for a tag run (workflow + tag →
  run-id) and the token/permissions used on poseidon.
- Decide whether linux/arm64 + arm32 (qemu) belong in the shipped release set
  or stay dev-only.
- GitLab Release creation needs a CI job token with `api` scope (release-cli).
- poseidon web download area: pick the path + provision an rrsync target (reuse
  the `clautolisp-deploy` pattern or a sibling account); wire `DOWNLOAD_DEPLOY_USER`.
- **Windows toolchain:** prefer **msys2/mingw** (make, gcc, zip) over choco+MSVC
  for the libredwg build — the Makefile is Unix-shaped and libdwg builds more
  reliably under mingw. `windows-latest` ships msys2 at `C:\msys64` (or use
  `msys2/setup-msys2`). pjb has pre-archived the Windows runner deps incl. msys2
  at `pfenny:c:\staging\run-forest-run\artefacts` (to be copied to poseidon) —
  usable as an offline dep cache and as the proven package set for the
  *self-hosted* Windows runner (reason-2 non-regression tests). `release.yml`
  now uses `msys2/setup-msys2` (MINGW64) with `gcc/cmake/make/zip/sbcl` in one
  shell, so the Unix Makefile + libredwg build run as on Linux.
  RESOLVED (2026-08-21 shakedown): `mingw-w64-x86_64-sbcl` works; libredwg builds
  (Ninja) after two fixes in `build-libredwg.sh` — (1) hand cmake a mixed path
  with `.exe` (MSYS mangles `/mingw64/bin/gcc`), (2) patch libredwg's CMakeLists
  to strip `LIBREDWG_SO_VERSION` (perl's trailing newline broke `config.h`).
  The `win-x64.zip` was verified against `windows-package-spec.md` (bin/ exes +
  libredwg/clal DLLs, lib/common-lisp :tree, VERSION).
- `.github/workflows/ci.yml` is now **workflow_dispatch-only** (was push/PR/tag):
  non-regression runs on GitLab (§2), so GitHub minutes are spent only on the
  Windows release build. Update the github/gitlab-parity note accordingly.
