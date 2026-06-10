# Self-hosted GitLab runners for the arm64 / macOS release lanes

GitLab's shared runners cover **linux/x86-64** (our `release:linux:x86-64`
job, via the CI image). The other release lanes are routed by `tags:` to
a self-hosted runner on an Apple-Silicon workstation:

| Job                   | tags           | executor | what it builds                 |
|-----------------------|----------------|----------|--------------------------------|
| `release:linux:arm64` | `linux, arm64` | docker   | linux/arm64 in a container     |
| `release:darwin:arm64`| `macos, arm64` | shell    | native macOS arm64 binaries    |

One Apple-Silicon Mac can serve **both**: its Docker engine runs
`linux/arm64` containers (for the docker lane), and the shell executor
builds macOS natively (macOS cannot be containerised). **Windows** is not
covered here — Windows containers need a Windows host; a Windows-arm64
lane needs a Win11-ARM VM with its own runner, or a paid SaaS/GitHub
`windows-11-arm` runner.

> **arm64 is SBCL-only.** Clozure CL has no arm64 build, so these lanes
> produce `*-sbcl` binaries only (the `bin/` dispatch defaults to sbcl).

## 1. Get a runner authentication token

The old per-instance *registration token* was removed (GitLab 18.0); the
Runners settings page no longer shows one. Instead create a **runner**,
which yields a `glrt-…` **authentication token**:

- **UI:** Project → Settings → CI/CD → Runners → **New project runner**.
  Set the platform and the tags (`linux,arm64` and/or `macos,arm64`),
  optionally untick "run untagged jobs", create → copy the `glrt-…`
  token. (Group runners need group Owner; project runners are simplest.)
- **API / PAT alternative** (if the button is unavailable): create a PAT
  with the **`create_runner`** scope, then
  `POST https://gitlab.com/api/v4/user/runners` with
  `runner_type=project_type&project_id=<id>&tag_list=macos,arm64`; the
  response carries the `glrt-…` token. A plain PAT is *not* itself a
  registration token.

Create one runner per executor (one for `macos,arm64` shell, one for
`linux,arm64` docker), or one runner advertising both tag sets.

## 2. Install + register on the workstation (macOS, MacPorts)

```sh
sudo port install gitlab-runner      # 18.x

# macOS arm64 — native shell executor
gitlab-runner register \
  --non-interactive \
  --url https://gitlab.com \
  --token glrt-XXXXXXXX \
  --executor shell \
  --description "mac-studio macos/arm64"

# linux/arm64 — docker executor (host Docker runs linux/arm64)
gitlab-runner register \
  --non-interactive \
  --url https://gitlab.com \
  --token glrt-YYYYYYYY \
  --executor docker \
  --docker-image buildpack-deps:bookworm \
  --description "mac-studio linux/arm64 (docker)"
```

Run it as a service so it keeps polling:

```sh
gitlab-runner install      # installs a launchd service
gitlab-runner start
```

The runner **long-polls GitLab outbound**, so it works behind NAT with no
inbound ports. When the workstation is asleep/off, tagged jobs simply
queue until it is back.

## 3. Toolchain the lanes expect

- **shell (macOS) lane:** the host must have `sbcl`, `cmake`, a C compiler
  (Xcode CLT), and Quicklisp at `~/quicklisp/` — i.e. the normal dev
  setup (`clautolisp/third-party/get-dependencies --install`).
- **docker (linux/arm64) lane:** self-contained — the job's
  `before_script` installs `sbcl`/`cmake` and bootstraps Quicklisp inside
  the `buildpack-deps:bookworm` (arm64) container.

## 4. Security

The **shell executor runs job scripts directly on your workstation as
your user.** Keep the release jobs gated to **protected tags**
(`rules: if $CI_COMMIT_TAG …`, already the case) and never enable these
runners for untrusted fork merge requests. The docker lane is safer
(isolated container) but still trusts the job; same gating applies.

## 5. Trying it

These lanes only run on a version tag (`v*` / `clautolisp-v*`) or when
started manually from a pipeline (`when: manual`). Push a tag (or use a
throwaway `vX.Y.Z-rcN`) and the tagged arm64/macOS jobs are dispatched to
the registered runner; their `dist/` artefacts attach to the pipeline.
