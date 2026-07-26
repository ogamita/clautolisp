#!/bin/sh
set -eu

script="$(cd "$(dirname "$0")/.." && pwd)/build-libredwg.sh"
temp="${TMPDIR:-/tmp}/clautolisp-compiler-path-$$"
mkdir -p "$temp/toolchain"
trap 'rm -rf "$temp"' EXIT HUP INT TERM

cat > "$temp/toolchain/cc" <<'EOF'
#!/bin/sh
case ":$PATH:" in
  *:"$(cd "$(dirname "$0")" && pwd)":*) ;;
  *) echo "compiler directory missing from PATH" >&2; exit 86 ;;
esac
if [ "${1:-}" = -dumpmachine ]; then
  echo x86_64-w64-mingw32
  exit 0
fi
out=
while [ "$#" -gt 0 ]; do
  if [ "$1" = -o ]; then shift; out=$1; fi
  shift
done
[ -n "$out" ] && : > "$out"
EOF
chmod +x "$temp/toolchain/cc"

PATH="/usr/bin:/bin" CC="$temp/toolchain/cc" \
  CLAUTOLISP_COMPILER_PROBE_ONLY=1 "$script" > "$temp/output" 2>&1
grep -q "compiler runtime directory: $temp/toolchain" "$temp/output"

echo "PASS: compiler runtime directory is added to PATH"
