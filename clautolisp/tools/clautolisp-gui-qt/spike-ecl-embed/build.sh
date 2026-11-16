#!/bin/bash
# Build the phase-2 ECL-embed-in-Qt6 spike.
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
g++ -std=c++17 -fPIC "$here/main.cpp" -o "$here/spike" \
    $(pkg-config --cflags Qt6Widgets) \
    $(ecl-config --cflags) \
    $(pkg-config --libs Qt6Widgets) \
    $(ecl-config --libs)
echo "built: $here/spike"
