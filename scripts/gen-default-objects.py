#!/usr/bin/env python3
"""Generate clautolisp/cador/source/default-objects.lisp from entget-pointers
probe results (section 12: the default objects of a new drawing).

usage: gen-default-objects.py PRODUCT=RESULTS.sexp ... > default-objects.lisp
  PRODUCT is autocad or bricscad; RESULTS.sexp a probe-results/<product>/<os>/
  <stamp>/results.sexp of the entget-pointers probe. The file's encoding
  follows the CAD's platform (BricsCAD on macOS writes MacRoman, the Windows
  CADs cp1252); it is detected.

Section 12 dumps each object as CODE=VALUE (AutoLISP prin1 values), a pointer
as <TYPE name> -- never a handle. The generated data keeps, per product, the
NOD's entries in order, each object's TYPE and BODY: its groups without the
header (0, 5, the {ACAD_REACTORS} / {ACAD_XDICTIONARY} groups, the owner 330)
nor, for a dictionary, its 3 / 350 entries (they are rebuilt from the
members). A pointer becomes (CODE :REF TYPE NAME), resolved by cador when it
makes the objects (a table record by name, else a made object by type and
key); one it cannot resolve is left out.
"""
import re
import sys

HEADER_CODES = {0, 5}


def decode(raw):
    for enc in ('utf-8', 'cp1252'):
        try:
            text = raw.decode(enc)
        except UnicodeDecodeError:
            continue
        # BricsCAD on macOS writes MacRoman: 0x8E (e acute) decodes as cp1252 Z-caron.
        if enc == 'cp1252' and 'Ž' in text:
            return raw.decode('mac_roman')
        return text
    return raw.decode('latin-1')


def results(path):
    """{case: value} of the ok probe-result lines of RESULTS.sexp."""
    out = {}
    for line in decode(open(path, 'rb').read()).replace('\r', '').split('\n'):
        m = re.match(r'\(\(KIND \. "probe-result"\) \(SUITE \. "entget-pointers"\) '
                     r'\(CASE \. "((?:[^"\\]|\\.)*)"\) \(STATUS \. "ok"\) '
                     r'\(VALUE \. "((?:[^"\\]|\\.)*)"\)\)$', line)
        if m:
            out[unescape(m.group(1))] = unescape(m.group(2))
    return out


def unescape(s):
    return re.sub(r'\\(.)', lambda m: m.group(1), s)


def parse_dump(text):
    """[(code, value)] of a CODE=VALUE dump; a value is ('str', s), ('num', x),
    ('point', [x...]) or ('ref', type, name)."""
    pairs, i, n = [], 0, len(text)
    while i < n:
        while i < n and text[i] == ' ':
            i += 1
        if i >= n:
            break
        m = re.compile(r'(-?\d+)=').match(text, i)
        if not m:
            raise ValueError('bad dump at %d: %r' % (i, text[i:i + 40]))
        code, i = int(m.group(1)), m.end()
        c = text[i]
        if c == '"':
            j, buf = i + 1, []
            while text[j] != '"':
                if text[j] == '\\':
                    j += 1
                buf.append(text[j])
                j += 1
            pairs.append((code, ('str', ''.join(buf))))
            i = j + 1
        elif c == '(':
            j = text.index(')', i)
            pairs.append((code, ('point', [float(x) for x in text[i + 1:j].split()])))
            i = j + 1
        elif c == '<':
            j = text.index('>', i)
            body = text[i + 1:j]
            typ, _, name = body.partition(' ')
            pairs.append((code, ('ref', typ, name)))
            i = j + 1
        else:
            j = text.find(' ', i)
            j = n if j < 0 else j
            tok = text[i:j]
            pairs.append((code, ('num', float(tok) if re.search(r'[.eE]', tok) else int(tok))))
            i = j
    return pairs


def body(pairs, dictionary):
    """PAIRS without the header and, for a dictionary, its entries."""
    out, group, owner_seen = [], False, False
    for code, value in pairs:
        if group:
            if code == 102 and value == ('str', '}'):
                group = False
            continue
        if code == 102 and value[0] == 'str' and value[1].startswith('{'):
            group = True
            continue
        if code in HEADER_CODES:
            continue
        if code == 330 and not owner_seen:
            owner_seen = True
            continue
        if dictionary and code in (3, 350, 360):
            continue
        out.append((code, value))
    return out


