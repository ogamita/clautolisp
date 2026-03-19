#!/usr/bin/env bash
set -euo pipefail

if [[ "${OS:-}" == "Windows_NT" ]]; then
  printf '%s\n' "ms-windows"
  exit 0
fi

case "$(uname -s)" in
  Darwin)
    printf '%s\n' "macos"
    ;;
  Linux)
    printf '%s\n' "linux"
    ;;
  MINGW*|MSYS*|CYGWIN*)
    printf '%s\n' "ms-windows"
    ;;
  *)
    printf '%s\n' "unknown"
    ;;
esac
