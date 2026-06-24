#!/usr/bin/env bash
set -euo pipefail

prefer_native_windows_emacs() {
  local candidate
  for candidate in \
    /mingw64/bin/emacs \
    /ucrt64/bin/emacs \
    /clang64/bin/emacs \
    /mingw32/bin/emacs \
    /usr/bin/emacs
  do
    if [ -x "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

current_emacs="$(command -v emacs 2>/dev/null || true)"

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    if [ -n "$current_emacs" ] && [ "${current_emacs#/opt/local/bin/}" = "$current_emacs" ]; then
      printf '%s\n' "$current_emacs"
      exit 0
    fi
    if prefer_native_windows_emacs; then
      exit 0
    fi
    ;;
  *)
    if [ -n "$current_emacs" ]; then
      printf '%s\n' "$current_emacs"
      exit 0
    fi
    ;;
esac

printf '%s\n' emacs