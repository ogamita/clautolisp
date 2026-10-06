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

# The CAD log's own header lines (probe-logfile): AutoCAD "[ AutoCAD - date ]---",
# BricsCAD "---------- [ BricsCAD - date] ----------". Not a prompt.
LOG_HEADER_RE = re.compile(r"^(?:-+ )?\[ (?:AutoCAD|BricsCAD|clautolisp) - ")

NON_ASCII_RUN_RE = re.compile(r"[^\x00-\x7f]+")


def repair_cp437_mojibake(text):
    """The Windows wrapper captures alfe's UTF-8 output through PowerShell's
    OEM code page, so an e-acute arrives as the two cp437 characters of its
    UTF-8 bytes (U+251C U+2310 for C3 A9). Undo that per run of non-ASCII
    characters; a run that does not round-trip is left as it is."""
    def fix(m):
        run = m.group(0)
        try:
            return run.encode("cp437").decode("utf-8")
        except (UnicodeEncodeError, UnicodeDecodeError):
            return run
    return NON_ASCII_RUN_RE.sub(fix, text)


def decode(path):
    with open(path, "rb") as fh:
        data = fh.read()
    if data[:2] in (b"\xff\xfe", b"\xfe\xff"):
        return data.decode("utf-16")
    # The Windows wrapper writes a UTF-8 BOM, a UTF-8 banner line, then the
    # transcript in UTF-16LE (PowerShell Tee-Object): decode each part as such.
    body = data[3:] if data[:3] == b"\xef\xbb\xbf" else data
    if body.count(b"\x00") > len(body) // 4:
        cut = body.find(b"\n") + 1   # the banner line is 8-bit
        head, tail = body[:cut], body[cut:]
        if len(tail) % 2:
            tail = tail[:-1]
        try:
            return head.decode("utf-8", errors="replace") + tail.decode("utf-16-le", errors="replace")
        except UnicodeDecodeError:
            pass
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
    """Collect the log lines of every block IN ORDER, then attribute each line
    to the command whose ECHO precedes it. Not by block: BricsCAD writes its
    log lazily, so a command's own log file starts with the previous command's
    tail (measured: job 16981155888)."""
    engine, order, lines = None, [], []
    for raw in decode(path).splitlines():
        line = raw.rstrip("\r\n").replace("\x00", "")
        if line.startswith("OPTKW-ENGINE\t"):
            engine = line.split("\t")[1:]
        elif line.startswith("OPTKW-BEGIN\t"):
            order.append(line.split("\t", 1)[1].strip())
        elif line.startswith("OPTKW-LOG\t"):
            text = line.split("\t", 1)[1]
            if not LOG_HEADER_RE.match(text):
                lines.append(repair_cp437_mojibake(text))
    echo = {name: re.compile(r"(?:^|[:>] ?)_?\.?" + re.escape(name.lstrip("_")) + r"\s*$", re.I)
            for name in order}
    commands = {name: [] for name in order}
    current = None
    for text in lines:
        for name in order:
            if echo[name].search(text):
                current = name
                break
        else:
            if current is not None:
                for m in BRACKET_RE.finditer(text):
                    for kw in m.group(1).split("/"):
                        kw = kw.strip()
                        if kw and kw not in commands[current]:
                            commands[current].append(kw)
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
