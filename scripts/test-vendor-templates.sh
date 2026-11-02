#!/bin/sh
# scripts/test-vendor-templates.sh -- run the DWG codec's tests on the vendor
# templates (.dwt) installed on THIS machine.
#
# The vendors' templates cannot be committed, so dwg-reads-vendor-templates
# (clautolisp/drawing-dwg/tests/dwg-tests.lisp) reads the ones named by
# CLAUTOLISP_TEST_DWT; this script finds them and sets it. An entry with a
# PRODUCT-UNITS-VERSION key is cross-checked against what the entget-pointers probe
# measured on that very file (cador's *MEASURED-DEFAULT-OBJECTS*): BricsCAD
# V26's en_US templates, which probe:template-defaults:bricscad-*:macos
# opened. AutoCAD 2026's are read and checked, not cross-checked (the measured
# AutoCAD set is 2022's). Needs libredwg built (make build-libraries).
set -e
cd "$(dirname "$0")/.."

entries=""
add() {
  if [ -f "$1" ]; then
    entries="${entries:+$entries;}$1${2:+|$2}"
  fi
}
bricscad="$HOME/Library/Application Support/Bricsys/BricsCAD/V26x64/en_US/Templates"
add "$bricscad/Default-imperial.dwt" bricscad-imperial-26
add "$bricscad/Default-m.dwt" bricscad-metric-26
for d in /Applications/Autodesk/AutoCAD*/AutoCAD*.app/Contents/Resources/UserDataCache/en-us/Template; do
  add "$d/acad.dwt"
  add "$d/acadiso.dwt"
done
if [ -z "$entries" ]; then
  echo "test-vendor-templates: no vendor template found on this machine" >&2
  exit 1
fi
echo "CLAUTOLISP_TEST_DWT=$entries"

cd clautolisp
CLAUTOLISP_TEST_DWT="$entries" sbcl --noinform --no-userinit --non-interactive \
  --eval '(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname)))) (when (probe-file ql) (load ql)))' \
  --eval '(ql:quickload "fiveam" :silent t)' \
  --eval '(require :asdf)' \
  --eval '(asdf:load-asd (merge-pathnames "clautolisp.asd" (uiop:getcwd)))' \
  --eval '(asdf:test-system "clautolisp/drawing-dwg/tests")'
