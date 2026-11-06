#!/usr/bin/env python3
"""Fusionne les resultats de probe-catalogue.lsp de plusieurs moteurs.

usage: compare.py NOM=fichier ... > tableau.org
Une ligne par cas ; les cas ou les moteurs different sont marques.
"""
import re
import sys

CASE = re.compile(r'^CASE (\d+) (.*?) => (.*) ; ERRNO=(.*)$')
CRASH = re.compile(r'^CASE (\d+) CRASH')


def load(path):
    cases = {}
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


def kind(result):
    """Classe un resultat : ERROR, CRASH, nil, ou valeur."""
    if result == 'CRASH':
        return 'CRASH'
    if result.startswith('(ERROR') or result.startswith('(READ-ERROR'):
        return 'ERROR'
    if result == '(VALUE nil)':
        return 'nil'
    return 'VALUE'


def cell(result, errno):
    text = result.replace('|', '\\vert{}')
    if errno not in ('0', ''):
        text += ' [errno ' + errno + ']'
    return text


def main(args):
    engines = []
    for arg in args:
        name, path = arg.split('=', 1)
        engines.append((name, load(path)))
    indices = sorted(set().union(*[set(c) for _, c in engines]))
    print('| # | expression | ' + ' | '.join(n for n, _ in engines) + ' | divergence |')
    print('|---+---+' + '---+' * len(engines) + '---|')
    for i in indices:
        src = next((c[i][0] for _, c in engines if i in c and c[i][0]), '?')
        kinds = []
        cells = []
        for _, c in engines:
            if i in c:
                _, res, errno = c[i]
                kinds.append(kind(res))
                cells.append(cell(res, errno))
            else:
                kinds.append('absent')
                cells.append('absent')
        present = [k for k in kinds if k != 'absent']
        if len(set(present)) > 1:
            div = 'NATURE (' + '/'.join(kinds) + ')'
        elif len(set(cells)) > 1:
            div = 'valeur ou message'
        else:
            div = ''
        print('| ' + str(i) + ' | =' + src.replace('|', '\\vert{}') + '= | '
              + ' | '.join(cells) + ' | ' + div + ' |')


if __name__ == '__main__':
    main(sys.argv[1:])
