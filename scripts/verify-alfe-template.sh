#!/usr/bin/env bash
# verify-alfe-template.sh -- alfe --template against the real CADs
# (issues/open/alfe-template-option.issue, acceptance): a session started
# from a template is a drawing of THAT template -- MEASUREMENT 0 for the
# imperial ones, 1 for the metric ones -- opened as alfe's per-run copy
# (DWGNAME template.dwg).
#
#   scripts/verify-alfe-template.sh [bricscad] [autocad]
#
# Each check prints `TEMPLATE <backend> <name> MEASUREMENT=<m> DWGNAME=<n>
# OK|FAIL'; the exit status is the number of failed checks (0: all passed).
set -u

root="${CI_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
alfe="${ALFE_BIN:-$root/autolisp-front-end/tools/alfe/bin/alfe-sbcl}"
[ -x "$alfe" ] || [ -x "$alfe.exe" ] || {
  echo "alfe not found: $alfe (make -C autolisp-front-end build-alfe-sbcl)" >&2; exit 2; }

backends=("$@")
[ ${#backends[@]} -gt 0 ] || backends=(bricscad autocad)

expr='(princ (strcat "MEASUREMENT=" (itoa (getvar "MEASUREMENT")) " DWGNAME=" (getvar "DWGNAME")))'
failed=0

check() {                               # backend template expected-measurement
  local backend="$1" template="$2" want="$3" args out
  args=(--no-init "--$backend" --timeout 180 --template "$template")
  [ "$backend" = autocad ] && args+=(--mode batch)
  out="$("$alfe" "${args[@]}" -x "$expr" 2>&1 | tr -d '\r')"
  local got
  got="$(printf '%s\n' "$out" | grep -o 'MEASUREMENT=[0-9]* DWGNAME=[^ ]*' | tail -n 1)"
  if [ "$got" = "MEASUREMENT=$want DWGNAME=template.dwg" ]; then
    echo "TEMPLATE $backend $template $got OK"
  else
    echo "TEMPLATE $backend $template ${got:-<no answer>} FAIL (want MEASUREMENT=$want DWGNAME=template.dwg)"
    printf '%s\n' "$out" | tail -n 15 | sed 's/^/    | /'
    failed=$((failed + 1))
  fi
}

for backend in "${backends[@]}"; do
  case "$backend" in
    bricscad) check bricscad Default-imperial.dwt 0
              check bricscad Default-m.dwt 1 ;;
    autocad)  check autocad acad.dwt 0
              check autocad acadiso.dwt 1 ;;
    *) echo "unknown backend: $backend" >&2; exit 2 ;;
  esac
done
exit "$failed"
