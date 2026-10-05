#!/usr/bin/env python3
"""Tests for scripts/ci-detect-probe-changes.py.

The expensive direction is OMISSION: a probe change mapped to no family is
never re-measured, and nothing says so. So these test the mapping, the
encoding the job rules match against, and that the check actually fires.

    python3 scripts/tests/test-ci-detect-probe-changes.py
"""

import importlib.util
import pathlib
import re
import unittest

HERE = pathlib.Path(__file__).resolve().parent
_spec = importlib.util.spec_from_file_location(
    "probechanges", HERE.parent / "ci-detect-probe-changes.py")
pc = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(pc)

E = pc.ENTITIES


class Families(unittest.TestCase):
    def test_a_probe_file_selects_only_its_family(self):
        self.assertEqual(pc.families_for([f"{E}/getcname-probe.lsp"]),
                         ["getcname"])

    def test_the_runner_script_selects_its_family(self):
        self.assertEqual(pc.families_for(["scripts/run-pgp-probe.ps1"]),
                         ["pgp"])

    def test_vendor_expectations_select_vendor(self):
        self.assertEqual(pc.families_for([f"{E}/selection-bricscad.sexp"]),
                         ["vendor"])

    def test_the_load_refusal_probe_is_also_part_of_the_suite(self):
        self.assertEqual(
            pc.families_for(["probes/sources/probe-load-refusal.lsp"]),
            ["load-refusal", "suite"])

    def test_code_and_documentation_select_nothing(self):
        self.assertEqual(pc.families_for([
            "clautolisp/cador/source/sysvars.lisp",
            "autolisp-front-end/source/runtime/autolisp-remote-io.lsp",
            "issues/open/TRIAGE.org"]), [])


class Encoding(unittest.TestCase):
    """The job rules test  $PROBES_CHANGED =~ /,family,/  -- a family must
    not match inside another's name (path-sysvars vs sysvars)."""

    def rule_matches(self, fam, fams):
        return bool(re.search(f",{fam},", pc.encode(fams)))

    def test_delimited(self):
        self.assertEqual(pc.encode(["pgp", "vendor"]), ",pgp,vendor,")
        self.assertEqual(pc.encode([]), "none")

    def test_sysvars_does_not_match_path_sysvars(self):
        self.assertFalse(self.rule_matches("sysvars", ["path-sysvars"]))
        self.assertTrue(self.rule_matches("path-sysvars", ["path-sysvars"]))


class MergeCommit(unittest.TestCase):
    def test_merge_request_merge_is_recognised(self):
        self.assertTrue(pc.is_merge_request_merge(
            "Merge branch 'x' into 'master'\n\nSee merge request ogamita/clautolisp!1",
            ["c", "p1", "p2"]))

    def test_direct_push_is_not(self):
        self.assertFalse(pc.is_merge_request_merge("fix", ["c", "p1"]))


class Check(unittest.TestCase):

    def tracked(self):
        return {
            f"{E}/entity-lifecycle-probe.lsp", "probes/sources/probe-core.lsp",
            "probes/sources/probe-load-refusal.lsp",
            "probes/sources/manifest.txt", "probes/scripts/run-probes.sh",
            f"{E}/encoding-probe.lsp", f"{E}/path-sysvars-probe.lsp",
            f"{E}/getcname-probe.lsp", f"{E}/pgp-probe.lsp",
            f"{E}/optkw-probe.lsp", f"{E}/pathname-probe.lsp",
            f"{E}/lispsys-bom-probe.lsp",
            "autolisp-spec/autolisp/dump-sysvars.lsp", *pc.UNCLAIMED}

    def yml(self):
        return "\n".join(f"$PROBES_CHANGED =~ /,{f},/" for f in pc.FAMILIES)

    def test_clean_tree_passes(self):
        self.assertEqual(pc.problems(self.tracked(), self.yml()), [])

    def test_an_unclassified_probe_fails(self):
        errs = pc.problems(self.tracked() | {f"{E}/new-thing-probe.lsp"},
                           self.yml())
        self.assertTrue(any("new-thing-probe" in e for e in errs), errs)

    def test_a_family_no_job_tests_fails(self):
        errs = pc.problems(self.tracked(), self.yml().replace(",pgp,", ",x,"))
        self.assertTrue(any("'pgp'" in e for e in errs), errs)


if __name__ == "__main__":
    unittest.main()
