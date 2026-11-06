#!/usr/bin/env python3
"""Convert a reviewed pgp probe artifact into a cadtui alias.sexp.

Input is a dist/pgp/<backend>-<os>.txt produced by run-pgp-probe.{sh,ps1}
(cadtui-locale-probe-pgp-aliases.issue) — tab-separated:

    PGP-ENGINE  <PROGRAM>  <ACADVER>  <PLATFORM>  <LOCALE>
    PGP-FILE    <path>
    PGP-RAW     L,      *LIGNE          # a command alias: ALIAS -> *COMMAND
    PGP-RAW     DXB,DXBIN.EXE,0,...     # an EXTERNAL command (no "*") -> skipped
    PGP-RAW     ; comment               # skipped
    PGP-DONE

The keyboard aliases are the THIRD, distinct CAD dictionary (spec §Localisation):
purely LOCAL, never _-prefixed, kept apart from the getcname command names. Only
the command-alias lines (the value field starts with "*") are kept; on a French
install the command they point at is the LOCALISED name (L -> LIGNE). External
commands and comments are dropped. The result is the (alias . command) alist
cadtui loads as the :alias dictionary.

    scripts/cadtui-pgp-to-sexp.py dist/pgp/bricscad-Darwin.txt \\
        -o clautolisp/cadtui/data/locale/fr_FR/alias.sexp
"""
import argparse
import re
import sys

# ALIAS , optional-spaces * COMMAND   (command aliases carry the leading '*').
ALIAS_RE = re.compile(r"^([A-Za-z0-9_.\-]+)\s*,\s*\*([A-Za-z0-9_.\-]+)\s*$")


def decode(path):
    with open(path, "rb") as fh:
        data = fh.read()
    if data[:2] in (b"\xff\xfe", b"\xfe\xff"):
        return data.decode("utf-16")
    for enc in ("utf-8-sig", "utf-8", "utf-16-le", "utf-16-be"):
        try:
            text = data.decode(enc)
        except UnicodeDecodeError:
            continue
        if "PGP" in text:
            return text
    stripped = data.replace(b"\x00", b"")
    if stripped[:3] == b"\xef\xbb\xbf":
        stripped = stripped[3:]
    return stripped.decode("utf-8", errors="replace")


def parse(path):
    engine, aliases, dups = None, {}, []
    for raw in decode(path).splitlines():
        parts = raw.rstrip("\r\n").split("\t")
        tag = parts[0] if parts else ""
        if tag == "PGP-ENGINE":
            engine = parts[1:]
        elif tag == "PGP-RAW" and len(parts) >= 2:
            # The .pgp line itself may contain tabs (ALIAS,<tabs>*COMMAND), so
            # rejoin everything after the PGP-RAW tag rather than taking one field.
            line = "\t".join(parts[1:]).strip()
            if not line or line.startswith(";"):
                continue
            m = ALIAS_RE.match(line)
            if m:
                alias, command = m.group(1), m.group(2)
                if alias in aliases and aliases[alias] != command:
                    dups.append((alias, aliases[alias], command))
                aliases.setdefault(alias, command)
    return engine, aliases, dups


def lisp_escape(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def emit(engine, aliases, dups, source):
    out = [";;;; cadtui — CAD keyboard-alias dictionary (:alias category).",
           ";;;; GENERATED from a .pgp probe artifact by",
           ";;;; scripts/cadtui-pgp-to-sexp.py — do not hand-edit; re-run the",
           ";;;; converter on a fresh artifact instead. Aliases are purely LOCAL",
           ";;;; and NEVER _-prefixed (spec §Localisation); the command an alias",
           ";;;; points at is the localised name (e.g. L -> LIGNE on fr_FR)."]
    if engine:
        out.append(";;;; source engine: %s" % "  ".join(engine))
    out.append(";;;; source artifact: %s" % source)
    out.append(";;;; %d alias(es)." % len(aliases))
    if dups:
        out.append(";;;; first-wins on duplicate alias: %s"
                   % ", ".join("%s(%s/%s)" % d for d in dups))
    out.append("(")
    for alias in sorted(aliases):
        out.append('  ("%s" . "%s")'
                   % (lisp_escape(alias), lisp_escape(aliases[alias])))
    out.append(")")
    return "\n".join(out) + "\n"


def main(argv):
    ap = argparse.ArgumentParser(description="pgp artifact -> cadtui alias.sexp")
    ap.add_argument("artifact", help="dist/pgp/<backend>-<os>.txt")
    ap.add_argument("-o", "--output", help="write here instead of stdout")
    args = ap.parse_args(argv)

    engine, aliases, dups = parse(args.artifact)
    text = emit(engine, aliases, dups, args.artifact)
    if args.output:
        with open(args.output, "w", encoding="utf-8") as fh:
            fh.write(text)
        sys.stderr.write("wrote %d alias(es) -> %s\n" % (len(aliases), args.output))
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
