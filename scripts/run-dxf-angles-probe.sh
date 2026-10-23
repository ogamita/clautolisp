#!/usr/bin/env bash
# run-dxf-angles-probe.sh -- MEASURE the unit of the angle groups of a DXF
# file the CAD writes, against entget of the same entities
# (issues/open/dxf-file-angle-units.issue,
# issues/open/dxf-angle-units-hatch-viewport-tables.issue). macOS/Linux twin
# of run-dxf-angles-probe.ps1.
#
#   scripts/run-dxf-angles-probe.sh --backend {clautolisp|bricscad|autocad|accoreconsole}
#
# --clautolisp gives the baseline column the vendor columns are compared with.
# `autocad' (GUI) and `accoreconsole' (headless) are separate backends on
# purpose: the same product two ways.
#
# Output: dist/dxf-angles/<backend>-<uname>.txt -- the DXFANG lines -- and
# dist/dxf-angles/<backend>-<uname>.dxf -- the DXF the CAD wrote. Copy both
# to clautolisp/drawing/tests/fixtures/vendor-dxf/ to make them a fixture of
# the drawing tests (see the README.org there).
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
probe="$root/autolisp-front-end/tests/scenarios/entities/dxf-angles-probe.lsp"
export ALFE_RUNTIME_LSP="${ALFE_RUNTIME_LSP:-$root/autolisp-front-end/source/runtime/autolisp-remote-io.lsp}"
export ALFE_BOOTSTRAP_LSP="${ALFE_BOOTSTRAP_LSP:-$root/autolisp-front-end/source/runtime/autolisp-bootstrap.lsp}"

[ -x "$alfe" ] || { echo "alfe not found/executable: $alfe (build it: make -C autolisp-front-end build-alfe-sbcl)" >&2; exit 2; }
[ -f "$probe" ] || { echo "probe not found: $probe" >&2; exit 2; }

declare -a bargs=("--no-init")
case "$backend" in
  bricscad)      bargs+=("--bricscad" "--mode" "batch" "--timeout" "300") ;;
  # --mode automation is the GUI engine (acad); --mode batch selects
  # AcCoreConsole.
  autocad)       bargs+=("--autocad" "--mode" "automation" "--timeout" "300") ;;
  accoreconsole) bargs+=("--autocad" "--mode" "batch" "--timeout" "300") ;;
  clautolisp)    bargs+=("--clautolisp") ;;
  *) echo "unknown backend: $backend" >&2; exit 2 ;;
esac
bargs+=("-l" "$probe")

out_dir="$root/dist/dxf-angles"; rm -rf "$out_dir"; mkdir -p "$out_dir"   # start empty: a reused build dir keeps other runs files
report="$out_dir/${backend}-$(uname).txt"
dxf_copy="$out_dir/${backend}-$(uname).dxf"
: > "$report"
rm -f "$dxf_copy"

# Where the CAD should write its DXF -- a WORK file, never the artefact: the
# exported file BECOMES the CAD's document, which the probe saves again at
# the end (so no quit finds it modified). The probe reports a copy of the
# export as it was measured on its DXFANG EXPORT-PATH line, and that copy is
# what goes into the artefact. A CAD started through COM may not inherit the
# environment; the probe then falls back on TEMPPREFIX.
export DXFANG_DXF="${TMPDIR:-/tmp}/dxfang-${backend}-export.dxf"
export DXFANG_BACKEND="$backend"

echo "########## BACKEND: $backend on $(uname) ##########" | tee -a "$report"
"$alfe" "${bargs[@]}" 2>&1 \
  | grep -aE "^DXFANG|BOOTSTRAP-FAILED|FAILED" | tee -a "$report"

# A report with no DONE line is a run that died mid-way; say so in the file
# itself, so a truncated run is never mistaken for a complete one.
grep -q '^DXFANG-DONE' "$report" \
  || echo "DXFANG-INCOMPLETE  the probe did not reach its end" | tee -a "$report"

# The DXF itself goes into the artefact, wherever the CAD wrote it.
written="$(grep -a '^DXFANG EXPORT-PATH ' "$report" | tail -n 1 \
             | sed -e 's/^DXFANG EXPORT-PATH //' -e 's/\r$//')"
if [ -n "$written" ] && [ -f "$written" ]; then
  [ "$written" = "$dxf_copy" ] || cp "$written" "$dxf_copy"
  echo "DXFANG-COPIED $dxf_copy" | tee -a "$report"
else
  echo "DXFANG-NO-DXF  no file at '${written}'" | tee -a "$report"
fi

echo "dxf-angles probe ($backend) -> $report"
