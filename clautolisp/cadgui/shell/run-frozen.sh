#!/bin/bash
# Run the FROZEN-engine cadgui shell (built with CADGUI_USE_LIB=1): the engine
# is linked in, so there is NO ASDF load and NO fasl cache -- it starts in a
# fraction of a second instead of the ~96 s cold compile of run.sh. Default
# mode is the headless --demo; pass a mode + file to override.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
{ ulimit -s 262144 2>/dev/null || ulimit -s 131072 2>/dev/null || ulimit -s 65536 2>/dev/null || true; }
t0=$(date +%s.%N)
"$here/cadgui-shell" "${1:---demo}" "${2:-$here/cadgui-frozen.png}"
rc=$?
t1=$(date +%s.%N)
echo "run-frozen: exit=$rc  wall=$(awk "BEGIN{printf \"%.2f\", $t1-$t0}")s"
exit "$rc"
