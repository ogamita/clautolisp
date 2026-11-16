#!/bin/bash
# Build the cadgui embedded-ECL Qt6 shell.
# Needs: g++, Qt6 (pkg-config Qt6Widgets), libecl-dev (ecl-config).
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
g++ -std=c++17 -fPIC "$here/cadgui-shell.cpp" -o "$here/cadgui-shell" \
    $(pkg-config --cflags Qt6Widgets) \
    $(ecl-config --cflags) \
    $(pkg-config --libs Qt6Widgets) \
    $(ecl-config --libs)
echo "built: $here/cadgui-shell"
