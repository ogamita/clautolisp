#!/usr/bin/env python3
"""Convert an optkw probe transcript into a cadtui option-keyword.sexp (first cut).

Input is a dist/optkw/<backend>-<os>.txt from run-optkw-probe.{sh,ps1}
(cadtui-locale-option-keywords.issue). The payload is the command prompt text
BETWEEN the markers:

    OPTKW-BEGIN   _OFFSET
    Specify offset distance or [Through/Erase/Layer] <...>:   (localised on a
    OPTKW-END     _OFFSET                                      French install)

For each command we extract the "[...]" option list(s) from its prompt and split
on "/", yielding the LOCAL option keywords. Output (per-command, first cut):

    (("_OFFSET" ("Par" "Effacer" "Calque"))
     ("_TRIM"   ("couPer" "Ligne" ...))
     ...)

NOTE: this captures the LOCAL keywords only. Pairing each to its international
keyword (a second English-prompt run with PROMPTOPTIONTRANSLATEKEYWORDS off,
matched by position) and the per-locale abbreviation letter (the capitalised
letters in each keyword) is a refinement once the localised capture is confirmed.
"""
import argparse
import re
import sys

BRACKET_RE = re.compile(r"\[([^\]]+)\]")


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
        if "OPTKW" in text:
            return text
    stripped = data.replace(b"\x00", b"")
    if stripped[:3] == b"\xef\xbb\xbf":
        stripped = stripped[3:]
    return stripped.decode("utf-8", errors="replace")


def parse(path):
    engine, commands, current, buf = None, {}, None, []
    for raw in decode(path).splitlines():
        line = raw.rstrip("\r\n")
        if line.startswith("OPTKW-ENGINE\t"):
            engine = line.split("\t")[1:]
        elif line.startswith("OPTKW-BEGIN\t"):
            current, buf = line.split("\t", 1)[1].strip(), []
        elif line.startswith("OPTKW-END\t"):
            if current is not None:
                kws = []
                for m in BRACKET_RE.finditer("\n".join(buf)):
                    for kw in m.group(1).split("/"):
                        kw = kw.strip()
                        if kw and kw not in kws:
                            kws.append(kw)
                commands[current] = kws
            current, buf = None, []
        elif current is not None:
            buf.append(line)
    return engine, commands


def lisp_escape(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def emit(engine, commands, source):
    out = [";;;; cadtui — CAD command option-keyword dictionary (:option-keyword).",
           ";;;; GENERATED from an optkw probe transcript by",
           ";;;; scripts/cadtui-optkw-to-sexp.py — do not hand-edit. FIRST CUT:",
           ";;;; command -> the LOCAL option keywords read from its prompt. The",
           ";;;; international pairing + abbreviation letters are a later refinement."]
    if engine:
        out.append(";;;; source engine: %s" % "  ".join(engine))
    out.append(";;;; source artifact: %s" % source)
    kept = {c: k for c, k in commands.items() if k}
    out.append(";;;; %d command(s) with options; %d probed."
               % (len(kept), len(commands)))
    out.append("(")
    for cmd in sorted(kept):
        kws = " ".join('"%s"' % lisp_escape(k) for k in kept[cmd])
        out.append('  ("%s" (%s))' % (lisp_escape(cmd), kws))
    out.append(")")
    return "\n".join(out) + "\n"


def main(argv):
    ap = argparse.ArgumentParser(description="optkw transcript -> option-keyword.sexp")
    ap.add_argument("artifact", help="dist/optkw/<backend>-<os>.txt")
    ap.add_argument("-o", "--output", help="write here instead of stdout")
    args = ap.parse_args(argv)
    engine, commands = parse(args.artifact)
    text = emit(engine, commands, args.artifact)
    if args.output:
        with open(args.output, "w", encoding="utf-8") as fh:
            fh.write(text)
        kept = sum(1 for k in commands.values() if k)
        sys.stderr.write("wrote %d command(s) with options -> %s\n"
                         % (kept, args.output))
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
