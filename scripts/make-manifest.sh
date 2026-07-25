#!/bin/sh
# POSIX sh — print the provenance manifest for one install/release phase.
#
#   sh scripts/make-manifest.sh <phase> > <staged-tree>/share/doc/<project>/manifest-<phase>.txt
#
# Canonical copy:
#   https://gitlab.com/informatimago/rules/-/blob/master/scripts/make-manifest.sh
# Rules it implements: build-rules.md § 7, version-rules.md (tag names).
# Fix it there, then re-vendor; do not diverge the copies.
#
# <phase> is a build phase name — programs | libraries | documentation |
# sources, or whatever a project's phases are called. Each staged tree
# gets its OWN manifest, because phases are staged and installed
# separately (CI often installs programs only; documentation may be
# rendered later on another host). One shared file would quietly
# describe whichever phase was installed last.
#
# The manifest answers "which commit is this tree built from", which no
# other installed file does: release notes describe a feature set, and a
# version stamp is shared by every commit between two releases.
# `release:' names the release tag when HEAD sits exactly on one;
# otherwise it says how far past the last release the build is — exactly
# the case where reading a version number misleads.
#
# Project-specific bits, both optional:
#
#   MANIFEST_PROJECT      project name (default: the work tree's basename)
#   MANIFEST_VERSIONS_CMD command printing "name version, name version"
#                         for the shipped programs
#                         (default: scripts/manifest-versions.sh if executable)
#
# Run from the top of the work tree. Outside a git checkout — a build
# from an unpacked source tarball — it falls back to the
# manifest-sources.txt that the source-packaging target put at the
# tarball root, so provenance survives the trip through the tarball.

set -u

phase=${1:-unknown}
RULES_URL=https://gitlab.com/informatimago/rules/-/blob/master/version-rules.md

project=${MANIFEST_PROJECT:-}
if [ -z "$project" ]; then
    root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    project=$(basename "$root")
fi

# --- shipped program versions (project hook) --------------------------
versions_cmd=${MANIFEST_VERSIONS_CMD:-scripts/manifest-versions.sh}
programs=
if [ -x "$versions_cmd" ]; then
    programs=$("$versions_cmd" 2>/dev/null)
elif [ -f "$versions_cmd" ]; then
    programs=$(sh "$versions_cmd" 2>/dev/null)
fi

# --- provenance -------------------------------------------------------
if git rev-parse --git-dir >/dev/null 2>&1; then
    origin=$(git remote get-url origin 2>/dev/null || echo "no origin remote")
    commit=$(git rev-parse HEAD)
    cdate=$(git log -1 --format=%aI)
    describe=$(git describe --tags --match 'release-[0-9]*' --always 2>/dev/null)
    exact=$(git describe --tags --exact-match --match 'release-[0-9]*' 2>/dev/null)
    if [ -n "$exact" ]; then
        release="$exact"
    elif [ -n "$describe" ] && [ "$describe" != "$(git rev-parse --short HEAD)" ]; then
        # release-1.6.11-3-gdf2874c -> 3 commits after release-1.6.11
        base=${describe%-*}; n=${base##*-}; base=${base%-*}
        release="none — $n commit(s) after $base"
    else
        release="none — no release tag in this history"
    fi
    ref=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached HEAD")
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        tree="dirty (uncommitted changes in the build tree)"
    else
        tree=clean
    fi
    source_note=
elif [ -f manifest-sources.txt ]; then
    origin=$(sed   -n 's/^origin: *//p'      manifest-sources.txt | head -1)
    commit=$(sed   -n 's/^commit: *//p'      manifest-sources.txt | head -1)
    cdate=$(sed    -n 's/^commit-date: *//p' manifest-sources.txt | head -1)
    describe=$(sed -n 's/^describe: *//p'    manifest-sources.txt | head -1)
    release=$(sed  -n 's/^release: *//p'     manifest-sources.txt | head -1)
    ref=$(sed      -n 's/^ref: *//p'         manifest-sources.txt | head -1)
    tree=$(sed     -n 's/^tree: *//p'        manifest-sources.txt | head -1)
    source_note="built from the source tarball, not a git checkout"
else
    origin="unknown"; commit="unknown"; cdate="unknown"; describe="unknown"
    release="unknown — no git checkout and no manifest-sources.txt"
    ref="unknown"; tree="unknown"
    source_note="no provenance available at build time"
fi

os=$(uname | tr 'A-Z' 'a-z' | sed -e 's/^mingw.*/windows/' -e 's/^msys.*/windows/' -e 's/^cygwin.*/windows/')
arch=$(uname -m | tr 'A-Z' 'a-z' | sed -e 's/^x86_64$/x86-64/' -e 's/^amd64$/x86-64/' -e 's/^aarch64$/arm64/')

cat <<EOF
# $project — provenance manifest
#
# Which commit this installed tree was built from. The release notes say
# what a release contains; this says which build you have. See
# $RULES_URL
# for what the version numbers and refs mean.

phase:        $phase
origin:       $origin
release:      $release
describe:     $describe
commit:       $commit
commit-date:  $cdate
ref:          $ref
tree:         $tree
EOF
[ -n "$programs" ]    && printf 'programs:     %s\n' "$programs"
printf 'built:        %s on %s/%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$os" "$arch"
[ -n "$source_note" ] && printf 'note:         %s\n' "$source_note"
exit 0
