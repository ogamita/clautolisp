#!/bin/sh
# Exercise the Makefile's pack-release-artefact BOTH ways on this host.
#
# The Windows branch (zip) would otherwise only ever run on Windows, i.e.
# it would ship having never been executed. This drives it here by forcing
# REL_OS, using a staged tree of our own, so a typo in that branch fails on
# any developer machine instead of on the release runner.
#
#   sh scripts/tests/test-pack-release-artefact.sh
set -e

root=$(cd "$(dirname "$0")/../.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT INT TERM

stage="$work/stage"
mkdir -p "$stage/bin"
echo payload > "$stage/bin/clautolisp"

status=0

# The Windows branch: a .zip whose entries are the tree's CONTENTS, with no
# wrapper directory -- the artefact must unpack straight into $PREFIX.
make -C "$root" release-libraries-pack-only \
     PACK_STAGE="$stage" PACK_KIND=libraries PACK_VER=0.0.0 \
     PACK_OS=windows PACK_ARCH=x86-64 DIST="$work/dist" > "$work/win.log" 2>&1 || {
    echo "FAIL: packing the Windows artefact errored:"; cat "$work/win.log"; exit 1; }

if [ -f "$work/dist/clautolisp-0.0.0-libraries-windows-x86-64.zip" ]; then
    if unzip -Z1 "$work/dist/clautolisp-0.0.0-libraries-windows-x86-64.zip" \
         | grep -q '^bin/clautolisp$\|^\./bin/clautolisp$'; then
        echo "ok  windows branch writes a .zip of the tree's contents"
    else
        echo "FAIL: the .zip does not contain bin/clautolisp at the root"
        unzip -Z1 "$work/dist/clautolisp-0.0.0-libraries-windows-x86-64.zip"
        status=1
    fi
else
    echo "FAIL: no .zip produced for os=windows"; status=1
fi

# Every other target: the .tar.bz2 pair, unchanged.
make -C "$root" release-libraries-pack-only \
     PACK_STAGE="$stage" PACK_KIND=binaries PACK_VER=0.0.0 \
     PACK_OS=linux PACK_ARCH=x86-64 DIST="$work/dist" > "$work/nix.log" 2>&1 || {
    echo "FAIL: packing the unix artefact errored:"; cat "$work/nix.log"; exit 1; }

if [ -f "$work/dist/clautolisp-0.0.0-binaries-linux-x86-64.tar.bz2" ]; then
    if tar -tjf "$work/dist/clautolisp-0.0.0-binaries-linux-x86-64.tar.bz2" \
         | grep -q '^\./bin/clautolisp$'; then
        echo "ok  unix branch writes a .tar.bz2 of the tree's contents"
    else
        echo "FAIL: the tarball does not contain ./bin/clautolisp"
        status=1
    fi
else
    echo "FAIL: no .tar.bz2 produced for os=linux"; status=1
fi

exit $status
