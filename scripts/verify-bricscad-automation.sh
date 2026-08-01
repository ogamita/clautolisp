#!/usr/bin/env bash
# verify-bricscad-automation.sh — macOS integration check for alfe's
# `--mode automation' BricsCAD path.
#
# On Windows, automation mode drives BricsCAD over COM from a VBScript
# bridge (bridge-bricscad.vbs, run by cscript); that path has been
# debugged repeatedly against the real product. The macOS counterpart —
# osascript running the generated launcher.applescript
# (EMIT-LAUNCHER-APPLESCRIPT) — has never been exercised end to end.
# This script does that: it drives a minimal `alfe --bricscad --mode
# automation' invocation through the real BricsCAD on macOS and asserts
# the full protocol cycle completes (READY -> request -> DONE -> clean
# exit, with the marker echoed back).
#
# On failure it re-runs the SAME request in `--mode batch'. That control
# separates "automation is broken" from "BricsCAD/the runner is broken":
#
#   automation FAIL + batch PASS  -> the AppleScript/automation path is at fault
#   automation FAIL + batch FAIL  -> the engine or the runner is at fault
#
# Both phases also record the exact command line alfe would launch
# (`--print-command'), so the log shows the osascript / bricscad argv
# even when the launch itself never gets off the ground. Failing runs
# keep their workdir and copy the staged artefacts (launcher.applescript,
# run-common.lsp, run.scr, protocol/status.txt) into
# dist/bricscad-automation/ for the job artifacts.
#
# Exit 0 iff the automation phase passes.

set -uo pipefail

root="${CI_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
alfe="${ALFE_BIN:-$root/autolisp-front-end/tools/alfe/bin/alfe-sbcl}"
outdir="$root/dist/bricscad-automation"

if [ ! -x "$alfe" ]; then
    echo "alfe binary not found at $alfe (build it: make -C autolisp-front-end build-alfe-sbcl)"
    exit 2
fi

# CAD-side runtime for a built-not-installed alfe (see alfe-cad-console-encoding).
export ALFE_RUNTIME_LSP="${ALFE_RUNTIME_LSP:-$root/autolisp-front-end/source/runtime/autolisp-remote-io.lsp}"
export ALFE_BOOTSTRAP_LSP="${ALFE_BOOTSTRAP_LSP:-$root/autolisp-front-end/source/runtime/autolisp-bootstrap.lsp}"

mkdir -p "$outdir"

marker="AUTOMATION-PROBE-OK-$$"
timeout_secs="${ALFE_PROBE_TIMEOUT:-240}"

# The request goes in a FILE (-l), not in -x "(princ \"...\")". Quoting an
# expression through a shell into a native argv is exactly what broke the
# Windows sibling of this probe (PowerShell dropped the inner quotes, the CAD
# princ'd an unbound symbol, and a PASSING run was reported as FAIL). A file
# has no quoting surface at all.
probe="$outdir/probe.lsp"
printf '(princ "%s")\n' "$marker" > "$probe"

# run_phase MODE -> 0 on success. Echoes everything it does.
run_phase () {
    local mode="$1"
    local wdfile="$outdir/$mode-workdir.txt"
    local log="$outdir/$mode.log"

    echo "== [$mode] command line alfe would launch =="
    "$alfe" --no-init --bricscad --mode "$mode" --print-command -l "$probe" \
        2>&1 | tee "$outdir/$mode-command.txt"

    echo "== [$mode] running: alfe --bricscad --mode $mode -l $probe =="
    "$alfe" --no-init --bricscad --mode "$mode" \
            --timeout "$timeout_secs" \
            --keep-workdir --write-workdir-path "$wdfile" \
            -l "$probe" 2>&1 | tee "$log"
    local code="${PIPESTATUS[0]}"

    local workdir=""
    [ -f "$wdfile" ] && workdir="$(head -n 1 "$wdfile")"

    if [ "$code" -eq 0 ] && grep -q -- "$marker" "$log"; then
        echo "== [$mode] PASS (exit 0, marker echoed) =="
        # Nothing to keep on success: --keep-workdir was only for triage.
        [ -n "$workdir" ] && [ -d "$workdir" ] && rm -rf "$workdir"
        return 0
    fi

    echo "== [$mode] FAIL: exit=$code marker-present=$(grep -c -- "$marker" "$log") =="
    if [ -n "$workdir" ] && [ -d "$workdir" ]; then
        echo "== [$mode] staged workdir kept: $workdir =="
        local keep="$outdir/$mode-workdir"
        mkdir -p "$keep"
        for artefact in launcher.applescript bridge-bricscad.vbs bridge-vbs.log \
                        run-common.lsp run.scr protocol/status.txt \
                        protocol/stdout.txt protocol/stderr.txt; do
            if [ -f "$workdir/$artefact" ]; then
                cp "$workdir/$artefact" "$keep/$(basename "$artefact")" 2>/dev/null
                echo "--- $artefact ---"
                head -n 40 "$workdir/$artefact"
            fi
        done
    fi
    return 1
}

echo "### phase 1: --mode automation (the path under test)"
if run_phase automation; then
    echo "### RESULT: automation PASS — the macOS AppleScript launcher drives"
    echo "### the full READY -> request -> DONE cycle on real BricsCAD."
    exit 0
fi

echo
echo "### phase 2: --mode batch (control: is the engine/runner healthy?)"
if run_phase batch; then
    echo "### RESULT: automation FAIL / batch PASS — BricsCAD and the runner are"
    echo "### fine; the fault is in the macOS automation (osascript +"
    echo "### launcher.applescript) path. See dist/bricscad-automation/."
else
    echo "### RESULT: automation FAIL / batch FAIL — the engine or the runner is"
    echo "### at fault, NOT specifically the automation path. Fix the baseline"
    echo "### first (see dist/bricscad-automation/)."
fi
exit 1
