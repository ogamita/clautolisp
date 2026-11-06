#!/usr/bin/env python3
"""Tests for scripts/check-native-pipeline-yaml.py.

The expensive direction is a FALSE PASS: a .gitlab/native.yml GitLab refuses
kills the whole child pipeline, and every macOS/Windows job with it, in
silence (native-pipeline-yaml-not-linted). So these prove each rejected shape
fires, that a correct file passes, and that the real file does.

    python3 scripts/tests/test-check-native-pipeline-yaml.py
"""

import importlib.util
import pathlib
import unittest

HERE = pathlib.Path(__file__).resolve().parent
_spec = importlib.util.spec_from_file_location(
    "nativeyaml", HERE.parent / "check-native-pipeline-yaml.py")
ny = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(ny)

GOOD = """\
stages: [test]
.gate:
  tags: [macos]
  rules:
    - if: '$CI_COMMIT_TAG =~ /^release-[0-9]/ && $MACOS_RUNNER == "online"'
      when: on_success
    - if: '($MACOS_RUNNER == "online" || $X != null) && $P =~ /,pgp,/i'
      allow_failure: true
    - when: never
probe:pgp:macos:
  extends: .gate
  script: [make probe]
after:pgp:
  needs: [probe:pgp:macos, {job: absent, optional: true}]
  trigger: {include: other.yml}
"""


def one_rule(cond):
    return f"""\
job:
  script: [true]
  rules:
    - if: {cond}
"""


class Expressions(unittest.TestCase):

    def assertRejected(self, expr, fragment):
        why = ny.expression_problem(expr)
        self.assertIsNotNone(why, f"{expr!r} should be rejected")
        self.assertIn(fragment, why)

    def assertAccepted(self, expr):
        self.assertIsNone(ny.expression_problem(expr), expr)

    def test_the_mr_462_doubled_dollar(self):
        self.assertRejected(
            '$$MACOS_RUNNER == "online" && $PROBES_CHANGED =~ /,iw,/', "`$'")

    def test_a_doubled_dollar_after_the_operator(self):
        self.assertRejected('$A == "x" && $$B == "y"', "`$'")

    def test_a_lone_dollar(self):
        self.assertRejected('$ == "x"', "`$'")

    def test_unbalanced_double_quote(self):
        self.assertRejected('$MACOS_RUNNER == "online', "unterminated")

    def test_unbalanced_single_quote(self):
        self.assertRejected("$MACOS_RUNNER == 'online", "unterminated")

    def test_unterminated_regex(self):
        self.assertRejected("$P =~ /,pgp,", "unterminated /regex/")

    def test_bad_regex_flag(self):
        self.assertRejected("$P =~ /,pgp,/x", "flag")

    def test_malformed_regex(self):
        self.assertRejected("$P =~ /(pgp/", "malformed regex")

    def test_match_against_a_string(self):
        self.assertRejected('$P =~ ",pgp,"', "regex")

    def test_a_regex_without_match_operator(self):
        self.assertRejected('$P == /,pgp,/', "`/'")

    def test_unbalanced_parenthesis(self):
        self.assertRejected('($A == "x" && $B == "y"', "unbalanced")
        self.assertRejected('$A == "x")', "unexpected")

    def test_dangling_logic(self):
        self.assertRejected('$A == "x" &&', "operand")

    def test_missing_operator(self):
        self.assertRejected('$A == "x" $B', "missing")

    def test_single_equals(self):
        self.assertRejected('$A = "x"', "unexpected")

    def test_correct_expressions(self):
        for expr in ['$CI_COMMIT_TAG',
                     '$A == "x"', "$A != 'x'", '$A == null',
                     '$A =~ /^release-[0-9]/', '$A !~ $PATTERN',
                     '$A =~ /a\\/b/i',
                     '($A == "x" || $B) && $C =~ /,c,/']:
            self.assertAccepted(expr)


class Files(unittest.TestCase):

    def test_a_correct_file_passes(self):
        self.assertEqual(ny.problems(GOOD), [])

    def test_a_doubled_dollar_rule_is_caught(self):
        bad = GOOD.replace("&& $MACOS_RUNNER", "&& $$MACOS_RUNNER")
        found = ny.problems(bad)
        self.assertEqual(len(found), 1, found)
        self.assertIn(".gate: rules[0]: if:", found[0])

    def test_an_unbalanced_quote_is_caught(self):
        found = ny.problems(one_rule("""'$A == "x'"""))
        self.assertEqual(len(found), 1, found)
        self.assertIn("unterminated", found[0])

    def test_an_if_that_is_not_a_string(self):
        found = ny.problems(one_rule("[1, 2]"))
        self.assertTrue(any("not a string" in p for p in found), found)

    def test_a_bad_when(self):
        found = ny.problems("job:\n  script: [x]\n  rules:\n"
                            "    - when: sometimes\n")
        self.assertTrue(any("when:" in p for p in found), found)

    def test_rules_not_a_list(self):
        found = ny.problems("job:\n  script: [x]\n  rules: {when: never}\n")
        self.assertTrue(any("not a list" in p for p in found), found)

    def test_workflow_rules_are_checked(self):
        found = ny.problems("workflow:\n  rules:\n    - if: '$$A'\n"
                            "job:\n  script: [x]\n")
        self.assertTrue(any(p.startswith("workflow:") for p in found), found)

    def test_a_job_without_script(self):
        found = ny.problems("job:\n  tags: [x]\n")
        self.assertTrue(any("no script:" in p for p in found), found)

    def test_a_hidden_template_needs_no_script(self):
        self.assertEqual(ny.problems(".tpl:\n  tags: [x]\n"), [])

    def test_script_inherited_through_extends(self):
        self.assertEqual(ny.problems(
            ".a:\n  script: [x]\n.b:\n  extends: .a\n"
            "job:\n  extends: [.b]\n"), [])

    def test_unknown_extends(self):
        found = ny.problems("job:\n  extends: .nope\n  script: [x]\n")
        self.assertTrue(any("unknown job" in p for p in found), found)

    def test_extends_cycle(self):
        found = ny.problems(".a:\n  extends: .b\n.b:\n  extends: .a\n")
        self.assertTrue(any("cycle" in p for p in found), found)

    def test_unknown_needs(self):
        found = ny.problems("job:\n  script: [x]\n  needs: [ghost]\n")
        self.assertTrue(any("needs unknown" in p for p in found), found)

    def test_invalid_yaml(self):
        found = ny.problems("job:\n  script: [x\n")
        self.assertTrue(found and "not valid YAML" in found[0], found)

    def test_anchors_and_merge_keys(self):
        self.assertEqual(ny.problems(
            ".v: &v\n  A: 1\njob:\n  variables:\n    <<: *v\n"
            "  script: [x]\n"), [])


class RealFile(unittest.TestCase):

    def test_native_yml_passes(self):
        self.assertEqual(ny.problems(ny.NATIVE_YML.read_text("utf-8")), [])

    def test_native_yml_with_one_dollar_doubled_fails(self):
        text = ny.NATIVE_YML.read_text("utf-8")
        needle = "if: '$MACOS_RUNNER"
        self.assertIn(needle, text)
        bad = text.replace(needle, "if: '$$MACOS_RUNNER", 1)
        self.assertEqual(len(ny.problems(bad)), 1)


if __name__ == "__main__":
    unittest.main()
