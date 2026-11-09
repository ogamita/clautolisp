#!/usr/bin/env python3
"""Classify every tracked path as CODE, DOC, or META, and guard the CI
change-gating lists against drift and silent gaps.

Why: the CI gates heavy lanes on `rules:changes:' so a push/MR that touches
only documentation does not re-run the code tests, and one that touches only
issues does not even rebuild the docs.  That is only SAFE if every tracked
path is classified and the gate lists cannot silently drift from what is
actually tested -- a mis-classification that treats a code change as "docs"
would skip the tests on real code.  This script is that guard.

Three buckets, with precedence CODE > META > DOC (code always wins, so a
file that looks like code is never skipped; issues/*.org is META, not DOC):

- CODE: the exact path list that native:pipeline gates on (read from
  .gitlab-ci.yml, the single source of truth).  The code lanes run iff a CODE
  path changed.
- META: the tracker and scaffolding (issues/**, licences, .claude/**, .keep,
  recorded probe-result data).  Nothing runs for a META-only change.
- DOC: prose and the documentation toolchain's inputs, SCOPED by location so
  issues/*.org stays META.  The documentation lane runs iff a CODE or DOC
  path changed.

Modes:
  (default)         classify git ls-files, print bucket counts, FAIL on any
                    unclassified path (the silent-gap guard).
  --show BUCKET     list the tracked files in CODE|DOC|META.
  --check-yaml      additionally assert the .gitlab-ci.yml anchors
                    &changes-code and &changes-doc match this script's CODE and
                    DOC lists (the drift guard).
"""
import importlib.util
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

# Reuse glob_to_regex + run_patterns from the native-gate checker so the CODE
# list has exactly ONE source of truth (native:pipeline's changes: block).
_spec = importlib.util.spec_from_file_location(
    "natchanges", ROOT / "scripts" / "check-native-pipeline-changes.py")
_nat = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_nat)
glob_to_regex = _nat.glob_to_regex
native_run_patterns = _nat.run_patterns  # the CODE list, from the YAML

# META: the tracker + scaffolding + recorded data.  A META-only change runs
# nothing (not the tests, not the doc build).  issues/** is listed BEFORE DOC
# in precedence so issues/*.org (e.g. TRIAGE.org) is META, never DOC.
META = [
    "issues/**",
    "COPYING", "LICENSE", "AUTHORS",
    "**/.gitignore", "**/.gitattributes",
    ".claude/**",
    "**/.dir-locals.el.example",
    "**/.keep",
    "**/*.plan",
    # Recorded probe OUTPUT kept as evidence: data, not code or docs.  (Files
    # here that match a CODE glob -- *.lsp/*.json/*.sexp -- are CODE by
    # precedence, conservatively re-running tests, exactly as today.)
    "autolisp-spec/results/**",
    "probe-results/**",
]

# DOC: prose + the documentation toolchain's inputs.  SCOPED by location
# (per top-level tree) rather than bare **/*.org, so issues/*.org does not
# leak in.  A new prose file in an unlisted location FAILS the classifier
# (the silent-gap guard), forcing an explicit decision -- never a silent skip.
DOC = [
    # the documentation tree and the spec/benchmark prose
    "documentation/**",
    "autolisp-spec/**/*.org", "autolisp-spec/**/*.md", "autolisp-spec/**/*.texi",
    "autolisp-benchmark/**/*.org", "autolisp-benchmark/**/*.md",
    # per-module READMEs / PLAN / notes living beside the code
    "clautolisp/**/*.org", "clautolisp/**/*.md",
    "autolisp-front-end/**/*.org", "autolisp-front-end/**/*.md",
    "autolisp-test/**/*.org", "autolisp-test/**/*.md",
    "probes/**/*.org", "probes/**/*.md",
    "scripts/**/*.org", "scripts/**/*.md",
    ".github/**/*.md",
    # top-level prose
    "README.md", "README.org", "INSTALL.org", "RELEASE_NOTES.org",
    "SPEC.md", "AGENTS.md",
    # man pages and the LaTeX/TeX/diagram inputs the manuals are built from
    "**/*.texi", "**/*.info", "**/*.man", "**/*.1", "**/*.3",
    "**/*.tex", "**/*.sty", "**/texmf.cnf",
    "**/*.graffle", "**/*.mmd", "**/*.puml", "**/*.dot", "**/*.html",
    # images and rendered documents (illustrations / build artefacts)
    "**/*.png", "**/*.jpg", "**/*.jpeg", "**/*.svg", "**/*.gif",
    "**/*.pdf", "**/*.eps",
]


