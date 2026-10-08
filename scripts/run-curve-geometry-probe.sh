#!/usr/bin/env bash
# run-curve-geometry-probe.sh -- MEASURE the curve-geometry surface (vlax-curve-*
# on ARC / CIRCLE / LINE / LWPOLYLINE with bulges / 2D POLYLINE, boundary params
# and dists, the ArcLength / TotalAngle / Length / Area ActiveX properties, how
# entmake / command ARC / vla-AddArc store an ARC's angles) off a CAD engine
# (issues/open/cador-curve-length-and-sampling.issue). macOS/Linux twin of
# run-curve-geometry-probe.ps1.
#
#   scripts/run-curve-geometry-probe.sh --backend {clautolisp|bricscad|autocad|accoreconsole}
#
# --clautolisp gives the baseline column the vendor columns are compared with.
# `autocad' (GUI) and `accoreconsole' (headless, no COM: the vla-* cases are
# expected to ERROR there) are separate backends on purpose.
#
# Output: dist/curve-geometry/<backend>-<uname>.txt -- the CURVE lines.
set -u

backend="clautolisp"
while [ $# -gt 0 ]; do
  case "$1" in
    --backend) backend="$2"; shift 2 ;;
    *) echo "usage: $0 --backend {clautolisp|bricscad|autocad|accoreconsole}" >&2
       exit 2 ;;
  esac
done

root="${CI_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
alfe="${ALFE_BIN:-$root/autolisp-front-end/tools/alfe/bin/alfe-sbcl}"
probe="$root/autolisp-front-end/tests/scenarios/entities/curve-geometry-probe.lsp"
export ALFE_RUNTIME_LSP="${ALFE_RUNTIME_LSP:-$root/autolisp-front-end/source/runtime/autolisp-remote-io.lsp}"
export ALFE_BOOTSTRAP_LSP="${ALFE_BOOTSTRAP_LSP:-$root/autolisp-front-end/source/runtime/autolisp-bootstrap.lsp}"

[ -x "$alfe" ] || { echo "alfe not found/executable: $alfe (build it: make -C autolisp-front-end build-alfe-sbcl)" >&2; exit 2; }
[ -f "$probe" ] || { echo "probe not found: $probe" >&2; exit 2; }

declare -a bargs=("--no-init")
case "$backend" in
  bricscad)      bargs+=("--bricscad" "--mode" "batch" "--timeout" "180") ;;
  # --mode automation is the GUI engine (acad); --mode batch selects
  # AcCoreConsole.
  autocad)       bargs+=("--autocad" "--mode" "automation" "--timeout" "300") ;;
  accoreconsole) bargs+=("--autocad" "--mode" "batch" "--timeout" "300") ;;
  clautolisp)    bargs+=("--clautolisp" "--host" "mock") ;;
  *) echo "unknown backend: $backend" >&2; exit 2 ;;
esac
bargs+=("-l" "$probe")

out_dir="$root/dist/curve-geometry"; mkdir -p "$out_dir"
report="$out_dir/${backend}-$(uname).txt"
: > "$report"

echo "########## BACKEND: $backend on $(uname) ##########" | tee -a "$report"
"$alfe" "${bargs[@]}" 2>&1 \
  | grep -aE "^CURVE|BOOTSTRAP-FAILED|FAILED" | tee -a "$report"

# A report with no DONE line is a run that died mid-way; say so in the file
# itself, so a truncated run is never mistaken for a complete one.
grep -q '^CURVE-DONE' "$report" \
  || echo "CURVE-INCOMPLETE  the probe did not reach its end" | tee -a "$report"

echo "curve-geometry probe ($backend) -> $report"
