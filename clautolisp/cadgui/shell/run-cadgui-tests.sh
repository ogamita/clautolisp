#!/bin/bash
# Run a clautolisp fiveam suite (cold) -- cadgui by default. Clears the ecl-*
# cache first (this ECL cannot reuse a warm cache; see NOTES-ecl.md). Overrides:
#   ECL=<path>             use a source-built ECL
#   SUITE_SYSTEM=<asd-sys> SUITE_PACKAGE=<pkg>   run another suite, e.g.
#     SUITE_SYSTEM=clautolisp/cador/tests SUITE_PACKAGE=clautolisp.cador.tests
# Exit 0 = pass.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"             # .../clautolisp (holds clautolisp.asd)
ECL="${ECL:-ecl}"
export CADGUI_CLAUTOLISP_DIR="$root"
rm -rf "$HOME/.cache/common-lisp/ecl-"* 2>/dev/null || true
{ ulimit -s 262144 2>/dev/null || ulimit -s 131072 2>/dev/null || ulimit -s 65536 2>/dev/null || true; }
cd "$root" || exit 3
exec "$ECL" --norc --load "$here/run-cadgui-tests.lisp" </dev/null
