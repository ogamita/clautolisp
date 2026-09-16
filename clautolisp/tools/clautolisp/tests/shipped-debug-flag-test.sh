#!/bin/sh
# Assert that the BUILT executable actually receives -d / --debug.
#
# The CCL kernel removes its own options from argv before any Lisp code
# runs, and -d / --debug are among them. So `clautolisp-ccl -d' and
# `alfe-ccl --debug' ran at the default verbosity and nothing noticed,
# because the test images never go through that kernel start-up
# (issues/closed/alfe-ccl-executable-drops-log-output.issue). The fix
# lives in the shared image generator
# (autolisp-reader/tools/read-autolisp/generate.lisp), so only a built
# executable can show it working.
#
# What is checked: each debug flag makes the program write MORE to stderr
# than the same run without it.
#
# Usage: shipped-debug-flag-test.sh EXECUTABLE [ARGUMENT...]
#   The ARGUMENTs are one run's command line. It should write
#   something extra to stderr under --debug, e.g.
#     clautolisp-ccl -x '(/ 1 0)'           (a CL backtrace is added)
#     alfe-ccl --clautolisp -x '(princ 1)'  (alfe[debug] lines)

set -u

if [ $# -lt 1 ] || [ ! -x "$1" ]; then
    echo "shipped-debug-flag-test: no executable at ${1:-<none>}" >&2
    echo "usage: $0 EXECUTABLE [ARGUMENT...]" >&2
    exit 2
fi
exe=$1
shift

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

stderr_lines() {
    "$exe" "$@" > /dev/null 2> "$tmp/err" < /dev/null
    wc -l < "$tmp/err" | tr -d ' '
}

base=$(stderr_lines "$@")
status=0
for flag in -d --debug; do
    n=$(stderr_lines "$flag" "$@")
    if [ "$n" -gt "$base" ]; then
        echo "ok   $flag: $n stderr lines (without: $base)"
    else
        echo "FAIL $flag: $n stderr lines, no more than without it ($base)." >&2
        echo "     The flag never reached the program." >&2
        status=1
    fi
done
exit $status