def lisp_string(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'


def lisp_real(x):
    r = repr(float(x))
    if 'e' in r:
        mant, _, exp = r.partition('e')
        if '.' not in mant:
            mant += '.0'
        return mant + 'd' + str(int(exp))
    return r + 'd0'


def lisp_pair(code, value):
    kind = value[0]
    if kind == 'str':
        return '(%d . %s)' % (code, lisp_string(value[1]))
    if kind == 'num':
        v = value[1]
        return '(%d . %s)' % (code, lisp_real(v) if isinstance(v, float) else str(v))
    if kind == 'point':
        return '(%d %s)' % (code, ' '.join(lisp_real(x) for x in value[1]))
    return '(%d :ref %s %s)' % (code, lisp_string(value[1]), lisp_string(value[2]))


def entries(res, prefix, label):
    """The member list of dictionary LABEL: [(key, case)]."""
    members = res.get(label + ': members', 'none')
    if members == 'none':
        return []
    out = []
    for item in members.split('; '):
        item = item.strip()
        if not item:
            continue
        key, _, _ = item.partition('=<')
        out.append(key)
    return out


def node(res, label, key, depth):
    """Lisp form (KEY TYPE BODY MEMBERS) for the object dumped under LABEL."""
    if label + ': dictionary' in res:
        pairs = parse_dump(res[label + ': dictionary'])
        typ = pairs[0][1][1]
        members = [node(res, label + '/' + k, k, depth + 1)
                   for k in entries(res, label, label)]
        return (key, typ, body(pairs, True), members)
    if label in res:
        pairs = parse_dump(res[label])
        xdict = node(res, label + ' xdict', 'xdict', depth + 1) \
            if label + ' xdict: dictionary' in res else None
        return (key, pairs[0][1][1], body(pairs, False), [], xdict)
    return None


def nod(res):
    keys = []
    for case in res:
        m = re.match(r'defaults: ([^/:]+)(: dictionary)?$', case)
        if m and m.group(1) not in keys:
            keys.append(m.group(1))
    return [n for n in (node(res, 'defaults: ' + k, k, 0) for k in keys) if n]


# The section-12 labels of the extension dictionaries -> their owner, as
# (KIND NAME): a table record, or (:table KIND) a symbol TABLE object.
XDICT_OWNERS = [('layer 0', '(:layer "0")'),
                ('*Model_Space BLOCK_RECORD', '(:block-record "*Model_Space")')] + [
    ('%s TABLE' % t, '(:table :%s)' % k) for t, k in
    [('BLOCK_RECORD', 'block-record'), ('LAYER', 'layer'), ('LTYPE', 'ltype'),
     ('STYLE', 'style'), ('DIMSTYLE', 'dimstyle'), ('APPID', 'appid'),
     ('VPORT', 'vport'), ('UCS', 'ucs'), ('VIEW', 'view')]]


def xdicts(res):
    """[(owner-form, node)] of the extension dictionaries the CAD made."""
    out = []
    for label, owner in XDICT_OWNERS:
        if 'xdict: ' + label + ': dictionary' not in res:
            continue                      # "none": the object has no xdict
        n = node(res, 'xdict: ' + label, 'xdict', 0)
        if n:
            out.append((owner, n))
    return out


def emit(form, indent):
    key, typ, body_pairs, members = form[:4]
    xdict = form[4] if len(form) > 4 else None
    pad = ' ' * indent
    lines = [pad + '(%s %s' % (lisp_string(key), lisp_string(typ))]
    lines.append(pad + ' (' + ('\n' + pad + '  ').join(lisp_pair(c, v) for c, v in body_pairs) + ')')
    if members:
        lines.append(pad + ' (')
        for m in members:
            lines.append(emit(m, indent + 2))
        lines.append(pad + ' )' + ('' if xdict else ')'))
    else:
        lines.append(pad + ' ()' + ('' if xdict else ')'))
    if xdict:
        # its own extension dictionary, as a 5th element
        lines.append(emit(xdict, indent + 1) + ')')
    return '\n'.join(lines)


# A paper layout is named in the CAD's language (the BricsCAD runner is
# French: "Pr\u00e9sentation1"); cador's are the English ones (vlax-api's
# "Layout1"), so a localized one is renamed: its key and its (1 . name).
LAYOUT_NAMES = {'Pr\u00e9sentation': 'Layout'}


def english_layouts(forms):
    for form in forms:
        key, typ, body_pairs, members = form[:4]
        if key == 'ACAD_LAYOUT':
            renamed = []
            for member in members:
                mkey, mtyp, mbody, mmembers = member[:4]
                new = mkey
                for local, english in LAYOUT_NAMES.items():
                    if mkey.startswith(local):
                        new = english + mkey[len(local):]
                mbody = [(c, ('str', new)) if (c == 1 and v == ('str', mkey)) else (c, v)
                         for c, v in mbody]
                renamed.append((new, mtyp, mbody, mmembers) + tuple(member[4:]))
            form = (key, typ, body_pairs, renamed)
        yield form


def main(argv):
    products = []
    for arg in argv:
        product, _, path = arg.partition('=')
        res = results(path)
        products.append((product, path, list(english_layouts(nod(res))), xdicts(res)))
    print(';;;; -*- mode:lisp; coding:utf-8 -*-')
    print(';;;; GENERATED by scripts/gen-default-objects.py -- do not edit by hand.')
    print(';;;; The default objects of a new drawing\'s named-object dictionary, as')
    print(';;;; the entget-pointers probe (section 12) measured them:')
    for product, path, _, _ in products:
        print(';;;;   %s: %s' % (product, path.split('probe-results/')[-1]))
    print()
    print('(in-package #:clautolisp.cador)')
    print()
    print('(defparameter *measured-default-objects*')
    print('  ;; PRODUCT -> ((KEY TYPE BODY MEMBERS [XDICT]) ...): BODY the groups after')
    print('  ;; the header, a pointer (CODE :REF TYPE NAME); MEMBERS the same, for a')
    print('  ;; dictionary; XDICT the object\'s own extension dictionary, if it has one.')
    print("  '(")
    for product, _, forms, _ in products:
        print('    (:%s' % product)
        for form in forms:
            print(emit(form, 5))
        print('     )')
    print('    ))')
    print()
    print('(defparameter *measured-extension-dictionaries*')
    print('  ;; PRODUCT -> ((OWNER (KEY TYPE BODY MEMBERS)) ...): the extension')
    print('  ;; dictionary of OWNER, (KIND NAME) a table record or (:TABLE KIND) a')
    print('  ;; symbol TABLE object.')
    print("  '(")
    for product, _, _, xds in products:
        print('    (:%s' % product)
        for owner, form in xds:
            print('     (%s' % owner)
            print(emit(form, 6) + ')')
        print('     )')
    print('    ))')


if __name__ == '__main__':
    main(sys.argv[1:])
