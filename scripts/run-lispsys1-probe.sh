#!/usr/bin/env bash
# scripts/run-lispsys1-probe.sh -- measure AutoCAD at LISPSYS 1, then put
# LISPSYS back to 0 (pjb, 2026-10-25: "Ok for LISPSYS 1, but restore it to 0
# afterwards"; the Windows runner's AutoCAD is at 0 and the SCHMS jobs rely
# on it).
#
# LISPSYS is persisted and takes effect at the NEXT launch, so every step is
# its own CAD session (each run-probes.sh run launches accoreconsole and
# quits it):
#   1. set LISPSYS 1;
#   2. a fresh session reads it back -- the measurement counts only if it
#      reads 1 (else this fails: nothing would be measured at 1);
#   3. the measurement suites (triage2's version suite, versions,
#      open-encoding) in a fresh session at 1;
#   4. ALWAYS (trap): set LISPSYS 0, and a fresh session must read 0, else
#      this fails loudly.
# usage: scripts/run-lispsys1-probe.sh [--reset-only]
set -u
cd "$(dirname "$0")/.."
export PROBE_NO_COMMIT=1

results_dir() { ls -dt probe-results/autocad/*/*/ 2>/dev/null | head -n 1; }

# The LISPSYS value the last run's session started with, or "?".
last_value() {
  local f
  f="$(results_dir)results.sexp"
  [[ -f "$f" ]] || { echo "?"; return; }
  tr -d '\r' < "$f" |
    sed -n 's/.*(CASE . "value at start") (STATUS . "ok") (VALUE . "\(.*\)")).*/\1/p' |
    tail -n 1
}

lispsys_run() {   # $1: 0 / 1 / read
  PROBE_SUITES=lispsys PROBE_LISPSYS="$1" bash probes/scripts/run-probes.sh autocad
}

reset_and_verify() {
  echo "run-lispsys1-probe: setting LISPSYS back to 0" >&2
  lispsys_run 0
  lispsys_run read
  local v
  v="$(last_value)"
  if [[ "$v" != "0" ]]; then
    echo "run-lispsys1-probe: LISPSYS reads $v after the reset, NOT 0 -- reset it by hand on this machine" >&2
    exit 1
  fi
  echo "run-lispsys1-probe: LISPSYS is 0 again" >&2
}

if [[ "${1:-}" == "--reset-only" ]]; then
  reset_and_verify
  exit 0
fi

trap reset_and_verify EXIT

lispsys_run 1
lispsys_run read
v="$(last_value)"
if [[ "$v" != "1" ]]; then
  echo "run-lispsys1-probe: a fresh session reads LISPSYS $v, not 1 -- nothing measured" >&2
  exit 1
fi
echo "run-lispsys1-probe: LISPSYS is 1 in a fresh session; measuring" >&2
PROBE_SUITES="triage2 versions open-encoding" bash probes/scripts/run-probes.sh autocad
