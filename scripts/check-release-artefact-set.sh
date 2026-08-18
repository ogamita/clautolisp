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

# RELATIVE paths, deliberately, and under the repo rather than in
# /tmp. The CI invokes the recipe as
#     make collect-artefacts COLLECT_IN=dist COLLECT_OUT=dist/combined
# -- both relative -- and this check exists to run what the CI runs. When
# it used an absolute mktemp -d instead, it passed while the real release
# silently dropped clautolisp-1.8.46-all.zip: the zip branch archives from
# inside a `cd', so a relative output path resolved against the staging
# directory. An absolute path hid the one bug the check was there to
# catch. Keep these relative.
root=$(cd "$(dirname "$0")/.." && pwd)
rel="dist/.check-artefact-set"
work="$root/$rel"
trap 'rm -rf "$work"' EXIT INT TERM
rm -rf "$work"
in="$work/in"
out="$work/out"
mkdir -p "$in"

# One entry per release target the pipeline builds. Keep in step with the
# release:* jobs in .gitlab-ci.yml -- check-release-collect-needs.sh is
# what makes forgetting that a failure rather than a silence.
TARGETS="linux-x86-64 linux-arm64 linux-arm32 darwin-arm64 windows-x86-64"

# Windows ships .zip, not .tar.bz2 (pjb, 2026-08-16): its package has its
# own layout, per documentation/windows-package-spec.md. Every other
# target ships the $PREFIX-shaped tar.bz2 pair.
target_extension () {
    case "$1" in
        windows-*) echo zip ;;
        *)         echo tar.bz2 ;;
    esac
}

expected="$work/expected"
: > "$expected"

for t in $TARGETS; do
    ext=$(target_extension "$t")
    for kind in binaries libraries; do
        d="$in/stage"
        mkdir -p "$d/marker"
        # A payload unique per (kind,target): the union must keep them all,
        # so an overwrite instead of a union shows up as a missing marker.
        echo "$kind-$t" > "$d/marker/$kind-$t"
        if [ "$ext" = zip ]; then
            ( cd "$d" && zip -qr "$in/clautolisp-$ver-$kind-$t.zip" . )
        else
            tar -C "$d" -cjf "$in/clautolisp-$ver-$kind-$t.tar.bz2" .
        fi
        rm -rf "$d"
        echo "clautolisp-$ver-$kind-$t.$ext" >> "$expected"
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
    # -all in BOTH formats: the tarball, and the zip Windows users need
    # (pjb, 2026-08-16). Same union, two containers.
    echo "clautolisp-$ver-all.tar.bz2"
    echo "clautolisp-$ver-all.zip"
    echo "clautolisp-$ver-binaries.tar.bz2"
    echo "clautolisp-$ver-documentation.tar.bz2"
    echo "clautolisp-$ver-libraries.tar.bz2"
    echo "clautolisp-$ver-sources.tar.bz2"
    echo "clautolisp-$ver-sources.zip"
} >> "$expected"

make -C "$root" collect-artefacts VERSION="$ver" \
    COLLECT_IN="$rel/in" COLLECT_OUT="$rel/out" \
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
check_all_union () {   # $1 = label, $2 = listing file
    missing=""
    for t in $TARGETS; do
        for kind in binaries libraries; do
            grep -q "marker/$kind-$t\$" "$2" || missing="$missing $kind-$t"
        done
    done
    grep -q "share/doc/manual\$" "$2" || missing="$missing documentation"
    grep -q "clautolisp-$ver/Makefile\$" "$2" || missing="$missing sources"
    if [ -n "$missing" ]; then
        echo "FAIL: $1 is not a complete union; missing:$missing"
        return 1
    fi
    echo "ok  $1 is the unpacked union of every artefact"
    return 0
}

# BOTH -all containers are checked. Checking only the tarball would let a
# half-built zip ship to the very users it exists for.
if [ -f "$out/clautolisp-$ver-all.tar.bz2" ]; then
    tar -tjf "$out/clautolisp-$ver-all.tar.bz2" > "$work/all-list"
    check_all_union "-all.tar.bz2" "$work/all-list" || status=1
else
    echo "FAIL: -all.tar.bz2 was not produced"; status=1
fi

if [ -f "$out/clautolisp-$ver-all.zip" ]; then
    unzip -Z1 "$out/clautolisp-$ver-all.zip" > "$work/all-zip-list"
    check_all_union "-all.zip" "$work/all-zip-list" || status=1
else
    echo "FAIL: -all.zip was not produced"; status=1
fi

exit $status
