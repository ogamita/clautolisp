#!/bin/bash
# Regression test for scripts/windows-environment.mk.
#
# Over ssh, a Windows host (pfenny) gives the MSYS2 shell no USERPROFILE,
# LOCALAPPDATA or APPDATA. UIOP then resolves its Windows XDG config home to
# the RELATIVE #P"config/", and loading quicklisp/setup.lisp dies with
#   Invalid pathname #P"config/": Expected an absolute pathname
# before a single file is compiled. The fragment supplies the missing values
# (only the missing ones), and every Makefile that runs a Lisp includes it.
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fails=0

mkdir -p "$work/windows-uname" "$work/unix-uname"
printf '#!/bin/sh\necho MINGW64_NT-10.0-26100\n' > "$work/windows-uname/uname"
printf '#!/bin/sh\necho Linux\n' > "$work/unix-uname/uname"
chmod +x "$work/windows-uname/uname" "$work/unix-uname/uname"

cat > "$work/Makefile" <<MK
include $root/scripts/windows-environment.mk
show:
	@echo "USERPROFILE=\$\$USERPROFILE"
	@echo "LOCALAPPDATA=\$\$LOCALAPPDATA"
	@echo "APPDATA=\$\$APPDATA"
MK

# run UNAME-DIR VAR=VALUE... -- the environment is exactly the given variables
# plus a PATH whose uname reports the platform under test.
run() {
    local unamedir=$1; shift
    env -i PATH="$work/$unamedir:$PATH" "$@" make -s -C "$work" show
}

expect() {
    local name=$1 want=$2 got=$3
    if [ "$want" = "$got" ]; then
        echo "ok   $name"
    else
        echo "FAIL $name"
        echo "     want: $want" | tr '\n' ' '; echo
        echo "     got:  $got"  | tr '\n' ' '; echo
        fails=$((fails + 1))
    fi
}

nl='
'
expect "windows over ssh (OS set): profile folders supplied" \
  "USERPROFILE=C:/Users/PPBN02261${nl}LOCALAPPDATA=C:/Users/PPBN02261/AppData/Local${nl}APPDATA=C:/Users/PPBN02261/AppData/Roaming" \
  "$(run unix-uname OS=Windows_NT USER=PPBN02261)"

expect "windows over ssh (no OS, uname MINGW): profile folders supplied" \
  "USERPROFILE=C:/Users/PPBN02261${nl}LOCALAPPDATA=C:/Users/PPBN02261/AppData/Local${nl}APPDATA=C:/Users/PPBN02261/AppData/Roaming" \
  "$(run windows-uname USER=PPBN02261)"

expect "windows, USERNAME preferred over USER" \
  "USERPROFILE=C:/Users/winname${nl}LOCALAPPDATA=C:/Users/winname/AppData/Local${nl}APPDATA=C:/Users/winname/AppData/Roaming" \
  "$(run windows-uname USERNAME=winname USER=msysname)"

# Over ssh USER may be the login form and USERNAME absent: the candidate
# whose profile folder exists wins, HOME's last component included.
mkdir -p "$work/Users/PPBN02261"
expect "windows, domain-style USER: the existing profile from HOME wins" \
  "USERPROFILE=$work/Users/PPBN02261${nl}LOCALAPPDATA=$work/Users/PPBN02261/AppData/Local${nl}APPDATA=$work/Users/PPBN02261/AppData/Roaming" \
  "$(run windows-uname USER=commun+ppbn02261 HOME=/home/PPBN02261 WINDOWS_PROFILES_ROOT="$work/Users")"

expect "windows, only HOME: its last component" \
  "USERPROFILE=C:/Users/PPBN02261${nl}LOCALAPPDATA=C:/Users/PPBN02261/AppData/Local${nl}APPDATA=C:/Users/PPBN02261/AppData/Roaming" \
  "$(run windows-uname HOME=/home/PPBN02261/)"

expect "windows, USERPROFILE present: the others derive from it" \
  "USERPROFILE=D:/Profiles/pp${nl}LOCALAPPDATA=D:/Profiles/pp/AppData/Local${nl}APPDATA=D:/Profiles/pp/AppData/Roaming" \
  "$(run windows-uname USER=PPBN02261 USERPROFILE=D:/Profiles/pp)"

expect "windows, values present: never overridden" \
  "USERPROFILE=C:/Users/pp${nl}LOCALAPPDATA=E:/Local${nl}APPDATA=E:/Roaming" \
  "$(run windows-uname USER=PPBN02261 USERPROFILE=C:/Users/pp LOCALAPPDATA=E:/Local APPDATA=E:/Roaming)"

expect "windows, no user name at all: nothing invented" \
  "USERPROFILE=${nl}LOCALAPPDATA=${nl}APPDATA=" \
  "$(run windows-uname)"

expect "unix: untouched" \
  "USERPROFILE=${nl}LOCALAPPDATA=${nl}APPDATA=" \
  "$(run unix-uname USER=pjb)"

# Every Makefile that starts a Lisp must include the fragment, or a bare
# `make -C <subproject> ...' over ssh fails the same way.
for mk in Makefile clautolisp/Makefile autolisp-front-end/Makefile \
          autolisp-test/Makefile autolisp-benchmark/Makefile; do
    if grep -qE '^include (\.\./)?scripts/windows-environment\.mk$' "$root/$mk"; then
        echo "ok   $mk includes scripts/windows-environment.mk"
    else
        echo "FAIL $mk does not include scripts/windows-environment.mk"
        fails=$((fails + 1))
    fi
done

if [ "$fails" -ne 0 ]; then
    echo "$fails failure(s)"
    exit 1
fi
echo "all windows-environment.mk checks passed"
