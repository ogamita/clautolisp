#!/bin/sh
# Keep MSYS2's Windows-form temporary-directory variables out of POSIX Emacs.
set -eu

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    for variable in TMPDIR TEMP TMP; do
      case "$variable" in
        TMPDIR) value=${TMPDIR-} ;;
        TEMP) value=${TEMP-} ;;
        TMP) value=${TMP-} ;;
      esac
      case "$value" in
        [A-Za-z]:/*|[A-Za-z]:\\*)
          if command -v cygpath >/dev/null 2>&1; then
            value=$(cygpath -u "$value")
          else
            value=/tmp
          fi
          case "$variable" in
            TMPDIR) TMPDIR=$value; export TMPDIR ;;
            TEMP) TEMP=$value; export TEMP ;;
            TMP) TMP=$value; export TMP ;;
          esac
          ;;
      esac
    done
    ;;
esac

exec "$@"
