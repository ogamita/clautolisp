#!/usr/bin/env python3
"""Assert that a scheduled pipeline can contain ONLY the nightly sweep.

ci-native-child-pipeline-creation-fails.issue.

The nightly schedule exists for one job: sweep:stale-child-pipelines,
which cancels child pipelines that have gone stale. Everything else must
be `never' on a schedule — and `never', not `manual', is the requirement:
a pipeline whose remaining jobs are manual STAYS ACTIVE, and its jobs
keep counting against the project's jobs-in-active-pipelines cap. A
nightly full of manual jobs would therefore BE the leak it was added to
drain, one pipeline per night.

That is not hypothetical. Reaching that cap on 2026-08-19 made every
pipeline in the project red with zero failed jobs, because no child
pipeline could be created any more.

This is a check rather than a comment because the failure mode is
silent and delayed: a job added later without the exclusion costs
nothing visible on the day, and shows up weeks afterwards as a project
that cannot start a pipeline.

    python3 scripts/check-nightly-sweep-isolation.py
    make check-nightly-sweep-isolation
"""
import re
import sys

text = open('.gitlab-ci.yml', encoding='utf-8').read()
lines = text.split('\n')
blocks, order, name, buf = {}, [], None, []
for l in lines:
    if re.match(r'^[A-Za-z_.][A-Za-z0-9:_.-]*:\s*$', l):
        if name:
            blocks[name] = '\n'.join(buf)
            order.append(name)
        name, buf = l.rstrip()[:-1], []
    elif name:
        buf.append(l)
if name:
    blocks[name] = '\n'.join(buf)
    order.append(name)


def excluded(n, seen=()):
    b = blocks.get(n, '')
    if '*not-on-schedule' in b:
        return True
    m = re.search(r'^\s*extends:\s*(.+)$', b, re.M)
    if m and n not in seen:
        parents = [p.strip(' []') for p in m.group(1).split(',')]
        return any(excluded(p, seen + (n,)) for p in parents if p)
    return False


if 'sweep:stale-child-pipelines' not in order:
    print("FAIL: sweep:stale-child-pipelines is gone -- the nightly schedule "
          "would run nothing, and the leak it drains would come back "
          "unnoticed.")
    sys.exit(1)

real = [n for n in order
        if not n.startswith('.')
        and n not in ('workflow', 'stages', 'variables', 'default', 'include')]
leaking = [n for n in real
           if n != 'sweep:stale-child-pipelines' and not excluded(n)]

print('jobs: %d' % len(real))
if leaking:
    print('FAIL: %d job(s) would still appear in a scheduled pipeline:'
          % len(leaking))
    for n in leaking:
        print('   ', n)
    sys.exit(1)
print('ok  a scheduled pipeline contains only sweep:stale-child-pipelines')
