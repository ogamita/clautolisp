#!/bin/sh
# POSIX sh — print the provenance manifest for one install/release phase.
#
#   sh scripts/make-manifest.sh <phase> > .../manifest-<phase>.txt
#
# <phase> is programs | libraries | documentation | sources. Each staged
# tree carries its own manifest, because the phases can be built and
# installed separately (CI installs programs only; documentation may be
# rendered later on another host) — a single shared file would quietly
# describe whichever phase was installed last.
#
# The manifest answers "which commit is this tree built from", which no
# other installed file does: RELEASE_NOTES.org describes the current
# feature set, not the build. `release:' names the release tag when HEAD
# sits exactly on one; otherwise it says how far past the last release
# the build is, which is exactly the case where guessing goes wrong.
#
# Run from the top of the work tree. Outside a git checkout (a build
# from an unpacked source tarball) it falls back to the
# manifest-sources.txt that release-sources put at the tarball root, so
# provenance survives the trip through the tarball.

set -u

phase=${1:-unknown}
RULES_URL=https://gitlab.com/informatimago/rules/-/blob/master/version-rules.md

# --- program version stamps ------------------------------------------
stamp() {   # <file> <program-name>
    [ -f "$1" ] || return 0
    v=$(sed -n 's/.*\*version\* *"\([0-9.]*\)".*/\1/p' "$1" | head -1)
    [ -n "$v" ] && printf '%s %s, ' "$2" "$v"
}
programs=$(
    stamp clautolisp/tools/clautolisp/source/version.lisp clautolisp
    stamp autolisp-front-end/tools/alfe/source/version.lisp alfe
    stamp clautolisp/autolisp-reader/tools/read-autolisp/source/version.lisp read-autolisp
)
programs=$(printf '%s' "$programs" | sed 's/, $//')

# --- provenance -------------------------------------------------------
if git rev-parse --git-dir >/dev/null 2>&1; then
    commit=$(git rev-parse HEAD)
    cdate=$(git log -1 --format=%aI)
    describe=$(git describe --tags --match 'release-[0-9]*' --always 2>/dev/null)
    exact=$(git describe --tags --exact-match --match 'release-[0-9]*' 2>/dev/null)
    if [ -n "$exact" ]; then
        release="$exact"
    elif [ -n "$describe" ] && [ "$describe" != "$(git rev-parse --short HEAD)" ]; then
        # release-1.6.11-3-gdf2874c -> 3 commits past release-1.6.11
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
    commit=$(sed -n 's/^commit: *//p'      manifest-sources.txt | head -1)
    cdate=$(sed  -n 's/^commit-date: *//p' manifest-sources.txt | head -1)
    describe=$(sed -n 's/^describe: *//p'  manifest-sources.txt | head -1)
    release=$(sed -n 's/^release: *//p'    manifest-sources.txt | head -1)
    ref=$(sed   -n 's/^ref: *//p'          manifest-sources.txt | head -1)
    tree=$(sed  -n 's/^tree: *//p'         manifest-sources.txt | head -1)
    source_note="built from the source tarball, not a git checkout"
else
    commit="unknown"; cdate="unknown"; describe="unknown"
    release="unknown — no git checkout and no manifest-sources.txt"
    ref="unknown"; tree="unknown"
    source_note="no provenance available at build time"
fi

os=$(uname | tr 'A-Z' 'a-z' | sed -e 's/^mingw.*/windows/' -e 's/^msys.*/windows/' -e 's/^cygwin.*/windows/')
arch=$(uname -m | tr 'A-Z' 'a-z' | sed -e 's/^x86_64$/x86-64/' -e 's/^amd64$/x86-64/' -e 's/^aarch64$/arm64/')

cat <<EOF
# clautolisp — provenance manifest
#
# Which commit this installed tree was built from. See share/doc/clautolisp/
# RELEASE_NOTES.org for what the release contains, and $RULES_URL
# for what the version numbers and refs mean.

phase:        $phase
release:      $release
describe:     $describe
commit:       $commit
commit-date:  $cdate
ref:          $ref
tree:         $tree
programs:     ${programs:-unknown}
built:        $(date -u '+%Y-%m-%dT%H:%M:%SZ') on $os/$arch
EOF
[ -n "$source_note" ] && printf 'note:         %s\n' "$source_note"
exit 0
