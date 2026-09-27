#!/usr/bin/env python3
"""Unit tests for the stale-pipeline sweep's SELECTION.

ci-job-activity-cap-refuses-master-pipelines.issue. The old sweep was never
tested, and every one of its defects was a selection defect: it looked at age
when the question was whether anyone could still play the jobs, it ignored
parents, and it reported success from a truncated listing. So what is tested
here is the decision, not that the script runs.

Each case below is one the previous sweep got WRONG on 2026-09-26. A test that
cannot fail proves nothing, so the pairs matter: the merged-MR child IS swept
and the OPEN-MR child of the same age is NOT.

    python3 scripts/tests/test-cancel-stale-pipelines.py
"""

import datetime
import importlib.util
import os
import pathlib
import unittest

HERE = pathlib.Path(__file__).resolve().parent
SCRIPT = HERE.parent / "cancel-stale-pipelines.py"

# The script is a hyphenated CLI, not an importable module name; load it by path
# so the test exercises the shipped file rather than a copy of its logic.
_spec = importlib.util.spec_from_file_location("sweep", SCRIPT)
sweep = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(sweep)

NOW = datetime.datetime(2026, 9, 27, 0, 0, 0, tzinfo=datetime.timezone.utc)


def stamp(hours_ago):
    return (NOW - datetime.timedelta(hours=hours_ago)).strftime(
        "%Y-%m-%dT%H:%M:%S.000Z")


def pipeline(pid=1, ref="master", source="parent_pipeline",
             status="running", hours_ago=1.0):
    return {"id": pid, "ref": ref, "source": source, "status": status,
            "created_at": stamp(hours_ago)}


def classify(p, mr_state=None, max_age=12, max_parent_age=48, protected=(),
             queued=False):
    return sweep.classify_pipeline(p, mr_state, NOW, max_age, max_parent_age,
                                   set(protected), has_queued_work=queued)


class MergeRequestRef(unittest.TestCase):
    def test_recognises_head_and_merge_refs(self):
        self.assertEqual(297, sweep.merge_request_iid(
            "refs/merge-requests/297/head"))
        self.assertEqual(297, sweep.merge_request_iid(
            "refs/merge-requests/297/merge"))

    def test_a_branch_is_not_a_merge_request(self):
        self.assertIsNone(sweep.merge_request_iid("master"))
        self.assertIsNone(sweep.merge_request_iid("fix-something"))
        self.assertIsNone(sweep.merge_request_iid(None))


class ChildOfAFinishedMergeRequest(unittest.TestCase):
    """THE case that filled the cap: four children of merged MRs, all young."""

    def young_child(self, pid=10):
        return pipeline(pid=pid, ref="refs/merge-requests/297/head",
                        hours_ago=0.5)

    def test_merged_is_swept_however_young(self):
        reason = classify(self.young_child(), mr_state="merged")
        self.assertIsNotNone(reason)
        self.assertIn("!297", reason)
        self.assertIn("merged", reason)

    def test_closed_is_swept_too(self):
        self.assertIsNotNone(classify(self.young_child(), mr_state="closed"))

    def test_but_an_OPEN_merge_request_of_the_same_age_is_left_alone(self):
        # The discriminating half: if this were swept, the sweep would kill the
        # verification of every merge request under review.
        self.assertIsNone(classify(self.young_child(), mr_state="opened"))

    def test_an_unknown_mr_state_falls_back_to_age(self):
        # An API hiccup must not turn into a cancellation.
        self.assertIsNone(classify(self.young_child(), mr_state=None))
        old = pipeline(ref="refs/merge-requests/297/head", hours_ago=30)
        self.assertIsNotNone(classify(old, mr_state=None))


