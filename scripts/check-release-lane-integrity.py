#!/usr/bin/env python3
"""Fail if a release can look published without being usable.

Five failure modes, every one of them seen for real, and the first four
silent -- the release went green, and the defect surfaced somewhere else,
later, as something that did not look like a release problem at all.

The first two cost release-1.8.46 its contents:

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

The next two cost 1.8.47 and 1.8.49 their usability, and were reported
from outside -- by the SCHMS+ CI, which could not install a release and
had to carry a workaround (release-asset-links-use-artifacts-file.issue):

  3. An expiry on collect:release's artefacts. The published release
     LINKS AT those artefacts, so a 30-day expiry turned every release
     older than a month into a catalogue of dead links, while the release
     page went on looking perfectly published.

  4. Asset links built through `/artifacts/file/', which is the artefact
     BROWSING page and serves HTML; `/artifacts/raw/' serves the file.
     Both answer 200, so a consumer writes 40 KB of HTML to disk under
     the archive's name and only fails at extraction, with a message
     about archive format rather than about the link.

The fifth is the loud one, and it cost two releases their schedule
rather than their contents:

  5. A `benchmark' stage ordered in front of a `release' stage. No release
     job declares `needs:', so it waits for the whole preceding stage --
     and benchmark:autocad:windows shares the concurrency-1 Windows runner
     with release:windows:x86-64. release-1.8.47 was cancelled by hand;
     release-1.8.49 waited out a two-hour timeout before its artefacts
     could start. A measurement must never be able to gate a product, so
     the ordering itself is checked: reordering the stages back would
     otherwise restore the fault with nothing to say so.

None is a hypothetical: each one shipped.

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

    # (3) a published release LINKS AT collect:release's artefacts, so an
    #     expiry on them is an expiry on the release. With the default
    #     30 days, every release older than a month turned into a catalogue
    #     of dead links while still looking published
    #     (release-asset-links-use-artifacts-file.issue).
    bodies = dict(found)
    collect = bodies.get("collect:release:")
    if collect is None:
        print("FAIL: collect:release not found -- the parser needs updating")
        status = 1
    elif re.search(r"expire_in:\s*never", block(collect, "artifacts")):
        print("ok  collect:release keeps its artefacts (the release links "
              "point at them)")
    else:
        print("FAIL: collect:release lets its artefacts expire, and the")
        print("      published release links AT those artefacts -- so the")
        print("      release becomes dead links on expiry. Use `expire_in:")
        print("      never'; a release is permanent, its assets must be too.")
        status = 1

    # (4) `/artifacts/file/' is the artefact BROWSING page and serves HTML;
    #     `/artifacts/raw/' serves the file. Both answer 200, so a `file'
    #     link fails only at extraction, in the consumer, with a message
    #     about archive format. Releases 1.8.47 and 1.8.49 shipped that way.
    emitters = ["scripts/make-gitlab-release.py"]
    for path in emitters:
        try:
            with open(path, encoding="utf-8") as stream:
                source = stream.read()
        except OSError:
            print("FAIL: %s is missing -- it is what publishes a release" % path)
            status = 1
            continue
        offenders = [ln.strip() for ln in source.splitlines()
                     if "artifacts/file/" in ln and not ln.strip().startswith("#")
                     and "`/artifacts/file/" not in ln]
        if offenders:
            print("FAIL: %s builds a link through the browsing page:" % path)
            for line in offenders:
                print("        %s" % line)
            print("      Use /artifacts/raw/ -- /artifacts/file/ serves HTML.")
            status = 1
        elif "artifacts/raw/" in source:
            print("ok  %s emits raw artefact links" % path)
        else:
            print("FAIL: %s emits no artefact link at all" % path)
            status = 1

    # (5) a measurement may not gate a product. Release jobs carry no
    #     `needs:', so stage order alone decides what waits for what, and
    #     the CAD benchmark shares the concurrency-1 Windows runner with
    #     the Windows release lane
    #     (benchmark-autocad-windows-hangs-and-blocks-release.issue).
    stages = []
    in_stages = False
    for line in text.splitlines():
        if re.match(r"^stages:\s*$", line):
            in_stages = True
            continue
        if in_stages:
            item = re.match(r"^\s+-\s+(\S+)\s*$", line)
            if item:
                stages.append(item.group(1))
            elif line.strip() and not line.lstrip().startswith("#"):
                break
    if not stages:
        print("FAIL: no stages: list parsed -- the parser needs updating")
        status = 1
    elif "benchmark" not in stages or "release" not in stages:
        print("ok  no benchmark/release stage pair to order")
    elif stages.index("benchmark") < stages.index("release"):
        print("FAIL: the `benchmark' stage runs BEFORE `release':")
        print("        %s" % " -> ".join(stages))
        print("      Release jobs declare no `needs:', so they wait for the")
        print("      whole benchmark stage -- and the CAD benchmark shares the")
        print("      concurrency-1 Windows runner with release:windows:x86-64.")
        print("      That ordering cost release-1.8.47 and release-1.8.49.")
        print("      A measurement may not gate a product: put `benchmark'")
        print("      after `collect'.")
        status = 1
    else:
        print("ok  benchmark runs after release (no measurement gates an "
              "artefact)")

    if status == 0:
        print("release lanes: %d per-target lanes assert their artefacts; "
              "no before_script exits; benchmark is off the release path"
              % lanes)
    return status


if __name__ == "__main__":
    sys.exit(main())
