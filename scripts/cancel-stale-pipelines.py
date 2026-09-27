#!/usr/bin/env python3
"""Cancel pipelines that can never finish, so they stop counting against the
project's job activity limit.

ci-job-activity-cap-refuses-master-pipelines.issue. Formerly
`cancel-stale-child-pipelines.py' (ci-native-child-pipeline-creation-fails,
option 2), renamed because it no longer sweeps only children -- a stuck PARENT
holds jobs against the same cap, and one of them had held fifteen for five
weeks.

WHY THIS EXISTS. The native child pipeline's jobs are `manual' whenever their
runner is offline, so the child NEVER completes on its own: it stays ACTIVE and
its jobs keep counting. One immortal pipeline per push. When the cap is reached,
GitLab refuses to create the NEXT pipeline -- and a pipeline that was never
created cannot report its own absence, so a merge lands on master with no CI at
all and the only trace is a red pipeline with zero jobs. That happened twice on
2026-09-26 (21:47Z and 21:55Z), which is what this rewrite is for.

WHAT CHANGED, and why each part is load-bearing:

1. AGE IS NOT THE ONLY CRITERION. The leak that filled the cap was four
   children of ALREADY-MERGED merge requests, all under two hours old. Their
   manual jobs can never be played -- the merge request is gone -- so no age
   threshold is the right question. `Could anyone still play this?' is, and the
   ref plus the MR's state answer it.

2. THE LISTING MUST BE COMPLETE, OR THE RUN IS A FAILURE. The old sweep paged
   five times and printed `child pipelines seen: 500' -- its page cap, not a
   count; paging to exhaustion finds 806. So it was blind to anything older
   than the newest 500 and said `nothing to sweep' while immortal pipelines
   ran. A truncated listing is now an error, not a number. Better still, the
   query asks for the ACTIVE statuses directly: active pipelines are few, so
   the window stops mattering.

3. STUCK PARENTS TOO, under a much larger threshold. A legitimately long master
   pipeline waiting on a serial Windows runner takes hours; five weeks is not
   that. Parents are swept on age alone -- there is no `nobody will play this'
   signal for them -- which is why their threshold is separate and generous.

4. NEVER CANCEL THE PIPELINE IT RUNS IN, nor that pipeline's own children. The
   sweep is meant to run in `.pre' of every master pipeline, so this is not
   hypothetical: without it the job would cancel the very pipeline it belongs
   to on its first run.

THE QUERY THAT MATTERS. Child pipelines are EXCLUDED from the plain pipelines
listing, which is how the first diagnosis of the 2026-08-19 outage came to
report "0 running pipelines" while seventeen children were running.
`source=parent_pipeline' is what shows them; the plain listing is what shows
parents. This script asks both.

    python3 scripts/cancel-stale-pipelines.py --dry-run
    python3 scripts/cancel-stale-pipelines.py --max-age-hours 12
"""

import argparse
import datetime
import json
import os
import re
import sys
import urllib.error
import urllib.request

API = os.environ.get("CI_API_V4_URL", "https://gitlab.com/api/v4")
PROJECT = os.environ.get("CI_PROJECT_ID", "")
# Reuse the token detect:runners already uses. NOTE: reading runners needs
# only read_api; CANCELLING needs `api'. A token with the narrower scope
# will list the stale pipelines and then fail to cancel them -- which this
# reports as a failure rather than swallowing, because a sweep that
# silently cancels nothing is indistinguishable from one that had nothing
# to do, and that is the failure mode this whole issue is about.
#
# TWO variables, in this order, and the order is the point. Cancelling needs
# `api'; reading runner status needs only `read_api'. When the sweep was first
# armed it inherited RUNNER_STATUS_TOKEN and every cancellation came back
# 403 Forbidden -- the broom had never swept anything, and nobody knew because
# the age-only rule never selected anything for it to fail on. So the sweep now
# names its OWN credential: set PIPELINE_SWEEP_TOKEN to a token with `api' and
# the read-only one stays read-only, which is the right shape when only one job
# in the project needs to write. RUNNER_STATUS_TOKEN remains the fallback so an
# installation that has not been split keeps working -- and still says plainly,
# via the 403 report at the end, when that token cannot cancel.
TOKEN = (os.environ.get("PIPELINE_SWEEP_TOKEN")
         or os.environ.get("RUNNER_STATUS_TOKEN", ""))

