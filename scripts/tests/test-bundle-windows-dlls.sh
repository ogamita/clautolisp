#!/bin/bash
# Deterministic import-graph regression: recursion, cycles, failure and notices.
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/tools" "$work/system/System32" "$work/packages/share/licenses/fixture" "$work/search" "$work/stage with spaces/bin"
export DLL_TEST_WORK=$work
printf 'fixture license\n' > "$work/packages/share/licenses/fixture/LICENSE"
touch "$work/system/System32/KERNEL32.dll"
cat > "$work/tools/cygpath" <<'SH'
#!/bin/sh
printf '%s\n' "$DLL_TEST_WORK/system"
SH
cat > "$work/tools/objdump" <<'SH'
#!/bin/sh
if [ "$(head -c 2 "$2")" = '#!' ]; then exit 9; fi
cat "$2"
SH
cat > "$work/tools/pacman" <<'SH'
#!/bin/sh
case "$1" in
 -Qqo) echo fixture ;;
 -Qlq) echo "$DLL_TEST_WORK/packages/share/licenses/fixture/LICENSE" ;;
 -Q) echo 'fixture 1.0' ;;
 *) exit 1 ;;
esac
SH
chmod +x "$work/tools/"*
export PATH="$work/tools:$work/search:$PATH"
export OBJDUMP="$work/tools/objdump"
printf ' DLL Name: first.dll\n DLL Name: KERNEL32.dll\n DLL Name: api-ms-win-test.dll\n' > "$work/stage with spaces/bin/program.exe"
printf '#!/bin/sh\nexit 0\n' > "$work/stage with spaces/bin/helper.exe"
printf ' DLL Name: second.dll\n' > "$work/search/first.dll"
printf ' DLL Name: first.dll\n' > "$work/search/second.dll"
bash "$root/scripts/bundle-windows-dlls.sh" "$work/stage with spaces" "$work/stage with spaces/dispatch"
cmp "$work/search/second.dll" "$work/stage with spaces/bin/second.dll"
cmp "$work/search/second.dll" "$work/stage with spaces/dispatch/second.dll"
cmp "$work/packages/share/licenses/fixture/LICENSE" "$work/stage with spaces/share/doc/clautolisp/runtime-licenses/fixture/LICENSE"
if [[ -f "$work/stage with spaces/bin/KERNEL32.dll" ]]; then exit 1; fi
printf ' DLL Name: missing-required.dll\n' > "$work/stage with spaces/bin/program.exe"
if bash "$root/scripts/bundle-windows-dlls.sh" "$work/stage with spaces" > "$work/error" 2>&1; then
    echo 'FAIL: unresolved import accepted'; exit 1
fi
grep -q 'Missing runtime DLL:.*missing-required.dll' "$work/error"
printf ' DLL Name: msys-2.0.dll\n' > "$work/stage with spaces/bin/program.exe"
if bash "$root/scripts/bundle-windows-dlls.sh" "$work/stage with spaces" > "$work/error" 2>&1; then
    cat "$work/error"; echo 'FAIL: MSYS runtime accepted'; exit 1
fi
grep -q 'Non-native Windows dependency' "$work/error"
printf ' DLL Name: unlicensed.dll\n' > "$work/stage with spaces/bin/program.exe"
printf '\n' > "$work/search/unlicensed.dll"
rm "$work/packages/share/licenses/fixture/LICENSE"
if bash "$root/scripts/bundle-windows-dlls.sh" "$work/stage with spaces" > "$work/error" 2>&1; then
    echo 'FAIL: missing license accepted'; exit 1
fi
grep -q 'No license files for fixture' "$work/error"
if OBJDUMP=false bash "$root/scripts/bundle-windows-dlls.sh" "$work/stage with spaces" > "$work/error" 2>&1; then
    echo 'FAIL: failed PE inspection accepted'; exit 1
fi
echo 'OK recursive DLL closure, cycles, licenses, missing imports, inspection failures and MSYS rejection'
