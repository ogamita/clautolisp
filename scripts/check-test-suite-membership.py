#!/usr/bin/env python3
"""Fail if a FiveAM test file would not actually RUN.

WHY THIS EXISTS. A test file without `(in-suite ...)' compiles, loads, and its
tests never run: the suite passes GREEN by not executing them. That happened
while fixing sysvar-table-ignores-runtime-dialect-change -- four new tests were
declared outside the suite, the run came back green, and the green was first
read as success. That closed issue ends with the recommendation this script
implements: "le harnais gagnerait a refuser un fichier de tests qui n'en a pas".

It is the worst failure shape this repository keeps meeting, because it looks
exactly like success. `make check-test-suite-membership'.

WHAT IS CHECKED, and each rule exists because its absence is silent:

1. A file with `(test NAME ...)' forms must also carry `(in-suite ...)'.
   Without it the tests attach to whatever suite happened to be current when
   the file was loaded -- in practice, nothing that gets run.

2. The suite it names must be DECLARED by a `def-suite' in the same tests/
   directory. A typo names a suite that does not exist, and FiveAM's
   `in-suite' signals at load time only for a suite it cannot find -- but a
   name that matches ANOTHER subproject's suite (they are symbols in different
   packages, and several are plausibly similar) would not.

3. A tests/ directory must not declare more than one ROOT suite (a `def-suite'
   with no `:in'). A second root is not reachable from the one the runner runs,
   so its tests are defined, loaded, and never executed -- the same silence as
   rule 1, one level up.

WHAT IS NOT CHECKED. Whether the runner actually runs the root suite, and
whether a child suite is reachable through `:in'. Those need the live FiveAM
registry rather than the source text; this script is the cheap half that runs
in every pipeline. See the issue for the dynamic complement.

autolisp-test/ is excluded: its corpus harness has its own `deftest' macros
and its own runner, so FiveAM's suite rules do not apply there.
"""

import argparse
import pathlib
import re
import sys

DEFAULT_ROOT = pathlib.Path(__file__).resolve().parent.parent

# Top-level FiveAM test definitions. `(test NAME' at column 0, which is how
# every test in this repository is written.
TEST_FORM = re.compile(r"^\(test\s+([^\s()]+)", re.MULTILINE)
IN_SUITE = re.compile(r"\(in-suite\s+'?([^\s()]+)\s*\)")
DEF_SUITE = re.compile(r"\(def-suite\s+'?([^\s()]+)([^)]*)\)", re.DOTALL)

# Its own harness, its own runner: not FiveAM suite territory.
EXCLUDED_DIRS = ("autolisp-test",)


def test_directories(root):
    """Every tests/ directory whose files this rule governs."""
    found = set()
    for pattern in ("*/tests/*.lisp", "*/*/tests/*.lisp"):
        for path in root.glob(pattern):
            found.add(path.parent)
    return sorted(d for d in found
                  if not any(part in EXCLUDED_DIRS for part in d.parts))


def suites_declared_in(directory):
    """Suite names declared in DIRECTORY, and those that are ROOTS (no :in)."""
    declared, roots = set(), set()
    for path in sorted(directory.glob("*.lisp")):
        text = path.read_text(encoding="utf-8", errors="replace")
        for name, rest in DEF_SUITE.findall(text):
            declared.add(name.lower())
            if ":in" not in rest:
                roots.add(name.lower())
    return declared, roots


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=pathlib.Path, default=DEFAULT_ROOT,
                        help="repository root to scan (default: this one). "
                             "Exists so the CHECK ITSELF can be tested against "
                             "fixtures that violate each rule -- a check nobody "
                             "has watched fail proves nothing.")
    args = parser.parse_args(argv)
    root = args.root.resolve()

    problems = []
    files_checked = 0
    directories = test_directories(root)

    for directory in directories:
        declared, roots = suites_declared_in(directory)
        rel_dir = directory.relative_to(root)

        # Rule 3: one root suite per tests/ directory.
        if len(roots) > 1:
            problems.append(
                "%s declares %d ROOT suites (%s). Only one can be the suite the "
                "runner runs; the others' tests load and never execute."
                % (rel_dir, len(roots), ", ".join(sorted(roots))))

        for path in sorted(directory.glob("*.lisp")):
            text = path.read_text(encoding="utf-8", errors="replace")
            tests = TEST_FORM.findall(text)
            if not tests:
                continue
            files_checked += 1
            rel = path.relative_to(root)
            in_suites = IN_SUITE.findall(text)
            if not in_suites:
                # Rule 1.
                problems.append(
                    "%s defines %d test(s) (%s...) and has NO (in-suite ...): "
                    "they would load and never run, and the suite would still "
                    "report green."
                    % (rel, len(tests), tests[0]))
                continue
            # Rule 2.
            for name in in_suites:
                if declared and name.lower() not in declared:
                    problems.append(
                        "%s says (in-suite %s) but no def-suite in %s declares "
                        "that name (declared: %s)."
                        % (rel, name, rel_dir,
                           ", ".join(sorted(declared)) or "none"))

    print("test directories: %d, files defining tests: %d"
          % (len(directories), files_checked))
    if problems:
        print("")
        for problem in problems:
            print("FAIL: %s" % problem)
        print("")
        print("A test that does not run is worse than a missing test: the suite")
        print("reports success. Add the (in-suite ...) the file needs, or fix")
        print("the suite name.")
        return 1
    print("ok  every file defining tests declares a suite that exists here")
    return 0


if __name__ == "__main__":
    sys.exit(main())
