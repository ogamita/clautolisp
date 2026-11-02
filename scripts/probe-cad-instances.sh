#!/usr/bin/env bash
# Probe: how a SECOND BricsCAD instance behaves on macOS.
#
# macOS twin of probe-cad-instances.ps1 (alfe-cad-launch-new-by-default,
# pjb 2026-10-23). alfe's macOS batch mode already starts the bricscad
# executable itself; its (opt-in) AppleScript path uses `open -a', which
# ACTIVATES a running copy, and addresses the app by PROCESS NAME. This
# measures, before either is changed:
#
#   1. Does a second direct launch of the executable give a second live
#      process, or does it exit / hand over to the first (single-instance
#      mutex, licence)? Which windows (dialogs) does each show?
#   2. Does `open -n -a' start a further instance through LaunchServices?
#      Which instance does a plain `open -a' activate when several run?
#   3. Can System Events address ONE of several same-named processes by its
#      unix id and make it frontmost -- the per-PID targeting an attach to
#      a given instance would need?
#
# Every instance it starts is ended (TERM, then KILL). Measures; never
# fails on a finding. Output: lines "CADINST ..." on stdout and in
# dist/cad-instances/cad-instances-bricscad-macos.txt.

set -u
ready_secs=${CADINST_READY_SECS:-60}
out_dir="dist/cad-instances"
mkdir -p "$out_dir"
log="$out_dir/cad-instances-bricscad-macos.txt"
: > "$log"
say() { printf 'CADINST %s\n' "$*" | tee -a "$log"; }

app=$(ls -d /Applications/BricsCAD*.app 2>/dev/null | sort | tail -1)
exe="$app/Contents/MacOS/bricscad"
if [ ! -x "$exe" ]; then say "no BricsCAD executable under /Applications"; exit 0; fi
say "app=$app"

work=$(mktemp -d "${TMPDIR:-/tmp}/cadinst.XXXXXX")
printf '(princ "\\nCADINST-SCRIPT-RAN\\n")\n' > "$work/noop.scr"

# Launch every instance as alfe does: WITH a drawing of its own and the
# clean profile when the runner names one. Started bare (no drawing, no
# profile), BricsCAD opens on the modal "BricsCAD Launcher" workspace dialog
# and waits -- which the first runs of this probe did on thalassa
# (pjb, 2026-10-23); see also the 2026-08-14 note in .gitlab/native.yml.
empty="autolisp-front-end/sour""ce/empty.dwg"
profile_args=()
if [ -n "${BRICSCAD_PROFILE_CLEAN:-}" ]; then
  profile_args=(-P "$BRICSCAD_PROFILE_CLEAN")
fi
say "profile=[${BRICSCAD_PROFILE_CLEAN:-}]"
drawing() { cp "$empty" "$work/$1.dwg" && printf '%s' "$work/$1.dwg"; }

bricscad_pids() { pgrep -U "$(id -u)" -f "$exe" | sort -n | tr '\n' ' '; }

windows_of() {
  osascript -e "tell application \"System Events\" to get name of every window of (first application process whose unix id is $1)" 2>&1 | tr '\n' ' '
}

frontmost_pid() {
  osascript -e 'tell application "System Events" to get unix id of first application process whose frontmost is true' 2>&1
}

started=""
cleanup() {
  for p in $(bricscad_pids); do
    case " $pre " in *" $p "*) continue ;; esac
    kill -TERM "$p" 2>/dev/null
  done
  sleep 10
  for p in $(bricscad_pids); do
    case " $pre " in *" $p "*) continue ;; esac
    kill -KILL "$p" 2>/dev/null && say "KILLED $p (TERM ignored)"
  done
  rm -rf "$work"
  say "DONE left-running=[$(bricscad_pids)]"
}
pre=$(bricscad_pids)
say "PRE running=[$pre]"
trap cleanup EXIT

launch_direct() {
  local tag=$1 before after
  before=$(bricscad_pids)
  "$exe" "$(drawing "$tag")" ${profile_args[@]+"${profile_args[@]}"} -B "$work/noop.scr" > "$work/$tag.out" 2>&1 &
  local child=$!
  sleep "$ready_secs"
  after=$(bricscad_pids)
  local alive=no; kill -0 "$child" 2>/dev/null && alive=yes
  say "DIRECT $tag child=$child child-alive=$alive before=[$before] after=[$after]"
  say "WINDOWS $tag $(windows_of "$child")"
  say "STDOUT $tag $(tr '\n' ' ' < "$work/$tag.out" | cut -c1-400)"
}

launch_direct A
launch_direct B

before=$(bricscad_pids)
open -n -a "$app" "$(drawing C)" --args ${profile_args[@]+"${profile_args[@]}"} -B "$work/noop.scr"
sleep "$ready_secs"
say "OPEN-N before=[$before] after=[$(bricscad_pids)]"

open -a "$app"
sleep 5
say "OPEN-A frontmost=$(frontmost_pid) running=[$(bricscad_pids)]"

for p in $(bricscad_pids); do
  case " $pre " in *" $p "*) continue ;; esac
  r=$(osascript -e "tell application \"System Events\" to set frontmost of (first application process whose unix id is $p) to true" 2>&1)
  sleep 3
  say "FRONT-BY-PID want=$p got=$(frontmost_pid) err=[$r]"
done
exit 0