class PlayedJobsAreQueuedWork(unittest.TestCase):
    """A job somebody PLAYED is not a clickable fallback.

    Observed before this rule existed: the child of merged !300 held TWELVE
    played jobs -- ten BricsCAD macOS probes from another session and two
    AutoCAD verifications -- all waiting for machines that are intermittent by
    design. The sweep's whole justification for taking a merged MR's child is
    that nobody can play its jobs again. Somebody already had.
    """

    def merged_child(self, hours_ago=0.5):
        return pipeline(ref="refs/merge-requests/300/head", hours_ago=hours_ago)

    def test_queued_work_spares_a_merged_mr_child(self):
        self.assertIsNotNone(classify(self.merged_child(), mr_state="merged"),
                             "without queued work it must still be swept")
        self.assertIsNone(classify(self.merged_child(), mr_state="merged",
                                   queued=True))

    def test_queued_work_survives_the_child_age_threshold(self):
        # A CAD machine that comes back when an office opens can easily be
        # more than 12h away.
        self.assertIsNone(classify(self.merged_child(hours_ago=20),
                                   mr_state="merged", queued=True))

    def test_but_it_buys_time_not_immortality(self):
        # Past the stuck threshold, a played job is not waiting for an office
        # to open any more.
        reason = classify(self.merged_child(hours_ago=60), mr_state="merged",
                          queued=True)
        self.assertIsNotNone(reason)
        self.assertIn("not coming", reason)


class QueuedWorkDetection(unittest.TestCase):
    """The discriminator, which took two attempts to find.

    A PENDING job is either a played manual job (a deliberate act) or one the
    pipeline's matrix scheduled (garbage, in a merged MR's child). REST cannot
    tell them apart -- measured 2026-09-27, a played verify:epure-api:windows and
    an auto-scheduled build:alfe:windows return byte-identical field sets. This
    ticket's earlier analysis concluded it was impossible; GraphQL's
    CiJob.manualJob says whether the job is DECLARED manual, and that is the
    distinction:

        pending + declared manual -> PLAYED
        pending + not manual      -> the matrix scheduled it
    """

    def test_unplayed_manual_jobs_are_not_queued_work(self):
        # Exactly what the sweep exists to clear: clickable fallbacks nobody
        # clicked.
        self.assertFalse(sweep.queued_work_p(
            [("manual", True), ("success", False), ("failed", False)]))

    def test_a_PLAYED_manual_job_is_queued_work(self):
        self.assertTrue(sweep.queued_work_p([("manual", True),
                                             ("pending", True)]))

    def test_an_AUTO_SCHEDULED_pending_job_is_NOT(self):
        # The case the old rule got wrong, and the reason the bucket refilled:
        # a merged MR's child full of matrix-scheduled pending jobs was spared.
        self.assertFalse(sweep.queued_work_p([("pending", False),
                                              ("pending", False)]))

    def test_a_RUNNING_job_is_spared_whatever_its_provenance(self):
        # Killing work in flight wastes it, and here it can leave a CAD process
        # behind.
        self.assertTrue(sweep.queued_work_p([("running", False)]))
        self.assertTrue(sweep.queued_work_p([("running", True)]))

    def test_a_mixture_is_spared_for_the_played_one(self):
        self.assertTrue(sweep.queued_work_p(
            [("pending", False), ("pending", False), ("pending", True)]))

    def test_unknown_counts_as_queued(self):
        # If we cannot tell, the safe answer is the one that does not cancel.
        self.assertTrue(sweep.queued_work_p(None))

    def test_an_empty_pipeline_holds_nothing(self):
        self.assertFalse(sweep.queued_work_p([]))


class ChildAge(unittest.TestCase):
    def test_an_abandoned_branch_child_is_swept_on_age(self):
        # A ref pushed once and never again has nothing to supersede it.
        reason = classify(pipeline(ref="fix-abandoned", hours_ago=20))
        self.assertIsNotNone(reason)
        self.assertIn(">=", reason)

    def test_a_young_branch_child_is_not(self):
        self.assertIsNone(classify(pipeline(ref="fix-in-progress",
                                            hours_ago=2)))


