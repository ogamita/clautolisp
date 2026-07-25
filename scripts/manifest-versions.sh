#!/bin/sh
# POSIX sh — print "name version, name version, …" for the programs this
# repository ships. Read by scripts/make-manifest.sh (via
# MANIFEST_VERSIONS_CMD, whose default is this path) to fill the
# manifest's `programs:' line.
#
# The extraction lives here, not in make-manifest.sh: that script is a
# vendored copy of the one in the rules repository and must stay
# project-independent.

set -u

v() {   # <program-name> <version.lisp>
    [ -f "$2" ] || return 0
    n=$(sed -n 's/.*\*version\* *"\([0-9.]*\)".*/\1/p' "$2" | head -1)
    [ -n "$n" ] && printf '%s %s, ' "$1" "$n"
}

{
    v clautolisp    clautolisp/tools/clautolisp/source/version.lisp
    v alfe          autolisp-front-end/tools/alfe/source/version.lisp
    v read-autolisp clautolisp/autolisp-reader/tools/read-autolisp/source/version.lisp
} | sed 's/, $//'
