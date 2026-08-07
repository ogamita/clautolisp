#!/usr/bin/env python3
"""Auto-start the native (macOS / Windows) CI jobs when their intermittent
runner is ONLINE, leaving them MANUAL when it is offline.

Rationale (runner-availability-gating.issue): the macOS/Windows runners are
intermittent laptops. We want the native jobs to run automatically when the
runner is up, but NOT pile up as stuck-pending jobs (and never redden the
pipeline) when it is down. GitLab rules: are evaluated at pipeline-creation
time and cannot see a probe job's runtime result, so the native jobs are
declared `when: manual` (their offline behaviour = the current manual
fallback, clickable and non-blocking). This orchestrator runs on the
always-on Linux runner, asks the API which native runners are ONLINE, and
`play`s the matching manual jobs of THIS pipeline — so online => automatic.

FAIL-SAFE by construction: if RUNNER_STATUS_TOKEN is absent or any API call
fails, it plays nothing and exits 0, i.e. every native job stays manual
(exactly today's behaviour). It can never wrongly auto-start a job or block
a pipeline.

Excludes release:* and benchmark:* — those are deliberately manual (release
packaging must not fire on every push; benchmarks are expensive) and keep
their manual fallback untouched.

Needs a CI/CD variable RUNNER_STATUS_TOKEN with `api` scope (playing a job
is a write; read_api is not enough). Recommended: a project access token,
masked; protected if you only want auto-start on protected refs.
"""
import json, os, sys, urllib.parse, urllib.request

API      = os.environ.get("CI_API_V4_URL", "https://gitlab.com/api/v4")
PROJECT  = os.environ.get("CI_PROJECT_ID")
PIPELINE = os.environ.get("CI_PIPELINE_ID")
TOKEN    = os.environ.get("RUNNER_STATUS_TOKEN", "")
NATIVE_TAGS   = ("macos", "windows")
SKIP_PREFIXES = ("release:", "benchmark:")   # never auto-start these


def api(method, path):
    req = urllib.request.Request(API + path, method=method)
    req.add_header("PRIVATE-TOKEN", TOKEN)
    with urllib.request.urlopen(req, timeout=30) as r:
        body = r.read()
    return json.loads(body) if body else None


def online_native_tags():
    up = set()
    for tag in NATIVE_TAGS:
        try:
            runners = api("GET", f"/projects/{PROJECT}/runners"
                                 f"?tag_list={urllib.parse.quote(tag)}&per_page=100")
            if any(r.get("status") == "online" for r in (runners or [])):
                up.add(tag)
        except Exception as e:               # noqa: BLE001 (fail-safe)
            print(f"  (could not query runners for tag {tag!r}: {e})")
    return up


def pipeline_jobs():
    jobs, page = [], 1
    while True:
        batch = api("GET", f"/projects/{PROJECT}/pipelines/{PIPELINE}"
                           f"/jobs?per_page=100&page={page}")
        if not batch:
            break
        jobs.extend(batch)
        if len(batch) < 100:
            break
        page += 1
    return jobs


def main():
    if not TOKEN:
        print("RUNNER_STATUS_TOKEN not set — leaving all native jobs manual "
              "(fail-safe: this is the current behaviour).")
        return 0
    if not (PROJECT and PIPELINE):
        print("CI_PROJECT_ID / CI_PIPELINE_ID missing — nothing to do.")
        return 0
    try:
        up = online_native_tags()
    except Exception as e:                    # noqa: BLE001
        print(f"runner detection failed ({e}); leaving jobs manual.")
        return 0
    print(f"online native runners: {sorted(up) or 'none'}")
    if not up:
        return 0
    try:
        jobs = pipeline_jobs()
    except Exception as e:                    # noqa: BLE001
        print(f"could not list pipeline jobs ({e}); nothing played.")
        return 0
    played = 0
    for j in jobs:
        name, status = j.get("name", ""), j.get("status")
        tags = set(j.get("tag_list") or [])
        if status != "manual":
            continue
        if not (tags & set(NATIVE_TAGS)):     # not a native job
            continue
        if name.startswith(SKIP_PREFIXES):
            continue
        if not (tags & up):                   # this job's runner is offline
            continue
        try:
            api("POST", f"/projects/{PROJECT}/jobs/{j['id']}/play")
            print(f"  played  {name}  (tags={sorted(tags)})")
            played += 1
        except Exception as e:                # noqa: BLE001
            print(f"  could not play {name}: {e}")
    print(f"auto-started {played} native job(s); the rest stay manual.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
