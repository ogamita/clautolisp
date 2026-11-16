#!/bin/bash
# Build the phase-2 ECL-embed-in-Qt6 spikes:
#   spike  (main.cpp)        -- display list from embedded ECL, offscreen PNG
#   spike2 (interactive.cpp) -- the live interactive window (nested event loop)
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
build_one() {   # $1 = source, $2 = output
  g++ -std=c++17 -fPIC "$here/$1" -o "$here/$2" \
      $(pkg-config --cflags Qt6Widgets) \
      $(ecl-config --cflags) \
      $(pkg-config --libs Qt6Widgets) \
      $(ecl-config --libs)
  echo "built: $here/$2"
}
build_one main.cpp spike
build_one interactive.cpp spike2
