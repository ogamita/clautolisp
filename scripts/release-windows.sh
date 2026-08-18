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

# The machine's PATH and the C compiler, in POSIX form. This must be SOURCED
# on the bash side: CC set from PowerShell comes through converted to
# "C:/msys64/..." and CMake truncates it at the colon (see the file).
. "$(dirname "$0")/environnement-windows.sh"

# dist/ is OURS to clear, because the runner no longer does it: on Windows
# `git clean -ffdx' fails outright when any file under dist/ is held open by
# a process, and takes the whole job down in get_sources (GIT_CLEAN_FLAGS in
# .gitlab-ci.yml). Publishing on top of a previous run's leftovers would be
# worse than failing, so this is an error, not a warning -- and it names the
# real cause, which the runner's own message never does.
if [ -e dist ] && ! rm -rf dist; then
    echo "ERROR: cannot clear dist/ -- a process is holding a file open."
    echo "       On this runner that is almost always a CAD engine that"
    echo "       outlived its job (accoreconsole/acad/bricscad). Check with:"
    echo "         Get-Process acad,accoreconsole,bricscad -ErrorAction SilentlyContinue"
    echo "       and stop it before retrying. See"
    echo "       issues/open/cad-runner-wedged-by-modal-dialog.issue"
    exit 1
fi

echo "--- environment"
uname -a
echo "MSYSTEM=${MSYSTEM:-<unset>}  CC=${CC:-<unset>}"
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

# Fail here rather than letting the release set come up short two files
# with a green job. The rule is shared with every other release lane --
# one definition, in the Makefile -- so Windows cannot drift from the
# others, and it checks the artefacts are non-empty, not merely present.
make verify-release-artefacts
