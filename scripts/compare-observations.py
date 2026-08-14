#!/usr/bin/env python3
"""Compare a probe's exhibited OBSERVE output against a scenario's
per-target :expected-observations (autolisp-spec ch.25 probe model).

    compare-observations.py <scenario.sexp> <probe-log>

The scenario .sexp carries, for its target, :expected-observations
(entries "(NAME EXPECTED [NORMATIVE])") and/or :expected-observations-default
(the token every un-named observation must equal). The probe log carries
`OBSERVE <name> <token>` lines. This mirrors alfe.conformance's
CLASSIFY-OBSERVATIONS so the real-CAD vendor harness gates the same way the
in-process conformance runner does:

  CONFORMS          exhibited == expected (== normative)
  KNOWN-DIVERGENCE  exhibited == expected but expected != normative (green)
  UNEXPECTED        exhibited != expected                     (fails, exit 1)
  MISSING           an expected observation was never emitted (fails, exit 1)

Prints a per-observation report and the tallies; exits 1 iff any UNEXPECTED
or MISSING, else 0.
"""
import re
import sys


# Byte-order marks, longest first: UTF-32-LE starts with the UTF-16-LE mark,
# so testing in this order matters.
BOMS = ((b"\xff\xfe\x00\x00", "utf-32-le"),
        (b"\x00\x00\xfe\xff", "utf-32-be"),
        (b"\xff\xfe", "utf-16-le"),
        (b"\xfe\xff", "utf-16-be"),
        (b"\xef\xbb\xbf", "utf-8-sig"))


def read_lines(path):
    """The lines of PATH, decoded by sniffing its byte-order mark.

    The probe log is written by whichever shell drives the harness, and
    Windows PowerShell's Tee-Object / Out-File default to UTF-16LE with a
    BOM. Reading that as UTF-8 does not raise — with errors="replace" it
    silently yields a wall of replacement characters, every OBSERVE line
    disappears, and this script then reported "backend unreachable or probe
    crashed" about a probe that had in fact emitted 101 observations
    perfectly. That is what the vendor probes failed on the first time they
    could run against real AutoCAD and BricsCAD (2026-08-14).

    Sniffing the BOM rather than fixing only the writer keeps this correct
    for logs already archived, and for whatever shell drives it next. UTF-8
    without a BOM remains the fallback, so nothing about the Unix path
    changes.
    """
    with open(path, "rb") as f:
        raw = f.read()
    for bom, encoding in BOMS:
        if raw.startswith(bom):
            return raw.decode(encoding, errors="replace").splitlines()
    return raw.decode("utf-8", errors="replace").splitlines()

ENTRY = re.compile(r'\(\s*"([^"]+)"\s+"([^"]+)"(?:\s+"([^"]+)")?\s*\)')


def parse_scenario(path):
    """Return (expected list of (name, expected, normative|None), default|None)."""
    expected, default = [], None
    collecting = False
    for line in read_lines(path):
        s = line.strip()
        m = re.match(r':expected-observations-default\s+"([^"]*)"', s)
        if m:
            default = m.group(1)
            continue
        if s.startswith(":expected-observations") and s.endswith("("):
            collecting = True
            continue
        if collecting:
            if s.startswith(")"):
                collecting = False
                continue
            em = ENTRY.match(s)
            if em:
                expected.append((em.group(1), em.group(2), em.group(3)))
    return expected, default


def parse_observations(path):
    table = {}
    for line in read_lines(path):
        s = line.strip()
        if s.startswith("OBSERVE "):
            parts = s[len("OBSERVE "):].split(None, 1)
            if len(parts) == 2:
                table[parts[0]] = parts[1].strip()
    return table


def main():
    if len(sys.argv) != 3:
        sys.exit("usage: compare-observations.py <scenario.sexp> <probe-log>")
    expected, default = parse_scenario(sys.argv[1])
    exhibited = parse_observations(sys.argv[2])

    tally = {"conforms": 0, "known-divergence": 0, "unexpected": 0, "missing": 0}
    lines, failures = [], []
    named = set()
    for name, exp, norm in expected:
        named.add(name)
        if name not in exhibited:
            tally["missing"] += 1
            failures.append(f"MISSING {name} (expected {exp})")
            lines.append(f"  MISSING          {name}: expected {exp}")
        elif exhibited[name] == exp:
            if norm is not None and norm != exp:
                tally["known-divergence"] += 1
                lines.append(f"  KNOWN-DIVERGENCE {name}: {exhibited[name]} (normative {norm})")
            else:
                tally["conforms"] += 1
                lines.append(f"  CONFORMS         {name}: {exhibited[name]}")
        else:
            tally["unexpected"] += 1
            failures.append(f"UNEXPECTED {name}: {exhibited[name]} != {exp}")
            lines.append(f"  UNEXPECTED       {name}: {exhibited[name]}, expected {exp}")
    if default is not None:
        for name, tok in sorted(exhibited.items()):
            if name in named:
                continue
            if tok == default:
                tally["conforms"] += 1
            else:
                tally["unexpected"] += 1
                failures.append(f"UNEXPECTED {name}: {tok} != default {default}")
                lines.append(f"  UNEXPECTED       {name}: {tok}, expected default {default}")

    for l in lines:
        if l.strip().startswith(("UNEXPECTED", "MISSING", "KNOWN-DIVERGENCE")):
            print(l)
    print("observations: %(conforms)d conforms, %(known-divergence)d known-divergence, "
          "%(unexpected)d unexpected, %(missing)d missing" % tally)
    if not exhibited:
        # Say what was actually observed about the LOG before blaming the
        # backend. The first time this fired on real CAD it accused an
        # engine that had emitted 101 perfectly good OBSERVE lines: the log
        # was UTF-16 and this script was reading it as UTF-8. A diagnostic
        # that names only the least likely cause sends the reader to the
        # wrong end of the pipeline.
        total = len(read_lines(sys.argv[2]))
        print("  (no OBSERVE lines parsed from a %d-line log — the probe may "
              "have crashed or the backend been unreachable, but check the log "
              "itself first: if it holds OBSERVE lines, they were not decoded)"
              % total)
        sys.exit(1)
    sys.exit(1 if (tally["unexpected"] or tally["missing"]) else 0)


if __name__ == "__main__":
    main()
