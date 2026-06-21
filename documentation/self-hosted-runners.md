# Self-hosted GitLab runners for clautolisp

clautolisp's CI runs entirely on **self-hosted** runners — no GitLab
shared minutes:

Runners are selected by **configuration tags** — `<os>,<arch>,<executor>`
(plus capability tags `gui`/`bricscad`/`autocad` where a job needs the
licensed GUI app). Tags describe the *machine*, not the project (the
group already scopes projects).

- **poseidon** (`poseidon.informatimago.com`) — a Debian server running
  `gitlab-runner` (under the unprivileged `runners` user, rootless docker)
  with a group runner **per group**. clautolisp is in the **ogamita**
  group, so its `linux,amd64,docker` jobs run on `ogamita-linux-docker`.
  poseidon is the always-on Linux compute box. GitLab's shared/instance
  runners are DISABLED for the project (out of compute minutes; self-hosted
  runners are exempt from the quota).
- **thalassa** — an Apple-Silicon laptop (`macos,arm64`) serving the macOS
  build + the native `linux,arm64` docker lane.
- **windows PC** — a `windows,amd64` laptop with GUI BricsCAD + AutoCAD.

thalassa and the windows PC are **intermittent** (laptops, not always on),
so their tagged jobs simply queue until the host is online — expected when
a branch is pushed for validation.

| Job                    | tags                  | runner               | what it builds              |
|------------------------|-----------------------|----------------------|-----------------------------|
| *(default: build/test)*| `linux, amd64, docker`| ogamita-linux-docker (poseidon) | linux/amd64 in a container  |
| `release:linux:x86-64` | `linux, amd64, docker`| ogamita-linux-docker (poseidon) | linux/x86-64 binaries       |
| `collect:release`      | `linux, amd64, docker`| ogamita-linux-docker (poseidon) | unions the per-target dist/ |
| `release:documentation`| `linux, amd64, docker`| ogamita-linux-docker (poseidon) | docs (Emacs + xelatex; toolchain apt-installed) |
| `release:linux:arm64`  | `linux, arm64, docker`| thalassa             | linux/arm64 in a container  |
| `release:darwin:arm64` | `macos, arm64, shell` | thalassa             | native macOS arm64 binaries |
| `release:windows:x86-64`| `windows, amd64, shell`| windows PC          | windows/amd64 (stub)        |

One Apple-Silicon Mac (thalassa) serves **both** arm64 lanes: its Docker
engine runs `linux/arm64` containers (the docker lane), and the shell
executor builds macOS natively (macOS cannot be containerised). The
**windows** lane runs on a separate Windows PC (shell executor); it is the
host carrying the GUI BricsCAD/AutoCAD toolchain.

> **arm64 is SBCL-only.** Clozure CL has no arm64 build, so these lanes
> produce `*-sbcl` binaries only (the `bin/` dispatch defaults to sbcl).

## 1. Get a runner authentication token

The old per-instance *registration token* was removed (GitLab 18.0); the
Runners settings page no longer shows one. Instead create a **runner**,
which yields a `glrt-…` **authentication token**.

**Prefer GROUP runners.** Register these against the **ogamita group**, not
the clautolisp project: a group runner is inherited by every project and
subgroup under the group, so other ogamita projects reuse it with no extra
setup. (Project runners are locked to one project — only use them when a
runner must NOT be shared.)

- **UI:** ogamita group → Settings → CI/CD → Runners → **New group runner**.
  Set the platform and the tags (`linux,arm64` and/or `macos,arm64`),
  tick/untick "run untagged jobs" as needed, create → copy the `glrt-…`
  token. (Creating group runners needs group Owner.)
- **API / PAT alternative** (scriptable across many groups): create a PAT
  with the **`create_runner`** scope, then
  `POST https://gitlab.com/api/v4/user/runners` with
  `runner_type=group_type&group_id=<id>&tag_list=macos,arm64`; the
  response carries the `glrt-…` token. A plain PAT is *not* itself a
  registration token.

