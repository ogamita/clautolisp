#!/usr/bin/env bash
# run-pgp-probe.sh — harvest the keyboard command aliases from a CAD install's
# alias file (acad.pgp / default.pgp), for cadtui's locale dictionaries
# (cadtui-locale-probe-pgp-aliases.issue). macOS/Linux twin of run-pgp-probe.ps1.
#
#   scripts/run-pgp-probe.sh --backend {clautolisp|bricscad|autocad|accoreconsole}
#
# The alias file is a data file; the probe only LOCATES and reads it (findfile),
# so a --clautolisp run just validates the probe shape (PGP-ABSENT + PGP-DONE).
# The real French aliases come from bricscad/autocad on the localised runner.
#
# Output: dist/pgp/<backend>-<uname>.txt — the PGP lines.
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
probe="$root/autolisp-front-end/tests/scenarios/entities/pgp-probe.lsp"
export ALFE_RUNTIME_LSP="${ALFE_RUNTIME_LSP:-$root/autolisp-front-end/source/runtime/autolisp-remote-io.lsp}"
export ALFE_BOOTSTRAP_LSP="${ALFE_BOOTSTRAP_LSP:-$root/autolisp-front-end/source/runtime/autolisp-bootstrap.lsp}"

[ -x "$alfe" ] || { echo "alfe not found/executable: $alfe (build it: make -C autolisp-front-end build-alfe-sbcl)" >&2; exit 2; }
[ -f "$probe" ] || { echo "probe not found: $probe" >&2; exit 2; }

declare -a bargs=("--no-init")
case "$backend" in
  bricscad)      bargs+=("--bricscad" "--mode" "batch" "--timeout" "180") ;;
  autocad)       bargs+=("--autocad" "--mode" "automation" "--timeout" "300") ;;
  accoreconsole) bargs+=("--autocad" "--mode" "batch" "--timeout" "300") ;;
  clautolisp)    bargs+=("--clautolisp" "--host" "mock") ;;
  *) echo "unknown backend: $backend" >&2; exit 2 ;;
esac
bargs+=("-l" "$probe")

out_dir="$root/dist/pgp"; mkdir -p "$out_dir"
report="$out_dir/${backend}-$(uname).txt"
: > "$report"

echo "########## BACKEND: $backend on $(uname) ##########" | tee -a "$report"
"$alfe" "${bargs[@]}" 2>&1 \
  | grep -aE "^PGP|BOOTSTRAP-FAILED|FAILED" | tee -a "$report"

grep -q '^PGP-DONE' "$report" \
  || echo "PGP-INCOMPLETE  the probe did not reach its end" | tee -a "$report"

echo "pgp probe ($backend) -> $report"
