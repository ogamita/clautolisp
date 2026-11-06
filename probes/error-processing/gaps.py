#!/usr/bin/env python3
"""List the catalogue cases where a clautolisp dialect does not behave like
the vendor it models: one returns, the other signals, returns nil, or dies.

usage: gaps.py OUT.org LABEL VENDOR-LOG[,LOG...] CLAUTOLISP-LOG[,LOG...] [LABEL V C ...]
"""
import re
import sys

CASE = re.compile(r'^CASE (\d+) (.*?) => (.*) ; ERRNO=(.*)$')
CRASH = re.compile(r'^CASE (\d+) CRASH')


def load(paths):
    d = {}
    for p in paths.split(','):
        for raw in open(p, 'rb'):
            line = raw.decode('utf-8', 'replace').rstrip('\r\n')
            m = CRASH.match(line)
            if m:
                d[int(m.group(1))] = (None, 'CRASH')
                continue
            m = CASE.match(line)
            if m:
                d[int(m.group(1))] = (m.group(2), m.group(3))
    return d


def kind(r):
    if r == 'CRASH':
        return 'CRASH'
    if 'WRITE-LINE-ERROR' in r or 'TYPE-ERROR' in r:
        return 'probe-failure'
    if r.startswith('(ERROR') or r.startswith('(READ-ERROR'):
        return 'ERROR'
    if r in ('(VALUE nil)', '(VALUE NIL)'):
        return 'nil'
    return 'value'


def esc(t, n=80):
    t = t if len(t) <= n else t[:n] + '…'
    return t.replace('|', '\\vert{}')


def main(argv):
    out, rest = argv[0], argv[1:]
    with open(out, 'w') as f:
        f.write('# -*- mode:org; coding:utf-8 -*-\n')
        f.write('#+TITLE: catalogue cases where clautolisp differs from the vendor its dialect models\n\n')
        while rest:
            label, vlog, clog, rest = rest[0], rest[1], rest[2], rest[3:]
            v, c = load(vlog), load(clog)
            rows = []
            for i in sorted(v):
                if i in c and kind(v[i][1]) != kind(c[i][1]):
                    rows.append('| %d | =%s= | %s / %s | ~%s~ | ~%s~ |' % (
                        i, esc(v[i][0] or c[i][0] or '?', 60), kind(v[i][1]), kind(c[i][1]),
                        esc(v[i][1]), esc(c[i][1])))
            f.write('* %s (%d)\n\n| # | expression | vendor / clautolisp | vendor | clautolisp |\n'
                    '|---+---+---+---+---|\n%s\n\n' % (label, len(rows), '\n'.join(rows)))
            print(label, len(rows))


if __name__ == '__main__':
    main(sys.argv[1:])
