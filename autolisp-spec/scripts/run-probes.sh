#!/usr/bin/env bash
set -euo pipefail

product="${1:?usage: run-probes.sh <product>}"
runner_template="${RUNNER_TEMPLATE:-}"

if [[ -z "$runner_template" ]]; then
  echo "RUNNER_TEMPLATE is required." >&2
  echo "Use placeholders __PROBE_FILE__ and __RESULT_DIR__ in the template." >&2
  exit 2
fi

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
platform="$("$root_dir/scripts/detect-platform.sh")"
timestamp="$(date -u +"%Y%m%dT%H%M%SZ")"
run_dir="$root_dir/results/$product/$platform/$timestamp"
result_file="$run_dir/results.sexp"
metadata_file="$run_dir/metadata.json"
wrapper_file="$run_dir/run-probes.lsp"

mkdir -p "$run_dir"

lisp_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

write_metadata() {
  local status="$1"
  local exit_code="$2"
  cat >"$metadata_file" <<EOF
{
  "product": "$(json_escape "$product")",
  "platform": "$(json_escape "$platform")",
  "timestamp_utc": "$(json_escape "$timestamp")",
  "status": "$(json_escape "$status")",
  "exit_code": $exit_code,
  "runner_template": "$(json_escape "$runner_template")",
  "result_file": "$(json_escape "$result_file")",
  "wrapper_file": "$(json_escape "$wrapper_file")"
}
EOF
}

cat >"$wrapper_file" <<EOF
(setq *autolisp-spec-result-file* "$(lisp_escape "$result_file")")
(setq *autolisp-spec-platform* "$(lisp_escape "$platform")")
(setq *autolisp-spec-product* "$(lisp_escape "$product")")
(setq *autolisp-spec-run-directory* "$(lisp_escape "$run_dir")")
(load "$(lisp_escape "$root_dir/sources/probe-core.lsp")")
(load "$(lisp_escape "$root_dir/sources/probe-atoi.lsp")")
(load "$(lisp_escape "$root_dir/sources/probe-atof.lsp")")
(load "$(lisp_escape "$root_dir/sources/probe-output.lsp")")
(autolisp-spec-begin-run)
(autolisp-spec-run-atoi-probes)
(autolisp-spec-run-atof-probes)
(autolisp-spec-run-output-probes)
(autolisp-spec-end-run)
(princ)
EOF

write_metadata "prepared" 0

cmd="$runner_template"
cmd="${cmd//__PROBE_FILE__/$wrapper_file}"
cmd="${cmd//__RESULT_DIR__/$run_dir}"

set +e
bash -lc "$cmd"
exit_code=$?
set -e

if [[ $exit_code -eq 0 ]]; then
  write_metadata "completed" "$exit_code"
else
  write_metadata "failed" "$exit_code"
fi

echo "Probe run directory: $run_dir"
exit "$exit_code"
