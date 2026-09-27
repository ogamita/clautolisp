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
    def test_the_run_list_is_read_from_the_ci_file(self):
        # Read from .gitlab-ci.yml, not duplicated here: the check must not be
        # able to drift from the behaviour it is checking.
        patterns = nat.run_patterns(nat.DEFAULT_ROOT)
        self.assertIn("**/*.lisp", patterns)
        self.assertIn("**/Dockerfile", patterns)
        self.assertGreater(len(patterns), 20,
                           "the gate should be generous; a short list is a "
                           "silent-skip risk")

    def test_the_repository_is_fully_classified(self):
        # The check's own subject, asserted: this is what keeps a new file type
        # from inheriting a decision nobody made.
        root = nat.DEFAULT_ROOT
        missing = nat.unclassified(nat.tracked_paths(root),
                                   nat.run_patterns(root), nat.IRRELEVANT)
        self.assertEqual([], missing,
                         "unclassified tracked paths: %s" % missing[:10])


if __name__ == "__main__":
    unittest.main(verbosity=2)
