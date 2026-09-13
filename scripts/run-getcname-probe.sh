#!/usr/bin/env bash
# run-getcname-probe.sh — harvest localised CAD command names via getcname off a
# CAD engine, for cadtui's locale dictionaries (cadtui-locale-probe-getcname.issue).
# macOS/Linux twin of run-getcname-probe.ps1.
#
#   scripts/run-getcname-probe.sh --backend {clautolisp|bricscad|autocad|accoreconsole}
#
# WHY IT EXISTS. cadtui translates CAD command names international<->local
# (spec §Localisation, getcname model). The canonical English names are known;
# their localised forms must be MEASURED on a localised install. getcname is a
# nil stub in clautolisp, so --clautolisp only validates the probe is well-formed
# (all ABSENT + a DONE line); the payload comes from bricscad/autocad on a
# localised runner (the runners' BricsCAD is a French install).
#
# `autocad' (GUI) and `accoreconsole' (headless) are separate backends on
# purpose: the same product two ways, and whether they translate identically is
# itself an answer.
#
# Output: dist/getcname/<backend>-<uname>.txt — the GETCNAME lines.
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
probe="$root/autolisp-front-end/tests/scenarios/entities/getcname-probe.lsp"
export ALFE_RUNTIME_LSP="${ALFE_RUNTIME_LSP:-$root/autolisp-front-end/source/runtime/autolisp-remote-io.lsp}"
export ALFE_BOOTSTRAP_LSP="${ALFE_BOOTSTRAP_LSP:-$root/autolisp-front-end/source/runtime/autolisp-bootstrap.lsp}"

[ -x "$alfe" ] || { echo "alfe not found/executable: $alfe (build it: make -C autolisp-front-end build-alfe-sbcl)" >&2; exit 2; }
[ -f "$probe" ] || { echo "probe not found: $probe" >&2; exit 2; }

declare -a bargs=("--no-init")
case "$backend" in
  bricscad)      bargs+=("--bricscad" "--mode" "batch" "--timeout" "180") ;;
  # --mode automation is the GUI engine (acad); --mode batch selects
  # AcCoreConsole. Whether the two translate identically is being measured.
  autocad)       bargs+=("--autocad" "--mode" "automation" "--timeout" "300") ;;
  accoreconsole) bargs+=("--autocad" "--mode" "batch" "--timeout" "300") ;;
  clautolisp)    bargs+=("--clautolisp" "--host" "mock") ;;
  *) echo "unknown backend: $backend" >&2; exit 2 ;;
esac
bargs+=("-l" "$probe")

out_dir="$root/dist/getcname"; mkdir -p "$out_dir"
report="$out_dir/${backend}-$(uname).txt"
: > "$report"

echo "########## BACKEND: $backend on $(uname) ##########" | tee -a "$report"
"$alfe" "${bargs[@]}" 2>&1 \
  | grep -aE "^GETCNAME|BOOTSTRAP-FAILED|FAILED" | tee -a "$report"

# A report with no DONE line is a run that died mid-way; say so in the file
# itself, so a truncated harvest is never mistaken for an engine that
# translates nothing.
grep -q '^GETCNAME-DONE' "$report" \
  || echo "GETCNAME-INCOMPLETE  the probe did not reach its end" | tee -a "$report"

echo "getcname probe ($backend) -> $report"
