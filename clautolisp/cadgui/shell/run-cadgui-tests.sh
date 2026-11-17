#!/bin/bash
# Run the clautolisp/cadgui fiveam suite (cold). Clears the ecl-* cache first
# (this ECL cannot reuse a warm cache; see NOTES-ecl.md). Override ECL=<path> to
# use a source-built ECL. Exit 0 = pass.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"             # .../clautolisp (holds clautolisp.asd)
ECL="${ECL:-ecl}"
export CADGUI_CLAUTOLISP_DIR="$root"
rm -rf "$HOME/.cache/common-lisp/ecl-"* 2>/dev/null || true
{ ulimit -s 262144 2>/dev/null || ulimit -s 131072 2>/dev/null || ulimit -s 65536 2>/dev/null || true; }
cd "$root" || exit 3
exec "$ECL" --norc --load "$here/run-cadgui-tests.lisp" </dev/null