class StuckParents(unittest.TestCase):
    """The fifteen jobs held since 2026-08-22 that nothing swept."""

    def test_a_five_week_old_parent_is_swept(self):
        reason = classify(pipeline(source="push", hours_ago=24 * 35))
        self.assertIsNotNone(reason)
        self.assertIn("stuck", reason)

    def test_a_parent_waiting_hours_on_a_serial_runner_is_not(self):
        # This is normal here: the Windows runner is serial and a native child
        # can keep a master pipeline open for hours. Sweeping it would be worse
        # than the leak.
        self.assertIsNone(classify(pipeline(source="push", hours_ago=10)))

    def test_a_parent_is_not_swept_by_the_child_threshold(self):
        # 20h is past the child threshold (12) and short of the parent one (48).
        self.assertIsNone(classify(pipeline(source="push", hours_ago=20)))


class NeverItsOwnPipeline(unittest.TestCase):
    """The sweep is meant to run in .pre of every master pipeline."""

    def test_the_current_pipeline_is_protected(self):
        old = pipeline(pid=99, source="push", hours_ago=24 * 40)
        self.assertIsNotNone(classify(old), "must be sweepable when unprotected")
        self.assertIsNone(classify(old, protected=(99,)))

    def test_the_current_pipelines_child_is_protected(self):
        child = pipeline(pid=100, ref="refs/merge-requests/297/head",
                         hours_ago=0.5)
        self.assertIsNotNone(classify(child, mr_state="merged"))
        self.assertIsNone(classify(child, mr_state="merged", protected=(100,)))


class OnlyActivePipelines(unittest.TestCase):
    def test_a_finished_pipeline_is_never_cancelled(self):
        for status in ("success", "failed", "canceled", "skipped"):
            done = pipeline(source="push", status=status, hours_ago=24 * 40)
            self.assertIsNone(classify(done), status)

    def test_every_active_status_is_considered(self):
        # `created' is the status the fifteen stuck jobs' pipeline reports its
        # jobs in, and `manual'/`scheduled' pipelines hold jobs just as well.
        for status in sweep.ACTIVE:
            old = pipeline(source="push", status=status, hours_ago=24 * 40)
            self.assertIsNotNone(classify(old), status)


class CrowdedBucket(unittest.TestCase):
    """The cap refuses far below GitLab's documented 500: a child pipeline was
    refused with 172 jobs active, and a refused pipeline has ZERO jobs, so it
    reads like an ordinary red rather than "your work never ran"."""

    def test_at_or_above_the_threshold_is_crowded(self):
        self.assertTrue(sweep.crowded_p(150, 150))
        self.assertTrue(sweep.crowded_p(172, 150))

    def test_below_it_is_not(self):
        self.assertFalse(sweep.crowded_p(149, 150))
        self.assertFalse(sweep.crowded_p(0, 150))

    def test_an_UNKNOWN_count_is_never_crowded(self):
        # A read-only token cannot list jobs. Manufacturing a failure out of
        # ignorance would make the sweep red for a reason unrelated to the
        # bucket -- and a sweep that is always red is not a gate.
        self.assertFalse(sweep.crowded_p(None, 150))
        self.assertFalse(sweep.crowded_p(None, 0))


class TruncationIsAFailure(unittest.TestCase):
    """`child pipelines seen: 500' was a page cap printed as a count."""

    def test_a_full_last_page_raises_instead_of_truncating(self):
        calls = []

        def always_full(path):
            calls.append(path)
            return [{"id": len(calls), "ref": "master", "source": "push",
                     "status": "running", "created_at": stamp(1)}
                    for _ in range(100)]

        original = sweep.request
        sweep.request = always_full
        try:
            with self.assertRaises(RuntimeError) as caught:
                sweep.active_pipelines(child=False)
            self.assertIn("truncated", str(caught.exception))
        finally:
            sweep.request = original

    def test_a_short_page_ends_the_listing_normally(self):
        def one_short_page(path):
            if "page=1" in path:
                return [{"id": 1, "ref": "master", "source": "push",
                         "status": "running", "created_at": stamp(1)}]
            return []

        original = sweep.request
        sweep.request = one_short_page
        try:
            found = sweep.active_pipelines(child=False)
            self.assertEqual(1, len(found))
        finally:
            sweep.request = original


if __name__ == "__main__":
    unittest.main(verbosity=2)
