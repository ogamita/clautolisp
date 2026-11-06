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

Several transcripts may be given (the runs of one product): their harvests are
MERGED -- a command takes the keywords of the first run that offered any, and
a later run that offers a DIFFERENT list for it is reported (stderr and a
header comment), never silently preferred. Needed because one run seldom
covers every command: AutoCAD's accoreconsole hangs part-way (2026-10-08), and
BricsCAD's lazily written log loses the LAST command's prompt.

That first cut holds the LOCAL keywords only. The SECOND mode pairs them with
their international keywords, per product, into the shipped dictionary:

    cadtui-optkw-to-sexp.py --pair probe-results/optkw/fr_FR/international-en.json \
        -o clautolisp/cadtui/data/locale/fr_FR/option-keyword.sexp

The pairing table (JSON) names, per product, the first-cut harvest it pairs and,
per command, the English reference page (url), the harvested local list (which
must still equal the harvest -- a moved harvest is refused, not re-paired
silently) and the aligned international list, where null = not settled by the
English documentation, left to measure on an English install. Output:

    ((:AUTOCAD ("_OFFSET" ("Through" . "Par") ("Erase" . "Effacer") ...) ...)
     (:BRICSCAD ...))

The local abbreviation is NOT stored: it is the local keyword's capitals
("aNnuler" -> N), or its parenthesised capitals ("etendu (ET)" -> ET), computed
by cadtui's OPTION-KEYWORD-ABBREVIATION.
"""
import argparse
import json
import os
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
                    for kw in split_options(m.group(1)):
                        kw = kw.strip()
                        if kw and kw not in commands[current]:
                            commands[current].append(kw)
    return engine, commands


def split_options(bracket):
    """Split a prompt's [a/b/c] option list on the slashes OUTSIDE
    parentheses: BricsCAD's ZOOM offers "Echelle (nx/nxp)" as ONE keyword
    (job 16981155888), which a plain split cut in two."""
    out, depth, cur = [], 0, []
    for ch in bracket:
        if ch == "(":
            depth += 1
        elif ch == ")" and depth:
            depth -= 1
        if ch == "/" and depth == 0:
            out.append("".join(cur))
            cur = []
        else:
            cur.append(ch)
    out.append("".join(cur))
    return out


def lisp_escape(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def source_label(path):
    """'job N dist/optkw/FILE' for a downloaded job artifact (.../a-N/dist/...),
    else the path as given."""
    m = re.search(r"a-(\d+)/(dist/.*)$", path.replace(os.sep, "/"))
    return "job %s %s" % m.groups() if m else path


def merge(runs):
    """RUNS = [(path, engine, commands)...] -> (engines, commands, conflicts).
    First run with keywords for a command wins; a differing later list is a
    conflict (command, kept-path, kept, other-path, other)."""
    engines, merged, owner, conflicts = [], {}, {}, []
    for path, engine, commands in runs:
        if engine and engine not in engines:
            engines.append(engine)
        for name, kws in commands.items():
            merged.setdefault(name, [])
            if not kws:
                continue
            if not merged[name]:
                merged[name], owner[name] = kws, path
            elif merged[name] != kws:
                conflicts.append((name, owner[name], merged[name], path, kws))
    return engines, merged, conflicts


def emit(engine, commands, source, conflicts=()):
    out = [";;;; cadtui — CAD command option-keyword dictionary (:option-keyword).",
           ";;;; GENERATED from an optkw probe transcript by",
           ";;;; scripts/cadtui-optkw-to-sexp.py — do not hand-edit. FIRST CUT:",
           ";;;; command -> the LOCAL option keywords read from its prompt. The",
           ";;;; international pairing + abbreviation letters are a later refinement."]
    for e in engine or []:
        out.append(";;;; source engine: %s" % "  ".join(e))
    for src in source:
        out.append(";;;; source artifact: %s" % src)
    for name, p1, k1, p2, k2 in conflicts:
        out.append(";;;; CONFLICT %s: kept %s from %s; %s offered %s"
                   % (name, k1, source_label(p1), source_label(p2), k2))
    kept = {c: k for c, k in commands.items() if k}
    out.append(";;;; %d command(s) with options; %d probed."
               % (len(kept), len(commands)))
    out.append("(")
    for cmd in sorted(kept):
        kws = " ".join('"%s"' % lisp_escape(k) for k in kept[cmd])
        out.append('  ("%s" (%s))' % (lisp_escape(cmd), kws))
    out.append(")")
    return "\n".join(out) + "\n"


STRING_RE = re.compile(r'"((?:[^"\\]|\\.)*)"')


def read_first_cut(path):
    """The {command: [local keyword ...]} of a first-cut .sexp written by EMIT
    (one command per line: ("_CMD" ("kw" ...)))."""
    commands = {}
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            if line.lstrip().startswith(";") or '("' not in line:
                continue
            strings = [re.sub(r"\\(.)", r"\1", m) for m in STRING_RE.findall(line)]
            if strings:
                commands[strings[0]] = strings[1:]
    return commands


def pair(table_path, root):
    """Return (pairs, unpaired, problems): pairs = {product: {command:
    [(international, local)...]}}; unpaired = [(product, command, local)]."""
    with open(table_path, encoding="utf-8") as fh:
        table = json.load(fh)
    pairs, unpaired, problems = {}, [], []
    for product in sorted(k for k in table if not k.startswith("_")):
        entry = table[product]
        harvest = read_first_cut(os.path.join(root, entry["harvest"]))
        out = pairs.setdefault(product, {})
        for command in sorted(entry["commands"]):
            spec = entry["commands"][command]
            local, intl = spec["local"], spec["international"]
            if harvest.get(command) != local:
                problems.append("%s %s: table local %r != harvest %r"
                                % (product, command, local, harvest.get(command)))
                continue
            if len(intl) != len(local):
                problems.append("%s %s: %d local vs %d international"
                                % (product, command, len(local), len(intl)))
                continue
            kept = []
            for i, l in zip(intl, local):
                if i is None:
                    unpaired.append((product, command, l))
                else:
                    kept.append((i, l))
            if kept:
                out[command] = (kept, spec["url"])
        for command in sorted(set(harvest) - set(entry["commands"])):
            for l in harvest[command]:
                unpaired.append((product, command, l))
    return pairs, unpaired, problems


def emit_pairs(pairs, unpaired, table_path):
    out = [";;;; cadtui -- CAD command option-keyword dictionary (:option-keyword).",
           ";;;; GENERATED by scripts/cadtui-optkw-to-sexp.py --pair %s" % table_path,
           ";;;; -- do not hand-edit; fix the pairing table or the harvest and re-run.",
           ";;;; Per PRODUCT (the two vendors' keyword sets differ), per international",
           ";;;; command: (international-keyword . local-keyword). The local keyword is",
           ";;;; as the French prompt shows it; its capitals are its abbreviation.",
           ";;;; International side: the vendor's English command reference (url per",
           ";;;; command below), paired by position and meaning -- not a measured",
           ";;;; English prompt. Missing => the international keyword (fallback)."]
    if unpaired:
        out.append(";;;; Left to measure on an English install (not settled by the docs):")
        for product, command, local in unpaired:
            out.append(";;;;   %s %s %s" % (product, command, local))
    out.append("(")
    for product in sorted(pairs):
        out.append(" (:%s" % product.upper())
        for command in sorted(pairs[product]):
            kept, url = pairs[product][command]
            out.append("  ;; %s" % url)
            body = " ".join('("%s" . "%s")' % (lisp_escape(i), lisp_escape(l))
                            for i, l in kept)
            out.append('  ("%s" %s)' % (lisp_escape(command), body))
        out[-1] += ")"
    out.append(")")
    return "\n".join(out) + "\n"


def main(argv):
    ap = argparse.ArgumentParser(description="optkw transcript -> option-keyword.sexp")
    ap.add_argument("artifact", nargs="*",
                    help="dist/optkw/<backend>-<os>.txt (several: merged, first wins)")
    ap.add_argument("--pair", metavar="TABLE.json",
                    help="pair the first-cut harvests named in TABLE.json with their"
                         " international keywords (the shipped option-keyword.sexp)")
    ap.add_argument("-o", "--output", help="write here instead of stdout")
    args = ap.parse_args(argv)
    if args.pair:
        root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        pairs, unpaired, problems = pair(args.pair, root)
        for p in problems:
            sys.stderr.write("cadtui-optkw-to-sexp: REFUSED %s\n" % p)
        if problems:
            return 1
        text = emit_pairs(pairs, unpaired, args.pair)
        count = sum(len(k) for c in pairs.values() for k, _ in c.values())
        summary = "paired %d keyword(s); %d left to measure" % (count, len(unpaired))
    else:
        if not args.artifact:
            ap.error("an artifact (or --pair TABLE.json) is required")
        runs = [(a,) + parse(a) for a in args.artifact]
        engines, commands, conflicts = merge(runs)
        for name, p1, k1, p2, k2 in conflicts:
            sys.stderr.write("cadtui-optkw-to-sexp: CONFLICT %s: kept %r (%s), %s offered %r\n"
                             % (name, k1, source_label(p1), source_label(p2), k2))
        text = emit(engines, commands, [source_label(a) for a in args.artifact],
                    conflicts)
        summary = "wrote %d command(s) with options" % sum(1 for k in commands.values() if k)
    if args.output:
        with open(args.output, "w", encoding="utf-8") as fh:
            fh.write(text)
        sys.stderr.write("%s -> %s\n" % (summary, args.output))
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