# Pipeline statuses that hold jobs against the cap.
ACTIVE = ("created", "waiting_for_resource", "preparing", "pending", "running",
          "manual", "scheduled")

# A merge request whose pipeline nobody can ever play again.
FINISHED_MR_STATES = ("merged", "closed")

MR_REF = re.compile(r"^refs/merge-requests/(\d+)/(?:head|merge)$")

# Enough pages to exhaust any plausible active set; hitting it is an error,
# not a silent truncation.
MAX_PAGES = 40


def request(path, method="GET"):
    url = "%s/projects/%s/%s" % (API, PROJECT, path)
    req = urllib.request.Request(url, method=method)
    req.add_header("PRIVATE-TOKEN", TOKEN)
    with urllib.request.urlopen(req, timeout=30) as response:
        body = response.read().decode("utf-8")
    return json.loads(body) if body.strip() else {}


def merge_request_iid(ref):
    """The MR iid a pipeline ref belongs to, or None when it is not an MR ref."""
    found = MR_REF.match(ref or "")
    return int(found.group(1)) if found else None


def age_hours(stamp, now):
    when = datetime.datetime.fromisoformat(stamp.replace("Z", "+00:00"))
    return (now - when).total_seconds() / 3600.0


def classify_pipeline(pipeline, mr_state, now,
                      max_age_hours, max_parent_age_hours, protected,
                      has_queued_work=False):
    """Why PIPELINE should be cancelled, or None to leave it alone.

    Pure, so the decision is testable without the API
    (scripts/tests/test-cancel-stale-pipelines.py). MR-STATE is the state of
    the merge request this pipeline belongs to, or None when it belongs to
    none or is unknown. PROTECTED is the set of pipeline ids this run must
    never touch -- its own pipeline and that pipeline's children.
    HAS-QUEUED-WORK says the pipeline holds a job somebody PLAYED that has not
    run yet (see %has_queued_work).
    """
    if pipeline["id"] in protected:
        return None
    if pipeline["status"] not in ACTIVE:
        return None

    age = age_hours(pipeline["created_at"], now)
    is_child = pipeline.get("source") == "parent_pipeline"
    iid = merge_request_iid(pipeline.get("ref"))

    if is_child:
        # A PLAYED job is queued work, not a clickable fallback, and the whole
        # justification for sweeping a merged MR's child is that nobody can
        # play its jobs again. Somebody already did. This is not hypothetical:
        # when this rule was missing, one merged MR's child held TWELVE played
        # jobs -- ten BricsCAD macOS probes from another session and two
        # AutoCAD verifications -- all waiting for machines that are
        # intermittent by design, so the queue is long on purpose. The first
        # armed sweep would have cancelled every one of them.
        #
        # It buys time, not immortality: past the PARENT threshold (the
        # "something is genuinely stuck" one) it is swept anyway, because a
        # played job that has waited two days is not waiting for an office to
        # open.
        if has_queued_work:
            if age >= max_parent_age_hours:
                return ("child holding played-but-unrun jobs for %.1fh "
                        "(>= %gh) -- the runner is not coming"
                        % (age, max_parent_age_hours))
            return None
        # The criterion that matters: nobody can play these again.
        if iid is not None and mr_state in FINISHED_MR_STATES:
            return ("child of !%d, which is %s -- its manual jobs can never "
                    "be played" % (iid, mr_state))
        if age >= max_age_hours:
            return "child active for %.1fh (>= %gh)" % (age, max_age_hours)
        return None

    # A parent has no "nobody will play this" signal, so age alone, generously.
    if age >= max_parent_age_hours:
        return ("pipeline still active after %.1fh (>= %gh) -- stuck"
                % (age, max_parent_age_hours))
    return None


