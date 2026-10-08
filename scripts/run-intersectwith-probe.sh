#!/usr/bin/env bash
# run-intersectwith-probe.sh -- measure the ActiveX entity method IntersectWith
# on a CAD engine (cador-intersectwith-missing.issue): the result's type, its
# safearray bounds, the points and their ORDER, for LINE / CIRCLE / ARC /
# ELLIPSE / LWPOLYLINE / POLYLINE pairs under the four acExtend options, by
# vla-IntersectWith and by vlax-invoke. macOS/Linux twin of
# run-intersectwith-probe.ps1.
#
#   scripts/run-intersectwith-probe.sh --backend {clautolisp|bricscad|autocad|accoreconsole}
#
# `autocad' (GUI, COM automation) and `accoreconsole' (headless) are separate
# backends on purpose: AcCoreConsole has no application object, and whether
# its vla- surface answers IntersectWith at all is itself an answer.
#
# Output: dist/intersectwith/<backend>-<uname>.txt -- the IWPROBE lines.
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
probe="$root/autolisp-front-end/tests/scenarios/entities/intersectwith-probe.lsp"
export ALFE_RUNTIME_LSP="${ALFE_RUNTIME_LSP:-$root/autolisp-front-end/source/runtime/autolisp-remote-io.lsp}"
export ALFE_BOOTSTRAP_LSP="${ALFE_BOOTSTRAP_LSP:-$root/autolisp-front-end/source/runtime/autolisp-bootstrap.lsp}"

[ -x "$alfe" ] || { echo "alfe not found/executable: $alfe (build it: make -C autolisp-front-end build-alfe-sbcl)" >&2; exit 2; }
[ -f "$probe" ] || { echo "probe not found: $probe" >&2; exit 2; }

declare -a bargs=("--no-init")
case "$backend" in
  bricscad)      bargs+=("--bricscad" "--mode" "batch" "--timeout" "180") ;;
  # --mode automation is the GUI engine (acad, full COM); --mode batch
  # selects AcCoreConsole.
  autocad)       bargs+=("--autocad" "--mode" "automation" "--timeout" "300") ;;
  accoreconsole) bargs+=("--autocad" "--mode" "batch" "--timeout" "300") ;;
  clautolisp)    bargs+=("--clautolisp" "--host" "mock") ;;
  *) echo "unknown backend: $backend" >&2; exit 2 ;;
esac
bargs+=("-l" "$probe")

out_dir="$root/dist/intersectwith"; mkdir -p "$out_dir"
report="$out_dir/${backend}-$(uname).txt"
: > "$report"

echo "########## BACKEND: $backend on $(uname) ##########" | tee -a "$report"
"$alfe" "${bargs[@]}" 2>&1 \
  | grep -aE "^IWPROBE|BOOTSTRAP-FAILED|FAILED" | tee -a "$report"

# A report with no DONE line is a run that died mid-way; say so in the file
# itself, so a truncated run is never mistaken for an engine that finds no
# intersections.
grep -q '^IWPROBE-DONE' "$report" \
  || echo "IWPROBE-INCOMPLETE  the probe did not reach its end" | tee -a "$report"

echo "intersectwith probe ($backend) -> $report"
