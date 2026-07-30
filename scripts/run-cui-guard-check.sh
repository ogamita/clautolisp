#!/usr/bin/env bash
# TEMPORARY verification + repair (remove with the debug job). An earlier build
# of quarantine-corrupt-bricscad-cui had a BOM false positive that renamed VALID
# BOM-prefixed default.cui files aside. This (1) restores any such file, then
# (2) launches BricsCAD via alfe with the FIXED guard and shows the CUI state
# before/after, proving the valid CUI is left alone and a truly-empty one is
# still quarantined, and BricsCAD reaches READY.
set -u
root="${CI_PROJECT_DIR:-$(pwd)}"
alfe="$root/autolisp-front-end/tools/alfe/bin/alfe-sbcl"
export ALFE_RUNTIME_LSP="$root/autolisp-front-end/source/runtime/autolisp-remote-io.lsp"
export ALFE_BOOTSTRAP_LSP="$root/autolisp-front-end/source/runtime/autolisp-bootstrap.lsp"
supdir="$HOME/Library/Application Support/Bricsys/BricsCAD"

show() {
  find "$supdir" -iname 'default.cui*' 2>/dev/null -exec sh -c '
    for f; do
      printf "%9s  head=[" "$(wc -c <"$f")"
      head -c 24 "$f" 2>/dev/null | tr -d "\r\n"; printf "]  %s\n" "$f"
    done' _ {} \; 2>/dev/null || echo "(none)"
}

echo "=== default.cui* BEFORE repair ==="; show

echo "=== repair: restore VALID default.cui.corrupt-* renamed by the BOM bug ==="
# Valid = non-empty AND, after an optional UTF-8 BOM, opens with '<'. Only
# restore when there is no live default.cui to clobber.
find "$supdir" -iname 'default.cui.corrupt-*' 2>/dev/null | while IFS= read -r f; do
  [ -s "$f" ] || { echo "  keep (empty, genuinely corrupt): $f"; continue; }
  first=$(dd if="$f" bs=1 count=8 2>/dev/null | tr -d '\357\273\277' | head -c1)
  orig="$(dirname "$f")/default.cui"
  if [ "$first" = "<" ] && [ ! -e "$orig" ]; then
    mv "$f" "$orig" && echo "  RESTORED valid CUI: $f -> $orig"
  else
    echo "  keep (not a lone valid CUI): $f"
  fi
done

echo "=== launch bricscad batch (FIXED guard: valid CUIs must survive) ==="
"$alfe" -norc --bricscad --mode batch --verbose --timeout 120 -x '(princ "CUI-GUARD-OK")' 2>&1

echo "=== default.cui* AFTER ==="; show
exit 0
