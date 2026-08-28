#!/bin/sh
# Assert that the BUILT clautolisp executable contains the compiler.
#
# Nothing else in the corpus runs the program that ships. Every compiler
# test system depends on clautolisp/autolisp-compiler directly -- as a test
# of the compiler must -- so the compiler's hooks are always installed in
# the TEST image, and the tests are true of that image. Whether the shipped
# executable has a compiler in it is a different question, and until 2.0.12
# nobody asked it: clautolisp/clautolisp-tool did not depend on the compiler
# system, so the program was built without one and every SPEED level behaved
# like SPEED 0. Nothing warned, because a NIL compiler hook meaning `run the
# interpreter' is exactly how the runtime is designed to work when the
# compiler is absent.
#
# The probe is CLAL-COMPILE-FILE, because it is the one surface that
# distinguishes `no compiler in this build' from every other failure: it
# signals COMPILER-NOT-AVAILABLE rather than falling back. A timing
# comparison between -O0 and -O3 would test the same thing less reliably.
#
# Usage: tools/clautolisp/tests/shipped-compiler-test.sh [PATH-TO-EXECUTABLE]
# Default executable: tools/clautolisp/bin/clautolisp-sbcl (make build-sbcl).

set -eu

here=$(dirname "$0")
root=$(cd "$here/../../.." && pwd)
exe=${1:-"$root/tools/clautolisp/bin/clautolisp-sbcl"}

if [ ! -x "$exe" ]; then
    echo "shipped-compiler-test: no executable at $exe" >&2
    echo "  build one first: make build-sbcl (or pass a path)" >&2
    exit 2
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/probe.lsp" <<'LSP'
(defun probe-add (a b) (+ a b))
LSP

status=0

# 1. The compiler is present at all: CLAL-COMPILE-FILE must produce an
#    artefact rather than reporting COMPILER-NOT-AVAILABLE.
out=$("$exe" --no-init -x "(princ (clal-compile-file \"$tmp/probe.lsp\"))" 2>&1) || true
case "$out" in
    *"does not include"*|*COMPILER-NOT-AVAILABLE*)
        echo "FAIL: the built executable has NO COMPILER." >&2
        echo "      $out" >&2
        echo "      Check that clautolisp/clautolisp-tool depends on" >&2
        echo "      clautolisp/autolisp-compiler in clautolisp.asd." >&2
        status=1
        ;;
esac

if [ ! -f "$tmp/probe.lap" ]; then
    echo "FAIL: clal-compile-file wrote no $tmp/probe.lap" >&2
    echo "      output was: $out" >&2
    status=1
fi

# 2. The artefact loads and the function it defines runs.
out=$("$exe" --no-init -x "(progn (load \"$tmp/probe.lap\") (princ (probe-add 2 3)))" 2>&1) || true
case "$out" in
    *5*) ;;
    *)
        echo "FAIL: the .lap did not load and run (expected 5)." >&2
        echo "      $out" >&2
        status=1
        ;;
esac

# 3. -O reaches the engine: the qualities the option asked for are the
#    qualities the engine reports.
out=$("$exe" --no-init -O speed=0,debug=1 -x '(princ (clal-optimization))' 2>&1) || true
case "$out" in
    *"(DEBUG 1)"*"(SPEED 0)"*) ;;
    *)
        echo "FAIL: -O speed=0,debug=1 did not reach (clal-optimization)." >&2
        echo "      $out" >&2
        status=1
        ;;
esac

if [ "$status" -eq 0 ]; then
    echo "shipped-compiler-test: OK ($exe has a compiler, .lap round-trips, -O applies)"
fi
exit "$status"
