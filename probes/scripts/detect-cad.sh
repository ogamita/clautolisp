#!/usr/bin/env bash
#
# detect-cad.sh PRODUCT
#
# Print a runner-command template for PRODUCT (autocad | bricscad |
# clautolisp) on this host, or exit non-zero if the engine cannot be
# found. The template contains placeholders run-probes.sh substitutes:
#
#   __PROBE_FILE__   the generated probe wrapper (.lsp)
#   __SCRIPT_FILE__  a generated CAD script (.scr) that loads the wrapper
#
# Overrides (skip auto-detection entirely):
#   AUTOCAD_RUNNER / BRICSCAD_RUNNER / CLAUTOLISP_RUNNER
#       full template, used verbatim.
#   AUTOCAD_ACCORECONSOLE / AUTOCAD_EXE / BRICSCAD_EXE / CLAUTOLISP_BIN
#       just the executable path; the template is built around it.
#
# Auto-detection mirrors alfe's backend discovery
# (autolisp-front-end/source/backend-*.lisp).

set -euo pipefail

product="${1:?usage: detect-cad.sh <autocad|bricscad|clautolisp>}"

platform="ms-windows"
case "$(uname -s 2>/dev/null || echo unknown)" in
  Darwin) platform="macos" ;;
  Linux)  platform="linux" ;;
  MINGW*|MSYS*|CYGWIN*) platform="ms-windows" ;;
  *) [[ "${OS:-}" == "Windows_NT" ]] && platform="ms-windows" || platform="unknown" ;;
esac

# First match of a glob, or empty.
first_glob() {
  local g
  for g in "$@"; do
    if [[ -e "$g" ]]; then printf '%s\n' "$g"; return 0; fi
  done
  return 1
}

emit() { printf '%s\n' "$1"; exit 0; }

case "$product" in
  clautolisp)
    [[ -n "${CLAUTOLISP_RUNNER:-}" ]] && emit "$CLAUTOLISP_RUNNER"
    bin="${CLAUTOLISP_BIN:-}"
    if [[ -z "$bin" ]]; then
      root="$(cd "$(dirname "$0")/../.." && pwd)"
      bin="$(first_glob \
        "$root/clautolisp/tools/clautolisp/bin/clautolisp-sbcl" \
        "$root/clautolisp/tools/clautolisp/bin/clautolisp-ccl" \
        || true)"
    fi
    [[ -n "$bin" && -x "$bin" ]] || { echo "detect-cad: no clautolisp binary (build it, or set CLAUTOLISP_BIN)" >&2; exit 3; }
    emit "\"$bin\" --clautolisp -q -l __PROBE_FILE__"
    ;;

  autocad)
    [[ -n "${AUTOCAD_RUNNER:-}" ]] && emit "$AUTOCAD_RUNNER"
    # Headless AutoCAD Core Console runs a .scr that loads the wrapper.
    bin="${AUTOCAD_ACCORECONSOLE:-}"
    if [[ -z "$bin" && "$platform" == "ms-windows" ]]; then
      bin="$(first_glob \
        "/c/Program Files/Autodesk/AutoCAD "*"/accoreconsole.exe" \
        "/c/Program Files/Autodesk/AutoCAD"*"/accoreconsole.exe" \
        || true)"
    fi
    if [[ -n "$bin" ]]; then emit "\"$bin\" /s __SCRIPT_FILE__"; fi
    # Fall back to full AutoCAD in script mode.
    bin="${AUTOCAD_EXE:-}"
    if [[ -z "$bin" && "$platform" == "ms-windows" ]]; then
      bin="$(first_glob \
        "/c/Program Files/Autodesk/AutoCAD "*"/acad.exe" \
        "/c/Program Files/Autodesk/AutoCAD LT "*"/acadlt.exe" \
        || true)"
    fi
    [[ -n "$bin" ]] || { echo "detect-cad: AutoCAD not found (set AUTOCAD_ACCORECONSOLE or AUTOCAD_RUNNER)" >&2; exit 3; }
    emit "\"$bin\" /b __SCRIPT_FILE__"
    ;;

  bricscad)
    [[ -n "${BRICSCAD_RUNNER:-}" ]] && emit "$BRICSCAD_RUNNER"
    bin="${BRICSCAD_EXE:-}"
    if [[ -z "$bin" ]]; then
      case "$platform" in
        macos)
          bin="$(first_glob \
            "/Applications/BricsCAD.app/Contents/MacOS/bricscad" \
            "/Applications/Bricsys/BricsCAD"*".app/Contents/MacOS/bricscad" \
            || true)" ;;
        ms-windows)
          bin="$(first_glob \
            "/c/Program Files/Bricsys/"*"/bricscad.exe" \
            "/c/Program Files/Bricsys/BricsCAD"*"/bricscad.exe" \
            || true)" ;;
      esac
    fi
    [[ -n "$bin" ]] || { echo "detect-cad: BricsCAD not found (set BRICSCAD_EXE or BRICSCAD_RUNNER)" >&2; exit 3; }
    emit "\"$bin\" -B __SCRIPT_FILE__"
    ;;

  *)
    echo "detect-cad: unknown product '$product'" >&2
    exit 2
    ;;
esac
