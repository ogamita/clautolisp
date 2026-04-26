#!/usr/bin/env bash
# Direct AutoCAD 2026 LISP runner for run-probes.sh (macOS).
#
# This is the macOS counterpart of run-probes-direct.sh: launches the
# AutoCAD 2026 GUI binary with `/b run.scr` so that AutoCAD reads
# our SCR after start-up. Like its BricsCAD sibling, it bypasses any
# wrapper that might redefine prin1 / princ / print / prompt.
#
# Usage from run-probes.sh:
#   RUNNER_TEMPLATE='bash autolisp-spec/scripts/run-probes-direct-autocad.sh __PROBE_FILE__ __RESULT_DIR__' \
#     bash autolisp-spec/scripts/run-probes.sh autocad
#
# Tunables:
#   AUTOCAD_BIN      Override the AutoCAD 2026 binary path
#                    (default /Applications/Autodesk/AutoCAD 2026/AutoCAD 2026.app/Contents/MacOS/AutoCAD).
#   PROBE_TIMEOUT    Maximum seconds to wait for the done marker (default 360).
set -euo pipefail

PROBE="${1:?probe file}"
RESULT_DIR="${2:?result dir}"
TIMEOUT="${PROBE_TIMEOUT:-360}"
AUTOCAD_BIN="${AUTOCAD_BIN:-/Applications/Autodesk/AutoCAD 2026/AutoCAD 2026.app/Contents/MacOS/AutoCAD}"

SCR="$RESULT_DIR/run-probes.scr"
DONE_MARKER="$RESULT_DIR/done.txt"

cat >"$SCR" <<EOF
;; AutoCAD 2026 probe runner — direct invocation, no autolisp-script wrapper.
(load "$PROBE")
(setq __done (open "$DONE_MARKER" "w"))
(if __done (progn (princ "DONE\n" __done) (close __done)))
QUIT Y
EOF

"$AUTOCAD_BIN" /b "$SCR" >"$RESULT_DIR/autocad.stdout" 2>"$RESULT_DIR/autocad.stderr" &
AUTOCAD_PID=$!

trap 'kill "$AUTOCAD_PID" 2>/dev/null || true' EXIT

elapsed=0
while [ ! -f "$DONE_MARKER" ] && [ "$elapsed" -lt "$TIMEOUT" ]; do
  sleep 2
  elapsed=$((elapsed + 2))
  if ! kill -0 "$AUTOCAD_PID" 2>/dev/null; then
    echo "AutoCAD exited prematurely after ${elapsed}s" >&2
    exit 2
  fi
done

if [ ! -f "$DONE_MARKER" ]; then
  echo "Probe run timed out after ${TIMEOUT}s" >&2
  kill "$AUTOCAD_PID" 2>/dev/null || true
  exit 3
fi

# Marker landed; give AutoCAD a chance to QUIT cleanly.
for i in 1 2 3 4 5 6 7 8 9 10; do
  if ! kill -0 "$AUTOCAD_PID" 2>/dev/null; then
    break
  fi
  sleep 1
done
if kill -0 "$AUTOCAD_PID" 2>/dev/null; then
  kill "$AUTOCAD_PID" 2>/dev/null || true
fi
trap - EXIT
echo "Probe run finished after ${elapsed}s"
exit 0
