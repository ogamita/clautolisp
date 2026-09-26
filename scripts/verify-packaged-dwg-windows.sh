#!/bin/sh
# The Windows side of the packaged-release DWG check, from an MSYS2 bash.
#
# clautolisp-distributed-native-libraries-not-loaded asked for the check on
# MS-Windows too, and that is not a formality: the Windows layout carries the
# extra rule. clal_dwg.dll IMPORTS libredwg.dll, a DLL has no rpath, and the
# loader does not resolve an import from "the directory next door" -- so the
# two files are not interchangeable halves and shipping one without the other
# cannot work. scripts/verify-packaged-dwg.sh exercises that case when it runs
# on Windows (it removes libredwg.dll and insists the program names it).
#
# WHY A SCRIPT AND NOT INLINE YAML: the runner's shell is PowerShell, and a
# PowerShell double-quoted string expands $(...) itself -- an inline
# `"$(cygpath -u ...)"' would be evaluated by PowerShell, which has no
# cygpath. scripts/release-windows.sh carries the same note and the same
# shape; this is that pattern, not a new one.
#
# Run by hand on the box with:
#   C:\msys64\usr\bin\bash.exe -lc "sh scripts/verify-packaged-dwg-windows.sh"
# or from PowerShell:
#   & scripts/avec-bash.ps1 scripts/verify-packaged-dwg-windows.sh
set -e

# A login shell (-l) sources profiles that may cd elsewhere, so be explicit.
cd "$(dirname "$0")/.."

# The machine's PATH and the C compiler, in POSIX form, MINGW64 first. Must be
# sourced on the bash side: a CC crossing the PowerShell boundary arrives as
# "C:/msys64/..." and CMake truncates it at the colon.
. "$(dirname "$0")/environnement-windows.sh"

echo "packaged-dwg-windows: building the native libraries (vendored libredwg + shim)"
make build-libraries

echo "packaged-dwg-windows: building the program images"
make build-programs

# The check itself is platform-neutral and detects Windows on its own.
echo "packaged-dwg-windows: running the packaged-release check"
sh scripts/verify-packaged-dwg.sh
