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

# Start from an empty dist/encoding/: a runner that reuses its build directory
# would otherwise ship older files of OTHER jobs in this job's artefact
# (encoding-probe-artifacts-and-macos-forward).
out_dir="$root/dist/encoding"; rm -rf "$out_dir"; mkdir -p "$out_dir"
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

# --- LOG: the CAD's own command-history log, read back by alfe --cad-log ------
# (encoding-situations-cli-options, the `log' situation; the .ps1 twin has the
# full rationale). BricsCAD V26 on macOS wrote no log in batch mode
# (probe-logfile); this records whether that still holds and, if a log
# appears, what --cad-log decoded and the log's raw first bytes.
if [ "$backend" != "clautolisp" ]; then
  log_lsp="$out_dir/log-probe.lsp"
  cad_log="$out_dir/cad-log-$backend.txt"
  wd_file="$out_dir/cad-log-workdir.txt"
  rm -f "$cad_log" "$wd_file"
  printf '%s\n' '(progn (apply (quote princ) (list (strcat "\nLOG-MARKER caf" (chr 233) " eur" (chr 8364) "\n"))) (vl-catch-all-apply (function (lambda () (command "_.LINE" "0,0" "1,1" ""))) nil) (princ "\nLOG WRITTEN\n") (princ))' > "$log_lsp"
  declare -a largs=()
  for a in "${bargs[@]}"; do
    [ "$a" = "-l" ] || [ "$a" = "$probe" ] || largs+=("$a")
  done
  largs+=("--keep-workdir" "--write-workdir-path" "$wd_file" "--cad-log" "$cad_log" "-l" "$log_lsp")
  echo "########## LOG: --cad-log ##########" | tee -a "$report"
  "$alfe" "${largs[@]}" 2>&1 | grep -aE "LOG |cad-log|BOOTSTRAP-FAILED|FAILED" \
    | sed "s|^|[LOG] |" | tee -a "$report"
  if [ -f "$cad_log" ]; then
    echo "[LOG] decoded: $(wc -l < "$cad_log") lines" | tee -a "$report"
    grep -a 'LOG-MARKER' "$cad_log" | head -3 | od -An -tx1 | sed "s|^|[LOG] decoded marker bytes (UTF-8):|" | tee -a "$report"
  else
    echo "[LOG] NO --cad-log FILE: $cad_log" | tee -a "$report"
  fi
  if [ -f "$wd_file" ]; then
    wd="$(head -1 "$wd_file")"
    for f in "$wd"/logs/*; do
      [ -f "$f" ] || continue
      [ "$(basename "$f")" = "debug.log" ] && continue
      echo "[LOG] raw $(basename "$f"): $(wc -c < "$f") bytes; first 16: $(head -c 16 "$f" | od -An -tx1 | tr -s ' ')" | tee -a "$report"
    done
    rm -rf "$wd"
  fi
fi

# --- FORWARD: -Efile-write utf-8 reaching the CAD's OPEN on every action -----
# The run-encoding-experiment.ps1 FORWARD step, ported (the .ps1 has the
# rationale; encoding-probe-artifacts-and-macos-forward): lispsys-forward-probe
# run three ways under -Efile-write utf-8 -- alfe-loaded from an entry file,
# given to -l, and with its OPEN calls in an -x form (E1F_MODE=x) -- each one
# alfe run. It measures end to end what BricsCAD/macOS does with the forwarded
# request: "w SIZE 3" / "a SIZE 1" is nothing forwarded (or forwarded and
# ignored), 4 / 2 UTF-8, 7 / 5 UTF-8 with a BOM; FORWARDED-ARG / -CCS say what
# alfe asked for.
if [ "$backend" != "clautolisp" ]; then
  forward="$root/autolisp-front-end/tests/scenarios/entities/lispsys-forward-probe.lsp"
  e1f_dir="$out_dir/e1f"; mkdir -p "$e1f_dir"
  forward_entry="$e1f_dir/e1f-entry.lsp"
  printf '(alfe-load "%s")\n' "$forward" > "$forward_entry"
  # The same -x form as the .ps1 (no double quote there for PowerShell 5.1's
  # sake; bash would not mind, but the two twins run the same text).
  forward_x="(e1f-x (open (e1f-xp 'w) (e1f-xm 'w)) (open (e1f-xp 'a) (e1f-xm 'a)))"
  declare -a fbase=()
  for a in "${bargs[@]}"; do
    [ "$a" = "-l" ] || [ "$a" = "$probe" ] || fbase+=("$a")
  done
  fbase+=("-Efile-write" "utf-8")
  run_forward() {
    local label="$1" mode="$2"; shift 2
    echo "########## $label ##########" | tee -a "$report"
    E1_DIR="$e1f_dir" E1F_MODE="$mode" "$alfe" "${fbase[@]}" "$@" 2>&1 \
      | grep -aE "^ENC |ENC-PROBE DONE|WARN|ERROR|BOOTSTRAP-FAILED|FAILED" \
      | sed "s|^|[$label] |" | tee -a "$report"
  }
  run_forward "FORWARD alfe-load" ""  -l "$forward_entry"
  run_forward "FORWARD -l"        ""  -l "$forward"
  run_forward "FORWARD -x"        "x" -l "$forward" -x "$forward_x"
fi

echo "encoding experiment ($backend) -> $report"
