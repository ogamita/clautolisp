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

ENTRY = re.compile(r'\(\s*"([^"]+)"\s+"([^"]+)"(?:\s+"([^"]+)")?\s*\)')


def parse_scenario(path):
    """Return (expected list of (name, expected, normative|None), default|None)."""
    expected, default = [], None
    collecting = False
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
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
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
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
        print("  (no OBSERVE lines — backend unreachable or probe crashed)")
        sys.exit(1)
    sys.exit(1 if (tally["unexpected"] or tally["missing"]) else 0)


if __name__ == "__main__":
    main()
