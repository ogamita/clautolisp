#!/usr/bin/env bash
# Run the alfe entity / drawing-data / selection conformance probes against a
# CAD backend (bricscad | autocad | clautolisp) and turn each probe's verdict
# line into a pass/fail, saving every probe's full output as an artifact.
#
#   scripts/run-vendor-probes.sh --backend bricscad [--dwg FILE] [--keep-workdir 1]
#
# This is the bash twin of run-vendor-probes.ps1 (macOS / Linux runners, and
# bash-on-Windows if PowerShell is in the way). The `clautolisp` backend runs
# the very same probes headlessly, which is how this script is validated
# without a real CAD.
#
# While alfe is blocked in the file-IPC protocol waiting for the CAD to reach
# READY (up to --timeout seconds), a background WATCHER tails the engine
# workdir -- the --write-workdir-path sidecar, run-scr-started.txt, the
# protocol status, and logs/debug.log -- and prints a timestamped timeline, so
# a stuck launch is diagnosable live instead of only from the final artifacts.
set -u

backend=""
dwg=""
keep_workdir="1"
while [ $# -gt 0 ]; do
  case "$1" in
    --backend) backend="$2"; shift 2 ;;
    --dwg)     dwg="$2"; shift 2 ;;
    --keep-workdir) keep_workdir="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
case "$backend" in
  bricscad|autocad|clautolisp) ;;
  *) echo "usage: $0 --backend bricscad|autocad|clautolisp [--dwg FILE] [--keep-workdir 0|1]" >&2; exit 2 ;;
esac

root="${CI_PROJECT_DIR:-$(pwd)}"
alfe="$root/autolisp-front-end/tools/alfe/bin/alfe-sbcl"
probe_dir="$root/autolisp-front-end/tests/scenarios/entities"
out_dir="$root/dist/vendor-probes/$backend"
mkdir -p "$out_dir"

if [ ! -x "$alfe" ]; then
  echo "alfe binary not found/executable at $alfe (build it: make -C autolisp-front-end build-alfe-sbcl)" >&2
  exit 2
fi

# Point alfe at the CAD-side runtime/bootstrap LSP shipped in the repo (alfe is
# built-not-installed on the runners; these take precedence over discovery).
rt_lsp="$root/autolisp-front-end/source/runtime/autolisp-remote-io.lsp"
bs_lsp="$root/autolisp-front-end/source/runtime/autolisp-bootstrap.lsp"
[ -f "$rt_lsp" ] && export ALFE_RUNTIME_LSP="$rt_lsp"   || echo "WARN: runtime lsp not found at $rt_lsp" >&2
[ -f "$bs_lsp" ] && export ALFE_BOOTSTRAP_LSP="$bs_lsp" || echo "WARN: bootstrap lsp not found at $bs_lsp" >&2
[ -n "$dwg" ] && export AUTOLISP_DWG="$dwg"

# Pure-CAD probes: on a runner whose default BricsCAD profile auto-loads a
# vertical application, name a CLEAN profile so the app-load does not block the
# script. Only forced when $BRICSCAD_PROFILE_CLEAN is set (macOS BricsCAD is
# typically already clean).
if [ "$backend" = "bricscad" ] && [ -n "${BRICSCAD_PROFILE_CLEAN:-}" ]; then
  export AUTOLISP_BRICSCAD_PROFILE="$BRICSCAD_PROFILE_CLEAN"
  echo "AUTOLISP_BRICSCAD_PROFILE = $AUTOLISP_BRICSCAD_PROFILE"
fi

echo "alfe: $alfe"
echo "ALFE_RUNTIME_LSP   = ${ALFE_RUNTIME_LSP:-}"
echo "ALFE_BOOTSTRAP_LSP = ${ALFE_BOOTSTRAP_LSP:-}"

# --- watcher: tail the engine workdir while alfe is blocked -------------
watch_workdir() {
  local wdfile="$1" stopflag="$2" start="$3"
  local wd="" started=0 nlines=0 laststatus=""
  while [ ! -f "$stopflag" ]; do
    local now=$(( $(date +%s) - start ))
    if [ -z "$wd" ] && [ -s "$wdfile" ]; then
      wd=$(tr -d '\r\n' < "$wdfile" 2>/dev/null)
      [ -n "$wd" ] && echo "[watch +${now}s] workdir = $wd"
    fi
    if [ -n "$wd" ]; then
      if [ "$started" = 0 ] && [ -f "$wd/run-scr-started.txt" ]; then
        started=1; echo "[watch +${now}s] run-scr-started.txt APPEARED -- the CAD script is running"
      fi
      if [ -f "$wd/protocol/status.txt" ]; then
        local st; st=$(tr -d '\r\n' < "$wd/protocol/status.txt" 2>/dev/null)
        if [ -n "$st" ] && [ "$st" != "$laststatus" ]; then laststatus="$st"; echo "[watch +${now}s] status -> $st"; fi
      fi
      if [ -f "$wd/logs/debug.log" ]; then
        local total; total=$(wc -l < "$wd/logs/debug.log" 2>/dev/null || echo 0)
        if [ "$total" -gt "$nlines" ]; then
          tail -n +$((nlines+1)) "$wd/logs/debug.log" 2>/dev/null | sed "s/^/[watch +${now}s] debug: /"
          nlines="$total"
        fi
      fi
    fi
    sleep 2
  done
}

