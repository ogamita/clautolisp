#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fail when a user-visible surface is missing from the user documentation.

AGENTS.md, "Documentation Synchronisation / The user-visible rule" (pjb,
2026-08-16): adding or modifying any user-visible feature requires updating
the documentation, INCLUDING the user manual of the tool concerned.  This
script is what keeps that rule honest between reviews: it reads the surface
out of the CODE and asserts that each name appears in the manual (and, for
CLI options, in the man page -- the terse cousin that reads off the same
option vocabulary).

It exists because a retrospective audit of the closed issues found gaps that
reading the issue notes did not reveal: five user-callable CLAL builtins, four
alfe options present in the man page but absent from the manual, and two
clautolisp options documented nowhere at all.  Every one of those was found by
comparing code against docs, which is exactly what this automates.

Run it:

    make check-user-visible-documentation      # from the repository root
    python3 scripts/check-user-visible-documentation.py [--verbose]

WHAT IT DOES NOT COVER, stated plainly so a green run is not read as more
than it is:

  - option names BUILT AT RUN TIME.  autolisp-cli composes the per-situation
    encoding options with (format nil "--~A-encoding" name), so they cannot be
    read out of the source text.  They are documented as a family; this script
    simply does not see them.
  - whether the prose is CORRECT, or complete, or still true.  It checks that
    the name is mentioned.  A name in a sentence that lies passes.
  - SYSTEM VARIABLES, deliberately.  pjb, 2026-08-16: sysvars are documented
    in autolisp-spec, not in a program's user manual -- they are language
    surface, not tool surface.  Demanding them here would push documentation
    into the wrong book.
  - AutoLISP builtins outside the CLAL- namespace: same reason, they are
    autolisp-spec's subject.  CLAL- is the exception because it has no vendor
    counterpart and exists only in this implementation.

An EXEMPTION is how a genuinely internal name stays out of the manual.  Each
carries a reason, and a stale exemption -- one naming something that no longer
exists -- is itself a failure, so the list cannot quietly rot.
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def read(*parts):
    """Document text, lower-cased once: every comparison here is
    case-insensitive (see Check.run)."""
    path = os.path.join(ROOT, *parts)
    with open(path, encoding="utf-8", errors="replace") as stream:
        return stream.read()


def read_document(*parts):
    return read(*parts).lower()


# --------------------------------------------------------------------------
# Extractors -- each returns a list of (label, [names...]) where the surface
# is documented if ANY of its names appears.  An option is one surface with
# several spellings: `-l' and `--load' are the same option, and a manual that
# says `-l FILE' has documented it.
# --------------------------------------------------------------------------

OPTION_SPEC_SPLIT = re.compile(r"make-option-spec")
OPTION_NAME = re.compile(r'"(--?[A-Za-z0-9][A-Za-z0-9-]*)"')


def cli_option_specs(source_text):
    """Option surfaces declared with MAKE-OPTION-SPEC.

    Splitting on the constructor groups every spelling of one option
    together, which is what makes the any-name rule correct."""
    surfaces = []
    for chunk in OPTION_SPEC_SPLIT.split(source_text)[1:]:
        # Stop at the handler: a lambda body may mention other option names
        # in its error messages, and those are not this option's spellings.
        head = chunk.split(":handler")[0]
        names = OPTION_NAME.findall(head)
        if names:
            surfaces.append((names[0], names))
    return surfaces


ENVIRONMENT_READ = re.compile(r'getenv\s+"([A-Z_][A-Z0-9_]*)"')


def environment_variables(source_paths):
    """Environment variables the program READS.

    pjb, 2026-08-16: environment variables and configuration settings are
    part of the documentation of these programs.  A variable that changes
    behaviour and is documented nowhere is a knob only its author can find."""
    names = set()
    for path in source_paths:
        names |= set(ENVIRONMENT_READ.findall(read(*path)))
    return [(name, [name]) for name in sorted(names)]


def lisp_sources(*parts):
    """Every non-test .lisp under the given directory.

    Tests are excluded on purpose: a fixture that sets an environment
    variable to exercise a branch is not a user-facing knob."""
    root = os.path.join(ROOT, *parts)
    found = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames
                       if d not in ("tests", "build", ".git", "third-party")]
        for filename in sorted(filenames):
            if filename.endswith(".lisp"):
                rel = os.path.relpath(os.path.join(dirpath, filename), ROOT)
                found.append(tuple(rel.split(os.sep)))
    return found


# Anchored at the start of a line: a spec entry opens one, while an enum's
# allowed values -- (:sexp :line) -- sit inline after :enum and would
# otherwise be collected as settings, inflating the count with names that
# are values, not knobs.
# The `'?' matters: the list opens as `'((:navigator ...', so without it the
# FIRST entry of every specs list is silently skipped -- the check would
# under-verify and still report green.
SETTING_ENTRY = re.compile(r"^\s*'?\(+\s*:([a-z][a-z0-9-]*)\s+:[a-z]", re.M)


