#!/usr/bin/env python3
"""classify-sysvar-diff.py -- triage a clautolisp-vs-BricsCAD sysvar dump diff.

Companion tool for Phase 2 of
issues/open/bricscad-dialect-sysvar-parity.issue. After the clean-profile
harvest job (harvest:sysvars:bricscad:* in .gitlab/native.yml) produces a
pristine BricsCAD reference dump, run this against the clautolisp dump to
sort the differing system variables into the issue's taxonomy buckets and,
crucially, to emit a ready-to-paste Lisp skeleton for bucket (b) -- the
"genuine value disagreements" that populate *BRICSCAD-FACTORY-DEFAULTS* in
clautolisp/cador/source/bricscad-sysvar-overrides.lisp.

Usage:

    scripts/classify-sysvar-diff.py CLAUTOLISP_DUMP ALFE_REFERENCE_DUMP

      CLAUTOLISP_DUMP     sysvars-clautolisp-<uname>-bricscad.txt
      ALFE_REFERENCE_DUMP sysvars-alfe-<uname>-bricscad.txt  (real BricsCAD)

stdlib only; no third-party deps. This is a HUMAN-IN-THE-LOOP triage aid:
the bucket-(b) skeleton it prints still has to be vetted for locale /
template / profile rows before anything is adopted (see the issue caveat).

Dump format (see autolisp-spec/autolisp/dump-sysvars.lsp): one line per
variable, NAME and VALUE both emitted with PRIN1:

    "NAME" VALUE

so NAME is a double-quoted string and VALUE is a re-readable Lisp datum
(nil, an integer, a float, a "string", or a (list ...)). We also parse the
defensive fallbacks `NAME value` and `NAME = value` in case a dump was
produced by a differently-shaped writer.
"""

import math
import re
import sys

# --- taxonomy: bucket (c) session/drawing/clock STATE ----------------------
# Names whose value is inherently dynamic (session, open drawing, wall
# clock). These must never be hardcoded as a factory default; they are a
# *good* difference. Exact names plus the TD* timer prefix.
STATE_NAMES = {
    "DWGNAME", "DWGPREFIX", "DWGTITLED", "SAVENAME", "SAVEFILE",
    "VIEWCTR", "VIEWSIZE", "VIEWDIR", "VIEWTWIST", "VIEWMODE",
    "EXTMIN", "EXTMAX", "VSMIN", "VSMAX", "LIMMIN", "LIMMAX",
    "CDATE", "DATE", "MILLISECS", "ERRNO",
    "LASTPROMPT", "LASTPOINT", "LASTANGLE",
    "CMDACTIVE", "CMDNAMES", "CMDDIA",
    "DBMOD", "HANDSEED", "HANDLES", "DIASTAT",
    "AREA", "PERIMETER", "DISTANCE", "TARGET",
    "SCREENSIZE", "SCREENBOXES", "SCREENMODE",
    "CLAYER", "CTAB", "CVPORT", "CLAYOUT", "CPROFILE", "CPLOTSTYLE",
    "LOGINNAME", "LOCALROOTPREFIX", "ROAMABLEROOTPREFIX",
    "PROGBAR", "OPENDWGCOUNT",
}
STATE_PREFIXES = ("TD",)  # TDCREATE TDUPDATE TDINDWG TDUSRTIMER TDU*...

# --- taxonomy: bucket (e) colour-format representation ---------------------
COLOUR_NAMES = {
    "white", "black", "red", "yellow", "green", "cyan", "blue",
    "magenta", "bylayer", "byblock", "byentity",
}
_HEX_COLOUR = re.compile(r"^#[0-9a-fA-F]{6}$")
_RGB_COLOUR = re.compile(r"^RGB[:\s]", re.IGNORECASE)

# Path-name suffixes for bucket (d).
PATH_SUFFIXES = ("PATH", "PREFIX", "FOLDER", "FILE", "LOCATION", "DIR")
PATH_SEPARATORS = ("/", "\\")

RAD_PER_DEG = math.pi / 180.0  # 0.017453292519943295


