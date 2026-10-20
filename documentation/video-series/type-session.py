#!/usr/bin/env python3
"""Drive an interactive program in a real pty, typing like a human.

usage: type-session.py SESSION.json

SESSION.json: {"cmd": [...], "cwd": DIR (relative to SESSION.json), "prompt": REGEX, "rows": N, "cols": N,
               "steps": [STEP...]}
STEP: {"type": TEXT, "expect": "prompt"|"eof"|REGEX, "before": s, "after": s}
      {"pause": s}
      {"key": "\u0004"}  -- raw keys, no newline, no wait

Everything the child prints is copied to our stdout as soon as it arrives,
so an enclosing `asciinema rec` sees each echoed keystroke with its timing.
"""
import json, os, random, re, sys, time
import pexpect

spec = json.load(open(sys.argv[1]))
# "cwd" is relative to the session file.
cwd = os.path.join(os.path.dirname(os.path.abspath(sys.argv[1])), spec.get("cwd", "."))
random.seed(42)
child = pexpect.spawn(spec["cmd"][0], spec["cmd"][1:], cwd=cwd,
                      encoding="utf-8",
                      dimensions=(spec.get("rows", 24), spec.get("cols", 90)))
pending = ""          # output not yet matched against an expectation


def pump(seconds):
    """Copy child output to stdout for SECONDS; return False at EOF."""
    global pending
    end = time.monotonic() + seconds
    while True:
        left = end - time.monotonic()
        if left <= 0:
            return True
        try:
            data = child.read_nonblocking(4096, timeout=min(left, 0.02))
        except pexpect.TIMEOUT:
            continue
        except pexpect.EOF:
            return False
        sys.stdout.write(data)
        sys.stdout.flush()
        pending += data


def wait_for(regex, timeout=60):
    global pending
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        m = regex and re.search(regex, pending)
        if m:
            pending = pending[m.end():]
            return
        if not pump(0.05):
            if regex is None:
                return
            raise SystemExit(f"EOF while waiting for {regex!r}")
    raise SystemExit(f"timeout waiting for {regex!r}; got {pending[-200:]!r}")


prompt = spec["prompt"]
wait_for(prompt)
for step in spec["steps"]:
    if "pause" in step:
        pump(step["pause"])
        continue
    if "key" in step:
        child.send(step["key"])
        pump(step.get("after", 1.0))
        continue
    pump(step.get("before", 0.8))
    pending = ""
    for ch in step["type"]:
        child.send(ch)
        pump(random.uniform(0.04, 0.11))
    pump(0.25)
    pending = ""
    child.send("\r")
    exp = step.get("expect", "prompt")
    wait_for(None if exp == "eof" else prompt if exp == "prompt" else exp)
    pump(step.get("after", 1.2))
child.close()
