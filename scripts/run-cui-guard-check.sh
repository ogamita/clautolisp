#!/usr/bin/env bash
# TEMPORARY verification (remove with the debug job): launch BricsCAD via alfe
# on the macOS runner and show the per-user default.cui state before/after, so
# we can see quarantine-corrupt-bricscad-cui fire on the real corrupt CUI and
# BricsCAD still reach READY.
set -u
root="${CI_PROJECT_DIR:-$(pwd)}"
alfe="$root/autolisp-front-end/tools/alfe/bin/alfe-sbcl"
export ALFE_RUNTIME_LSP="$root/autolisp-front-end/source/runtime/autolisp-remote-io.lsp"
export ALFE_BOOTSTRAP_LSP="$root/autolisp-front-end/source/runtime/autolisp-bootstrap.lsp"
supdir="$HOME/Library/Application Support/Bricsys/BricsCAD"
echo "=== default.cui* BEFORE ==="
find "$supdir" -iname 'default.cui*' 2>/dev/null -exec sh -c 'printf "%8s  %s  head=[" "$(wc -c <"$1")" "$1"; head -c 20 "$1" 2>/dev/null | tr -d "\n"; echo "]"' _ {} \; || echo "(none)"
echo "=== launch bricscad batch (quarantine fires if corrupt) ==="
"$alfe" -norc --bricscad --mode batch --verbose --timeout 120 -x '(princ "CUI-GUARD-OK")' 2>&1
echo "=== default.cui* AFTER ==="
find "$supdir" -iname 'default.cui*' 2>/dev/null -exec sh -c 'printf "%8s  %s  head=[" "$(wc -c <"$1")" "$1"; head -c 20 "$1" 2>/dev/null | tr -d "\n"; echo "]"' _ {} \; || echo "(none)"
exit 0
