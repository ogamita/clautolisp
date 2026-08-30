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
# Auto-detection ASKS ALFE when alfe is on PATH:
#
#     $ alfe --list-cad-programs
#     acad-2026          /Applications/Autodesk/AutoCAD 2026/.../AutoCAD
#     accoreconsole-2026 /Applications/.../AcCoreConsole
#     bricscad-v26       /Applications/BricsCAD V26.app/Contents/MacOS/bricscad
#     clautolisp         (embedded in alfe)
#
# because alfe already HAS this discovery and keeps it working. This file
# used to say it "mirrors" alfe's -- and mirroring is exactly how it came
# to miss /Applications/BricsCAD V26.app (versioned bundle, space in the
# name) while alfe found it without difficulty on the same machine. Two
# copies of a search path is one copy too many. The globs below stay as a
# fallback for a machine with no alfe on PATH, which is the CI case today.

# Ask alfe for an executable whose listing name starts with one of the
# given prefixes, in order, so a caller can prefer accoreconsole over
# acad. Prints the path, or fails.
alfe_lookup() {
  local prefix path
  command -v alfe >/dev/null 2>&1 || return 1
  for prefix in "$@"; do
    # The listing is `name<blanks>path'; a path may contain spaces, so
    # everything after the first run of blanks is the path.
    path="$(alfe --list-cad-programs 2>/dev/null |
            sed -n "s/^${prefix}[A-Za-z0-9._-]*[[:blank:]][[:blank:]]*//p" |
            head -n 1)"
    if [[ -n "$path" && "$path" != '('* && -e "$path" ]]; then
      printf '%s\n' "$path"
      return 0
    fi
  done
  return 1
}

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
      # .exe first: the Windows build produces clautolisp-sbcl.exe (pjb,
      # 2026-08-16), and the `-x' test below is not execution, so it will
      # not resolve the suffix on its own.
      bin="$(first_glob \
        "$root/clautolisp/tools/clautolisp/bin/clautolisp-sbcl.exe" \
        "$root/clautolisp/tools/clautolisp/bin/clautolisp-ccl.exe" \
        "$root/clautolisp/tools/clautolisp/bin/clautolisp-sbcl" \
        "$root/clautolisp/tools/clautolisp/bin/clautolisp-ccl" \
        || true)"
    fi
    [[ -n "$bin" && -x "$bin" ]] || { echo "detect-cad: no clautolisp binary (build it, or set CLAUTOLISP_BIN)" >&2; exit 3; }
    emit "\"$bin\" --no-init --clautolisp -q -l __PROBE_FILE__"
    ;;

  autocad)
    [[ -n "${AUTOCAD_RUNNER:-}" ]] && emit "$AUTOCAD_RUNNER"
    # Headless AutoCAD Core Console runs a .scr that loads the wrapper.
    # accoreconsole FIRST because it is the headless one, which is what a
    # probe wants; alfe lists both, so ask in that order.
    bin="${AUTOCAD_ACCORECONSOLE:-}"
    [[ -z "$bin" ]] && bin="$(alfe_lookup accoreconsole || true)"
    if [[ -n "$bin" ]]; then emit "\"$bin\" /s __SCRIPT_FILE__"; fi
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
    [[ -z "$bin" ]] && bin="$(alfe_lookup bricscad || true)"
    if [[ -z "$bin" ]]; then
      case "$platform" in
        macos)
          # The real installation is VERSIONED and has a space in the
          # bundle name: /Applications/BricsCAD V26.app/Contents/MacOS/
          # bricscad. Neither of the two globs that used to be here
          # matched it, so BricsCAD was never found on macOS -- this file
          # claims at the top to mirror alfe's discovery, and alfe walks
          # "/Applications/BricsCAD*.app/" (backend-bricscad.lisp), which
          # does match. The versioned glob goes FIRST so a machine with
          # several versions gets the newest by the sort first_glob's
          # caller relies on.
          bin="$(first_glob \
            "/Applications/BricsCAD"*".app/Contents/MacOS/bricscad" \
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
