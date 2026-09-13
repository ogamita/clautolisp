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


def _decode(path):
    """Read PATH as text, sniffing the encoding. BricsCAD emits clean UTF-8;
    AutoCAD/AcCoreConsole emit UTF-16, and the PowerShell wrapper can further
    mangle it into a UTF-8 BOM prepended to a UTF-16LE body with stray one-byte
    newlines (odd length). Returns the decoded string with the GETCNAME lines
    intact whatever the shape."""
    with open(path, "rb") as fh:
        data = fh.read()
    if data[:2] in (b"\xff\xfe", b"\xfe\xff"):        # clean UTF-16 (BOM)
        return data.decode("utf-16")
    for enc in ("utf-8-sig", "utf-8", "utf-16-le", "utf-16-be"):
        try:
            text = data.decode(enc)
        except UnicodeDecodeError:
            continue
        if "GETCNAME" in text:                        # the right codec yields tags
            return text
    # Franken-encoding: drop NULs + a leading UTF-8 BOM to recover the ASCII
    # body (AutoCAD's localised command names are ASCII).
    stripped = data.replace(b"\x00", b"")
    if stripped[:3] == b"\xef\xbb\xbf":
        stripped = stripped[3:]
    return stripped.decode("utf-8", errors="replace")


def parse(path):
    engine = None
    fwd = {}   # international (with _) -> local
    rt = {}    # local -> international (with _)
    for raw in _decode(path).splitlines():
        parts = raw.rstrip("\r\n").split("\t")
        tag = parts[0] if parts else ""
        if tag == "GETCNAME-ENGINE":
            engine = parts[1:]
        elif tag == "GETCNAME" and len(parts) >= 4 and parts[2] == "VALUE":
            fwd[parts[1]] = parts[3]
        elif tag == "GETCNAME-RT" and len(parts) >= 4 and parts[2] == "VALUE":
            rt[parts[1]] = parts[3]
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


def emit(engines, pairs, dropped, sources, conflicts, lax):
    out = []
    out.append(";;;; cadtui — CAD command-name dictionary (:command category).")
    out.append(";;;; GENERATED from getcname probe artifact(s) by")
    out.append(";;;; scripts/cadtui-getcname-to-sexp.py — do not hand-edit; re-run the")
    out.append(";;;; converter on fresh artifacts instead. getcname output is generated")
    out.append(";;;; fact (spec §Localisation). Key = international name (canonical, _-")
    out.append(";;;; prefixed); value = the localised name. Missing => international fallback.")
    out.append(";;;; When several vendors are merged the FIRST artifact wins a value")
    out.append(";;;; conflict; each vendor's own extra commands are all kept (union).")
    for src, engine in zip(sources, engines):
        out.append(";;;; source: %s%s"
                   % (src, ("  [" + "  ".join(engine) + "]") if engine else ""))
    out.append(";;;; kept %d command(s) whose round trip closes%s; dropped %d."
               % (len(pairs), " (+lax one-way)" if lax else "", len(dropped)))
    if conflicts:
        out.append(";;;; value divergences across vendors (kept the first's):")
        for k, kept, other, src in conflicts:
            out.append(";;;;   %s = %s (kept) vs %s (%s)"
                       % (strip_underscore(k), kept, other, src))
    if dropped:
        out.append(";;;; dropped (round trip did not close): %s"
                   % ", ".join(strip_underscore(i) for i, _l, _b in dropped))
    out.append("(")
    for intl, local in pairs:
        out.append('  ("%s" . "%s")' % (lisp_escape(intl), lisp_escape(local)))
    out.append(")")
    return "\n".join(out) + "\n"


def main(argv):
    ap = argparse.ArgumentParser(description="getcname artifact(s) -> cadtui command.sexp")
    ap.add_argument("artifacts", nargs="+",
                    help="dist/getcname/<backend>-<os>.txt (first wins value conflicts)")
    ap.add_argument("-o", "--output", help="write here instead of stdout")
    ap.add_argument("--lax", action="store_true",
                    help="also keep VALUE lines with no round-trip line")
    args = ap.parse_args(argv)

    # Merge artifacts in order; the FIRST to define a key wins, and every
    # vendor's own commands are unioned in (a divergent value is recorded).
    merged_fwd, merged_rt, engines, conflicts = {}, {}, [], []
    for path in args.artifacts:
        engine, fwd, rt = parse(path)
        engines.append(engine)
        for k, v in fwd.items():
            if k in merged_fwd and merged_fwd[k] != v:
                conflicts.append((k, merged_fwd[k], v, path))
            merged_fwd.setdefault(k, v)
        for k, v in rt.items():
            merged_rt.setdefault(k, v)

    pairs, dropped = build_pairs(merged_fwd, merged_rt, args.lax)
    text = emit(engines, pairs, dropped, args.artifacts, conflicts, args.lax)
    if args.output:
        with open(args.output, "w", encoding="utf-8") as fh:
            fh.write(text)
        sys.stderr.write("wrote %d command(s) -> %s (dropped %d, %d divergence(s))\n"
                         % (len(pairs), args.output, len(dropped), len(conflicts)))
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