def configuration_settings(source_text, *spec_variables):
    """Settings of lisp.conf / aldo.conf, from the *SETTING-SPECS* lists.

    The specs lists are the authority rather than the default-configuration
    alists: they enumerate exactly the settings `set' can change, which is
    what a user can act on.  :DECORATIONS is structural (edited as data, not
    through `set') and correctly absent from them."""
    surfaces = []
    for variable in spec_variables:
        start = source_text.find(variable)
        if start < 0:
            raise SystemExit("check: %s is gone from settings.lisp -- the "
                             "extractor needs updating, not deleting"
                             % variable)
        # Up to the closing docstring of that defparameter.
        chunk = source_text[start:]
        chunk = chunk[:chunk.find('"')]
        for name in SETTING_ENTRY.findall(chunk):
            surfaces.append((name, [name]))
    # sedit-on-quit is carried by BOTH interactors (aldo over lisp); it is
    # one documented setting, not two.
    seen = set()
    unique = []
    for label, names in surfaces:
        if label not in seen:
            seen.add(label)
            unique.append((label, names))
    return unique


ARGV_TOKEN = re.compile(r'"(--?[A-Za-z][A-Za-z0-9-]*)"')


def engine_argv_tokens(source_paths):
    """Option tokens alfe puts on an engine's command line.

    pjb, 2026-08-16: alfe's documentation does not repeat clautolisp's -- for
    alfe, clautolisp is a CAD like AutoCAD and BricsCAD -- but every option
    alfe takes into account and transmits, one way or another, to clautolisp
    or AutoCAD or BricsCAD must be documented FOR ALFE.

    alfe's own declared options are covered by the option-spec check; this
    catches the other half: a token alfe injects itself.  `--no-init' is the
    case that motivated it -- alfe imposes it on the spawned clautolisp, so
    the user's engine init files silently do not run.

    Only tokens longer than two characters are considered, and that is a
    correctness point rather than a shortcut: a one-letter token is matched
    as a SUBSTRING of the documentation, so `-c' is "found" inside
    `--clautolisp' and would pass no matter what.  Reporting those as
    verified would be a lie; the single-letter engine switches (-B, -c, -P)
    are the CAD's own, documented by the CAD.
    """
    names = set()
    for path in source_paths:
        names |= set(token for token in ARGV_TOKEN.findall(read(*path))
                     if len(token) > 2)
    return [(name, [name]) for name in sorted(names)]


def backend_sources():
    return [parts for parts in lisp_sources("autolisp-front-end")
            if parts[-1].startswith("backend-")]


BUILTIN_REGISTRATION = re.compile(r'make-core-builtin-subr\s+"([A-Z0-9][A-Z0-9-]*)"')


def clal_builtins(source_text):
    """User-callable builtins in the reserved CLAL- namespace.

    The registration list is the authority: a `defun builtin-clal-x' that is
    never registered is not callable, and must not be demanded of the manual."""
    names = sorted(set(name for name in BUILTIN_REGISTRATION.findall(source_text)
                       if name.startswith("CLAL-")))
    return [(name, [name]) for name in names]


# --------------------------------------------------------------------------
# Exemptions: name -> reason.  A reason is mandatory; "internal" alone is not
# one.  Keep this list short -- it is the escape hatch, not the norm.
# --------------------------------------------------------------------------

EXEMPTIONS = {
    # Not knobs of the clautolisp program: they are the calling convention
    # of autolisp-file-compat/tools/run-file-compat/launch.lisp, a test
    # launcher that ERRORS when they are unset.  Nobody running clautolisp
    # can set them to any effect, so documenting them in the user manual
    # would describe a control the reader does not have.
    "CLAUTOLISP_ROOT":
        "input of the file-compat test launcher, not a knob of the program",
    "CLAUTOLISP_FILE_COMPAT_ARGS_FILE":
        "input of the file-compat test launcher, not a knob of the program",
}


# --------------------------------------------------------------------------
# The checks
# --------------------------------------------------------------------------

class Check:
    def __init__(self, title, surfaces, targets):
        self.title = title
        self.surfaces = surfaces
        self.targets = targets          # [(label, text)]

    def run(self, verbose=False):
        failures = []
        for label, names in self.surfaces:
            if label in EXEMPTIONS:
                continue
            for target_label, text in self.targets:
                # Case-insensitively: the manual writes AutoLISP calls in
                # lower case inside examples ((clal-nav-file "x")) while the
                # code registers the name upper case.  Matching exactly would
                # report the whole CLAL- namespace as undocumented -- a check
                # that cries wolf gets switched off, so this matters.
                if not any(name.lower() in text for name in names):
                    failures.append((label, names, target_label))
        if verbose:
            print("  %d surfaces x %d document(s)"
                  % (len(self.surfaces), len(self.targets)))
        return failures


