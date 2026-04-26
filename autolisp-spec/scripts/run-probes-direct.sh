#!/usr/bin/env bash
# Direct BricsCAD V26 LISP runner for run-probes.sh.
#
# This is the macOS-vanilla path: launch BricsCAD via its bundled
# `Contents/MacOS/bricscad` binary with `-B run.scr`, where `run.scr`
# does `(load PROBE_FILE)` and then quits.
#
# It exists alongside the autolisp-script wrapper-based path because
# the wrapper at ~/works/sncf-reseau/src/outils-autolisp/autolisp-script/
# redefines prin1 / princ / print / prompt to single-argument helpers
# that mirror command-line output. Probes that need the 2-argument
# `(prin1 expr stream)` / `(princ expr stream)` form (such as the
# printer-surface output suite) cannot be tested through the wrapper
# and must use this direct runner.
#
# Usage from run-probes.sh:
#   RUNNER_TEMPLATE='bash autolisp-spec/scripts/run-probes-direct.sh __PROBE_FILE__ __RESULT_DIR__' \
#     bash autolisp-spec/scripts/run-probes.sh bricscad
#
# Tunables:
#   BRICSCAD_BIN     Override the BricsCAD V26 binary (default
#                    /Applications/BricsCAD V26.app/Contents/MacOS/bricscad).
#   PROBE_TIMEOUT    Maximum seconds to wait for the done marker
#                    (default 240).
#
# Strategy:
#   1. Write a SCR file that loads PROBE_FILE then explicitly quits BricsCAD.
#   2. Launch /Applications/BricsCAD V26.app/Contents/MacOS/bricscad -B SCR.
#   3. Poll RESULT_DIR/results.sexp for the "run-end" marker; or exit on timeout.
#   4. Send a graceful kill if BricsCAD is still alive after the marker.
set -euo pipefail

PROBE="${1:?probe file}"
RESULT_DIR="${2:?result dir}"
TIMEOUT="${PROBE_TIMEOUT:-240}"
BRICSCAD_BIN="${BRICSCAD_BIN:-/Applications/BricsCAD V26.app/Contents/MacOS/bricscad}"

SCR="$RESULT_DIR/run-probes.scr"
DONE_MARKER="$RESULT_DIR/done.txt"

cat >"$SCR" <<EOF
;; BricsCAD probe runner — direct invocation, no autolisp-script wrapper.
;; Uses an unmodified prin1 / open / close.
(load "$PROBE")
(setq __done (open "$DONE_MARKER" "w"))
(if __done (progn (princ "DONE\n" __done) (close __done)))
QUIT Y
EOF

# Launch BricsCAD V26 in the background.
"$BRICSCAD_BIN" -B "$SCR" >"$RESULT_DIR/bricscad.stdout" 2>"$RESULT_DIR/bricscad.stderr" &
BRICSCAD_PID=$!

trap 'kill "$BRICSCAD_PID" 2>/dev/null || true' EXIT

# Poll for the done marker.
elapsed=0
while [ ! -f "$DONE_MARKER" ] && [ "$elapsed" -lt "$TIMEOUT" ]; do
  sleep 2
  elapsed=$((elapsed + 2))
  if ! kill -0 "$BRICSCAD_PID" 2>/dev/null; then
    echo "BricsCAD exited prematurely after ${elapsed}s" >&2
    exit 2
  fi
done

if [ ! -f "$DONE_MARKER" ]; then
  echo "Probe run timed out after ${TIMEOUT}s" >&2
  kill "$BRICSCAD_PID" 2>/dev/null || true
  exit 3
fi

# Marker landed — give BricsCAD a chance to QUIT cleanly, then enforce.
for i in 1 2 3 4 5 6 7 8 9 10; do
  if ! kill -0 "$BRICSCAD_PID" 2>/dev/null; then
    break
  fi
  sleep 1
done
if kill -0 "$BRICSCAD_PID" 2>/dev/null; then
  kill "$BRICSCAD_PID" 2>/dev/null || true
fi
trap - EXIT
echo "Probe run finished after ${elapsed}s"
exit 0
