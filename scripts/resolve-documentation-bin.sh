#!/bin/sh
# Print the native MSYS2 directory containing the documentation tools.
# Plain MSYS and Emacs shells do not normally include these directories.

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    for directory in /ucrt64/bin /mingw64/bin /clang64/bin; do
      if [ -x "$directory/xelatex.exe" ] &&
         [ -x "$directory/fmtutil.exe" ]; then
        printf '%s\n' "$directory"
        exit 0
      fi
    done
    ;;
esac
