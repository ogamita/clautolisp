#!/bin/bash
# Run the cadgui shell: embedded ECL loads the real clautolisp/cadgui and (by
# default) drives the LIVE interactive path offscreen with synthetic mouse
# events (device->world->getpoint through the real handlers).
#
# The ecl-* fasl cache is cleared each run (cold load). This ECL cannot reuse a
# WARM cache: asdf:load-system against a populated cache overflows the C stack
# in the planner (ASDF/PLAN::STAMP), independent of the ASDF version -- measured
# both under Quicklisp's 3.3.7.3 and ECL's bundled 3.1.8.8. So a fresh embedded
# cl_boot + load-system pays the full ~96 s compile every run. To ITERATE
# without that cost, use the DEV IMAGE instead (build-dev-image.sh) for Lisp-
# side work; freezing the engine for the C++ shell (monolithic library + link)
# is the standing follow-up (see NOTES-ecl.md).
set -u
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"             # .../clautolisp (holds clautolisp.asd)
rm -rf "$HOME/.cache/common-lisp/ecl-"* 2>/dev/null || true
{ ulimit -s 262144 2>/dev/null || ulimit -s 131072 2>/dev/null || ulimit -s 65536 2>/dev/null || true; }
export CADGUI_CLAUTOLISP_DIR="$root"
cd "$root" || exit 3
# On a real display, run "$here/cadgui-shell" with no args for the live window.
"$here/cadgui-shell" "${1:---demo}" "${2:-$here/cadgui-scene.png}"
