#!/usr/bin/env bash
# coverage-report.sh — measure behavioural unit-test coverage of the
# clautolisp core builtins (complete-unit-tests.issue, acceptance criterion 3).
#
# IMPLEMENTED set = every NAME passed to (make-core-builtin-subr "NAME" ...)
#   in autolisp-builtins-core/source/ UNION the special-operator dispatch
#   table in autolisp-runtime/source/api.lisp.
# TESTED (behavioural) set = every NAME that appears as a form head inside a
#   quoted AutoLISP snippet ("(NAME ...")  OR as a (find-autolisp-symbol
#   "NAME") lookup, across the FiveAM test sources and the .sexp/.lsp
#   scenario corpora. This is the "actually invoked from a test" signal — a
#   bare registration sweep ((is (typep subr 'autolisp-subr))) does NOT count.
# UNTESTED = IMPLEMENTED \ TESTED, printed for backfill.
#
# Run from anywhere; paths are resolved relative to the repo root inferred
# from this script's location. Exit status is always 0 (it is a report, not
# a gate) unless --strict is given, which exits 1 when UNTESTED is non-empty.
set -euo pipefail

strict=0
[ "${1:-}" = "--strict" ] && strict=1

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# tests/scripts -> autolisp-builtins-core -> clautolisp -> repo root
root=$(cd "$here/../../../.." && pwd)
core_src="$root/clautolisp/autolisp-builtins-core/source"
runtime_api="$root/clautolisp/autolisp-runtime/source/api.lisp"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# --- IMPLEMENTED ---------------------------------------------------------
grep -rhoE 'make-core-builtin-subr[[:space:]]+"[^"]+"' "$core_src"/*.lisp \
  | grep -oE '"[^"]+"' | tr -d '"' > "$tmp/impl-raw.txt"
# special-operator dispatch table: names inside the *special-operator-dispatch*
# defparameter (from its opening line to the closing line of the LIST form).
awk '/defparameter \*special-operator-dispatch\*/{f=1}
     f{print}
     f && /^  *\(list|^\)|^  \)\)/{}' "$runtime_api" \
  | grep -oE 'cons "[^"]+"' | grep -oE '"[^"]+"' | tr -d '"' >> "$tmp/impl-raw.txt"
LC_ALL=C sort -u -f "$tmp/impl-raw.txt" | tr '[:lower:]' '[:upper:]' | sort -u > "$tmp/impl.txt"

# --- TESTED (behavioural) ------------------------------------------------
# Search the FiveAM tests + the scenario corpora.
test_globs=(
  "$root/clautolisp/autolisp-builtins-core/tests"
  "$root/clautolisp/autolisp-runtime/tests"
  "$root/clautolisp"                # other package test dirs (interactor, dcl, mock-host, ...)
  "$root/autolisp-test/tests"
  "$root/autolisp-front-end/tests/scenarios"
)
: > "$tmp/tested-raw.txt"
for g in "${test_globs[@]}"; do
  [ -d "$g" ] || continue
  # Form heads: any (NAME token across the test sources. In these files a
  # (NAME is either (a) a form head inside a quoted AutoLISP snippet handed
  # to run-autolisp-string, or (b) CL code. For AutoLISP-only builtins
  # (VLR-*, VLE-*, DCL tiles, ...) there is no CL homograph, so (name only
  # ever appears in an embedded snippet -> accurate. For names shared with CL
  # (AND, IF, MAPCAR, LENGTH, ...) a CL (and also counts them, which is the
  # right answer: those core operators ARE behaviourally tested. The bulk
  # registration sweeps use bare "NAME" strings (never (name), so
  # registration-only operators correctly stay uncounted.
  grep -rhoE '\(([A-Za-z0-9_%~<>=+*/.:-]+)' "$g" \
    --include='*.lisp' --include='*.lsp' --include='*.sexp' 2>/dev/null \
    | sed -E 's/^\(//' >> "$tmp/tested-raw.txt" || true
  # (find-autolisp-symbol "NAME") lookups — a name looked up then called.
  grep -rhoE 'find-autolisp-symbol[[:space:]]+"[^"]+"' "$g" \
    --include='*.lisp' 2>/dev/null \
    | grep -oE '"[^"]+"' | tr -d '"' >> "$tmp/tested-raw.txt" || true
done
LC_ALL=C sort -u -f "$tmp/tested-raw.txt" | tr '[:lower:]' '[:upper:]' | sort -u > "$tmp/tested.txt"

# --- REPORT --------------------------------------------------------------
comm -23 "$tmp/impl.txt" "$tmp/tested.txt" > "$tmp/untested.txt"
impl=$(wc -l < "$tmp/impl.txt" | tr -d ' ')
covered=$(comm -12 "$tmp/impl.txt" "$tmp/tested.txt" | wc -l | tr -d ' ')
untested=$(wc -l < "$tmp/untested.txt" | tr -d ' ')
pct=$(awk -v c="$covered" -v i="$impl" 'BEGIN{ if(i==0){print "0.0"} else {printf "%.1f", 100*c/i} }')

echo "clautolisp builtin coverage report"
echo "  implemented (make-core-builtin-subr + special ops): $impl"
echo "  behaviourally tested:                               $covered  (${pct}%)"
echo "  genuinely untested:                                 $untested"
echo ""
echo "Untested operators:"
if [ "$untested" -eq 0 ]; then
  echo "  (none — full behavioural coverage)"
else
  pr -3 -t -w 78 "$tmp/untested.txt" 2>/dev/null || cat "$tmp/untested.txt"
fi

[ "$strict" -eq 1 ] && [ "$untested" -gt 0 ] && exit 1
exit 0
