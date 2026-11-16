#!/bin/bash
# Run the cadgui shell: embedded ECL loads the real clautolisp/cadgui and renders
# an engine-built scene offscreen. Clears the ecl-* asdf cache (ECL's warm-cache
# ASDF self-upgrade overflows the planner) and sets a finite large stack.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
root="/home/claude/clautolisp/.claude/worktrees/fix-windows-asdf-pathnames/clautolisp"
rm -rf "$HOME/.cache/common-lisp/ecl-"* 2>/dev/null || true
{ ulimit -s 262144 2>/dev/null || ulimit -s 131072 2>/dev/null || ulimit -s 65536 2>/dev/null || true; }
export CADGUI_CLAUTOLISP_DIR="$root"
cd "$root" || exit 3
"$here/cadgui-shell" "${1:-$here/cadgui-scene.png}"