def active_pipelines(child):
    """Every ACTIVE pipeline, children or parents, listed exhaustively.

    Asks per status so the result sets stay small: a page cap cannot silently
    truncate what it never had to page through. Raises RuntimeError if a
    listing would be truncated anyway -- reporting success from a partial
    listing is the defect this replaces.
    """
    source = "&source=parent_pipeline" if child else ""
    found = {}
    for status in ACTIVE:
        for page in range(1, MAX_PAGES + 1):
            batch = request("pipelines?status=%s%s&per_page=100&page=%d"
                            % (status, source, page))
            if not batch:
                break
            for pipeline in batch:
                found[pipeline["id"]] = pipeline
            if len(batch) < 100:
                break
            if page == MAX_PAGES:
                raise RuntimeError(
                    "pipeline listing truncated at %d pages for status=%s "
                    "(child=%s): refusing to report a partial sweep"
                    % (MAX_PAGES, status, child))
    return list(found.values())


def has_queued_work(pipeline_id):
    """Does this pipeline hold a job somebody PLAYED that has not run yet?

    A job still in `manual' is an unplayed, clickable fallback -- exactly what
    the sweep exists to clear away. A job in `pending' or `running' was either
    scheduled automatically or PLAYED BY HAND, and is queued work: on this
    project it is typically a CAD verification waiting for a machine that is
    intermittent by design, so waiting hours is normal and cancelling it throws
    away a deliberate act.

    Unknown counts as "yes". If the jobs cannot be listed, the safe answer is
    the one that does not cancel.
    """
    try:
        for page in range(1, MAX_PAGES + 1):
            batch = request("pipelines/%s/jobs?per_page=100&page=%d"
                            % (pipeline_id, page))
            if not batch:
                return False
            for job in batch:
                if job.get("status") in ("pending", "running"):
                    return True
            if len(batch) < 100:
                return False
    except (urllib.error.URLError, urllib.error.HTTPError, ValueError):
        return True
    return True


def crowded_p(jobs, warn_at):
    """Is the activity bucket close enough to the ceiling to say so?

    JOBS is the active-job count, or None when it could not be read -- and an
    UNKNOWN count must never count as crowded. A read-only token cannot list
    jobs, and manufacturing a failure out of ignorance would make the sweep red
    for a reason that has nothing to do with the bucket.

    The threshold is low on purpose: a child pipeline was refused at 172 active
    jobs, far below GitLab's documented 500, so the useful warning comes well
    before the number looks alarming.
    """
    return jobs is not None and jobs >= warn_at


def protected_ids(pipeline_id):
    """This pipeline and its own children -- never swept by itself."""
    if not pipeline_id:
        return set()
    keep = {int(pipeline_id)}
    try:
        for bridge in request("pipelines/%s/bridges" % pipeline_id):
            downstream = bridge.get("downstream_pipeline") or {}
            if downstream.get("id"):
                keep.add(downstream["id"])
    except (urllib.error.URLError, urllib.error.HTTPError, ValueError):
        # Better to protect less precisely than to abort the sweep; the
        # current pipeline's own id is the one that really matters.
        pass
    return keep