Create one runner per executor (one for `macos,arm64` shell, one for
`linux,arm64` docker) — **each gets its OWN `glrt-…` token.** Reusing one
token for a second `register` on the same machine fails with "A runner
with this system ID and token has already been registered" (one token =
one runner; the shared machine system_id is fine and expected).

> **Maximal reuse:** a group runner only covers ONE top-level group and its
> subgroups — it cannot span two sibling top-level groups. If you keep many
> separate top-level groups you must register a runner set per group. To
> avoid that, nest the projects as **subgroups under a single top-level
> group**; then one group runner at the top is inherited by them all.

## 2. The poseidon (linux/amd64) group runner

clautolisp's linux/amd64 jobs run on the **ogamita group** runner
`ogamita-linux-docker`, which already exists on poseidon — there is
nothing project-specific to register for clautolisp. poseidon runs
`gitlab-runner` as a system service under the unprivileged `runners`
user, with rootless docker; the runner config lives at
`~runners/.gitlab-runner/config.toml` (the daemon's socket is
`unix:///run/user/1002/docker.sock`). See `~/admin.org` on poseidon for
the maintenance commands.

Two prerequisites for clautolisp to actually use it:

1. **The runner must be enabled for the clautolisp project.** Group
   runners cover every project in the group by default; confirm under
   clautolisp → Settings → CI/CD → Runners that the group runner shows as
   *Available*.
2. **Disable shared/instance runners for the project** so the untagged
   linux/amd64 jobs can only be picked up by the group runner (otherwise
   GitLab's shared runners may grab them).

> **dind note.** The CI-image build (`build:clautolisp-ci-image`) uses a
> `docker:27-dind` service, exactly like the ogamita-group `delta-ota`
> image jobs (`docker:26-dind`). If delta-ota's image builds pass on this
> rootless runner, clautolisp's will too. If dind turns out not to work
> under the rootless/non-privileged daemon, switch the image build to
> kaniko (as the `bocl` project does) — no privileged container required.

## 3. Install + register on the workstation (macOS, MacPorts)

In the new (authentication-token) workflow, **tags and runner options are
set in the UI when you create the runner** and are reserved on the
server: `register` accepts only the name + executor config. Passing
`--tag-list` (or `--locked` / `--run-untagged` / `--access-level` /
`--maximum-timeout` / `--paused` / `--maintenance-note`) is a FATAL error.
So do NOT pass `--tag-list`; set tags when creating each runner.

```sh
sudo port install gitlab-runner      # 18.x

# macOS arm64 — native shell executor (runner created in UI with tags macos,arm64)
gitlab-runner register \
  --non-interactive \
  --url https://gitlab.com \
  --token glrt-MACOS_TOKEN \
  --executor shell \
  --description "mac-studio macos/arm64"

# linux/arm64 — docker executor (a SEPARATE runner, tags linux,arm64 set in UI)
gitlab-runner register \
  --non-interactive \
  --url https://gitlab.com \
  --token glrt-LINUX_TOKEN \
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

## 4. Toolchain the lanes expect

- **shell (macOS) lane:** the host must have `sbcl`, `cmake`, a C compiler
  (Xcode CLT), and Quicklisp at `~/quicklisp/` — i.e. the normal dev
  setup (`clautolisp/third-party/get-dependencies --install`).
- **docker (linux/arm64) lane:** self-contained — the job's
  `before_script` installs `sbcl`/`cmake` and bootstraps Quicklisp inside
  the `buildpack-deps:bookworm` (arm64) container.

## 5. Security

The **shell executor runs job scripts directly on your workstation as
your user.** Keep the release jobs gated to **protected tags**
(`rules: if $CI_COMMIT_TAG …`, already the case) and never enable these
runners for untrusted fork merge requests. The docker lane is safer
(isolated container) but still trusts the job; same gating applies.

## 6. Trying it

These lanes only run on a version tag (`v*` / `clautolisp-v*`) or when
started manually from a pipeline (`when: manual`). Push a tag (or use a
throwaway `vX.Y.Z-rcN`) and the tagged arm64/macOS jobs are dispatched to
the registered runner; their `dist/` artefacts attach to the pipeline.
