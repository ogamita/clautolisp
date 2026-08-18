#!/usr/bin/env python3
"""Fail if a release lane can go green without producing its artefacts.

Two failure modes, both seen for real in release-1.8.46, both silent:

  1. `exit' inside a before_script. GitLab concatenates before_script and
     script into ONE shell, so an exit there ends the whole job -- and
     ends it SUCCESSFULLY. release:linux:arm32 guarded its optional CCL
     install with `exit 0', ran for 35 seconds, uploaded an empty dist/,
     went green, and the release simply had no arm32 artefacts. Nothing
     anywhere was red.

  2. A per-target lane that never asserts what it built. GitLab uploads
     whatever `paths:' matches, empty directories included, and calls it
     success. Every release:<os>:<arch> lane must therefore end by running
     `make verify-release-artefacts'.

Neither is a hypothetical: both cost a published release its contents.

    python3 scripts/check-release-lane-integrity.py
    make check-release-lane-integrity
"""
import re
import sys

CI = sys.argv[1] if len(sys.argv) > 1 else ".gitlab-ci.yml"

# Lanes that build for one target. release:documentation and release:sources
# produce no per-target binaries, so the artefact assertion does not apply.
PER_TARGET = re.compile(r"^release:[a-z0-9-]+:[a-z0-9-]+:$")


def jobs(text):
    """Split the file into top-level (name, body) pairs."""
    out, name, buf = [], None, []
    for line in text.splitlines():
        if re.match(r"^[A-Za-z_.][A-Za-z0-9:_.-]*:\s*$", line):
            if name:
                out.append((name, "\n".join(buf)))
            name, buf = line.rstrip()[:-1] + ":", []
        elif name:
            buf.append(line)
    if name:
        out.append((name, "\n".join(buf)))
    return out


def block(body, key):
    """The lines of `key:' in this job body, up to the next sibling key."""
    lines = body.splitlines()
    for i, line in enumerate(lines):
        if re.match(r"^\s*%s:\s*$" % key, line):
            indent = len(line) - len(line.lstrip())
            kept = []
            for nxt in lines[i + 1:]:
                if nxt.strip() and (len(nxt) - len(nxt.lstrip())) <= indent:
                    break
                kept.append(nxt)
            return "\n".join(kept)
    return ""


def main():
    with open(CI, encoding="utf-8") as stream:
        text = stream.read()

    found = jobs(text)
    if not found:
        print("FAIL: no jobs parsed from %s -- fix the parser, do not delete "
              "the check" % CI)
        return 1

    status = 0
    lanes = 0

    for name, body in found:
        # (1) `exit' in a before_script ends the job green.
        pre = block(body, "before_script")
        for line in pre.splitlines():
            bare = line.strip().lstrip("-").strip()
            if bare.startswith("#"):
                continue
            if re.search(r"\bexit\b", bare):
                print("FAIL: %s has `exit' in its before_script:" % name)
                print("        %s" % bare)
                print("      before_script and script share one shell, so this")
                print("      ends the JOB, and ends it green with no artefacts.")
                print("      Skip the step instead (case/esac or if/fi).")
                status = 1

        # (2) a per-target lane must assert what it produced.
        if not PER_TARGET.match(name):
            continue
        lanes += 1
        script = block(body, "script")
        if "verify-release-artefacts" in script:
            print("ok  %s asserts its artefacts" % name)
        elif "release-windows.sh" in script:
            # The Windows lane hands off to bash; the assertion lives there.
            try:
                with open("scripts/release-windows.sh", encoding="utf-8") as sh:
                    if "verify-release-artefacts" in sh.read():
                        print("ok  %s asserts its artefacts (via "
                              "release-windows.sh)" % name)
                        continue
            except OSError:
                pass
            print("FAIL: %s delegates to release-windows.sh, which does not run"
                  % name)
            print("      make verify-release-artefacts.")
            status = 1
        else:
            print("FAIL: %s never runs `make verify-release-artefacts', so an" % name)
            print("      empty build would upload an empty dist/ and pass.")
            status = 1

    if lanes == 0:
        print("FAIL: no per-target release lanes matched -- the parser needs "
              "updating")
        status = 1

    if status == 0:
        print("release lanes: %d per-target lanes assert their artefacts; "
              "no before_script exits" % lanes)
    return status


if __name__ == "__main__":
    sys.exit(main())