# --- dump parsing ----------------------------------------------------------

def parse_dump(path):
    """Return {NAME: raw_value_string} from a dump file.

    NAME is upper-cased and unquoted. raw_value_string is the verbatim
    Lisp datum text (e.g. 'nil', '4133', '"ISO-25"', '(0.0 0.0 0.0)').
    """
    out = {}
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        for line in fh:
            line = line.rstrip("\n").rstrip("\r").strip()
            if not line:
                continue
            name, raw = _split_name_value(line)
            if name is None:
                continue
            out[name.upper()] = raw.strip()
    return out


def _split_name_value(line):
    """Split one dump line into (NAME, RAW-VALUE-STRING).

    Primary shape: `"NAME" VALUE`. Defensive fallbacks: `NAME = value`
    and `NAME value` (whitespace-separated, unquoted name).
    """
    if line.startswith('"'):
        # Find the closing quote of the NAME token (no escapes expected in
        # a sysvar name, but tolerate \" just in case).
        i = 1
        while i < len(line):
            if line[i] == "\\":
                i += 2
                continue
            if line[i] == '"':
                break
            i += 1
        else:
            return None, None
        name = line[1:i]
        rest = line[i + 1:].strip()
        return name, rest
    # Fallback: NAME [=] value
    m = re.match(r"^([A-Za-z0-9_]+)\s*=\s*(.*)$", line)
    if m:
        return m.group(1), m.group(2)
    parts = line.split(None, 1)
    if len(parts) == 2:
        return parts[0], parts[1]
    if len(parts) == 1:
        return parts[0], "nil"
    return None, None


# --- value interpretation --------------------------------------------------

def is_nil(raw):
    return raw is None or raw.strip().lower() in ("", "nil")


def as_float(raw):
    """Return raw as a float if it looks purely numeric, else None."""
    if raw is None:
        return None
    s = raw.strip()
    if not re.match(r"^[+-]?(\d+\.?\d*|\.\d+)([eEdD][+-]?\d+)?$", s):
        return None
    s = s.replace("d", "e").replace("D", "e")
    try:
        return float(s)
    except ValueError:
        return None


def unquote(raw):
    """If raw is a "quoted string", return its contents, else None."""
    if raw and len(raw) >= 2 and raw[0] == '"' and raw[-1] == '"':
        return raw[1:-1]
    return None


def looks_colour(raw):
    s = unquote(raw)
    if s is None:
        # A bare token like White / #ffffff (defensive).
        s = raw.strip() if raw else ""
    if s is None:
        return False
    if _HEX_COLOUR.match(s) or _RGB_COLOUR.match(s):
        return True
    return s.strip().lower() in COLOUR_NAMES


def has_path_sep(raw):
    s = unquote(raw)
    if s is None:
        return False
    return any(sep in s for sep in PATH_SEPARATORS)


def normalized_equal(a, b):
    """True when the two raw values are the same value (not a real diff)."""
    if is_nil(a) and is_nil(b):
        return True
    fa, fb = as_float(a), as_float(b)
    if fa is not None and fb is not None:
        return fa == fb
    return a.strip() == b.strip()


# --- classification --------------------------------------------------------

def classify(name, cval, aval):
    """Return the bucket key for a DIFFERING (name, clautolisp, alfe) row.

    Precedence matters: state/paths/representation are peeled off before a
    residual is called a 'genuine value disagreement' (bucket b)."""
    # (a) existence: BricsCAD (alfe) has no such variable.
    if is_nil(aval) and not is_nil(cval):
        return "a_existence"
    # reverse existence is not one of the issue's named buckets; park it.
    if is_nil(cval) and not is_nil(aval):
        return "z_clautolisp_nil"

    # (c) session / drawing / clock state.
    if name in STATE_NAMES or name.startswith(STATE_PREFIXES):
        return "c_state"

    # (d) machine paths (name suffix or a path separator in either value).
    if name.endswith(PATH_SUFFIXES) or has_path_sep(cval) or has_path_sep(aval):
        return "d_paths"

    # (e) colour-format representation.
    if looks_colour(cval) or looks_colour(aval):
        return "e_colour"

    fa, fc = as_float(aval), as_float(cval)
    if fa is not None and fc is not None:
        # (g) radian-vs-degree: ratio ~ pi/180 (or its inverse).
        if fa != 0.0 and fc != 0.0:
            for hi, lo in ((fc, fa), (fa, fc)):
                if lo != 0.0 and abs((hi / lo) - RAD_PER_DEG) < 1e-4:
                    return "g_radian_degree"
        # (f) single-float print noise: numerically ~equal within 1e-4.
        if abs(fa - fc) <= 1e-4:
            return "f_float_noise"

    # (b) the Phase-2 target: a genuine value disagreement.
    return "b_genuine"