def _matchers(patterns):
    return [glob_to_regex(p) for p in patterns]


def classify(path, code_m, meta_m, doc_m):
    if any(m.match(path) for m in code_m):
        return "CODE"
    if any(m.match(path) for m in meta_m):
        return "META"
    if any(m.match(path) for m in doc_m):
        return "DOC"
    return None


def tracked_paths():
    out = subprocess.run(["git", "ls-files"], cwd=ROOT,
                         capture_output=True, text=True, check=True).stdout
    return [p for p in out.splitlines() if p]


def yaml_anchor_list(name):
    """Read the quoted glob list of a `.NAME: &NAME` block from .gitlab-ci.yml,
    the same text-parsing discipline check-native-pipeline-changes.py uses
    (no YAML lib dependency)."""
    text = (ROOT / ".gitlab-ci.yml").read_text(encoding="utf-8")
    # Match only the anchor DEFINITION line `.name: &name` (not a comment or a
    # `*name' reference that merely mentions it).
    anchor = re.search(r"^\.\S*:\s*&%s\s*$" % re.escape(name), text, re.MULTILINE)
    if not anchor:
        raise SystemExit("FAIL: anchor &%s not found in .gitlab-ci.yml" % name)
    rest = text[anchor.end():]
    end = re.search(r"\n\S", rest)  # next top-level (non-indented) line
    block = rest[: end.start()] if end else rest
    return re.findall(r'^\s*-\s*"([^"]+)"\s*$', block, re.MULTILINE)


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    code = native_run_patterns(ROOT)
    if not code:
        raise SystemExit("FAIL: could not read native:pipeline CODE list")
    code_m, meta_m, doc_m = _matchers(code), _matchers(META), _matchers(DOC)
    paths = tracked_paths()
    buckets = {"CODE": [], "DOC": [], "META": [], None: []}
    for p in paths:
        buckets[classify(p, code_m, meta_m, doc_m)].append(p)

    if argv and argv[0] == "--show":
        for p in buckets.get(argv[1].upper(), []):
            print(p)
        return 0

    print("ci-classify-changes: CODE=%d DOC=%d META=%d of %d tracked"
          % (len(buckets["CODE"]), len(buckets["DOC"]),
             len(buckets["META"]), len(paths)))

    rc = 0
    if buckets[None]:
        print("FAIL: %d path(s) classified as NEITHER code, doc nor meta:"
              % len(buckets[None]))
        for p in buckets[None][:60]:
            print("  " + p)
        print("Classify each: add a CODE glob to native:pipeline (and the "
              "&changes-code anchor), a DOC glob, or a META glob here.")
        rc = 1

    if "--check-yaml" in argv:
        for anchor, want, label in (("changes-code", code, "CODE"),
                                     ("changes-doc", DOC, "DOC")):
            got = yaml_anchor_list(anchor)
            if sorted(got) != sorted(want):
                print("FAIL: &%s anchor drifted from the %s list" % (anchor, label))
                only_yaml = sorted(set(got) - set(want))
                only_src = sorted(set(want) - set(got))
                if only_yaml:
                    print("  in YAML only : " + ", ".join(only_yaml))
                if only_src:
                    print("  in %s only : %s" % (label, ", ".join(only_src)))
                rc = 1
        if rc == 0:
            print("ok  &changes-code and &changes-doc match the classifier lists")

    if rc == 0:
        print("ok  every tracked path is code, doc or meta")
    return rc


if __name__ == "__main__":
    sys.exit(main())
