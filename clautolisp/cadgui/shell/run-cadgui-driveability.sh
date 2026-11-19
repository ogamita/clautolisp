#!/bin/bash
# Run the cadgui driveability guard (cadgui-action-layer slice D) cold on ECL.
# Exit 0 = GREEN (every action registered + reachable only via invoke-action +
# driven headless); nonzero = violations (the guard prints each). Wire into CI
# like scripts/ci-classify-changes.py. Override the ECL with ECL=<path>.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"             # .../clautolisp (holds clautolisp.asd)
ECL="${ECL:-ecl}"
export CADGUI_CLAUTOLISP_DIR="$root"
rm -rf "$HOME/.cache/common-lisp/ecl-"* 2>/dev/null || true
{ ulimit -s 262144 2>/dev/null || ulimit -s 131072 2>/dev/null || ulimit -s 65536 2>/dev/null || true; }
cd "$root" || exit 3
exec "$ECL" --norc --load "$here/run-cadgui-driveability.lisp" </dev/null
