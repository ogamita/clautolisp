#!/usr/bin/env bash
# run-block-comment-probe.sh -- VERIFY that alfe's CAD-side loader skips
# AutoLISP ;| ... |; block comments when it loads a file (-l)
# (issues/open/alfe-cad-source-loader-evaluates-block-comments.issue). macOS/Linux twin of
# run-block-comment-probe.ps1.
#
#   scripts/run-block-comment-probe.sh --backend {clautolisp|bricscad|autocad|accoreconsole}
#
# --clautolisp gives the baseline column the vendor columns are compared with.
# `autocad' (GUI) and `accoreconsole' (headless) are separate backends on
# purpose: the same product two ways.
#
# Output: dist/block-comment/<backend>-<uname>.txt -- the BLKC lines.
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
probe="$root/autolisp-front-end/tests/scenarios/entities/block-comment-probe.lsp"
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
  clautolisp)    bargs+=("--clautolisp") ;;
  *) echo "unknown backend: $backend" >&2; exit 2 ;;
esac
# -l: the file goes through alfe's CAD-side loader, the code under test.
bargs+=("-l" "$probe")

out_dir="$root/dist/block-comment"; mkdir -p "$out_dir"
report="$out_dir/${backend}-$(uname).txt"
: > "$report"

echo "########## BACKEND: $backend on $(uname) ##########" | tee -a "$report"
"$alfe" "${bargs[@]}" 2>&1 \
  | grep -aE "^BLKC|BOOTSTRAP-FAILED|FAILED|BOOM|ERROR" | tee -a "$report"

# A report with no DONE line is a run that died mid-way; say so in the file
# itself, so a truncated run is never mistaken for a complete one.
grep -q '^BLKC-DONE' "$report" \
  || echo "BLKC-INCOMPLETE  the probe did not reach its end" | tee -a "$report"

echo "block-comment probe ($backend) -> $report"
