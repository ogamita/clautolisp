#!/bin/bash
# usage (MSYS2 bash on the Windows CAD host):
#   run-windows.sh ENGINE OUTDIR START CMD...     ENGINE = bricscad | accoreconsole
# Generates OUTDIR/run.scr (load both probes, then one script line per CMD)
# and runs the engine on it.  Pitfalls met on 2026-11-03, all handled here:
#  - an ssh session lacks most of the user's Windows environment (USERPROFILE,
#    TEMP, APPDATA, and the FlexLM licence variables): accoreconsole then fails
#    with "Can't redirect stdout" or segfaults.  We import HKLM + HKCU
#    "Environment" from the registry.
#  - MSYS2 rewrites /i /s /b /Automation into paths: MSYS2_ARG_CONV_EXCL='*'.
#  - CMDACTIVE has bit 4 set while a script runs.
eng=$1; out=$2; start=$3; shift 3
here=$(cd "$(dirname "$0")" && pwd -W)
mkdir -p "$out"; O=$(cd "$out" && pwd -W)
import_env () {   # import REG_SZ / REG_EXPAND_SZ values of one registry key
  reg query "$1" 2>/dev/null | tr -d '\r' | while read -r name type value; do
    case $type in REG_SZ|REG_EXPAND_SZ) ;; *) continue;; esac
    case $name in Path|PATH|USERNAME|TEMP|TMP) continue;; esac
    printf '%s=%s\n' "$name" "$value"
  done
}
uprof=$(cygpath -w "$(cygpath -H)/$(id -un | sed 's/.*+//')")
envv=( "USERPROFILE=$uprof" "APPDATA=$uprof\\AppData\\Roaming" "LOCALAPPDATA=$uprof\\AppData\\Local"
       "TEMP=$uprof\\AppData\\Local\\Temp" "TMP=$uprof\\AppData\\Local\\Temp"
       "USERNAME=$(id -un | sed 's/.*+//')" "ProgramData=C:\\ProgramData" "ALLUSERSPROFILE=C:\\ProgramData"
       "ProgramFiles(x86)=C:\\Program Files (x86)" "CommonProgramFiles=C:\\Program Files\\Common Files" )
while IFS= read -r kv; do envv+=( "$kv" ); done < <(import_env 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'; import_env 'HKCU\Environment')
export MSYS2_ARG_CONV_EXCL='*'
{
  echo "(setq m (open \"$O/scr-started.txt\" \"w\"))"
  echo "(close m)"
  echo "(if (getvar \"SECURELOAD\") (vl-catch-all-apply 'setvar '(\"SECURELOAD\" 0)))"
  echo "(setq *probe-dir* \"${O//\\//}\" *probe-start* $start)"
  echo "(load \"${here//\\//}/probe-error-handler.lsp\")"
  echo "(load \"${here//\\//}/probe-error-catalogue.lsp\")"
  for c in "$@"; do echo "$c"; done
  echo "(progn (setq m (open \"$O/scr-done.txt\" \"w\")) (close m))"
  echo "._QUIT _N"
} > "$out/run.scr"
case $eng in
  bricscad)      exe=${BRICSCAD_EXE:-$(ls -d "/c/Program Files/Bricsys/"*/bricscad.exe | tail -n 1)}
                 env "${envv[@]}" "$exe" /Automation /b "$(cygpath -w "$out/run.scr")" > "$out/stdout.txt" 2>&1 & ;;
  accoreconsole) exe=${AUTOCAD_ACCORECONSOLE:-$(ls -d "/c/Program Files/Autodesk/AutoCAD "*/accoreconsole.exe | tail -n 1)}
                 [ -f "$out/empty.dwg" ] || { echo "put an empty drawing at $out/empty.dwg (alfe stages one)"; exit 2; }
                 env "${envv[@]}" "$exe" /i "$(cygpath -w "$out/empty.dwg")" /s "$(cygpath -w "$out/run.scr")" > "$out/stdout.txt" 2>&1 & ;;
esac
pid=$!
for i in $(seq 1 ${PROBE_TIMEOUT:-240}); do sleep 1; kill -0 $pid 2>/dev/null || break; [ -f "$out/scr-done.txt" ] && { sleep 3; break; }; done
kill -0 $pid 2>/dev/null && { kill $pid; sleep 3; }
exit 0
