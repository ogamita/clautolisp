#!/usr/bin/env python3
"""Fail when a tracked path is classified by neither half of native:pipeline's
`changes:' gate.

WHY THIS EXISTS. A merge request now spawns the native child pipeline only when
it changes something those lanes could exercise
(ci-job-activity-cap-refuses-master-pipelines: eight merge requests in three
hours, six documentation-only, put 172 jobs in flight and GitLab then refused a
pipeline outright -- zero jobs, reading like an ordinary red while the work
never ran).

GitLab has no "only these paths changed" primitive, so the gate is written as
"run when these changed". That inverts the risk: a pattern MISSING from the list
silently skips the native lanes on a real code change, and this repository has
been bitten twice by that exact shape -- a release "quietly missing two
platforms WHILE BOTH MACHINES WERE ONLINE ... Worse than the blocking it
replaced, and invisible".

So the gate is not allowed to be silent. Every tracked path must match either

  * the RUN list, read from `.gitlab-ci.yml' itself -- one source of truth, so
    the check cannot drift from the behaviour; or
  * the IRRELEVANT list below, which is declared HERE, with a reason.

A path matching neither fails this check. Adding a new kind of file therefore
forces a decision instead of inheriting one, which is the whole point: the
failure mode being guarded against is not "wrong answer" but "no answer, and
nobody notices".

Overlap is fine and deliberate: a path in both lists runs the lanes, because
GitLab runs the child if ANY changed file matches. Omission is the expensive
direction, so the RUN list is generous.

    python3 scripts/check-native-pipeline-changes.py
    make check-native-pipeline-changes
"""

import pathlib
import re
import subprocess
import sys

DEFAULT_ROOT = pathlib.Path(__file__).resolve().parent.parent

# Paths that CANNOT affect a native Windows/macOS lane. Each entry is a
# deliberate declaration, not a convenience: if one of these turns out to matter,
# it belongs in the RUN list in .gitlab-ci.yml instead.
IRRELEVANT = [
    # Prose. Org is the repository's document format, Markdown is for agents and
    # GitLab, and the issue files are the tracker.
    "**/*.org",
    "**/*.md",
    "**/*.issue",
    "**/*.texi",
    "**/*.info",
    # Man pages: built from .man sources, read by humans.
    "**/*.man",
    "**/*.1",
    "**/*.3",
    # Licences and other top-level prose with no extension.
    "COPYING",
    "LICENSE",
    "AUTHORS",
    "**/.gitignore",
    "**/.gitattributes",
    # Images and rendered documents: build artefacts or illustrations.
    "**/*.png",
    "**/*.jpg",
    "**/*.jpeg",
    "**/*.svg",
    "**/*.gif",
    "**/*.pdf",
    "**/*.eps",
    # Editor and agent scaffolding.
    "**/.dir-locals.el.example",
    ".claude/**",
    # The documentation toolchain's own inputs: a LaTeX preamble and a TeX
    # configuration used when rendering the manuals. They change what a PDF
    # looks like, never what a Windows or macOS lane does.
    "**/*.sty",
    "**/texmf.cnf",
    # Diagram SOURCES for the documents (Graffle, Mermaid, PlantUML, Graphviz)
    # and one demo page. Rendered into the manuals; nothing executes them.
    "**/*.graffle",
    "**/*.mmd",
    "**/*.puml",
    "**/*.dot",
    "**/*.html",
    # Recorded probe OUTPUT from past vendor runs, kept as evidence. Reading it
    # is how a divergence is reviewed; changing it cannot alter a lane.
    "autolisp-spec/results/**",
    # Placeholders that keep an otherwise-empty directory in git, and the
    # planning documents beside the issues.
    "**/.keep",
    "**/*.plan",
]


