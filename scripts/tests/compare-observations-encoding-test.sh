#!/bin/sh
# Regression test: compare-observations.py must read a probe log whatever
# encoding the driving shell wrote it in.
#
# The vendor probes failed on real AutoCAD and BricsCAD the first time they
# could run (2026-08-14) with "0 conforms, N missing, (no OBSERVE lines —
# backend unreachable or probe crashed)". The probes were fine: they had
# emitted 101, 27 and 21 OBSERVE lines. Windows PowerShell's Tee-Object
# writes the log as UTF-16LE with a BOM, and the comparator opened it as
# UTF-8 with errors="replace" — which does not raise, it silently yields
# replacement characters, so every OBSERVE line vanished and the harness
# blamed the CAD.
#
# Runs anywhere: the encodings are produced here, not by a shell we need.
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
work=${TMPDIR:-/tmp}/compare-observations-encoding-$$
mkdir -p "$work"
trap 'rm -rf "$work"' EXIT HUP INT TERM

cat >"$work/scenario.sexp" <<'EOF'
(:target "test"
 :expected-observations-default "yes"
 :expected-observations (
   ("a.one" "yes")
   ("b.two" "rejected")
 ))
EOF

# The log the probe would produce, with CRLF as a Windows shell writes it.
printf 'noise before\r\nOBSERVE a.one yes\r\nOBSERVE b.two rejected\r\nnoise after\r\n' \
  > "$work/log.utf8"

python3 - "$work/log.utf8" "$work" <<'EOF'
import sys
src, work = sys.argv[1], sys.argv[2]
text = open(src, encoding="utf-8").read()
for name, encoding, bom in (("log.utf16le", "utf-16-le", b"\xff\xfe"),
                            ("log.utf16be", "utf-16-be", b"\xfe\xff"),
                            ("log.utf8bom", "utf-8-sig", b"")):
    with open(f"{work}/{name}", "wb") as f:
        f.write(bom)
        f.write(text.encode(encoding))
EOF

for variant in log.utf8 log.utf16le log.utf16be log.utf8bom; do
  if ! out=$(python3 "$root/scripts/compare-observations.py" \
               "$work/scenario.sexp" "$work/$variant" 2>&1); then
    echo "FAIL: $variant — comparator exited non-zero:" >&2
    echo "$out" >&2
    exit 1
  fi
  if ! printf '%s\n' "$out" | grep -q "2 conforms"; then
    echo "FAIL: $variant — expected 2 conforms, got:" >&2
    echo "$out" >&2
    exit 1
  fi
  echo "ok: $variant"
done

# And the check must still be able to FAIL: a log with no OBSERVE lines at
# all is a real failure, and its message must name the log before it blames
# the backend.
printf 'nothing to see here\r\n' > "$work/log.empty"
if out=$(python3 "$root/scripts/compare-observations.py" \
           "$work/scenario.sexp" "$work/log.empty" 2>&1); then
  echo "FAIL: a log with no observations must exit non-zero" >&2
  exit 1
fi
if ! printf '%s\n' "$out" | grep -q "no OBSERVE lines parsed"; then
  echo "FAIL: expected the log-first diagnostic, got:" >&2
  echo "$out" >&2
  exit 1
fi
echo "ok: empty log still fails, with a diagnostic that names the log"

echo "compare-observations encoding test passed"
