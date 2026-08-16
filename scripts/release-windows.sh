#!/bin/sh
# Build and package the Windows release artefacts, from an MSYS2 bash.
#
# pjb, 2026-08-16: "J'ai construit les zip windows avec make release sur
# windows sans probleme (a partir d'un bash msys2)". So the Windows lane
# runs the ordinary Makefile from bash instead of reimplementing packaging
# in PowerShell; the .zip container is chosen by the Makefile itself
# (pack-release-artefact branches on the target OS).
#
# This lives in a file rather than inline in .gitlab-ci.yml on purpose.
# The runner's shell is PowerShell, and a PowerShell double-quoted string
# expands $(...) ITSELF -- so an inline `cd "$(cygpath -u ...)"' would be
# evaluated by PowerShell, which has no cygpath, instead of by bash. Moving
# the shell code here removes that trap entirely, and makes it reviewable
# and runnable by hand on the box:
#
#   C:\msys64\usr\bin\bash.exe -lc "sh scripts/release-windows.sh"
set -e

# The job's working directory is already the project root, but be explicit:
# a login shell (-l) sources profiles that may cd elsewhere.
cd "$(dirname "$0")/.."

echo "--- environment"
uname -a
echo "MSYSTEM=${MSYSTEM:-<unset>}"
command -v sbcl >/dev/null 2>&1 && sbcl --version || echo "sbcl: NOT FOUND"
command -v cc   >/dev/null 2>&1 && cc --version | head -1 || echo "cc: NOT FOUND"
command -v cmake >/dev/null 2>&1 && cmake --version | head -1 || echo "cmake: NOT FOUND"
command -v zip  >/dev/null 2>&1 || {
    echo "ERROR: zip is required -- the Windows artefacts are .zip"
    echo "       pacman -S zip"
    exit 1
}

echo "--- build"
make build-libraries
make build-programs

echo "--- package"
make release-programs release-libraries

echo "--- produced"
ls -l dist

# Name the artefacts the collect phase expects, and fail here rather than
# letting the release set come up short two files with a green job.
missing=""
for kind in binaries libraries; do
    ls dist/clautolisp-*-$kind-windows-*.zip >/dev/null 2>&1 || missing="$missing $kind"
done
if [ -n "$missing" ]; then
    echo "ERROR: no Windows .zip produced for:$missing"
    echo "       collect:release expects clautolisp-<ver>-<kind>-windows-<arch>.zip"
    exit 1
fi
echo "ok: Windows binaries + libraries zips produced"
