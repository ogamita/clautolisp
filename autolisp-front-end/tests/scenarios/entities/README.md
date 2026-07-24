# Portable entity-lifecycle conformance probes

This directory holds the **portable AutoLISP entity CRUD probes** for the
`entity-mutation-parity` work: one create → read → modify → read →
delete → restore lifecycle per drawing-entity family, written so the
*same* source runs UNCHANGED under clautolisp and, via alfe, under
BricsCAD and AutoCAD.

## Files

| File                              | Role                                                                 |
|-----------------------------------|----------------------------------------------------------------------|
| `entity-lifecycle-probe.lsp`      | **Canonical portable probe.** Self-contained AutoLISP; the source of truth. |
| `entity-lifecycle.sexp`           | alfe conformance scenario — runs the probe under the clautolisp backend (mock host). |
| `entity-lifecycle-bricscad.sexp`  | Same probe, classified `:bricscad-only` — runs only where BricsCAD is detected. |
| `entity-lifecycle-autocad.sexp`   | Same probe, classified `:autocad-only` — runs only on a host with AutoCAD. |

The three `.sexp` files **embed a byte-identical copy** of
`entity-lifecycle-probe.lsp` in their `:setup-files` (the conformance
runner lays fixtures down in a throwaway working directory, so it cannot
reference a sibling file). The `.lsp` is canonical; if you change it,
regenerate the embedded copies — see *Regenerating* below.

## What the probe checks

For each of `LINE POINT CIRCLE ARC ELLIPSE TEXT LWPOLYLINE SOLID 3DFACE
RAY XLINE`:

- `entmakex` returns an **ENAME** (not a list) that feeds straight into
  `entget`;
- `entget` returns the definition list with the type (group 0) and a
  handle (group 5);
- `handent` round-trips the handle back to the ENAME;
- `entmod` sets colour (group 62) and the change reads back;
- `entdel` removes the entity (`entget` → nil) and a second `entdel`
  restores it (the documented within-session toggle).

Plus: the `entmakex` / `entmake` return contract (and that a
code-short entity fails soft with nil, never an error); the XData
lifecycle (`regapp` → `entmod` a `-3` group → `entget` suppresses it
without an application list and surfaces it with one); and `entnext`
traversal.

The probe prints one `ok` / `FAIL` line per assertion and, as its **last
line**, either `ALL ENTITY PROBES PASSED` or `ENTITY PROBES FAILED: <n>`.
The scenarios key on that string.

## Running

Under clautolisp (headless, mock host):

```
clautolisp --clautolisp --host mock -l entity-lifecycle-probe.lsp
```

Under a real CAD via alfe (this is the **vendor-verification tail**,
currently BLOCKED on real CAD access — see
`issues/open/entity-mutation-parity.issue`):

```
alfe --bricscad -l entity-lifecycle-probe.lsp     # on a BricsCAD host
alfe --autocad  -l entity-lifecycle-probe.lsp     # on a Windows/AutoCAD host
```

Or from inside a running CAD: `(load "entity-lifecycle-probe.lsp")`.

As part of the alfe conformance suite (the clautolisp scenario runs;
the CAD ones self-skip when the product is absent):

```
make -C autolisp-front-end test
```

## Regenerating the embedded copies

After editing `entity-lifecycle-probe.lsp`, refresh the `:setup-files`
copy inside each `.sexp` so they stay byte-identical. The copies were
produced by reading the `.lsp` and `prin1`-escaping it into the plist;
any equivalent method works — the only invariant the suite enforces is
that running the embedded probe prints `ALL ENTITY PROBES PASSED`.

## Deliberately deferred

`INSERT` (needs a block definition), `POLYLINE`/`VERTEX`/`SEQEND` and
`ATTDEF`/`ATTRIB` (complex-entity sequences with prerequisites) are
exercised at the model/host unit-test level
(`clautolisp/autolisp-mock-host/tests/entity-api-tests.lisp`,
`clautolisp/drawing/tests/entity-families-tests.lisp`) rather than in
this portable probe, because a portable create needs block/regapp setup
that differs subtly across vendors. See the deferred-families inventory
in `issues/open/entity-mutation-parity.issue`.
