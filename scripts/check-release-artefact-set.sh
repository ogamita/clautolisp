#!/bin/sh
# Fail unless `make collect-artefacts' produces the release artefact set
# pjb specified on 2026-08-16 (release-artefact-set-incomplete.issue).
#
# It fabricates a complete set of per-target inputs, runs the REAL collect
# recipe over them, and diffs the produced file list against the expected
# one. Reading the recipe is not enough: the gaps this exists to prevent
# were all invisible until the recipe was actually run.
#
# The expected set is derived from the fabricated targets, not hard-coded
# per platform, so adding a runner means adding it to TARGETS here and
# nowhere else -- the check then demands its artefacts like any other.
#
#   sh scripts/check-release-artefact-set.sh
#   make check-release-artefact-set
set -e

ver=0.0.0-check
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT INT TERM
in="$work/in"
out="$work/out"
mkdir -p "$in"

# One entry per release target the pipeline builds. Keep in step with the
# release:* jobs in .gitlab-ci.yml -- check-release-collect-needs.sh is
# what makes forgetting that a failure rather than a silence.
TARGETS="linux-x86-64 linux-arm64 linux-arm32 darwin-arm64 windows-x86-64"

expected="$work/expected"
: > "$expected"

for t in $TARGETS; do
    for kind in binaries libraries; do
        d="$in/stage"
        mkdir -p "$d/marker"
        # A payload unique per (kind,target): the union must keep them all,
        # so an overwrite instead of a union shows up as a missing marker.
        echo "$kind-$t" > "$d/marker/$kind-$t"
        tar -C "$d" -cjf "$in/clautolisp-$ver-$kind-$t.tar.bz2" .
        rm -rf "$d"
        echo "clautolisp-$ver-$kind-$t.tar.bz2" >> "$expected"
    done
done

d="$in/stage"; mkdir -p "$d/share/doc"
echo doc > "$d/share/doc/manual"
tar -C "$d" -cjf "$in/clautolisp-$ver-documentation.tar.bz2" .
rm -rf "$d"

d="$in/stage"; mkdir -p "$d/clautolisp-$ver"
echo src > "$d/clautolisp-$ver/Makefile"
tar -C "$d" -cjf "$in/clautolisp-$ver-sources.tar.bz2" .
rm -rf "$d"
echo zip > "$in/clautolisp-$ver-sources.zip"

{
    echo "clautolisp-$ver-all.tar.bz2"
    echo "clautolisp-$ver-binaries.tar.bz2"
    echo "clautolisp-$ver-documentation.tar.bz2"
    echo "clautolisp-$ver-libraries.tar.bz2"
    echo "clautolisp-$ver-sources.tar.bz2"
    echo "clautolisp-$ver-sources.zip"
} >> "$expected"

make collect-artefacts VERSION="$ver" COLLECT_IN="$in" COLLECT_OUT="$out" \
    > "$work/collect.log" 2>&1 || {
        echo "FAIL: collect-artefacts errored:"; cat "$work/collect.log"; exit 1; }

ls -1 "$out" | sort > "$work/got"
sort "$expected" > "$work/want"

status=0
if ! diff -u "$work/want" "$work/got" > "$work/diff"; then
    echo "FAIL: the collected release set is not the specified one"
    echo "      (-- expected, ++ produced)"
    sed -n '3,$p' "$work/diff"
    status=1
else
    echo "ok  release set: $(wc -l < "$work/want" | tr -d ' ') artefacts, exactly as specified"
fi

# The -all artefact is an UNPACKED UNION, so every target's marker must be
# present in it. A merge that overwrote instead of unioning would still
# produce a file of the right NAME, and the name check above would pass.
if [ -f "$out/clautolisp-$ver-all.tar.bz2" ]; then
    tar -tjf "$out/clautolisp-$ver-all.tar.bz2" > "$work/all-list"
    missing=""
    for t in $TARGETS; do
        for kind in binaries libraries; do
            grep -q "marker/$kind-$t\$" "$work/all-list" || missing="$missing $kind-$t"
        done
    done
    grep -q "share/doc/manual\$" "$work/all-list" || missing="$missing documentation"
    grep -q "clautolisp-$ver/Makefile\$" "$work/all-list" || missing="$missing sources"
    if [ -n "$missing" ]; then
        echo "FAIL: -all is not a complete union; missing:$missing"
        status=1
    else
        echo "ok  -all is the unpacked union of every artefact"
    fi
fi

exit $status
