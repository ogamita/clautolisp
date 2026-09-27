#!/usr/bin/env python3
"""Tests for the native:pipeline `changes:' classification check.

The check exists because omission is the expensive direction: a pattern missing
from the gate silently skips the Windows/macOS lanes on a real code change. So
the tests concentrate on the two things that would make it useless -- a glob
translation that quietly matches too much, and a failure that does not fire.

    python3 scripts/tests/test-check-native-pipeline-changes.py
"""

import importlib.util
import pathlib
import unittest

HERE = pathlib.Path(__file__).resolve().parent
SCRIPT = HERE.parent / "check-native-pipeline-changes.py"

_spec = importlib.util.spec_from_file_location("natchanges", SCRIPT)
nat = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(nat)


class GlobTranslation(unittest.TestCase):
    """`*' must NOT cross a directory separator and `**' must.

    This is the whole reason the translation is written out instead of using
    fnmatch, whose `*' crosses separators -- with fnmatch, `*.lisp' would match
    `a/b/c.lisp' and every pattern would be silently wider than it reads.
    """

    def match(self, pattern, path):
        return bool(nat.glob_to_regex(pattern).match(path))

    def test_star_does_not_cross_a_separator(self):
        self.assertTrue(self.match("*.lisp", "foo.lisp"))
        self.assertFalse(self.match("*.lisp", "dir/foo.lisp"))

    def test_doublestar_slash_crosses_any_depth_including_none(self):
        self.assertTrue(self.match("**/*.lisp", "foo.lisp"))
        self.assertTrue(self.match("**/*.lisp", "a/foo.lisp"))
        self.assertTrue(self.match("**/*.lisp", "a/b/c/foo.lisp"))

    def test_a_trailing_doublestar_covers_a_whole_tree(self):
        self.assertTrue(self.match("clautolisp/third-party/**",
                                   "clautolisp/third-party/libredwg"))
        self.assertTrue(self.match("clautolisp/third-party/**",
                                   "clautolisp/third-party/a/b/c.c"))
        self.assertFalse(self.match("clautolisp/third-party/**",
                                    "clautolisp/other/libredwg"))

    def test_an_exact_path_matches_only_itself(self):
        self.assertTrue(self.match(".gitmodules", ".gitmodules"))
        self.assertFalse(self.match(".gitmodules", "sub/.gitmodules"))

    def test_a_dot_is_not_a_wildcard(self):
        # re.escape must be doing its job, or "*.lisp" would match "axlisp".
        self.assertFalse(self.match("*.lisp", "axlisp"))


class Unclassified(unittest.TestCase):
    RUN = ["**/*.lisp", "**/tools/**"]
    IRRELEVANT = ["**/*.org"]

    def test_a_path_in_neither_list_is_reported(self):
        self.assertEqual(
            ["src/thing.rs"],
            nat.unclassified(["src/a.lisp", "doc/b.org", "src/thing.rs"],
                             self.RUN, self.IRRELEVANT))

    def test_a_path_in_either_list_is_accepted(self):
        self.assertEqual(
            [],
            nat.unclassified(["a.lisp", "deep/a.lisp", "x/tools/y/script",
                              "notes.org"],
                             self.RUN, self.IRRELEVANT))

    def test_overlap_is_fine(self):
        # A path in BOTH lists runs the lanes, because GitLab runs the child if
        # ANY changed file matches. Overlap costs a spurious child; that is the
        # cheap direction and must not be treated as a conflict.
        self.assertEqual(
            [],
            nat.unclassified(["x/tools/readme.org"], self.RUN, self.IRRELEVANT))

    def test_an_empty_run_list_reports_everything(self):
        # The degenerate case: if the gate lost its patterns, the check must not
        # quietly pass.
        self.assertEqual(["a.lisp"], nat.unclassified(["a.lisp"], [], []))


class TheRealGate(unittest.TestCase):
    """The gate may be ABSENT, which is a real state, not a broken test.

    It was reverted on 2026-09-27 after failing to match a merge request that
    changed scripts/*.py. So these assert the CONTRACT in whichever state the
    repository is in, which is what keeps them meaningful when it returns --
    a test that only passes while a feature exists gets deleted the day it is
    reverted, and then nothing guards its comeback.
    """

    def test_the_run_list_is_read_from_the_ci_file_when_there_is_one(self):
        patterns = nat.run_patterns(nat.DEFAULT_ROOT)
        if patterns is None:
            self.skipTest("no changes: gate at the moment (reverted)")
        # Read from .gitlab-ci.yml, not duplicated here: the check must not be
        # able to drift from the behaviour it is checking.
        self.assertIn("**/*.lisp", patterns)
        self.assertIn("**/Dockerfile", patterns)
        self.assertGreater(len(patterns), 20,
                           "the gate should be generous; a short list is a "
                           "silent-skip risk")

    def test_the_repository_is_fully_classified_when_there_is_a_gate(self):
        root = nat.DEFAULT_ROOT
        patterns = nat.run_patterns(root)
        if patterns is None:
            self.skipTest("no changes: gate at the moment (reverted)")
        missing = nat.unclassified(nat.tracked_paths(root), patterns,
                                   nat.IRRELEVANT)
        self.assertEqual([], missing,
                         "unclassified tracked paths: %s" % missing[:10])

    def test_the_check_passes_on_this_repository(self):
        # Meaningful in BOTH states, which is the point: with a gate it passes
        # because every tracked path is classified, and without one because the
        # absence is a choice rather than an error. The first version of this
        # was `assertEqual(0, ... if ... else 0)' -- a tautology that could not
        # fail, which is worse than no test.
        self.assertEqual(0, nat.main([str(nat.DEFAULT_ROOT)]))


if __name__ == "__main__":
    unittest.main(verbosity=2)
