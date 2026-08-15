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
  - surfaces other than the three below: sysvars, AutoLISP builtins outside
    the CLAL- namespace, environment variables, settings.  Adding a surface
    here is cheap; the extractor is the only new part.

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
