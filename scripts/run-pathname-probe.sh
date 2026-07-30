#!/usr/bin/env bash
# run-pathname-probe.sh — drive pathname-probe.lsp against a CAD backend to
# confirm how "." / ".." path segments are resolved (cad-path-dotdot-
# resolution.issue). macOS / Linux twin of run-pathname-probe.ps1.
#
#   scripts/run-pathname-probe.sh --backend {clautolisp|bricscad|autocad} [--dwg FILE]
#
# Output: dist/pathname/<backend>-<uname>.txt — the PATHPROBE lines.
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
probe="$root/autolisp-front-end/tests/scenarios/entities/pathname-probe.lsp"
# CAD-side runtime for a built-not-installed alfe (see alfe-cad-console-encoding).
export ALFE_RUNTIME_LSP="${ALFE_RUNTIME_LSP:-$root/autolisp-front-end/source/runtime/autolisp-remote-io.lsp}"
export ALFE_BOOTSTRAP_LSP="${ALFE_BOOTSTRAP_LSP:-$root/autolisp-front-end/source/runtime/autolisp-bootstrap.lsp}"

[ -x "$alfe" ] || { echo "alfe not found/executable: $alfe (build it: make -C autolisp-front-end build-alfe-sbcl)" >&2; exit 2; }
[ -f "$probe" ] || { echo "probe not found: $probe" >&2; exit 2; }

out_dir="$root/dist/pathname"; mkdir -p "$out_dir"
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

echo "########## BACKEND: $backend ##########" | tee -a "$report"
"$alfe" "${bargs[@]}" 2>&1 \
  | grep -aE "^PATHPROBE |BOOTSTRAP-FAILED|FAILED" | tee -a "$report"
echo | tee -a "$report"
echo "pathname probe ($backend) -> $report"
