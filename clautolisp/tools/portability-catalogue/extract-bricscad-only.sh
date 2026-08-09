#!/bin/bash
# -*- mode:sh; coding:utf-8 -*-
#
# bash, not sh: the intersection below uses process substitution.
#
# Enumerate the BricsCAD-only names that clautolisp IMPLEMENTS -- the
# backlog for the dialect-portability catalogue
# (clautolisp/autolisp-runtime/source/portability.lisp).
#
# Why the intersection and not chapter 24 wholesale: a BricsCAD-only
# function clautolisp does NOT implement already fails loudly with
# :undefined-function, so it is not a silent portability hazard. The
# hazard is precisely the name that WORKS here and on BricsCAD and
# fails on AutoCAD -- code written against clautolisp picks it up
# without any signal that it has left portable AutoLISP.
#
# The catalogue is populated incrementally, as each entry's supporting
# host set is confirmed (the policy set by
# issues/.../clautolisp-dialect-portability-warnings). This script is
# how that backlog is refreshed; do not hand-transcribe the list.
#
# Usage:  bash clautolisp/tools/portability-catalogue/extract-bricscad-only.sh [--count]

set -eu

here=$(dirname "$0")
repo=$(cd "$here/../../.." && pwd)
spec="$repo/autolisp-spec/documentation/autolisp-visual-lisp-specification-draft.org"
builtins="$repo/clautolisp/autolisp-builtins-core/source/api.lisp"

for f in "$spec" "$builtins"; do
    [ -f "$f" ] || { echo "error: missing $f" >&2; exit 1; }
done

# Chapter 24 entry names. The chapter runs from its own heading to the
# next level-1 heading; entries are "** Function Entry: NAME" or
# "** Subr Entry: NAME". The file is CRLF, hence the \r strip.
chapter24=$(awk '
    /^\* 24 BricsCAD Extensions/ { inch=1; next }
    /^\* 2[5-9] / { inch=0 }
    inch && /^\*\* (Function|Subr) Entry: / {
        sub(/^\*\* (Function|Subr) Entry: /, "");
        sub(/\r$/, "");
        print
    }' "$spec" | sort -u)

# Names clautolisp actually registers as core builtins.
implemented=$(grep -o 'make-core-builtin-subr[[:space:]]*"[^"]*"' "$builtins" \
              | sed 's/.*"\(.*\)"/\1/' | sort -u)

both=$(printf '%s\n' "$chapter24" | comm -12 - <(printf '%s\n' "$implemented"))

if [ "${1:-}" = "--count" ]; then
    printf 'chapter-24-entries: %s\n' "$(printf '%s\n' "$chapter24" | grep -c .)"
    printf 'implemented-builtins: %s\n' "$(printf '%s\n' "$implemented" | grep -c .)"
    printf 'silent-hazards (intersection): %s\n' "$(printf '%s\n' "$both" | grep -c .)"
    exit 0
fi

printf '%s\n' "$both"
