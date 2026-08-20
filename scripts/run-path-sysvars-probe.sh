#!/usr/bin/env bash
# run-path-sysvars-probe.sh — read every path-carrying system variable off a
# CAD engine (bricscad-sysvars-on-macos.issue). macOS/Linux twin of
# run-path-sysvars-probe.ps1.
#
#   scripts/run-path-sysvars-probe.sh --backend {clautolisp|bricscad|autocad|accoreconsole}
#
# WHY IT EXISTS. The system-variable inventory marks most of these
# :host-specific, so the catalogue carries "" — which means nobody measured
# them, NOT that a real CAD leaves them empty. Every proposal about what
# clautolisp should put in them is a guess until this has run.
#
# `autocad' and `accoreconsole' are separate backends here, deliberately:
# they are the same product launched two ways (GUI vs headless), and whether
# they populate the same variables is one of the questions being asked. A
# variable only the GUI fills is one clautolisp has no reason to imitate.
#
# Output: dist/path-sysvars/<backend>-<uname>.txt — the PATHSYSVAR lines.
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
probe="$root/autolisp-front-end/tests/scenarios/entities/path-sysvars-probe.lsp"
export ALFE_RUNTIME_LSP="${ALFE_RUNTIME_LSP:-$root/autolisp-front-end/source/runtime/autolisp-remote-io.lsp}"
export ALFE_BOOTSTRAP_LSP="${ALFE_BOOTSTRAP_LSP:-$root/autolisp-front-end/source/runtime/autolisp-bootstrap.lsp}"

[ -x "$alfe" ] || { echo "alfe not found/executable: $alfe (build it: make -C autolisp-front-end build-alfe-sbcl)" >&2; exit 2; }
[ -f "$probe" ] || { echo "probe not found: $probe" >&2; exit 2; }

declare -a bargs=("--no-init")
case "$backend" in
  bricscad)      bargs+=("--bricscad" "--mode" "batch" "--timeout" "180") ;;
  # --mode automation is the GUI engine (acad); --mode batch selects
  # AcCoreConsole. That one flag is the whole difference being measured.
  autocad)       bargs+=("--autocad" "--mode" "automation" "--timeout" "300") ;;
  accoreconsole) bargs+=("--autocad" "--mode" "batch" "--timeout" "300") ;;
  clautolisp)    bargs+=("--clautolisp" "--host" "mock") ;;
  *) echo "unknown backend: $backend" >&2; exit 2 ;;
esac
bargs+=("-l" "$probe")

out_dir="$root/dist/path-sysvars"; mkdir -p "$out_dir"
report="$out_dir/${backend}-$(uname).txt"
: > "$report"

echo "########## BACKEND: $backend on $(uname) ##########" | tee -a "$report"
"$alfe" "${bargs[@]}" 2>&1 \
  | grep -aE "^PATHSYSVAR|BOOTSTRAP-FAILED|FAILED" | tee -a "$report"

# A report with no DONE line is a run that died mid-way; say so in the file
# itself, so a truncated probe is never mistaken for an engine that defines
# nothing.
grep -q '^PATHSYSVAR-DONE' "$report" \
  || echo "PATHSYSVAR-INCOMPLETE  the probe did not reach its end" | tee -a "$report"

echo "path-sysvars probe ($backend) -> $report"