def glob_to_regex(pattern):
    """Translate a GitLab `changes:' glob to a regex.

    `**' crosses directory separators, `*' does not, `?' is one non-separator
    character. Written out rather than delegated to fnmatch because fnmatch's
    `*' also crosses separators, which would make `**/*.lisp' and `*.lisp'
    indistinguishable and quietly widen every pattern.
    """
    out = ["^"]
    i = 0
    while i < len(pattern):
        char = pattern[i]
        if pattern.startswith("**/", i):
            out.append("(?:.*/)?")
            i += 3
        elif pattern.startswith("**", i):
            out.append(".*")
            i += 2
        elif char == "*":
            out.append("[^/]*")
            i += 1
        elif char == "?":
            out.append("[^/]")
            i += 1
        else:
            out.append(re.escape(char))
            i += 1
    out.append("$")
    return re.compile("".join(out))


def run_patterns(root):
    """The RUN list, read out of native:pipeline's `changes:' block.

    Parsed from the text rather than with a YAML library so the check has no
    dependency the CI image might lack, and anchored on the job name so it
    cannot accidentally read another job's `changes:'.
    """
    text = (root / ".gitlab-ci.yml").read_text(encoding="utf-8")
    start = text.find("\nnative:pipeline:")
    if start < 0:
        raise SystemExit("FAIL: native:pipeline not found in .gitlab-ci.yml")
    # The job ends at the next top-level key.
    rest = text[start + 1:]
    end = re.search(r"\n(?=[A-Za-z.][^\s:]*:)", rest[1:])
    block = rest[: end.start() + 1] if end else rest
    # A KEY, not the word: `changes:' also occurs in the prose comments around
    # the rule, and matching those is how the first version of this reported
    # "lists no paths" against a block that had none because the text it found
    # was a sentence. Text-parsing YAML is fragile; anchoring on a line that is
    # only whitespace + the key is the cheap way to keep it honest.
    found = re.search(r"^\s*changes:\s*$", block, re.MULTILINE)
    changes = found.start() if found else -1
    if changes < 0:
        # The gate is ABSENT, which is a real state and not an error: it was
        # reverted on 2026-09-27 after failing to match a merge request that
        # changed scripts/*.py. The classification is still worth keeping --
        # it is the list the gate needs when it returns, and it already found
        # four real omissions -- so the check reports and passes instead of
        # failing on a situation somebody chose.
        return None
    patterns = re.findall(r'^\s*-\s*"([^"]+)"\s*$', block[changes:], re.MULTILINE)
    if not patterns:
        raise SystemExit("FAIL: native:pipeline's changes: block lists no paths")
    return patterns


def tracked_paths(root):
    out = subprocess.run(["git", "-C", str(root), "ls-files"],
                         capture_output=True, text=True, check=True).stdout
    return [line for line in out.splitlines() if line]


def unclassified(paths, run, irrelevant):
    matchers = [glob_to_regex(p) for p in list(run) + list(irrelevant)]
    return [p for p in paths if not any(m.match(p) for m in matchers)]


def main(argv=None):
    root = DEFAULT_ROOT if not argv else pathlib.Path(argv[0]).resolve()
    run = run_patterns(root)
    if run is None:
        print("native:pipeline has no changes: gate at the moment -- it was")
        print("reverted after failing to match a real code change. Nothing to")
        print("classify against; the IRRELEVANT list here is kept for when the")
        print("gate returns (ci-job-activity-cap-refuses-master-pipelines).")
        return 0
    paths = tracked_paths(root)
    missing = unclassified(paths, run, IRRELEVANT)

    print("native:pipeline changes: %d run pattern(s), %d declared-irrelevant"
          % (len(run), len(IRRELEVANT)))
    print("tracked paths checked: %d" % len(paths))
    if missing:
        print("")
        print("FAIL: %d tracked path(s) match neither the RUN list in"
              % len(missing))
        print("      .gitlab-ci.yml nor the declared-irrelevant list in this")
        print("      script, so a merge request touching ONLY them would skip")
        print("      the native lanes without anybody deciding that:")
        for path in missing[:40]:
            print("        %s" % path)
        if len(missing) > 40:
            print("        ... and %d more" % (len(missing) - 40))
        print("")
        print("Classify each one: add its pattern to native:pipeline's changes:")
        print("if the native lanes could exercise it, or to IRRELEVANT here with")
        print("a reason if they could not. Omission is the expensive direction.")
        return 1
    print("ok  every tracked path is classified")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
