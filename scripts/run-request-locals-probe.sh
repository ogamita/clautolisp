#!/usr/bin/env bash
# run-request-locals-probe.sh -- MEASURE whether a user program's globals
# survive alfe's request machinery on a CAD engine: a (setq f 1 text "t" ...)
# made by the -l file, by an -x request and by a function, read back by a
# LATER request (issues/open/alfe-eval-request-locals-capture-user-setq.issue).
# macOS/Linux twin of run-request-locals-probe.ps1.
#
#   scripts/run-request-locals-probe.sh --backend {clautolisp|bricscad|autocad|accoreconsole}
#
# --clautolisp gives the baseline column the vendor columns are compared with.
# `autocad' (GUI) and `accoreconsole' (headless) are separate backends on
# purpose: the same product two ways.
#
# Output: dist/request-locals/<backend>-<uname>.txt -- the RLOCALS lines.
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
probe="$root/autolisp-front-end/tests/scenarios/entities/request-locals-probe.lsp"
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
# Step 1: the -l file sets the names; step 2: an -x setq; step 3: a function
# setting them, as --main runs one. Each is read back by a LATER request.
bargs+=("-l" "$probe" "-x" "(rlp-report 1)"
        "-x" "(setq f 111 text 112 r 113 path 114 form 115 source 116 err 117 normalized 118 result 119 keep 120 req-id 121 rc 122 line 123 obj 124 msg 125 args 126 name 127 value 128 x 129 s 130 idx 131 back 132 on 133)" "-x" "(rlp-report 2)"
        "-x" "(rlp-set-in-fn)" "-x" "(rlp-report 3)" "-x" "(rlp-done)")

out_dir="$root/dist/request-locals"; mkdir -p "$out_dir"
report="$out_dir/${backend}-$(uname).txt"
: > "$report"

echo "########## BACKEND: $backend on $(uname) ##########" | tee -a "$report"
"$alfe" "${bargs[@]}" 2>&1 \
  | grep -aE "^RLOCALS|BOOTSTRAP-FAILED|FAILED" | tee -a "$report"

# A report with no DONE line is a run that died mid-way; say so in the file
# itself, so a truncated run is never mistaken for a complete one.
grep -q '^RLOCALS-DONE' "$report" \
  || echo "RLOCALS-INCOMPLETE  the probe did not reach its end" | tee -a "$report"

echo "request-locals probe ($backend) -> $report"
