#!/usr/bin/env python3
"""Convert a reviewed getcname probe artifact into a cadtui command.sexp.

Input is a dist/getcname/<backend>-<os>.txt produced by run-getcname-probe.{sh,ps1}
(cadtui-locale-probe-getcname.issue) — tab-separated lines:

    GETCNAME-ENGINE   <PROGRAM>  <ACADVER>  <PLATFORM>  <LOCALE>
    GETCNAME     _LINE   VALUE     LIGNE          # international -> local
    GETCNAME-RT  LIGNE   VALUE     _LINE          # local -> international (round trip)
    GETCNAME     _QUIT   IDENTITY  QUIT           # English install / untranslated
    GETCNAME     _FOO    ABSENT                   # engine does not know it (or the stub)

getcname output is generated fact, safe to import (spec §Localisation, ~750-756).
We keep only the VALUE lines whose ROUND TRIP CLOSES — the local name maps back to
the same international name — so a mistranslation or a one-way quirk never lands
silently. The result is the (international . local) alist cadtui loads as the
:command dictionary; a missing command simply falls back to the international form.

    scripts/cadtui-getcname-to-sexp.py dist/getcname/bricscad-Linux.txt \\
        -o clautolisp/cadtui/data/locale/fr_FR/command.sexp

With --lax, VALUE lines with no round-trip line are kept too (flagged in the
header) — use only for a reviewed artifact where the round trip was not emitted.
"""
import argparse
import sys


def parse(path):
    engine = None
    fwd = {}   # international (with _) -> local
    rt = {}    # local -> international (with _)
    with open(path, encoding="utf-8", errors="replace") as fh:
        for raw in fh:
            line = raw.rstrip("\r\n")
            parts = line.split("\t")
            tag = parts[0] if parts else ""
            if tag == "GETCNAME-ENGINE":
                engine = parts[1:]
            elif tag == "GETCNAME" and len(parts) >= 4:
                _, intl, status, result = parts[0], parts[1], parts[2], parts[3]
                if status == "VALUE":
                    fwd[intl] = result
            elif tag == "GETCNAME-RT" and len(parts) >= 4:
                _, local, status, result = parts[0], parts[1], parts[2], parts[3]
                if status == "VALUE":
                    rt[local] = result
    return engine, fwd, rt


def strip_underscore(name):
    return name[1:] if name.startswith("_") else name


def build_pairs(fwd, rt, lax):
    """(international, local) pairs whose round trip closes (or all, if lax)."""
    pairs, dropped = [], []
    for intl, local in sorted(fwd.items()):
        back = rt.get(local)
        if back is not None and strip_underscore(back) == strip_underscore(intl):
            pairs.append((intl, local))
        elif lax and back is None:
            pairs.append((intl, local))
        else:
            dropped.append((intl, local, back))
    return pairs, dropped


def lisp_escape(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def emit(engine, pairs, dropped, source, lax):
    out = []
    out.append(";;;; cadtui — CAD command-name dictionary (:command category).")
    out.append(";;;; GENERATED from a getcname probe artifact by")
    out.append(";;;; scripts/cadtui-getcname-to-sexp.py — do not hand-edit; re-run the")
    out.append(";;;; converter on a fresh artifact instead. getcname output is generated")
    out.append(";;;; fact (spec §Localisation). Key = international name (canonical, _-")
    out.append(";;;; prefixed); value = the localised name. Missing => international fallback.")
    if engine:
        out.append(";;;; source engine: %s" % "  ".join(engine))
    out.append(";;;; source artifact: %s" % source)
    out.append(";;;; kept %d command(s) whose round trip closes%s; dropped %d."
               % (len(pairs), " (+lax one-way)" if lax else "", len(dropped)))
    if dropped:
        out.append(";;;; dropped (round trip did not close): %s"
                   % ", ".join(strip_underscore(i) for i, _l, _b in dropped))
    out.append("(")
    for intl, local in pairs:
        out.append('  ("%s" . "%s")' % (lisp_escape(intl), lisp_escape(local)))
    out.append(")")
    return "\n".join(out) + "\n"


def main(argv):
    ap = argparse.ArgumentParser(description="getcname artifact -> cadtui command.sexp")
    ap.add_argument("artifact", help="dist/getcname/<backend>-<os>.txt")
    ap.add_argument("-o", "--output", help="write here instead of stdout")
    ap.add_argument("--lax", action="store_true",
                    help="also keep VALUE lines with no round-trip line")
    args = ap.parse_args(argv)

    engine, fwd, rt = parse(args.artifact)
    pairs, dropped = build_pairs(fwd, rt, args.lax)
    text = emit(engine, pairs, dropped, args.artifact, args.lax)
    if args.output:
        with open(args.output, "w", encoding="utf-8") as fh:
            fh.write(text)
        sys.stderr.write("wrote %d command(s) -> %s (dropped %d)\n"
                         % (len(pairs), args.output, len(dropped)))
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
