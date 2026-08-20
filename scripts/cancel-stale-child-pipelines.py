#!/usr/bin/env python3
"""Cancel child pipelines that have been active too long.

ci-native-child-pipeline-creation-fails.issue, option 2 — the sweep.

WHY THIS EXISTS. The native child pipeline's jobs are `manual' whenever
their runner is offline, so the child NEVER completes on its own: it
stays ACTIVE, and its jobs keep counting against the project's
jobs-in-active-pipelines cap. One immortal pipeline per push. On
2026-08-19 the cap was reached — 17 children still `running', the oldest
seven hours old — and no new child could be created, which made every
pipeline in the project red with zero failed jobs.

Option 1 (`default: interruptible: true' in .gitlab/native.yml) lets
GitLab auto-cancel a child when a NEWER pipeline supersedes it. That
covers a branch pushed repeatedly, and only that: a ref pushed once and
then abandoned — a merge request merged from its last push, which is the
normal case — has nothing to supersede it, and its child lives for ever.
This sweep is what drains those.

It is deliberately a broom, not a fix. The mechanism that manufactures
immortal pipelines is still there; this empties the bucket nightly.

THE QUERY THAT MATTERS. Child pipelines are EXCLUDED from the plain
pipelines listing, which is how the first diagnosis of that outage came
to report "0 running pipelines" while seventeen children were running.
`source=parent_pipeline' is what shows them.

    python3 scripts/cancel-stale-child-pipelines.py --dry-run
    python3 scripts/cancel-stale-child-pipelines.py --max-age-hours 12
"""

import argparse
import datetime
import json
import os
import sys
import urllib.error
import urllib.request

API = os.environ.get("CI_API_V4_URL", "https://gitlab.com/api/v4")
PROJECT = os.environ.get("CI_PROJECT_ID", "")
# Reuse the token detect:runners already uses. NOTE: reading runners needs
# only read_api; CANCELLING needs `api'. A token with the narrower scope
# will list the stale pipelines and then fail to cancel them — which this
# reports as a failure rather than swallowing, because a sweep that
# silently cancels nothing is indistinguishable from one that had nothing
# to do, and that is the failure mode this whole issue is about.
TOKEN = os.environ.get("RUNNER_STATUS_TOKEN", "")

ACTIVE = ("running", "pending", "created", "waiting_for_resource", "manual")


def request(path, method="GET"):
    url = "%s/projects/%s/%s" % (API, PROJECT, path)
    req = urllib.request.Request(url, method=method)
    req.add_header("PRIVATE-TOKEN", TOKEN)
    with urllib.request.urlopen(req, timeout=30) as response:
        body = response.read().decode("utf-8")
    return json.loads(body) if body.strip() else {}


def child_pipelines():
    """Every child pipeline, newest first, over a few pages."""
    found = []
    for page in range(1, 6):
        batch = request("pipelines?source=parent_pipeline&per_page=100&page=%d"
                        % page)
        if not batch:
            break
        found.extend(batch)
        if len(batch) < 100:
            break
    return found


def age_hours(stamp, now):
    when = datetime.datetime.fromisoformat(stamp.replace("Z", "+00:00"))
    return (now - when).total_seconds() / 3600.0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--max-age-hours", type=float,
                        default=float(os.environ.get("SWEEP_MAX_AGE_HOURS")
                                      or 12),
                        help="cancel active child pipelines older than this "
                             "(default 12)")
    parser.add_argument("--dry-run", action="store_true",
                        help="list what would be cancelled, cancel nothing")
    args = parser.parse_args()

    if not TOKEN or not PROJECT:
        print("FAIL: RUNNER_STATUS_TOKEN and CI_PROJECT_ID are both required.")
        print("      Refusing to report success without having looked: a")
        print("      sweep that quietly does nothing is the failure this")
        print("      exists to prevent.")
        return 1

    now = datetime.datetime.now(datetime.timezone.utc)
    try:
        children = child_pipelines()
    except (urllib.error.URLError, urllib.error.HTTPError, ValueError) as err:
        print("FAIL: could not list child pipelines: %s" % err)
        return 1

    active = [p for p in children if p["status"] in ACTIVE]
    stale = [p for p in active
             if age_hours(p["created_at"], now) >= args.max_age_hours]

    print("child pipelines seen: %d, active: %d, older than %gh: %d"
          % (len(children), len(active), args.max_age_hours, len(stale)))

    failures = 0
    for pipeline in sorted(stale, key=lambda p: p["created_at"]):
        label = "%d %-44s %5.1fh" % (pipeline["id"], pipeline["ref"][:44],
                                     age_hours(pipeline["created_at"], now))
        if args.dry_run:
            print("  would cancel %s" % label)
            continue
        try:
            request("pipelines/%d/cancel" % pipeline["id"], method="POST")
            print("  cancelled    %s" % label)
        except (urllib.error.URLError, urllib.error.HTTPError) as err:
            print("  FAILED       %s: %s" % (label, err))
            failures += 1

    if failures:
        print("FAIL: %d cancellation(s) refused. If the token has read_api "
              "but not api," % failures)
        print("      this is exactly what it looks like -- widen the scope.")
        return 1

    if not stale:
        print("nothing to sweep; the %d active child pipeline(s) are all "
              "younger than %gh" % (len(active), args.max_age_hours))
    return 0


if __name__ == "__main__":
    sys.exit(main())