def count_active_jobs():
    """Jobs counting against the cap, or None when it cannot be counted.

    Printed rather than enforced: the log is the one place anybody looks at
    this mechanism, and a filling bucket should be visible there BEFORE it
    refuses a merge.
    """
    total = 0
    try:
        for scope in ("created", "pending", "running"):
            for page in range(1, MAX_PAGES + 1):
                batch = request("jobs?scope[]=%s&per_page=100&page=%d"
                                % (scope, page))
                if not batch:
                    break
                total += len(batch)
                if len(batch) < 100:
                    break
    except (urllib.error.URLError, urllib.error.HTTPError, ValueError):
        return None
    return total


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--max-age-hours", type=float,
                        default=float(os.environ.get("SWEEP_MAX_AGE_HOURS")
                                      or 12),
                        help="cancel active CHILD pipelines older than this "
                             "(default 12)")
    parser.add_argument("--max-parent-age-hours", type=float,
                        default=float(os.environ.get("SWEEP_MAX_PARENT_AGE_HOURS")
                                      or 48),
                        help="cancel active NON-child pipelines older than "
                             "this (default 48)")
    parser.add_argument("--dry-run", action="store_true",
                        help="list what would be cancelled, cancel nothing")
    parser.add_argument("--warn-at", type=int,
                        default=int(os.environ.get("SWEEP_WARN_ACTIVE_JOBS")
                                    or 150),
                        help="active-job count above which a sweep that found "
                             "NOTHING to cancel reports failure (default 150; "
                             "a child pipeline was refused at 172)")
    args = parser.parse_args()
    warn_at = args.warn_at

    if not TOKEN or not PROJECT:
        print("FAIL: a token (PIPELINE_SWEEP_TOKEN, else RUNNER_STATUS_TOKEN)")
        print("      and CI_PROJECT_ID are both required. Cancelling needs the")
        print("      `api' scope; a read_api token lists the pipelines and then")
        print("      fails every cancellation with 403.")
        print("      Refusing to report success without having looked: a")
        print("      sweep that quietly does nothing is the failure this")
        print("      exists to prevent.")
        return 1

    now = datetime.datetime.now(datetime.timezone.utc)
    keep = protected_ids(os.environ.get("CI_PIPELINE_ID"))
    try:
        pipelines = active_pipelines(child=True) + active_pipelines(child=False)
    except (urllib.error.URLError, urllib.error.HTTPError, ValueError,
            RuntimeError) as err:
        print("FAIL: could not list pipelines: %s" % err)
        return 1

    # One MR lookup per distinct iid, not per pipeline.
    mr_states = {}
    for pipeline in pipelines:
        iid = merge_request_iid(pipeline.get("ref"))
        if iid is not None and iid not in mr_states:
            try:
                mr_states[iid] = request("merge_requests/%d" % iid).get("state")
            except (urllib.error.URLError, urllib.error.HTTPError, ValueError):
                mr_states[iid] = None

    doomed = []
    for pipeline in sorted(pipelines, key=lambda p: p["created_at"]):
        iid = merge_request_iid(pipeline.get("ref"))
        # Asked only for children, and only once the cheap checks could not
        # already spare the pipeline -- it is one request per candidate.
        queued = (has_queued_work(pipeline["id"])
                  if pipeline.get("source") == "parent_pipeline"
                  else False)
        reason = classify_pipeline(pipeline, mr_states.get(iid), now,
                                   args.max_age_hours,
                                   args.max_parent_age_hours, keep,
                                   has_queued_work=queued)
        if reason:
            doomed.append((pipeline, reason))

    jobs = count_active_jobs()
    print("active pipelines: %d (%d protected), to cancel: %d"
          % (len(pipelines), len(keep), len(doomed)))
    print("jobs counting against the activity cap: %s"
          % ("unknown" if jobs is None else jobs))

    # THE CEILING IS LOWER THAN THE DOCUMENTED 500. Measured 2026-09-27: a child
    # pipeline was refused with "The pipeline job activity limit was exceeded"
    # while 172 jobs were active, so the practical margin is far thinner than
    # anyone assumed -- and a refusal produces a pipeline with ZERO jobs, which
    # reads like an ordinary red rather than "your work never ran".
    #
    # Saying the number is not enough: nobody reads a log line that is fine
    # ninety-nine times. So when the bucket is high AND this sweep found nothing
    # it may cancel, it FAILS -- that combination is exactly the actionable one,
    # "full, and I cannot help". High with something to cancel is not a failure:
    # the sweep is doing its job.
    crowded = crowded_p(jobs, warn_at)
    if crowded:
        print("")
        print("WARNING: %d active jobs (threshold %d). The cap refuses new"
              % (jobs, warn_at))
        print("         pipelines well below GitLab's documented 500 -- a child")
        print("         pipeline was refused at 172. A refused pipeline has ZERO")
        print("         jobs and looks like an ordinary failure, so the work")
        print("         simply does not run.")
        print("         Levers, in order of bluntness: open fewer merge requests")
        print("         (each one spawns a native child of ~21 platform jobs);")
        print("         let the CAD backlog drain; reduce what a docs-only")
        print("         change creates. See")
        print("         ci-job-activity-cap-refuses-master-pipelines.")

    failures = 0
    for pipeline, reason in doomed:
        label = "%d %-44s %s" % (pipeline["id"], (pipeline["ref"] or "")[:44],
                                 reason)
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

    if not doomed:
        print("nothing to sweep; every active pipeline is either protected, "
              "young, or still playable")
        if crowded:
            print("FAIL: the bucket is crowded and this sweep has nothing it "
                  "may cancel.")
            print("      Not a defect in the sweep -- a report that it cannot "
                  "help, which")
            print("      is the one state worth interrupting someone for.")
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
