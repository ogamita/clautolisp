#!/usr/bin/env python3
"""Which CAD PROBE FAMILIES did this pipeline's change touch?

pjb (2026-09-28): "run the vendor probe jobs only when new probes are
written (or old probes modified); probe results are stored in the project
and git."  A probe measures the VENDOR's behaviour, and its answer is
committed, so running it again on a change that did not touch it only
re-measures the same thing -- ~30 serial CAD jobs per push, against the
project's jobs-in-active-pipelines cap
(ci-job-activity-cap-refuses-master-pipelines).

Two modes:

  ci-detect-probe-changes.py emit FILE
      Appends PROBES_CHANGED=,fam1,fam2,  to the dotenv FILE (detect:runners'
      runners.env), which native:pipeline passes to the child.  Each probe
      job in .gitlab/native.yml runs automatically only when its family is
      listed (and its runner is online); otherwise it is `manual', still
      playable by hand.  The commas delimit, so a rule tests  =~ /,family,/.

  ci-detect-probe-changes.py check
      Fails when a probe-looking tracked file belongs to no family, when a
      family's patterns match no tracked file (a rename left it behind), or
      when a family is not tested by any job rule of .gitlab/native.yml --
      the omissions that would otherwise skip a probe IN SILENCE.

WHY NOT `rules: changes:' in the child: in a child pipeline (source
parent_pipeline) `changes:' always evaluates true, so the question has to
be answered in the parent, where the diff is known, and handed down as a
trigger variable -- the same channel as MACOS_RUNNER / WINDOWS_RUNNER.

WHICH DIFF:
  merge request  -> CI_MERGE_REQUEST_DIFF_BASE_SHA .. HEAD
  default branch -> HEAD^1 .. HEAD, EXCEPT a merge request's merge commit,
                    whose probes already ran in the merge request pipeline
                    (a direct push to master still gets them)
  anything else  -> nothing (tags do not re-run probes; a release does not
                    need the vendor re-measured)
If the diff cannot be computed the families are reported EMPTY, loudly:
the probe jobs are then manual, and their committed results stand.
"""
import importlib.util
import os
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
_spec = importlib.util.spec_from_file_location(
    "natchanges", ROOT / "scripts" / "check-native-pipeline-changes.py")
_nat = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_nat)
glob_to_regex = _nat.glob_to_regex

ENTITIES = "autolisp-front-end/tests/scenarios/entities"

# family -> the files whose change means "this probe was written or modified".
# The shared alfe runtime (autolisp-remote-io.lsp, autolisp-bootstrap.lsp) is
# deliberately NOT here: it is alfe, tested by alfe's own lanes, not a probe.
FAMILIES = {
    "vendor": [
        f"{ENTITIES}/entity-lifecycle*",
        f"{ENTITIES}/drawing-data*",
        f"{ENTITIES}/selection*",
        f"{ENTITIES}/bricscad-extensions-probe.lsp",
        "scripts/run-vendor-probes.*",
    ],
    "suite": ["probes/**"],
    "load-refusal": [
        "probes/sources/probe-load-refusal.lsp",
        "probes/sources/probe-core.lsp",
        "probes/sources/manifest.txt",
        "probes/scripts/**",
    ],
    "encoding": [f"{ENTITIES}/encoding-probe.lsp",
                 "scripts/run-encoding-experiment.*"],
    "lispsys-bom": [f"{ENTITIES}/lispsys-bom-probe.lsp",
                    f"{ENTITIES}/lispsys-forward-probe.lsp",
                    "scripts/run-lispsys-bom-probe.*"],
    "path-sysvars": [f"{ENTITIES}/path-sysvars-probe.lsp",
                     "scripts/run-path-sysvars-probe.*"],
    "getcname": [f"{ENTITIES}/getcname-probe.lsp",
                 "scripts/run-getcname-probe.*"],
    "pgp": [f"{ENTITIES}/pgp-probe.lsp", "scripts/run-pgp-probe.*"],
    "optkw": [f"{ENTITIES}/optkw-probe.lsp", "scripts/run-optkw-probe.*"],
    "pathname": [f"{ENTITIES}/pathname-probe.lsp",
                 "scripts/run-pathname-probe.*"],
    "curve-geometry": [f"{ENTITIES}/curve-geometry-probe.lsp",
                       "scripts/run-curve-geometry-probe.*"],
    "intersectwith": [f"{ENTITIES}/intersectwith-probe.lsp",
                      "scripts/run-intersectwith-probe.*"],
    "console-flood": [f"{ENTITIES}/console-flood-probe.lsp",
                      "scripts/run-console-flood-probe.*"],
    "real-transport": [f"{ENTITIES}/real-transport-probe.lsp",
                       "scripts/run-real-transport-probe.*"],
    "block-comment": [f"{ENTITIES}/block-comment-probe.lsp",
                      "scripts/run-block-comment-probe.*"],
    "sysvars": ["autolisp-spec/autolisp/dump-sysvars.lsp"],
    "entget-pointers": ["probes/sources/probe-entget-pointers.lsp"],
}

