#!/usr/bin/env bash
#
# run-probes.sh PRODUCT
#
# Run the probe suite (probes/sources/manifest.txt) inside PRODUCT
# (autocad | bricscad | clautolisp), writing one record per line to a
# committed results file:
#
#   probe-results/<product>/<platform>/<timestamp>/results.sexp
#
# The runner command is taken from $RUNNER_TEMPLATE if set, otherwise
# from probes/scripts/detect-cad.sh PRODUCT (which honours the
# AUTOCAD_*/BRICSCAD_*/CLAUTOLISP_* overrides). Unless PROBE_NO_COMMIT
# is set, the results file + metadata are git-added and committed (never
# pushed) so they can be handed back for processing.
#
# Usage is normally indirect, via the top-level Makefile:
#   make probe                 # auto-detect a CAD, else clautolisp
#   make probe-autocad
#   make probe-bricscad
#   make probe-clautolisp      # headless baseline column

set -euo pipefail

product="${1:?usage: run-probes.sh <autocad|bricscad|clautolisp>}"

probes_dir="$(cd "$(dirname "$0")/.." && pwd)"
repo_root="$(cd "$probes_dir/.." && pwd)"
sources_dir="$probes_dir/sources"
manifest="$sources_dir/manifest.txt"

[[ -f "$manifest" ]] || { echo "run-probes: missing $manifest" >&2; exit 2; }

platform="ms-windows"
case "$(uname -s 2>/dev/null || echo unknown)" in
  Darwin) platform="macos" ;;
  Linux)  platform="linux" ;;
  MINGW*|MSYS*|CYGWIN*) platform="ms-windows" ;;
  *) [[ "${OS:-}" == "Windows_NT" ]] && platform="ms-windows" || platform="unknown" ;;
esac

# Resolve the runner command template.
runner_template="${RUNNER_TEMPLATE:-}"
if [[ -z "$runner_template" ]]; then
  runner_template="$(bash "$probes_dir/scripts/detect-cad.sh" "$product")" || {
    echo "run-probes: could not locate a runner for '$product'." >&2
    echo "Pass one explicitly, e.g.:" >&2
    echo "  make probe-$product RUNNER_TEMPLATE='\"/path/to/engine\" /s __SCRIPT_FILE__'" >&2
    exit 3
  }
fi

timestamp="$(date -u +"%Y%m%dT%H%M%SZ")"
run_rel="probe-results/$product/$platform/$timestamp"
run_dir="$repo_root/$run_rel"
result_file="$run_dir/results.sexp"
metadata_file="$run_dir/metadata.json"
wrapper_file="$run_dir/run-probes.lsp"
script_file="$run_dir/run-probes.scr"

mkdir -p "$run_dir"

lisp_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

# --- generate the probe wrapper (.lsp) -------------------------------
{
  printf '(setq cad-probe-result-file "%s")\n'  "$(lisp_escape "$result_file")"
  printf '(setq cad-probe-platform "%s")\n'      "$(lisp_escape "$platform")"
  printf '(setq cad-probe-product "%s")\n'       "$(lisp_escape "$product")"
  printf '(setq cad-probe-run-directory "%s")\n' "$(lisp_escape "$run_dir")"
  printf '(load "%s")\n' "$(lisp_escape "$sources_dir/probe-core.lsp")"
  # Load every suite file from the manifest.
  while read -r src fn _rest; do
    [[ -z "$src" || "$src" == \#* ]] && continue
    printf '(load "%s")\n' "$(lisp_escape "$sources_dir/$src")"
  done < "$manifest"
  printf '(cad-probe-begin-run)\n'
  while read -r src fn _rest; do
    [[ -z "$src" || "$src" == \#* ]] && continue
    printf '(%s)\n' "$fn"
  done < "$manifest"
  printf '(cad-probe-end-run)\n'
  printf '(princ)\n'
} > "$wrapper_file"

# --- generate the CAD script (.scr) that loads the wrapper -----------
# A CAD command script evaluates a leading-paren line as AutoLISP.
{
  printf '(load "%s")\n' "$(lisp_escape "$wrapper_file")"
} > "$script_file"

write_metadata() {
  cat > "$metadata_file" <<EOF
{
  "product": "$(json_escape "$product")",
  "platform": "$(json_escape "$platform")",
  "timestamp_utc": "$(json_escape "$timestamp")",
  "status": "$(json_escape "$1")",
  "exit_code": $2,
  "runner_template": "$(json_escape "$runner_template")",
  "result_file": "$(json_escape "$run_rel/results.sexp")"
}
EOF
}

write_metadata "prepared" 0

cmd="$runner_template"
cmd="${cmd//__PROBE_FILE__/$wrapper_file}"
cmd="${cmd//__SCRIPT_FILE__/$script_file}"

echo "run-probes: $product on $platform" >&2
echo "  runner : $cmd" >&2
echo "  output : $run_rel/results.sexp" >&2

set +e
bash -lc "$cmd"
exit_code=$?
set -e

if [[ $exit_code -eq 0 && -s "$result_file" ]]; then
  write_metadata "completed" "$exit_code"
else
  write_metadata "failed" "$exit_code"
  echo "run-probes: WARNING — runner exit $exit_code, result file $( [[ -s $result_file ]] && echo non-empty || echo EMPTY )." >&2
fi

# --- commit the results ----------------------------------------------
if [[ -n "${PROBE_NO_COMMIT:-}" ]]; then
  echo "run-probes: PROBE_NO_COMMIT set — not committing." >&2
elif git -C "$repo_root" rev-parse --git-dir >/dev/null 2>&1; then
  git -C "$repo_root" add "$run_rel/results.sexp" "$run_rel/metadata.json"
  if git -C "$repo_root" diff --cached --quiet -- "$run_rel"; then
    echo "run-probes: nothing to commit." >&2
  else
    git -C "$repo_root" commit -q -m "probes: $product/$platform $timestamp" \
        -- "$run_rel/results.sexp" "$run_rel/metadata.json"
    echo "run-probes: committed $run_rel (not pushed)." >&2
  fi
else
  echo "run-probes: not a git repo — results left uncommitted at $run_dir." >&2
fi

echo "Probe run directory: $run_dir"
exit "$exit_code"
