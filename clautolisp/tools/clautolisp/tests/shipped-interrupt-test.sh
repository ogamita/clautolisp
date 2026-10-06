#!/bin/sh
# Assert that the BUILT executable applies --on-interrupt to a real Control-C
# (SIGINT), with no host-Lisp break loop in sight.
#
# Before clautolisp 2.2.218 only the SBCL build had a SIGINT handler: the CCL
# build dropped the user into CCL's own `1 >' break loop under every policy
# (debugger-public-interface-and-on-error.issue). The in-process FiveAM test
# (interrupt-tests.lisp) shows the handler path; this one shows the program
# that ships, whose start-up the test image never goes through.
#
# Each case runs an endless AutoLISP loop, sends SIGINT after a pause, and
# checks the outcome:
#   quit    exits 130 and says "interrupted";
#   ignore  keeps running (it is then killed) and never breaks;
#   debug   breaks into aldo ("interrupt (Control-C)"); `q' (piped in) aborts
#           the program, which exits 0 without running the next action;
#   debug + a second SIGINT while the debugger waits exits 130 at once.
#
# Usage: shipped-interrupt-test.sh EXECUTABLE

set -u

if [ $# -ne 1 ] || [ ! -x "$1" ]; then
    echo "shipped-interrupt-test: no executable at ${1:-<none>}" >&2
    echo "usage: $0 EXECUTABLE" >&2
    exit 2
fi
exe=$1

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
loop='(progn (princ "start") (terpri) (setq i 0) (while t (setq i (1+ i))))'
status=0

ok()   { echo "ok   $*"; }
fail() { echo "FAIL $*" >&2; status=1; }

# run POLICY INPUT SIGNALS: start the loop under --on-interrupt POLICY with
# INPUT on stdin, send SIGNALS SIGINTs 3 s apart, then report the exit status
# in $rc (KILLED when it had to be killed) and the output in $tmp/out.
run() {
    policy=$1 input=$2 signals=$3
    printf '%s' "$input" > "$tmp/in"
    "$exe" --no-init --on-interrupt "$policy" -x "$loop" -x '(princ "after")' \
        < "$tmp/in" > "$tmp/out" 2>&1 &
    pid=$!
    sleep 3
    n=0
    while [ "$n" -lt "$signals" ]; do
        kill -INT "$pid" 2>/dev/null
        sleep 3
        n=$((n + 1))
    done
    if kill -0 "$pid" 2>/dev/null; then
        kill -KILL "$pid" 2>/dev/null
        wait "$pid" 2>/dev/null
        rc=KILLED
    else
        wait "$pid"
        rc=$?
    fi
}

no_break_loop() {
    if grep -q 'Break: interrupt signal\|^1 >\|interactive interrupt' "$tmp/out"; then
        fail "$1: the host Lisp's break loop showed up:"; cat "$tmp/out" >&2
    fi
}

run quit '' 1
if [ "$rc" = 130 ] && grep -q 'interrupted' "$tmp/out"; then ok "quit: exit 130"
else fail "quit: exit $rc"; cat "$tmp/out" >&2; fi
no_break_loop quit

run ignore '' 1
if [ "$rc" = KILLED ] && ! grep -q 'interrupted' "$tmp/out"; then ok "ignore: kept running"
else fail "ignore: exit $rc"; cat "$tmp/out" >&2; fi
no_break_loop ignore

run debug 'q
' 1
if [ "$rc" = 0 ] && grep -q 'interrupt (Control-C)' "$tmp/out" && ! grep -q 'after' "$tmp/out"
then ok "debug: broke into aldo, q aborted (exit 0)"
else fail "debug: exit $rc"; cat "$tmp/out" >&2; fi
no_break_loop debug

# A second Control-C while the debugger waits for input: stdin stays open
# (a FIFO nobody writes to) so the debugger is still up when it arrives.
mkfifo "$tmp/fifo"
sleep 30 > "$tmp/fifo" &
holder=$!
"$exe" --no-init --on-interrupt debug -x "$loop" < "$tmp/fifo" > "$tmp/out" 2>&1 &
pid=$!
sleep 3; kill -INT "$pid" 2>/dev/null
sleep 3; kill -INT "$pid" 2>/dev/null
sleep 3
if kill -0 "$pid" 2>/dev/null; then
    kill -KILL "$pid" 2>/dev/null; wait "$pid" 2>/dev/null; rc=KILLED
else
    wait "$pid"; rc=$?
fi
kill "$holder" 2>/dev/null
if [ "$rc" = 130 ] && grep -q 'second interrupt' "$tmp/out"; then ok "debug: second Control-C exits 130"
else fail "debug, second Control-C: exit $rc"; cat "$tmp/out" >&2; fi
no_break_loop "second Control-C"

exit $status