# What a probe file looks like; every tracked match must be in a family or
# declared here on purpose.
PROBE_LOOKING = [
    "**/*-probe.lsp",
    "probes/**",
    "scripts/*probe*.lsp",
    "scripts/run-*probe*",
    "scripts/probe-*",
    "scripts/run-encoding-experiment.*",
    f"{ENTITIES}/*.sexp",
]
UNCLAIMED = {
    # run by no job at all
    f"{ENTITIES}/gui-console-probe.lsp":
        "no CI job runs it (encoding-situations-cli-options notes it)",
    # "-probe" in the name, but not a CAD probe job's input
    "autolisp-front-end/tests/scenarios/language/comparison-operators-probe.lsp":
        "a language scenario (generate-comparison-scenarios.lisp), not a"
        " probe job",
    "clautolisp/examples/greet/greet-probe.lsp": "an example",
    "scripts/epure-symbol-probe.lsp":
        "loaded by verify:epure-api:windows, a manual-only verify job",
    # manual-only diagnostics: they never auto-run, so there is nothing to gate
    "scripts/probe-autocad-com-registration.ps1":
        "probe:com-registration:autocad:windows is manual-only",
    "scripts/probe-cad-session-state.ps1":
        "probe:cad-session-state:windows is manual-only",
    "scripts/probe-trustedpaths-registry.ps1":
        "probe:trustedpaths-registry:windows is manual-only",
}


def _match(patterns, path):
    return any(glob_to_regex(p).match(path) for p in patterns)


def families_for(paths):
    return sorted({fam for fam, pats in FAMILIES.items()
                   for p in paths if _match(pats, p)})


def encode(families):
    # never an empty value: a dotenv with an empty one is not worth the risk
    return "," + ",".join(families) + "," if families else "none"


def _git(*args):
    return subprocess.run(["git", "-C", str(ROOT), *args], check=True,
                          capture_output=True, text=True).stdout


def _have(rev):
    return subprocess.run(["git", "-C", str(ROOT), "cat-file", "-e",
                           f"{rev}^{{commit}}"],
                          capture_output=True).returncode == 0


def _diff(base):
    if not _have(base):
        # shallow clone: fetch just enough to reach the base
        if base == "HEAD^1":
            subprocess.run(["git", "-C", str(ROOT), "fetch", "--quiet",
                            "--deepen=1", "origin"], capture_output=True)
        else:
            subprocess.run(["git", "-C", str(ROOT), "fetch", "--quiet",
                            "--depth=1", "origin", base], capture_output=True)
    return _git("diff", "--name-only", "--no-renames", base, "HEAD").split()


def changed_paths(env=os.environ):
    """(paths, why) -- paths is None when the diff could not be computed."""
    if env.get("CI_PIPELINE_SOURCE") == "merge_request_event":
        base = env.get("CI_MERGE_REQUEST_DIFF_BASE_SHA", "")
        if not base:
            return None, "merge request without CI_MERGE_REQUEST_DIFF_BASE_SHA"
        why = f"merge request diff {base[:8]}..HEAD"
    elif (env.get("CI_COMMIT_BRANCH")
          and env.get("CI_COMMIT_BRANCH") == env.get("CI_DEFAULT_BRANCH")):
        if is_merge_request_merge(env.get("CI_COMMIT_MESSAGE", ""),
                                  _git("rev-list", "--parents", "-n1",
                                       "HEAD").split()):
            return [], "merge request merge commit: its MR pipeline ran them"
        base, why = "HEAD^1", "direct push, HEAD^1..HEAD"
    else:
        return [], "neither a merge request nor the default branch"
    try:
        return _diff(base), why
    except subprocess.CalledProcessError as e:
        return None, f"git diff against {base} failed: {e.stderr.strip()}"


def is_merge_request_merge(message, parents_line):
    return len(parents_line) > 2 and "See merge request" in message


def emit(out):
    paths, why = changed_paths()
    if paths is None:
        print(f"  PROBES_CHANGED: CANNOT TELL ({why}) -> no probe family;"
              " the probe jobs stay manual")
        paths = []
    fams = families_for(paths)
    print(f"  PROBES_CHANGED={encode(fams)}   ({why}; {len(paths)} paths)")
    with open(out, "a") as f:
        f.write(f"PROBES_CHANGED={encode(fams)}\n")
    return 0


def problems(paths, native_yml):
    errs = []
    for p in paths:
        if (_match(PROBE_LOOKING, p) and p not in UNCLAIMED
                and not families_for([p])):
            errs.append(f"probe-looking file in no family: {p}")
    for p in UNCLAIMED:
        if p not in paths:
            errs.append(f"UNCLAIMED entry matches no tracked file: {p}")
    for fam, pats in FAMILIES.items():
        if not any(_match(pats, p) for p in paths):
            errs.append(f"family {fam!r} matches no tracked file")
        if not re.search(rf"\$PROBES_CHANGED =~ /,{re.escape(fam)},/",
                         native_yml):
            errs.append(f"family {fam!r} is tested by no rule in"
                        " .gitlab/native.yml")
    return errs


def check():
    paths = set(_git("ls-files").split("\n")) - {""}
    errs = problems(paths, (ROOT / ".gitlab" / "native.yml").read_text())
    for e in errs:
        print(f"check-probe-families: {e}", file=sys.stderr)
    if not errs:
        print(f"check-probe-families: OK ({len(FAMILIES)} families)")
    return 1 if errs else 0


def main(argv):
    if len(argv) >= 2 and argv[1] == "emit":
        return emit(argv[2] if len(argv) > 2 else "runners.env")
    if len(argv) >= 2 and argv[1] == "check":
        return check()
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
