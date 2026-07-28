#!/usr/bin/env bash
# run-encoding-experiment.sh — drive encoding-probe.lsp under a MATRIX of
# encoding knobs (Unix LANG / LC_* here; see the .ps1 twin for Windows
# chcp/codepage) against a CAD backend, to DISCOVER which knob actually
# changes the encoding a target exhibits. Feeds the encoding-situations §7
# defaults table (issues/open/encoding-{situations-cli-options,consolidation}).
#
#   scripts/run-encoding-experiment.sh --backend {clautolisp|bricscad|autocad} [--dwg FILE]
#
# Output: dist/encoding/<backend>-<uname>.txt — every probe line prefixed
# with its knob label, so a diff across knobs shows the effect (or lack of).
# The probe reports the target identity (PRODUCT/SYSCODEPAGE/LISPSYS/...),
# the env it sees (LANG/LC_*), the file-write bytes under default / ccs
# codecs, a console accent line, and a (setvar SYSCODEPAGE) attempt.
set -u

backend="clautolisp"
dwg=""
while [ $# -gt 0 ]; do
  case "$1" in
    --backend) backend="$2"; shift 2 ;;
    --dwg)     dwg="$2"; shift 2 ;;
    *) echo "usage: $0 --backend {clautolisp|bricscad|autocad} [--dwg FILE]" >&2; exit 2 ;;
  esac
done

root="${CI_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
alfe="${ALFE_BIN:-$root/autolisp-front-end/tools/alfe/bin/alfe-sbcl}"
probe="$root/autolisp-front-end/tests/scenarios/entities/encoding-probe.lsp"
# CAD-side runtime for a built-not-installed alfe (see alfe-cad-console-encoding).
export ALFE_RUNTIME_LSP="${ALFE_RUNTIME_LSP:-$root/autolisp-front-end/source/runtime/autolisp-remote-io.lsp}"
export ALFE_BOOTSTRAP_LSP="${ALFE_BOOTSTRAP_LSP:-$root/autolisp-front-end/source/runtime/autolisp-bootstrap.lsp}"

[ -x "$alfe" ] || { echo "alfe not found/executable: $alfe (build it: make -C autolisp-front-end build-alfe-sbcl)" >&2; exit 2; }
[ -f "$probe" ] || { echo "probe not found: $probe" >&2; exit 2; }

out_dir="$root/dist/encoding"; mkdir -p "$out_dir"
report="$out_dir/${backend}-$(uname).txt"
: > "$report"

declare -a bargs=("--no-init")
case "$backend" in
  bricscad)   bargs+=("--bricscad" "--mode" "batch" "--timeout" "180") ;;
  autocad)    bargs+=("--autocad" "--mode" "batch"); [ -n "$dwg" ] && bargs+=("--dwg" "$dwg") ;;
  clautolisp) bargs+=("--clautolisp" "--host" "mock") ;;
  *) echo "unknown backend: $backend" >&2; exit 2 ;;
esac
bargs+=("-l" "$probe")

# Run the probe once under a labelled set of VAR=VALUE env assignments, and
# fold its ENC lines (prefixed) into the report + the console.
run_knob() {
  local label="$1"; shift
  echo "########## KNOB: $label ##########" | tee -a "$report"
  env "$@" "$alfe" "${bargs[@]}" 2>&1 \
    | grep -aE "^ENC |ENC-PROBE DONE|BOOTSTRAP-FAILED|FAILED" \
    | sed "s|^|[$label] |" | tee -a "$report"
  echo | tee -a "$report"
}

# --- the Unix locale knob matrix -------------------------------------------
run_knob "baseline"
run_knob "LANG=C"                 LANG=C LC_ALL= LC_CTYPE=
run_knob "LANG=en_US.UTF-8"       LANG=en_US.UTF-8 LC_ALL= LC_CTYPE=
run_knob "LANG=fr_FR.UTF-8"       LANG=fr_FR.UTF-8 LC_ALL= LC_CTYPE=
run_knob "LC_ALL=en_US.UTF-8"     LC_ALL=en_US.UTF-8 LANG= LC_CTYPE=
run_knob "LC_ALL=C"               LC_ALL=C LANG= LC_CTYPE=
run_knob "LC_ALL=fr_FR.ISO8859-1" LC_ALL=fr_FR.ISO8859-1 LANG= LC_CTYPE=
run_knob "LC_CTYPE=en_US.UTF-8"   LC_CTYPE=en_US.UTF-8 LANG= LC_ALL=
run_knob "LC_CTYPE=ISO-8859-1"    LC_CTYPE=ISO-8859-1 LANG= LC_ALL=

echo "encoding experiment ($backend) -> $report"
