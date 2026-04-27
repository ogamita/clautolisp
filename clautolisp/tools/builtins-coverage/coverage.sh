#!/bin/bash
# Builds a coverage report comparing core-builtins (registered in
# autolisp-builtins-core/source/api.lisp) against the function
# entries in the AutoLISP/Visual LISP specification draft.
#
# Output: Markdown table on stdout, with a per-category roll-up
# at the top and a per-function status line below.
set -euo pipefail
SELF=$(cd "$(dirname "$0")" && pwd)
# tools/builtins-coverage -> clautolisp/ -> repo root.
ROOT=$(cd "$SELF/../.." && pwd)
REPO=$(cd "$ROOT/.." && pwd)
SPEC="$REPO/autolisp-spec/documentation/autolisp-visual-lisp-specification-draft.org"
API="$ROOT/autolisp-builtins-core/source/api.lisp"

if [[ ! -r "$SPEC" ]]; then
  echo "spec not found: $SPEC" >&2; exit 1
fi
if [[ ! -r "$API" ]]; then
  echo "api not found: $API" >&2; exit 1
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Spec function entries (host-aware AND host-independent).
grep -E '^\*\* +(Function Entry|Subr Entry): ' "$SPEC" \
  | sed 's/^\*\* [^:]*: //' \
  | tr 'A-Z' 'a-z' \
  | sort -u > "$TMP/spec.txt"

# Registered builtins in core-builtins.
grep -oE 'make-core-builtin-subr "[^"]+"' "$API" \
  | sed 's/make-core-builtin-subr //' \
  | tr -d '"' \
  | tr 'A-Z' 'a-z' \
  | sort -u > "$TMP/impl.txt"

# Categorise via simple prefix-based bucketing. Vendor-extension
# prefixes (acet-, dos_, vle-, vlax-curve-) and host-bound
# families (grdraw, regapp, etc.) are listed separately so the
# "core" bucket reflects host-independent coverage.
classify() {
  local fn="$1"
  case "$fn" in
    acet-*|acet::*) echo "ext-express" ;;
    dos_*) echo "ext-doslib" ;;
    vle-*|vle_*) echo "ext-vle" ;;
    layerstate-*|vl-layerstates-*) echo "host-layerstate" ;;
    vlax-curve-*) echo "ext-curve" ;;
    vla-*|vlax-*|_vlax-*) echo "host-com" ;;
    vlr-*) echo "host-reactor" ;;
    grarc|grclear|grdraw|grfill|grread|grtext|grvecs|redraw|redraw_dialog|graphscr|tablet|textpage|textscr|setview|vports) echo "host-graphics" ;;
    entsel|nentsel|nentselp|getfiled|alert|init_dialog|*dlg|acad_colordlg|acad_helpdlg|acad_truecolordlg|acad_truecolorcli|inspector|vl-hidepromptmenu|vl-showpromptmenu|showhtmlmodalwindow|dlg-sysvars|doc_clipboard) echo "host-ui" ;;
    getcfg|setcfg|getenv|setenv|menucmd|menugroup|namedobjdict|regapp|initcommandversion|initdia|getpid|get_diskserialid|*registry-*) echo "host-config" ;;
    arx|arxload|arxunload|ads|autoarxload|vl-arx-import|vl-load-com|vl-load-reactors|vl-load-all|vl-init|vl-vbaload|vl-vbarun|vl-acad-defun|vl-acad-undefun|vl-list-loaded-lisp|vl-list-loaded-vlx|vl-vlx-loaded-p|vl-unload-vlx|vl-list-exported-functions|vl-get-resource|'lisp$'*|'bcad$'*|vlisp-*|vmon|ssnamex|xdroom|xdsize|acad_strlsort) echo "host-modules" ;;
    dictadd|dictnext|dictobjname|dictremove|dictrename|dictsearch) echo "host-dict" ;;
    *push-error*|*pop-error*|*-dbmod) echo "host-errstack" ;;
    bpoly|expand|gc|mem|alloc|getcname|getpropertyvalue|setpropertyvalue|ispropertyreadonly|ispropertyvalid|listallproperties|dumpallproperties|layoutlist|get_attr|osnap|fnsplitl|command-s|cvunit|trans|textbox|sleep|until|ver|help|startapp|nentselp|acdimenableupdate|vl-getcurrentdir|vl-getstartupdir|vl-setcurrentdir|vl-cmdf|vl-enable-user-cancel|vl-getgeomextents|vl-rmdir|vl-local-undo-*|vl-vplayer-*|vl-subent-*|vl-vector-project-pointtoentity|vl-annotative-*) echo "host-misc" ;;
    *) echo "core" ;;
  esac
}

# macOS default bash is 3.2 — no associative arrays. Use a flat
# table file instead: each line is "<category>\t<status>" where
# status is "done" or "todo".
TABLE="$TMP/table.tsv"
: > "$TABLE"
while read -r fn; do
  cat=$(classify "$fn")
  if grep -qxF "$fn" "$TMP/impl.txt"; then
    printf '%s\tdone\n' "$cat" >> "$TABLE"
  else
    printf '%s\ttodo\n' "$cat" >> "$TABLE"
  fi
done < "$TMP/spec.txt"

bucket_total() {
  awk -F'\t' -v c="$1" '$1==c{n++}END{print n+0}' "$TABLE"
}
bucket_done() {
  awk -F'\t' -v c="$1" '$1==c && $2=="done"{n++}END{print n+0}' "$TABLE"
}

# Header.
echo "# clautolisp builtins coverage report"
echo
echo "Generated against $(basename "$SPEC")"
echo
echo "## Per-category summary"
echo
echo "| Category | Implemented | Spec-listed | Coverage |"
echo "|---|---:|---:|---:|"
for cat in core host-com host-reactor host-graphics host-ui host-config host-modules host-layerstate host-dict host-errstack host-misc ext-curve ext-express ext-doslib ext-vle; do
  done_n=$(bucket_done "$cat")
  total_n=$(bucket_total "$cat")
  if [[ $total_n -eq 0 ]]; then continue; fi
  pct=$(( 100 * done_n / total_n ))
  printf '| %s | %d | %d | %d%% |\n' "$cat" "$done_n" "$total_n" "$pct"
done

# Bonus implementations (registered but not in the spec corpus —
# these are typically aliases or our own helpers).
echo
echo "## Implemented but not in the spec corpus"
echo
comm -23 "$TMP/impl.txt" "$TMP/spec.txt" | sed 's/^/- `/;s/$/`/'

# Per-function detail, core bucket only — the host-bound and
# extension buckets are tracked in their own phases.
echo
echo "## Core-bucket gaps (spec functions not yet registered)"
echo
while read -r fn; do
  cat=$(classify "$fn")
  [[ "$cat" == "core" ]] || continue
  if ! grep -qxF "$fn" "$TMP/impl.txt"; then
    echo "- \`$fn\`"
  fi
done < "$TMP/spec.txt"
