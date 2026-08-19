#!/usr/bin/env python3
"""Fail when a documentation source uses a glyph the PDF build would drop.

tex-pdf-characters.issue. XeLaTeX has NO automatic font fallback: a
codepoint the main font lacks is dropped, xelatex says "Missing
character(s)" among hundreds of other lines, and the PDF is produced
successfully and is simply wrong. That is the failure this exists to
turn into a build error.

documentation/clautolisp-doc-preamble.sty already maps the exotic
glyphs to fallback families -- but only the ones somebody noticed. The
gap this check closes is the NEXT glyph: someone writes a "≠" in a
manual, no one runs the PDF build on a machine that lacks it, and the
character disappears from the published document without a word.

Rather than compiling every PDF (slow, and it only proves anything about
the fonts installed on the machine that ran it), this reads the sources
and the preamble and asks fontconfig which families actually have each
codepoint. Three outcomes:

  covered by the main font      -- nothing to do
  mapped in the preamble        -- fine, that is what the map is for
  neither                       -- reported: either add a \\newunicodechar
                                   line, or install a font that has it

    python3 scripts/check-doc-glyph-coverage.py
    make check-doc-glyph-coverage
"""

import os
import re
import subprocess
import sys
import unicodedata

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PREAMBLE = os.path.join(
    ROOT, "autolisp-front-end", "documentation", "clautolisp-doc-preamble.sty")

# The faces the preamble selects. BOTH matter: org renders =code= and
# verbatim through the MONO font, and a glyph the serif face has can be
# absent from the mono one. U+27FA is exactly that -- present in DejaVu
# Serif, missing from DejaVu Sans Mono, and silently dropped from the sedit
# spec for that reason. A codepoint is safe only when every face that might
# render it has it; otherwise it needs a map, which applies in both.
MAIN_FONTS = ["DejaVu Serif", "Noto Serif", "Latin Modern Roman"]
MONO_FONTS = ["DejaVu Sans Mono", "Noto Sans Mono", "Latin Modern Mono"]

# Codepoints every TeX engine handles: ASCII, plus the Latin-1 range the
# default font covers, plus the typographic punctuation org emits itself
# (smart quotes and dashes) which the LaTeX writer turns into commands.
ALWAYS_FINE = set(range(0x20, 0x7F)) | set(range(0xA0, 0x100)) | {
    0x2018, 0x2019, 0x201C, 0x201D,   # curly quotes
    0x2013, 0x2014,                   # en/em dash
    0x2026,                           # ellipsis
    0x00A0,                           # nbsp
}


def documentation_sources():
    """Every .org under a documentation/ directory — the PDF sources."""
    found = []
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames
                       if d not in (".git", "build", "third-party", "dist",
                                    ".cache", "node_modules")]
        if os.path.basename(dirpath) != "documentation":
            continue
        for name in sorted(filenames):
            if name.endswith(".org"):
                found.append(os.path.join(dirpath, name))
    return found


def mapped_codepoints():
    """The codepoints the preamble maps with \\newunicodechar."""
    try:
        with open(PREAMBLE, encoding="utf-8") as stream:
            text = stream.read()
    except OSError:
        return set()
    return {ord(m) for m in re.findall(r"\\newunicodechar\{(.)\}", text)}


def families_with(codepoint):
    """The installed font families fontconfig says have CODEPOINT."""
    proc = subprocess.run(["fc-list", ":charset=%04X" % codepoint, "family"],
                          capture_output=True, text=True)
    if proc.returncode != 0:
        return []
    families = set()
    for line in proc.stdout.splitlines():
        for name in line.split(","):
            name = name.strip()
            if name:
                families.add(name)
    return sorted(families)


def preamble_copies():
    """Every clautolisp-doc-preamble.sty in the tree (one per subproject)."""
    found = []
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames
                       if d not in (".git", "build", "third-party", "dist",
                                    ".cache", "node_modules")]
        if "clautolisp-doc-preamble.sty" in filenames:
            found.append(os.path.join(dirpath, "clautolisp-doc-preamble.sty"))
    return sorted(found)


def check_preamble_copies():
    """The per-subproject copies must be identical.

    Each subproject's documentation build loads the copy beside its own
    sources, so a fix applied to one copy fixes ONE subproject's PDFs and
    leaves the others dropping the glyph — which is what happened while
    fixing this issue: the mapping was added to the alfe copy and the
    clautolisp document went on losing the character, with the build still
    green. Nothing enforced the sameness, so nothing noticed.
    """
    copies = preamble_copies()
    if len(copies) < 2:
        return 0, copies
    digests = {}
    for path in copies:
        with open(path, "rb") as stream:
            digests.setdefault(stream.read(), []).append(
                os.path.relpath(path, ROOT))
    if len(digests) == 1:
        return 0, copies
    print("FAIL: the %d copies of clautolisp-doc-preamble.sty have drifted "
          "apart:" % len(copies))
    for index, paths in enumerate(digests.values(), 1):
        print("        version %d: %s" % (index, ", ".join(paths)))
    print("      Each subproject loads the copy beside its own sources, so a")
    print("      glyph mapped in one and not the others is dropped from the")
    print("      others' PDFs, silently. Make them identical.")
    return 1, copies


def main():
    sources = documentation_sources()
    if not sources:
        print("FAIL: no documentation sources found -- fix the walk, do not "
              "delete the check")
        return 1

    status, copies = check_preamble_copies()

    mapped = mapped_codepoints()
    if not mapped:
        print("FAIL: no \\newunicodechar mappings read from %s" % PREAMBLE)
        return 1

    # codepoint -> the files that use it
    used = {}
    for path in sources:
        with open(path, encoding="utf-8", errors="replace") as stream:
            for character in stream.read():
                point = ord(character)
                if point in ALWAYS_FINE or character in "\n\t\r":
                    continue
                used.setdefault(point, set()).add(os.path.relpath(path, ROOT))

    unmapped, unavailable = [], []
    for point in sorted(used):
        if point in mapped:
            continue
        families = families_with(point)
        if not families:
            unavailable.append((point, families))
        elif not (any(font in families for font in MAIN_FONTS)
                  and any(font in families for font in MONO_FONTS)):
            unmapped.append((point, families))

    if unavailable:
        status = 1
        print("FAIL: %d codepoint(s) NO installed font provides -- the PDF "
              "drops them silently:" % len(unavailable))
        for point, _ in unavailable:
            report(point, used, [])
        print("      Install a font that has them, then map them in")
        print("      clautolisp-doc-preamble.sty.")

    if unmapped:
        status = 1
        print("FAIL: %d codepoint(s) the main font lacks and the preamble does "
              "not map:" % len(unmapped))
        for point, families in unmapped:
            report(point, used, families)
        print("      A font HAS each of these, so xelatex would still drop")
        print("      them: it does not fall back on its own. Add a")
        print("      \\newunicodechar line to clautolisp-doc-preamble.sty.")

    if status == 0:
        print("doc glyphs: %d distinct non-ASCII codepoint(s) across %d "
              "source(s); every one is in a body face or mapped, and the %d "
              "preamble copies agree"
              % (len(used), len(sources), len(copies)))
    return status


def report(point, used, families):
    try:
        name = unicodedata.name(chr(point))
    except ValueError:
        name = "?"
    where = sorted(used[point])
    print("        U+%04X %s  (%s)" % (point, chr(point), name))
    print("            used in: %s%s"
          % (", ".join(where[:3]), " …" if len(where) > 3 else ""))
    if families:
        print("            available in: %s%s"
              % (", ".join(families[:4]), " …" if len(families) > 4 else ""))


if __name__ == "__main__":
    sys.exit(main())
