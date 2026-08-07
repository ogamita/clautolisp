#!/usr/bin/env python3
"""Detect whether the intermittent native (macOS / Windows) runners are
ONLINE and emit a dotenv the child `native` pipeline consumes to decide, at
its creation, whether each native job is automatic (online) or manual
(offline). See runner-availability-gating.issue.

Writes MACOS_RUNNER / WINDOWS_RUNNER = online|offline to the file named by
argv[1] (default runners.env). FAIL-SAFE: a missing RUNNER_STATUS_TOKEN or
any API error yields `offline`, i.e. the native jobs fall back to manual
(today's behaviour) — never a false `online`.
"""
import json, os, sys, urllib.parse, urllib.request

API     = os.environ.get("CI_API_V4_URL", "https://gitlab.com/api/v4")
PROJECT = os.environ.get("CI_PROJECT_ID")
TOKEN   = os.environ.get("RUNNER_STATUS_TOKEN", "")
TAGS    = (("macos", "MACOS_RUNNER"), ("windows", "WINDOWS_RUNNER"))


def online(tag):
    if not (TOKEN and PROJECT):
        return False
    try:
        req = urllib.request.Request(
            f"{API}/projects/{PROJECT}/runners"
            f"?tag_list={urllib.parse.quote(tag)}&per_page=100")
        req.add_header("PRIVATE-TOKEN", TOKEN)
        with urllib.request.urlopen(req, timeout=30) as r:
            runners = json.loads(r.read())
        return any(x.get("status") == "online" for x in runners)
    except Exception as e:                       # noqa: BLE001 (fail-safe)
        print(f"  ({tag}: detection failed: {e} -> offline)")
        return False


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "runners.env"
    if not TOKEN:
        print("RUNNER_STATUS_TOKEN not set -> all native runners reported "
              "offline (fail-safe: native jobs stay manual).")
    lines = []
    for tag, var in TAGS:
        state = "online" if online(tag) else "offline"
        lines.append(f"{var}={state}")
        print(f"  {var}={state}")
    with open(out, "w") as f:
        f.write("\n".join(lines) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
