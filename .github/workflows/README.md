# GitHub Actions ⇄ GitLab CI parity

`gitlab.com/ogamita/clautolisp` is the primary repo; GitHub is an
**automatic git mirror**. Mirroring copies refs, tags, and files verbatim —
it does **not** translate CI. `.gitlab-ci.yml` lands in the GitHub tree as an
inert file that GitHub Actions never reads (Actions reads only
`.github/workflows/*.yml`), and GitLab ignores `.github/`. So the two CI
systems are independent and each must be maintained by hand.

**`.gitlab-ci.yml` is the source of truth.** `.github/workflows/ci.yml`
mirrors only the **common** lanes — the ones that run on a stock
`ubuntu-latest` runner. Setup (SBCL, optional CCL, Quicklisp) is factored
into the composite action `.github/actions/setup-lisp`.

## The rule

> **Before merging to `master`, or cutting a release tag / release branch,
> re-sync `.github/workflows/ci.yml` with the COMMON lanes of
> `.gitlab-ci.yml`.** When you add, remove, or change a common lane in
> `.gitlab-ci.yml` (a new `make` target, a renamed suite, a dependency
> bump), make the matching edit here in the same change. GitLab-only lanes
> are never mirrored.

`.gitlab-ci.yml` carries a banner comment listing which jobs are COMMON vs
GITLAB-ONLY; keep that banner and this table in step.

## Job mapping (common lanes)

| GitLab job | GitHub job → step |
|---|---|
| `test:clautolisp:sbcl` | `sbcl-test` → clautolisp FiveAM (SBCL) |
| `test:clautolisp:file-compat:sbcl` | `sbcl-test` → file-compat (SBCL) |
| `test:autolisp-test:sbcl` | `sbcl-test` → autolisp-test harness |
| `test:alfe:sbcl` | `sbcl-test` → alfe FiveAM (SBCL) |
| `test:alfe:conformance` | `sbcl-test` → alfe scenario conformance |
| `test:alfe:spec-coverage` | `sbcl-test` → alfe spec-coverage gate |
| `test:clautolisp:ccl` | `ccl-test` → clautolisp FiveAM (CCL) |
| `test:clautolisp:file-compat:ccl` | `ccl-test` → file-compat (CCL) |
| `test:alfe:ccl` | `ccl-test` → alfe FiveAM (CCL) |
| `build:alfe:sbcl` | `alfe-binary` → build + version + smoke + artifact |

## GitLab-only (NOT mirrored, and why)

The native and CAD lanes need runners GitHub-hosted runners can't provide:

- `*:macos` / `*:windows` — GitLab self-hosted runners (thalassa arm64 macOS;
  a Windows PC). GitHub-hosted `macos-*` / `windows-*` exist but carry no
  BricsCAD/AutoCAD, so the CAD-dependent ones can't run there regardless.
- `verify:*`, `vendor:probes:*`, `*:probe:*`, `encoding:experiment:*`,
  `benchmark:*` — real BricsCAD/AutoCAD hosts.
- `build:clautolisp-ci-image` — builds the GitLab Docker image.
- `release:*`, `pages`, `collect`, `deploy:*` — GitLab release/deploy plumbing
  (GitHub has its own `release.yml`).

If a native lane ever needs GitHub coverage, dual-register the self-hosted
machine to GitHub, or use a GitHub-hosted runner only for the CAD-free part.

## CCL provisioning

`ubuntu-latest` has SBCL in apt but no CCL. The `setup-lisp` action installs
Clozure CL v1.13 the same way `clautolisp/docker/Dockerfile` does (clone the
source, overlay the release kernel/heap tarball, wrap `lx86cl64` as `ccl`).
Keep the `CCL_VERSION` in `setup-lisp/action.yml` and the Dockerfile in step.
