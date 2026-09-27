#!/usr/bin/env python3
"""Tests for the suite-membership check: each rule must actually FIRE.

The whole value of that check is in the cases it REJECTS, so every rule here is
exercised against a fixture that violates it and against one that does not. A
check nobody has watched fail proves nothing -- and the defect it guards against
(a test file that loads and never runs) already passed for green once, which is
why the check exists at all.

    python3 scripts/tests/test-check-test-suite-membership.py
"""

import importlib.util
import pathlib
import tempfile
import unittest

HERE = pathlib.Path(__file__).resolve().parent
SCRIPT = HERE.parent / "check-test-suite-membership.py"

_spec = importlib.util.spec_from_file_location("membership", SCRIPT)
membership = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(membership)

GOOD_PACKAGE = "(def-suite widget-suite)\n"
GOOD_TESTS = "(in-suite widget-suite)\n\n(test widget-works\n  (is (= 1 1)))\n"


class Fixture:
    """A throwaway repository tree: <root>/<module>/tests/<files>."""

    def __init__(self, files, module="widget"):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = pathlib.Path(self.tmp.name)
        tests = self.root / module / "tests"
        tests.mkdir(parents=True)
        for name, text in files.items():
            (tests / name).write_text(text, encoding="utf-8")

    def run(self):
        return membership.main(["--root", str(self.root)])

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        self.tmp.cleanup()
        return False


class TheCleanCase(unittest.TestCase):
    def test_a_well_formed_tree_passes(self):
        with Fixture({"package.lisp": GOOD_PACKAGE,
                      "widget-tests.lisp": GOOD_TESTS}) as f:
            self.assertEqual(0, f.run())

    def test_a_file_with_no_tests_needs_no_suite(self):
        # Helpers and fixtures are not test files; requiring in-suite of them
        # would make the check noise, and noise gets switched off.
        with Fixture({"package.lisp": GOOD_PACKAGE,
                      "helpers.lisp": "(defun helper () 42)\n",
                      "widget-tests.lisp": GOOD_TESTS}) as f:
            self.assertEqual(0, f.run())


class Rule1MissingInSuite(unittest.TestCase):
    """The documented failure: tests load, never run, suite reports green."""

    def test_a_test_file_without_in_suite_fails(self):
        with Fixture({"package.lisp": GOOD_PACKAGE,
                      "widget-tests.lisp": "(test orphan\n  (is (= 1 1)))\n"}) as f:
            self.assertEqual(1, f.run())

    def test_and_adding_the_in_suite_fixes_it(self):
        # The pair matters: same file, one line different, opposite verdict.
        with Fixture({"package.lisp": GOOD_PACKAGE,
                      "widget-tests.lisp":
                          "(in-suite widget-suite)\n(test orphan\n  (is (= 1 1)))\n"}) as f:
            self.assertEqual(0, f.run())


class Rule2UnknownSuiteName(unittest.TestCase):
    def test_in_suite_naming_a_suite_nobody_declares_fails(self):
        with Fixture({"package.lisp": GOOD_PACKAGE,
                      "widget-tests.lisp":
                          "(in-suite widgit-suite)\n(test typo\n  (is (= 1 1)))\n"}) as f:
            self.assertEqual(1, f.run())


class Rule3TwoRootSuites(unittest.TestCase):
    def test_two_root_suites_in_one_directory_fail(self):
        with Fixture({"package.lisp": "(def-suite widget-suite)\n"
                                      "(def-suite gadget-suite)\n",
                      "widget-tests.lisp": GOOD_TESTS}) as f:
            self.assertEqual(1, f.run())

    def test_but_a_CHILD_suite_is_fine(self):
        # `:in' makes it reachable from the root, so it does run.
        with Fixture({"package.lisp": "(def-suite widget-suite)\n"
                                      "(def-suite gadget-suite :in widget-suite)\n",
                      "widget-tests.lisp": GOOD_TESTS}) as f:
            self.assertEqual(0, f.run())


class TheExclusion(unittest.TestCase):
    def test_autolisp_test_is_left_alone(self):
        # Its corpus harness has its own deftest macros and its own runner, so
        # applying FiveAM's suite rules there would be wrong, not strict.
        with Fixture({"corpus-tests.lisp": "(test orphan\n  (is (= 1 1)))\n"},
                     module="autolisp-test") as f:
            self.assertEqual(0, f.run())


if __name__ == "__main__":
    unittest.main(verbosity=2)
