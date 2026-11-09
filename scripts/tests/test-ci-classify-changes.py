#!/usr/bin/env python3
"""Unit + integration tests for scripts/ci-classify-changes.py."""
import importlib.util
import pathlib
import sys
import unittest

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
_spec = importlib.util.spec_from_file_location(
    "ciclass", ROOT / "scripts" / "ci-classify-changes.py")
cc = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(cc)


class Classify(unittest.TestCase):
    def setUp(self):
        # Small synthetic lists so the test does not depend on the live YAML.
        self.code = cc._matchers(["**/*.lisp", "**/*.py", "**/tools/**"])
        self.meta = cc._matchers(["issues/**", "COPYING", ".claude/**"])
        self.doc = cc._matchers(["documentation/**", "**/*.org", "README.md"])

    def c(self, p):
        return cc.classify(p, self.code, self.meta, self.doc)

    def test_code_wins_over_everything(self):
        # a .lisp is code wherever it lives, even under issues/ (conservative:
        # never skip tests on something that looks like code)
        self.assertEqual(self.c("clautolisp/cador/source/model.lisp"), "CODE")
        self.assertEqual(self.c("issues/open/repro.lisp"), "CODE")

    def test_issues_org_is_meta_not_doc(self):
        # the crux: issues/*.org (e.g. TRIAGE.org) must be META, so an
        # issues-only change rebuilds nothing -- META precedes DOC.
        self.assertEqual(self.c("issues/open/TRIAGE.org"), "META")
        self.assertEqual(self.c("issues/open/foo.issue"), "META")

    def test_doc_paths_are_doc(self):
        self.assertEqual(self.c("documentation/manual.org"), "DOC")
        self.assertEqual(self.c("clautolisp/README.org"), "DOC")
        self.assertEqual(self.c("README.md"), "DOC")

    def test_meta_scaffolding(self):
        self.assertEqual(self.c("COPYING"), "META")
        self.assertEqual(self.c(".claude/settings.json"), "META")

    def test_unclassified_is_none(self):
        self.assertIsNone(self.c("weird/thing.xyz"))


class Anchors(unittest.TestCase):
    def test_yaml_anchor_list_reads_definition_not_comment(self):
        import tempfile
        import os
        body = (
            "# mentions &changes-code in a comment, must be ignored\n"
            ".changes-code: &changes-code\n"
            '  - "**/*.lisp"\n'
            '  - "**/*.py"\n'
            ".next: &next\n"
            '  - "nope"\n')
        d = tempfile.mkdtemp()
        (pathlib.Path(d) / ".gitlab-ci.yml").write_text(body)
        saved = cc.ROOT
        try:
            cc.ROOT = pathlib.Path(d)
            self.assertEqual(cc.yaml_anchor_list("changes-code"),
                             ["**/*.lisp", "**/*.py"])
        finally:
            cc.ROOT = saved


class LiveRepo(unittest.TestCase):
    def test_every_tracked_path_classified(self):
        # Integration: the real repository must be fully classified (rc 0).
        self.assertEqual(cc.main([]), 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
