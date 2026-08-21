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
runtime_manifest="$build/clautolisp-runtime-library"

# A compiler selected by an absolute CC (notably /mingw64/bin/gcc from a
# plain MSYS or Emacs shell) still launches cc1 and the linker as child
# processes.  Their MinGW runtime DLLs live beside the compiler and Windows
# resolves them through PATH.  Keep that directory visible throughout both
# the CMake build and the shim link.
host_uname="$(uname -s)"
if [ -z "${CC+x}" ]; then
  case "$host_uname" in
    MINGW*|MSYS*|CYGWIN*)
      if [ -x /mingw64/bin/gcc ]; then
        compiler=/mingw64/bin/gcc
      else
        echo "error: the native MSYS2 MINGW64 compiler is not installed" >&2
        echo "install it with: pacman -S --needed mingw-w64-x86_64-gcc" >&2
        exit 1
      fi ;;
    *) compiler=cc ;;
  esac
else
  compiler="$CC"
fi
compiler_path="$(command -v "$compiler" 2>/dev/null || true)"
if [ -z "$compiler_path" ]; then
  echo "error: C compiler '$compiler' was not found" >&2
  exit 1
fi
compiler_dir="$(cd "$(dirname "$compiler_path")" && pwd)"
PATH="$compiler_dir:$PATH"
export PATH

echo "C compiler: $compiler_path"
echo "compiler runtime directory: $compiler_dir"