def build_checks():
    clautolisp_manual = read_document("clautolisp", "documentation",
                                      "clautolisp-user-manual.org")
    clautolisp_man = read_document("clautolisp", "documentation", "man",
                                   "clautolisp.1")
    alfe_manual = read_document("autolisp-front-end", "documentation",
                                "alfe-user-manual.org")
    alfe_man = read_document("autolisp-front-end", "documentation", "man",
                             "alfe.1")

    # The man page writes options in groff with escaped dashes (\-\-load), so
    # a literal "--load" is never found in it.  Unescaping is what makes the
    # man-page half of the check mean anything -- without it every option
    # would appear undocumented, the check would be all noise, and the honest
    # outcome would be to delete it.
    alfe_man = alfe_man.replace("\\-", "-")
    clautolisp_man = clautolisp_man.replace("\\-", "-")

    return [
        Check("clautolisp CLI options",
              cli_option_specs(read("clautolisp", "autolisp-cli", "source",
                                    "spec.lisp")),
              [("clautolisp user manual", clautolisp_manual),
               ("clautolisp man page", clautolisp_man),
               # The third track named by the rule.  Checkable here because
               # the usage text lives in main.lisp while the option specs
               # live in spec.lisp: matching one file against the other can
               # actually fail.  alfe deliberately has no equivalent check --
               # its usage text sits in the same cli.lisp as its specs, so
               # the comparison would pass by construction, and a check that
               # cannot fail is worse than no check at all.
               ("clautolisp --help", read_document("clautolisp", "tools",
                                                   "clautolisp", "source",
                                                   "main.lisp"))]),
        Check("alfe CLI options",
              cli_option_specs(read("autolisp-front-end", "source",
                                    "cli.lisp")),
              [("alfe user manual", alfe_manual),
               ("alfe man page", alfe_man)]),
        Check("CLAL- builtins",
              clal_builtins(read("clautolisp", "autolisp-builtins-core",
                                 "source", "api.lisp")),
              [("clautolisp user manual", clautolisp_manual)]),
        Check("clautolisp environment variables",
              environment_variables(lisp_sources("clautolisp")),
              [("clautolisp documentation",
                clautolisp_manual + clautolisp_man)]),
        Check("alfe environment variables",
              environment_variables(lisp_sources("autolisp-front-end")),
              [("alfe documentation", alfe_manual + alfe_man)]),
        Check("options alfe transmits to an engine",
              engine_argv_tokens(backend_sources()),
              [("alfe documentation", alfe_manual + alfe_man)]),
        Check("configuration settings (lisp.conf / aldo.conf)",
              configuration_settings(read("clautolisp", "autolisp-debug-ui",
                                          "source", "settings.lisp"),
                                     "*setting-specs*", "*lisp-setting-specs*"),
              [("clautolisp user manual", clautolisp_manual)]),
    ]


def stale_exemptions(checks):
    """Exemptions naming a surface that no longer exists.

    Without this an exemption outlives the thing it excused, and the next
    surface to reuse that name is silently waved through."""
    live = set()
    for check in checks:
        for label, _names in check.surfaces:
            live.add(label)
    return sorted(name for name in EXEMPTIONS if name not in live)


def main(argv):
    verbose = "--verbose" in argv[1:]
    checks = build_checks()

    gaps = 0
    for check in checks:
        failures = check.run(verbose=verbose)
        print("%s: %d surface(s)%s"
              % (check.title, len(check.surfaces),
                 "" if not failures else " -- %d GAP(S)" % len(failures)))
        for label, names, target in failures:
            spellings = " / ".join(names)
            print("    MISSING from %s: %s" % (target, spellings))
        gaps += len(failures)

    stale = stale_exemptions(checks)
    for name in stale:
        print("    STALE EXEMPTION: %s no longer exists; remove it" % name)

    print()
    if gaps or stale:
        if gaps:
            print("FAIL: %d undocumented user-visible surface(s)." % gaps)
            print("Document each in the user manual of the tool concerned")
            print("(AGENTS.md, Documentation Synchronisation), or add an")
            print("exemption WITH A REASON in %s."
                  % os.path.relpath(os.path.abspath(__file__), ROOT))
        if stale:
            print("FAIL: %d stale exemption(s) naming a surface that is gone."
                  % len(stale))
        return 1

    print("OK: every user-visible surface checked is documented.")
    print("Note: run-time-composed option names and prose CORRECTNESS are")
    print("out of scope -- see the module docstring.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