declare -a probe_names=("entity-lifecycle" "drawing-data" "selection")
declare -a probe_files=("entity-lifecycle-probe.lsp" "drawing-data-probe.lsp" "selection-probe.lsp")
declare -a probe_pass=("ALL ENTITY PROBES PASSED" "ALL DRAWING-DATA PROBES PASSED" "ALL SELECTION PROBES PASSED")

failed=0
summary="vendor probes: $backend"$'\n'"alfe: $alfe"$'\n'"dwg: ${dwg:-<none>}"$'\n'
tmp_base="${TMPDIR:-/tmp}"

for i in "${!probe_names[@]}"; do
  name="${probe_names[$i]}"
  file="${probe_files[$i]}"
  pass="${probe_pass[$i]}"
  probe_path="$probe_dir/$file"
  log="$out_dir/$name.log"
  echo "=== $backend : $name ==="

  # Copy the drawing to a unique temp name per probe so back-to-back runs never
  # share/lock the same file.
  probe_dwg=""
  if [ -n "$dwg" ] && [ -f "$dwg" ]; then
    probe_dwg="$tmp_base/vp-$backend-$name-$$-$i.dwg"
    cp -f "$dwg" "$probe_dwg"
  fi

  # Assemble alfe args per backend. --no-init: a test run must not auto-load
  # the runner's user init file (~/.autolisp etc.) -- it varies per machine
  # and pollutes the plan.
  declare -a args=("--no-init")
  wd_path_file=""
  if [ "$keep_workdir" = "1" ]; then
    wd_path_file="$tmp_base/vp-wd-$backend-$name-$$-$i.txt"
    rm -f "$wd_path_file"
    args+=("--debug" "--verbose" "--keep-workdir" "--write-workdir-path" "$wd_path_file")
  fi
  case "$backend" in
    bricscad) args+=("--bricscad" "--mode" "batch" "--timeout" "180") ;;
    autocad)  args+=("--autocad" "--mode" "batch")
              [ -n "$probe_dwg" ] && args+=("--dwg" "$probe_dwg") ;;
    clautolisp) args+=("--clautolisp") ;;
  esac
  args+=("-l" "$probe_path")

  # Launch the watcher, run alfe (blocking), then stop the watcher.
  stopflag="$tmp_base/vp-stop-$backend-$name-$$-$i"
  rm -f "$stopflag"
  start_ts=$(date +%s)
  watcher_pid=""
  if [ "$keep_workdir" = "1" ]; then
    watch_workdir "$wd_path_file" "$stopflag" "$start_ts" &
    watcher_pid=$!
  fi
  "$alfe" "${args[@]}" 2>&1 | tee "$log"
  if [ -n "$watcher_pid" ]; then
    touch "$stopflag"; wait "$watcher_pid" 2>/dev/null; rm -f "$stopflag"
  fi
  [ -n "$probe_dwg" ] && rm -f "$probe_dwg" "${probe_dwg%.dwg}".dwl "${probe_dwg%.dwg}".bak 2>/dev/null

  # Copy the kept workdir (path from the authoritative sidecar) into artifacts.
  if [ "$keep_workdir" = "1" ] && [ -s "$wd_path_file" ]; then
    wd=$(tr -d '\r\n' < "$wd_path_file")
    if [ -n "$wd" ] && [ -d "$wd" ]; then
      cp -R "$wd" "$out_dir/$name-workdir" 2>/dev/null && echo "kept workdir copied -> $out_dir/$name-workdir"
    fi
    rm -f "$wd_path_file"
  fi

  if grep -qF "$pass" "$log" 2>/dev/null; then
    summary+="PASS  $name"$'\n'; echo "PASS  $name"
  else
    failed=$((failed+1))
    verdict="no verdict (backend unreachable or crashed)"
    if grep -qE "PROBES FAILED: [0-9]+" "$log" 2>/dev/null; then
      verdict="$(grep -oE "PROBES FAILED: [0-9]+" "$log" | head -1) assertion(s) failed"
    fi
    summary+="FAIL  $name -- $verdict"$'\n'; echo "FAIL  $name -- $verdict"
  fi
  unset args
done

printf '%s\n' "$summary" > "$out_dir/SUMMARY.txt"
echo "--- $backend vendor-probe summary ---"
printf '%s\n' "$summary"
if [ "$failed" -gt 0 ]; then echo "$failed probe(s) failed on $backend"; exit 1; fi
echo "all vendor probes passed on $backend"
exit 0
