#!/usr/bin/env bash
# TEMPORARY CAD smoke / diagnostic harness — cad-runtime bug-cluster debugging.
#
# Runs a handful of alfe evaluations against a selected CAD backend on a real
# runner and prints labelled results, so we can:
#   * confirm a backend/platform even LAUNCHES (esp. the new --cad acad batch
#     on Windows and --cad accoreconsole on macOS), and
#   * see the real-CAD behaviour of the cluster bugs (princ/prin1 trailing
#     newlines, (load VAR) argument evaluation, large single-form load),
#     both as a pre-fix baseline and to confirm a fix on re-push.
#
# This is a DEBUG aid driven by the temporary debug:cad:* CI jobs. Remove it,
# and those jobs, once the CAD-runtime cluster work has landed.
#
# Usage: run-cad-smoke.sh --cad DENOT [--mode batch|auto|automation] [--dwg FILE]
set -u

cad=""
mode="batch"
dwg=""
while [ $# -gt 0 ]; do
  case "$1" in
    --cad)  cad="$2";  shift 2 ;;
    --mode) mode="$2"; shift 2 ;;
    --dwg)  dwg="$2";  shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
[ -n "$cad" ] || { echo "usage: $0 --cad DENOT [--mode MODE] [--dwg FILE]" >&2; exit 2; }

root="${CI_PROJECT_DIR:-$(pwd)}"
alfe="$root/autolisp-front-end/tools/alfe/bin/alfe-sbcl"
out_dir="$root/dist/cad-debug/${cad}-$(uname -s)"
mkdir -p "$out_dir"

if [ ! -x "$alfe" ]; then
  echo "alfe binary not found/executable at $alfe (build: make -C autolisp-front-end build-alfe-sbcl)" >&2
  exit 2
fi

# Point alfe at the CAD-side runtime/bootstrap shipped in the repo (alfe is
# built-not-installed on the runners; these take precedence over discovery).
rt_lsp="$root/autolisp-front-end/source/runtime/autolisp-remote-io.lsp"
bs_lsp="$root/autolisp-front-end/source/runtime/autolisp-bootstrap.lsp"
[ -f "$rt_lsp" ] && export ALFE_RUNTIME_LSP="$rt_lsp"   || echo "WARN: runtime lsp not found at $rt_lsp" >&2
[ -f "$bs_lsp" ] && export ALFE_BOOTSTRAP_LSP="$bs_lsp" || echo "WARN: bootstrap lsp not found at $bs_lsp" >&2

# macOS ships bash 3.2, where "${arr[@]}" on an EMPTY array under `set -u`
# aborts ("unbound variable"). Build the optional --dwg args so the expansion
# is safe whether or not a drawing was given (the ${a[@]+"${a[@]}"} idiom).
# Diagnostic: on macOS, accoreconsole batch needs a drawing/template but the
# backend's template discovery only looks next to the (deeply-nested) binary.
# List any .dwt the AutoCAD install ships so we learn the real macOS path, and
# auto-supply the first as --dwg when the caller gave none, so the accoreconsole
# smoke can get past [NO-DWG] and actually evaluate (does the unlicensed engine
# run?). Bake the discovered path into the backend afterwards.
if [ -z "$dwg" ] && { [ "$cad" = "accoreconsole" ] || [ "$cad" = "autocad" ] || [ "$cad" = "acad" ]; }; then
  echo "==== SMOKE template-scan (.dwt under /Applications/Autodesk) ===="
  found_dwt="$(find /Applications/Autodesk -iname '*.dwt' 2>/dev/null | sort | tee "$out_dir/dwt-candidates.txt" | head -1)"
  find /Applications/Autodesk -iname '*.dwt' 2>/dev/null | sort | head -8
  if [ -n "$found_dwt" ]; then
    # The bundle templates are READ-ONLY ("currently in use or is read-only"),
    # which makes accoreconsole exit before READY. Copy to a writable temp and
    # feed THAT, so we get past the read-only blocker and see whether the engine
    # actually runs headless on macOS (or hits the Qt::AA_PluginApplication wall).
    writable_dwg="$out_dir/seed.dwg"
    if cp "$found_dwt" "$writable_dwg" 2>/dev/null; then
      chmod u+w "$writable_dwg" 2>/dev/null || true
      dwg="$writable_dwg"
      echo "auto-selected template: $found_dwt"
      echo "writable copy:          $dwg"
    else
      dwg="$found_dwt"
      echo "auto-selected template (could not copy; using read-only): $dwg"
    fi
  else
    echo "no .dwt template found under /Applications/Autodesk"
  fi
  echo
fi

dwg_args=()
[ -n "$dwg" ] && dwg_args=(--dwg "$dwg")

echo "############################################################"
echo "# CAD smoke: --cad $cad --mode $mode  (host $(uname -s))"
echo "# alfe: $alfe"
echo "# dwg:  ${dwg:-<none>}"
echo "############################################################"

# 0) Discovery — what CAD installs does alfe see on this runner? (no launch)
echo "==== SMOKE discover (--list-cad-programs) ===="
"$alfe" --list-cad-programs 2>&1 | tee "$out_dir/00-discover.log"
echo

# Helper: run one eval smoke, capture log + exit code, never abort the script.
# The script uses `set -u` (not `-e`), so a non-zero alfe just continues.
smoke() {
  local label="$1"; shift
  echo "==== SMOKE $label  (--cad $cad --mode $mode) ===="
  "$alfe" -norc --cad "$cad" --mode "$mode" ${dwg_args[@]+"${dwg_args[@]}"} \
          --verbose --timeout 120 "$@" 2>&1 | tee "$out_dir/$label.log"
  local rc=${PIPESTATUS[0]}
  echo "---- $label exit: $rc ----"
  echo
}

# 1) Does the backend launch and evaluate at all?
smoke launch -x '(princ "SMOKE-LAUNCH-OK")'

# 2) princ/prin1 trailing-newline bug (alfe-princ-prin1-spurious-newlines).
#    Correct output is the single line "1 ABC" then END on its own line; the
#    bug puts every primitive's output on its own line.
smoke princ-prin1 \
  -x '(progn (prin1 1) (princ " ") (prin1 (quote abc)) (terpri) (princ "END"))'

# 3) (load VAR) argument-evaluation bug (alfe-load-form-argument-not-evaluated).
loadme="$out_dir/loadme.lsp"
printf '(princ "LOADED-FROM-FILE-OK")\n' > "$loadme"
smoke load-form \
  -x "(progn (setq p \"$loadme\") (load p) (princ \" AFTER-LOAD\"))"

echo "############################################################"
echo "# CAD smoke done: --cad $cad --mode $mode"
echo "# logs under: $out_dir"
echo "############################################################"
# Diagnostic harness: always exit 0 so an offline/misbehaving CAD never reddens
# the (allow_failure) debug pipeline — read the logs/artifacts for results.
exit 0