BUCKET_TITLES = [
    ("a_existence",      "(a) existence  [alfe=nil, clautolisp non-nil]  -> Phase 1"),
    ("b_genuine",        "(b) GENUINE value disagreements  -> Phase 2 target"),
    ("c_state",          "(c) session / drawing / clock state  -> keep dynamic"),
    ("d_paths",          "(d) machine paths  -> keep-as-difference / Phase 3"),
    ("e_colour",         "(e) colour-format representation"),
    ("f_float_noise",    "(f) single-float print noise (~equal within 1e-4)"),
    ("g_radian_degree",  "(g) radian-vs-degree representation"),
    ("z_clautolisp_nil", "(z) clautolisp=nil, alfe non-nil  [residual, not a named bucket]"),
]


def main(argv):
    if len(argv) != 3:
        sys.stderr.write(
            "usage: classify-sysvar-diff.py "
            "CLAUTOLISP_DUMP ALFE_REFERENCE_DUMP\n")
        return 2
    clautolisp = parse_dump(argv[1])
    alfe = parse_dump(argv[2])

    names = sorted(set(clautolisp) | set(alfe))
    buckets = {key: [] for key, _ in BUCKET_TITLES}
    same = 0
    for name in names:
        cval = clautolisp.get(name)
        aval = alfe.get(name)
        # A name missing from one side reads as nil (the host has no such
        # variable), matching dump-sysvars.lsp's own nil-for-absent rule.
        if cval is None:
            cval = "nil"
        if aval is None:
            aval = "nil"
        if normalized_equal(cval, aval):
            same += 1
            continue
        buckets[classify(name, cval, aval)].append((name, cval, aval))

    total_diff = sum(len(v) for v in buckets.values())
    print("# sysvar diff classification")
    print("#   clautolisp dump : %s (%d vars)" % (argv[1], len(clautolisp)))
    print("#   alfe reference  : %s (%d vars)" % (argv[2], len(alfe)))
    print("#   identical       : %d" % same)
    print("#   differing       : %d" % total_diff)
    print("#")
    for key, title in BUCKET_TITLES:
        rows = buckets[key]
        print("#   %5d  %s" % (len(rows), title))
    print()

    # Per-bucket listing (names only) for the non-target buckets.
    for key, title in BUCKET_TITLES:
        if key == "b_genuine":
            continue
        rows = buckets[key]
        if not rows:
            continue
        print("## %s" % title)
        for name, cval, aval in rows:
            print("#   %-28s clautolisp=%-20s alfe=%s" % (name, cval, aval))
        print()

    # Bucket (b): ready-to-paste skeleton for *BRICSCAD-FACTORY-DEFAULTS*.
    genuine = buckets["b_genuine"]
    print("## (b) GENUINE value disagreements -- paste into "
          "*BRICSCAD-FACTORY-DEFAULTS*")
    print("## after human-vetting each row for locale / template / profile "
          "contamination")
    print("## (the reference session's LOCALE, DIMSTYLE, INTERFERELAYER, "
          "search paths, etc.).")
    print("## Values shown are the alfe (real BricsCAD) side.")
    if not genuine:
        print(";; (none)")
    else:
        for name, cval, aval in genuine:
            print('    ("%s" . %s)   ; was (autocad) %s' % (name, aval, cval))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
