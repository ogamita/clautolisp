#!/usr/bin/env bash
# run-command-prompts-gui-autocad.sh -- capture command-line prompts from a
# GUI AutoCAD (acad.exe), the only place interactive prompts exist.
# windows-runner-sunset-probe-campaign.issue B12, path 1.
#
# Headless accoreconsole cannot do this: a loaded-lisp (command "_LINE") does
# not suspend there, so LASTPROMPT never holds the command's prompt (proven
# 2026-10-25, probe:suite:autocad:windows emitted only the ENV record). A GUI
# acad.exe launched with `/b run.scr' reads the SCR after start-up and runs the
# SAME probe in the real interactive app, where (command ...) suspends between
# tokens and LASTPROMPT reflects the prompt. Windows twin of
# autolisp-spec/scripts/run-probes-direct-autocad.sh.
#
#   scripts/run-command-prompts-gui-autocad.sh <out-dir>
#
# acad.exe is a GUI app, so results travel through FILES, not stdout: the probe
# appends to <out-dir>/results.sexp (ending run-end); the SCR writes
# <out-dir>/done.txt after the load returns. We poll for done.txt, then QUIT.
#
# Tunables: AUTOCAD_ACAD (acad.exe path), PROBE_TIMEOUT (default 300).
#
# This is EXPECTED to be fragile: a CI runner with no interactive desktop, or
# no GUI license seat, cannot show acad.exe and the run will time out with no
# results. That outcome is itself the finding -- report it, do not retry blind.
set -u

out_dir="${1:?usage: $0 <out-dir>}"
mkdir -p "$out_dir"
root="${CI_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
timeout_s="${PROBE_TIMEOUT:-300}"

# Windows path form (C:/...) that acad.exe's (load ...) accepts, from a MINGW
# path. cygpath -m gives mixed (forward-slash) Windows paths; fall back to a
# leading-drive rewrite if cygpath is absent.
winpath() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"
  else echo "$1" | sed -E 's#^/([a-zA-Z])/#\U\1:/#'; fi
}

acad="${AUTOCAD_ACAD:-C:/Program Files/Autodesk/AutoCAD 2022/acad.exe}"
# If the default is absent, try to find any acad.exe next to an accoreconsole.
if [ ! -f "$acad" ]; then
  found=$(ls "/c/Program Files/Autodesk/"*/acad.exe 2>/dev/null | head -1 || true)
  [ -n "$found" ] && acad="$(winpath "$found")"
fi

core="$(winpath "$root/probes/sources/probe-core.lsp")"
probe="$(winpath "$root/probes/sources/probe-command-prompts.lsp")"
results_win="$(winpath "$out_dir/results.sexp")"
done_win="$(winpath "$out_dir/done.txt")"
wrapper="$out_dir/gui-wrapper.lsp"
scr="$out_dir/gui-run.scr"
: > "$out_dir/results.sexp"
rm -f "$out_dir/done.txt"

# The wrapper seeds probe-core's run context, loads the suite, and runs it.
cat > "$wrapper" <<EOF
(setq cad-probe-result-file "$results_win")
(setq cad-probe-product "autocad")
(setq cad-probe-platform "ms-windows-gui")
(setq cad-probe-run-directory ".")
(load "$core")
(load "$probe")
(cad-probe-begin-run)
(cad-probe-run-command-prompts-probes)
(cad-probe-end-run)
(princ)
EOF
wrapper_win="$(winpath "$wrapper")"

# The SCR acad reads after start-up: run the wrapper, mark done, quit.
cat > "$scr" <<EOF
(load "$wrapper_win")
(setq __cp_done (open "$done_win" "w"))
(if __cp_done (progn (princ "DONE" __cp_done) (close __cp_done)))
QUIT
Y
EOF
scr_win="$(winpath "$scr")"

echo "########## GUI AutoCAD command-prompt capture ##########"
echo "acad   : $acad"
echo "scr    : $scr_win"
echo "results: $results_win"
if [ ! -f "$acad" ]; then
  echo "FAILED: acad.exe not found at '$acad' (set AUTOCAD_ACAD)"; exit 2
fi

# A /b script runs in the STARTUP DRAWING's context. If acad starts on the
# Start tab with no drawing open (the default profile here), the script never
# runs and acad sits idle (observed 2026-10-25). So OPEN A DRAWING explicitly:
# the runner's empty.dwg (the accoreconsole probes' PROBE_DWG), else a shipped
# template via /t, else bare /b as a last resort.
dwg_win="${PROBE_DWG:-c:/gitlab-runner/dwg/empty.dwg}"
dwg_unix="$(printf '%s' "$dwg_win" | sed -E 's#^([A-Za-z]):/#/\L\1/#')"
if [ -f "$dwg_unix" ]; then
  launch=("$dwg_win" /b "$scr_win"); echo "drawing: $dwg_win"
else
  tmpl=$(ls "/c/Program Files/Autodesk/"*/Template/acadiso.dwt 2>/dev/null | head -1)
  if [ -n "$tmpl" ]; then launch=(/t "$(winpath "$tmpl")" /b "$scr_win"); echo "template: $tmpl"
  else launch=(/b "$scr_win"); echo "WARNING: no drawing/template -- acad may sit on the Start tab"; fi
fi

# MSYS/MINGW rewrites an argument that looks like a POSIX path -- notably the
# `/b' switch -- into a Windows path before handing it to a native .exe, so
# acad.exe would receive a bogus path and try to OPEN IT AS A DRAWING
# ("fichier dessin introuvable"). Disable that conversion for this launch; our
# paths are already Windows-form (C:/...), so nothing legitimate needs it.
MSYS2_ARG_CONV_EXCL='*' MSYS_NO_PATHCONV=1 \
  "$acad" "${launch[@]}" >"$out_dir/acad.stdout" 2>"$out_dir/acad.stderr" &
pid=$!
# Kill acad on a graceful cancel (GitLab sends SIGTERM before SIGKILL), not
# only on clean EXIT -- a plain EXIT trap is skipped by cancel, which is how an
# earlier cancelled run left acad orphaned on the desktop.
trap 'kill "$pid" 2>/dev/null || true' EXIT TERM INT

elapsed=0
while [ ! -f "$out_dir/done.txt" ] && [ "$elapsed" -lt "$timeout_s" ]; do
  sleep 3; elapsed=$((elapsed + 3))
  kill -0 "$pid" 2>/dev/null || { echo "acad exited early after ${elapsed}s"; break; }
done

# Give acad a moment to QUIT, then ensure it is gone.
for i in 1 2 3 4 5 6 7 8 9 10; do kill -0 "$pid" 2>/dev/null || break; sleep 1; done
kill "$pid" 2>/dev/null || true
trap - EXIT

echo "=== CMDPROBE lines captured ==="
grep -aE '"command-prompts"' "$out_dir/results.sexp" 2>/dev/null | head -60 || true
n=$(grep -acE '"command-prompts"' "$out_dir/results.sexp" 2>/dev/null || echo 0)
echo "command-prompts records: $n  (done.txt: $([ -f "$out_dir/done.txt" ] && echo yes || echo NO), elapsed ${elapsed}s)"
# allow_failure in CI, but exit non-zero if nothing came back so it is visible.
[ "$n" -gt 1 ] 2>/dev/null && exit 0 || exit 4
