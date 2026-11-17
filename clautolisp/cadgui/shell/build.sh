#!/bin/bash
# Build the cadgui embedded-ECL Qt6 shell.
# Needs: g++, Qt6 (pkg-config Qt6Widgets), libecl-dev (ecl-config).
#
# Two modes:
#   bash build.sh                 -- runtime ASDF load of clautolisp/cadgui
#                                    (cold ~96 s per run; see NOTES-ecl.md).
#   CADGUI_USE_LIB=1 bash build.sh -- link the monolithic static library
#                                    (build-cadgui-lib.sh first) and initialize
#                                    the engine from C: no runtime ASDF, instant
#                                    start. The FAST iteration path.
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
lib="$here/clautolisp--cadgui--all-systems.a"
extra_cflags=""
extra_objs=""
extra_libs=""
if [ "${CADGUI_USE_LIB:-0}" = "1" ]; then
  if [ ! -f "$lib" ] || [ ! -f "$here/cadgui-lib-init.h" ]; then
    echo "build.sh: CADGUI_USE_LIB=1 but the library/header is missing."
    echo "          run: bash build-cadgui-lib.sh"
    exit 2
  fi
  extra_cflags="-DCADGUI_USE_LIB"
  extra_objs="$lib"
  extra_libs="-lffi"          # cffi's foreign support, pulled in by the library
  echo "build.sh: linking frozen engine $(basename "$lib")"
fi
if [ "${CADGUI_TRACE:-0}" = "1" ]; then
  extra_cflags="$extra_cflags -DCADGUI_TRACE"
  echo "build.sh: tracing enabled (-DCADGUI_TRACE)"
fi
g++ -std=c++17 -fPIC $extra_cflags "$here/cadgui-shell.cpp" $extra_objs -o "$here/cadgui-shell" \
    $(pkg-config --cflags Qt6Widgets) \
    $(ecl-config --cflags) \
    $(pkg-config --libs Qt6Widgets) \
    $(ecl-config --libs) \
    $extra_libs
echo "built: $here/cadgui-shell"
