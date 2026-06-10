#!/bin/sh
# Build the vendored libredwg and the clautolisp CFFI shim (Phase 17e).
#
# Produces:
#   third-party/libredwg/build/libredwg.{dylib,so}   (the library)
#   drawing-dwg/source/clal_dwg.{dylib,so}            (the shim)
#
# The shim embeds an rpath to the libredwg build dir, so loading the
# shim from Lisp pulls in libredwg automatically. Requires a C compiler
# and cmake (generic build tooling); libredwg itself is the vendored
# submodule, not a package-manager dependency.
set -eu

here="$(cd "$(dirname "$0")" && pwd)"   # clautolisp/drawing-dwg
root="$(cd "$here/.." && pwd)"          # clautolisp
lr="$root/third-party/libredwg"
build="$lr/build"

if [ ! -f "$lr/CMakeLists.txt" ]; then
  echo "error: libredwg submodule not checked out at $lr" >&2
  echo "run: git submodule update --init --recursive" >&2
  exit 1
fi

# libredwg's own submodule (jsmn).
git -C "$lr" submodule update --init

# Configure + build the shared library.
#  - DISABLE_WERROR: this clang/SDK turns several libredwg warnings fatal.
#  - -Wno-unused-command-line-argument: clang rejects -fstack-clash-protection.
#  - -D_DARWIN_C_SOURCE: expose memmem() in <string.h> on macOS (no-op elsewhere).
cmake -S "$lr" -B "$build" \
      -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DDISABLE_WERROR=ON \
      -DCMAKE_C_FLAGS="-Wno-unused-command-line-argument -D_DARWIN_C_SOURCE"
cmake --build "$build" --target redwg \
      -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)"

# Compile the shim, linked against libredwg. Two rpaths so the SAME
# binary works both in the dev tree (libredwg in $build) and when
# installed adjacent to libredwg (release layout lib/clautolisp/<os>/<arch>/):
#   - $build                : dev build dir (absolute)
#   - @loader_path / $ORIGIN: the shim's own directory (relocatable)
ext=dylib
origin='@loader_path'
if [ "$(uname)" = "Linux" ]; then ext=so; origin='$ORIGIN'; fi
cc -shared -fPIC -O2 -D_DARWIN_C_SOURCE \
   -o "$here/source/clal_dwg.$ext" "$here/source/clal_dwg.c" \
   -I"$build/src" -I"$build" -I"$lr/include" -I"$lr/src" \
   -L"$build" -lredwg -Wl,-rpath,"$build" -Wl,-rpath,"$origin"

echo "built: $here/source/clal_dwg.$ext  (+ $build/libredwg.$ext)"
