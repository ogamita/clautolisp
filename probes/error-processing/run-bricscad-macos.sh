#!/bin/bash
# usage: mac-bricscad.sh OUTDIR START CMD...   (lance BricsCAD V26 macOS sur un script genere)
out=$1; start=$2; shift 2
rm -rf "$out"; mkdir -p "$out"; D=$(cd "$(dirname "$0")" && pwd); O=$(cd "$out" && pwd)
{
  echo "(setq m (open \"$O/scr-started.txt\" \"w\"))"
  echo "(close m)"
  echo "(if (getvar \"SECURELOAD\") (vl-catch-all-apply 'setvar '(\"SECURELOAD\" 0)))"
  echo "(setq *probe-dir* \"$O\" *probe-start* $start)"
  echo "(load \"$D/probe-error-handler.lsp\")"
  echo "(load \"$D/probe-error-catalogue.lsp\")"
  for c in "$@"; do echo "$c"; done
  echo "(progn (setq m (open \"$O/scr-done.txt\" \"w\")) (close m))"
  echo "._QUIT _N"
} > "$O/run.scr"
"${BRICSCAD_EXE:-/Applications/BricsCAD V26.app/Contents/MacOS/bricscad}" -B "$O/run.scr" > "$O/bc-stdout.txt" 2>&1 &
pid=$!
for i in $(seq 1 ${PROBE_TIMEOUT:-120}); do sleep 1; kill -0 $pid 2>/dev/null || break; [ -f "$O/scr-done.txt" ] && { sleep 2; break; }; done
kill -0 $pid 2>/dev/null && { kill $pid; while kill -0 $pid 2>/dev/null; do sleep 1; done; }
exit 0
