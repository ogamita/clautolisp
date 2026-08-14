#!/bin/sh
set -eu

script="$(cd "$(dirname "$0")/.." && pwd)/build-libredwg.sh"
temp="${TMPDIR:-/tmp}/clautolisp-msys2-toolchain-$$"
mkdir -p "$temp"
trap 'rm -rf "$temp"' EXIT HUP INT TERM

make_compiler () {
  name=$1
  target=$2
  printf '%s\n' '#!/bin/sh' \
    "if [ \"\${1:-}\" = -dumpmachine ]; then printf '%s\\n' '$target'; exit 0; fi" \
    'exit 99' > "$temp/$name"
  chmod +x "$temp/$name"
}

make_compiler msys-cc x86_64-pc-msys
make_compiler mingw-cc x86_64-w64-mingw32

if PATH="$temp:$PATH" MSYSTEM=MSYS CC=msys-cc \
   CLAUTOLISP_BUILD_PROBE_ONLY=1 "$script" >"$temp/reject.log" 2>&1; then
  echo "FAIL: MSYS compiler was accepted" >&2
  exit 1
fi
grep -q "Native Windows SBCL/CCL cannot safely load" "$temp/reject.log"

if PATH="$temp:$PATH" MSYSTEM=UCRT64 CC=mingw-cc \
   CLAUTOLISP_BUILD_PROBE_ONLY=1 "$script" >"$temp/reject-ucrt.log" 2>&1; then
  echo "FAIL: UCRT64 compiler was accepted" >&2
  exit 1
fi
grep -q "must be built from an MSYS2 MINGW64 shell" "$temp/reject-ucrt.log"

PATH="$temp:$PATH" MSYSTEM=MINGW64 CC=mingw-cc \
  CLAUTOLISP_BUILD_PROBE_ONLY=1 "$script" >"$temp/accept.log" 2>&1
grep -q "x86_64-w64-mingw32 (mingw" "$temp/accept.log"

printf '!<arch>\n' > "$temp/libredwg.dll.a"
printf 'MZ' > "$temp/libredwg.dll"
[ "$(od -An -N2 -tx1 "$temp/libredwg.dll" | tr -d ' \r\n')" = 4d5a ]
[ "$(od -An -N2 -tx1 "$temp/libredwg.dll.a" | tr -d ' \r\n')" != 4d5a ]

echo "PASS: MSYS2 native compiler and PE runtime checks"