compiler_target="$("$compiler_path" -dumpmachine 2>/dev/null || true)"
echo "compiler target: $compiler_target"
case "$host_uname" in
  MINGW*|MSYS*|CYGWIN*)
    case "$compiler_target" in
      *mingw32*) ;;
      *)
        echo "error: '$compiler_path' does not target native Windows ($compiler_target)" >&2
        echo "use /mingw64/bin/gcc, not /usr/bin/cc or /usr/bin/gcc" >&2
        exit 1 ;;
    esac
    case "$compiler_path" in
      /ucrt64/*|/clang64/*|/clangarm64/*)
        echo "error: use the MINGW64/MSVCRT compiler for the native Windows codec" >&2
        echo "UCRT64/Clang builds import private UCRT API sets unavailable to native SBCL/CCL" >&2
        exit 1 ;;
    esac ;;
esac

if [ ! -f "$lr/CMakeLists.txt" ]; then
  echo "error: libredwg submodule not checked out at $lr" >&2
  echo "run: git submodule update --init --recursive" >&2
  exit 1
fi

# libredwg's own submodule (jsmn).
git -C "$lr" submodule update --init

# GCC can print its version while cc1.exe still fails to start when a MinGW
# runtime DLL is absent from PATH.  Probe the actual compilation pipeline so
# the failure is actionable instead of appearing later as silent Error 1s.
mkdir -p "$build"
if [ -f "$build/CMakeCache.txt" ]; then
  cached_compiler="$(sed -nE 's/^CMAKE_C_COMPILER[^=]*=(.*)$/\1/p' "$build/CMakeCache.txt" | head -n 1)"
  if [ -n "$cached_compiler" ] && [ "$cached_compiler" != "$compiler_path" ]; then
    echo "compiler changed ($cached_compiler -> $compiler_path); resetting generated CMake state"
    rm -f "$build/CMakeCache.txt"
    rm -rf "$build/CMakeFiles"
  fi
fi
compiler_probe="$build/clautolisp-compiler-probe.o"
if ! printf '%s\n' 'int clautolisp_compiler_probe(void) { return 0; }' |
     "$compiler_path" -x c -c -o "$compiler_probe" -; then
  rm -f "$compiler_probe"
  echo "error: compiler '$compiler_path' could not run its C compilation pipeline" >&2
  echo "ensure '$compiler_dir' is on PATH and reinstall the matching MSYS2 toolchain if necessary" >&2
  exit 1
fi
rm -f "$compiler_probe"

if [ "${CLAUTOLISP_COMPILER_PROBE_ONLY:-0}" = 1 ]; then
  exit 0
fi

# Configure + build the shared library.
#  - DISABLE_WERROR: this clang/SDK turns several libredwg warnings fatal.
#  - -w: silence libredwg's (very verbose) warnings. We don't act on a
#        vendored lib's warnings, and on CI the flood blows GitLab's 4 MB
#        job-log cap during the build — hiding any real downstream error.
#  - -Wno-unused-command-line-argument: clang rejects -fstack-clash-protection.
#  - -D_DARWIN_C_SOURCE: expose memmem() in <string.h> on macOS (no-op elsewhere).
# libredwg captures LIBREDWG_SO_VERSION via execute_process(perl …) WITHOUT
# OUTPUT_STRIP_TRAILING_WHITESPACE, so perl's trailing newline is substituted
# INTO the generated src/config.h define:
#     #define LIBREDWG_SO_VERSION "0:14:0
#     "
# which gcc rejects as "missing terminating \" character". It only bites where
# perl exists (MSYS2); the Linux CI image has no perl so the var keeps its clean
# default. Add the strip to the vendored CMakeLists (idempotent; harmless
# everywhere) before configuring.
if [ -f "$lr/CMakeLists.txt" ]; then
  sed -i 's/OUTPUT_VARIABLE LIBREDWG_SO_VERSION)/OUTPUT_VARIABLE LIBREDWG_SO_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)/' "$lr/CMakeLists.txt"
fi

# The value handed to a NATIVE cmake must be a path it can stat. On MSYS2/MinGW
# the POSIX $compiler_path (/mingw64/bin/gcc) is mangled to C:/msys64/mingw64/
# bin/gcc (no .exe) when it crosses into native cmake, which then rejects it as
# "not a full path to an existing compiler tool". Convert to a mixed path and
# ensure the .exe suffix there; elsewhere pass $compiler_path unchanged.
cmake_compiler="$compiler_path"
case "$host_uname" in
  MINGW*|MSYS*|CYGWIN*)
    cmake_compiler="$(cygpath -m "$compiler_path" 2>/dev/null || echo "$compiler_path")"
    case "$cmake_compiler" in *.exe) ;; *) cmake_compiler="$cmake_compiler.exe" ;; esac
    ;;
esac
cmake -S "$lr" -B "$build" \
      -DCMAKE_C_COMPILER="$cmake_compiler" \
      -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DDISABLE_WERROR=ON \
      -DCMAKE_C_FLAGS="-w -Wno-unused-command-line-argument -D_DARWIN_C_SOURCE"
cmake --build "$build" --target redwg \
      -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)"

# Compile the shim, linked against libredwg. Two rpaths so the SAME
# binary works both in the dev tree (libredwg in $build) and when
# installed adjacent to libredwg (release layout lib/clautolisp/<os>/<arch>/):
#   - $build                : dev build dir (absolute)
#   - @loader_path / $ORIGIN: the shim's own directory (relocatable)
case "$(uname)" in
  Linux)               ext=so;    origin='$ORIGIN' ;;
  Darwin)              ext=dylib; origin='@loader_path' ;;
  MINGW*|MSYS*|CYGWIN*) ext=dll;  origin='' ;;   # Windows: no rpath; the
                                                 # loader resolves DLLs from
                                                 # the shim's own dir / PATH
  *)                   ext=so;    origin='$ORIGIN' ;;
esac

# Windows DLLs have no rpath; clal_dwg.dll's dependency libredwg.dll is
# resolved at load time (bindings.lisp pre-loads it from the same dir).
rpaths=""
[ -n "$origin" ] && rpaths="-Wl,-rpath,$build -Wl,-rpath,$origin"

# On MinGW the import library may be libredwg.dll.a under $build or
# $build/src; search both. -fPIC is a no-op (and harmless) on Windows.
"$compiler_path" -shared -fPIC -O2 -D_DARWIN_C_SOURCE \
   -o "$here/source/clal_dwg.$ext" "$here/source/clal_dwg.c" \
   -I"$build/src" -I"$build" -I"$lr/include" -I"$lr/src" \
   -L"$build" -L"$build/src" -lredwg $rpaths

case "$ext" in
  dll)
    if ! command -v objdump >/dev/null 2>&1; then
      echo "error: objdump is required to validate the Windows codec" >&2
      exit 1
    fi
    if objdump -p "$here/source/clal_dwg.dll" | grep -qi 'api-ms-win-crt-private'; then
      echo "error: clal_dwg.dll imports a private UCRT API set; rebuild with /mingw64/bin/gcc" >&2
      exit 1
    fi
    imported_runtime="$(objdump -p "$here/source/clal_dwg.dll" |
      sed -nE 's/.*DLL Name: ([^ ]*redwg\.dll).*/\1/p' | head -n 1)"
    runtime_library="$build/$imported_runtime" ;;
  dylib) runtime_library="$(find "$build" -type f -name 'libredwg*.dylib' -print | head -n 1)" ;;
  so) runtime_library="$(find "$build" -type f \( -name 'libredwg.so' -o -name 'libredwg.so.*' \) -print | head -n 1)" ;;
esac
if [ -z "${runtime_library:-}" ] || [ ! -f "$runtime_library" ]; then
  echo "error: could not locate the LibreDWG runtime imported by the shim" >&2
  exit 1
fi
printf '%s\n' "$runtime_library" > "$runtime_manifest"

echo "built: $here/source/clal_dwg.$ext"
echo "LibreDWG runtime: $runtime_library"
