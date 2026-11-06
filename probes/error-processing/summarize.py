#!/usr/bin/env python3
"""Build the org tables of error-processing-per-dialect.issue from the
catalogue logs (probe-error-catalogue.lsp).

usage: summarize.py OUT-DIR NAME=log[,log...] ...
  The first two engines are the two vendors compared (AutoCAD, BricsCAD);
  the following ones are extra columns (BricsCAD V25, clautolisp dialects).
  Several logs for one engine are read in order: a later log overrides an
  earlier one (re-runs of a subset of the cases).
Writes OUT-DIR/catalogue-comparison.org (every case) and
OUT-DIR/catalogue-divergences.org (only the cases where the vendors differ,
classified).
"""
import os
import re
import sys

CASE = re.compile(r'^CASE (\d+) (.*?) => (.*) ; ERRNO=(.*)$')
CRASH = re.compile(r'^CASE (\d+) CRASH')


def load(paths):
    cases = {}
    for path in paths:
        with open(path, 'rb') as f:
            for raw in f:
                line = raw.decode('utf-8', errors='replace').rstrip('\r\n')
                m = CRASH.match(line)
                if m:
                    cases[int(m.group(1))] = (None, 'CRASH', '')
                    continue
                m = CASE.match(line)
                if m:
                    cases[int(m.group(1))] = (m.group(2), m.group(3), m.group(4))
    return cases


def kind(res):
    if res is None:
        return 'absent'
    if res == 'CRASH':
        return 'CRASH'
    if res.startswith('(ERROR') or res.startswith('(READ-ERROR'):
        return 'ERROR'
    if res in ('(VALUE nil)', '(VALUE NIL)'):
        return 'nil'
    return 'value'


def esc(text):
    return text.replace('|', '\\vert{}')


def cell(entry, width=70):
    if entry is None:
        return '-'
    _, res, errno = entry
    text = res if len(res) <= width else res[:width] + '…'
    if errno not in ('0', ''):
        text += ' [errno ' + errno + ']'
    return '~' + esc(text) + '~' if text else ''


def main(argv):
    out = argv[0]
    engines = []
    for arg in argv[1:]:
        name, paths = arg.split('=', 1)
        engines.append((name, load(paths.split(','))))
    indices = sorted(set().union(*[set(c) for _, c in engines]))
    names = [n for n, _ in engines]
    header = '| # | expression | ' + ' | '.join(names) + ' |'
    rule = '|---+---+' + '---+' * (len(names) - 1) + '---|'
    rows_all, rows_div = [], []
    for i in indices:
        src = next((c[i][0] for _, c in engines if i in c and c[i][0]), '?')
        entries = [c.get(i) for _, c in engines]
        row = ('| ' + str(i) + ' | =' + esc(src) + '= | '
               + ' | '.join(cell(e) for e in entries) + ' |')
        rows_all.append(row)
        a, b = entries[0], entries[1]
        if a is None or b is None:
            continue
        ka, kb = kind(a[1]), kind(b[1])
        if ka != kb:
            rows_div.append((ka + ' / ' + kb, row))
        elif a[1] != b[1] and ka == 'value':
            rows_div.append(('value / value', row))
        elif a[1] != b[1] and ka == 'ERROR':
            rows_div.append(('message only', row))
    with open(os.path.join(out, 'catalogue-comparison.org'), 'w') as f:
        f.write('# -*- mode:org; coding:utf-8 -*-\n')
        f.write('#+TITLE: error-processing catalogue, every case\n\n')
        f.write(header + '\n' + rule + '\n' + '\n'.join(rows_all) + '\n')
    order = ['CRASH', 'ERROR / value', 'value / ERROR', 'ERROR / nil', 'nil / ERROR',
             'nil / value', 'value / nil', 'value / value', 'message only']
    def rank(k):
        for n, o in enumerate(order):
            if o in k:
                return n
        return len(order)
    with open(os.path.join(out, 'catalogue-divergences.org'), 'w') as f:
        f.write('# -*- mode:org; coding:utf-8 -*-\n')
        f.write('#+TITLE: error-processing catalogue, cases where '
                + names[0] + ' and ' + names[1] + ' differ\n\n')
        for k in sorted(set(k for k, _ in rows_div), key=rank):
            sel = [r for kk, r in rows_div if kk == k]
            f.write('* ' + names[0] + ' / ' + names[1] + ' = ' + k
                    + ' (' + str(len(sel)) + ')\n\n')
            f.write(header + '\n' + rule + '\n' + '\n'.join(sel) + '\n\n')
    counts = {}
    for k, _ in rows_div:
        counts[k] = counts.get(k, 0) + 1
    print(len(indices), 'cases;', len(rows_div), 'vendor divergences:', counts)


if __name__ == '__main__':
    main(sys.argv[1:])
