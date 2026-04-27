# autolisp-test Plan

## Purpose

This file is the canonical task tracker for the `autolisp-test` subproject.

The Org documents in `documentation/` remain the place for test-suite rationale, conformance model, and design notes. Actionable work items should be tracked here.

## Current Status

- The subproject structure exists.
- The conformance model is defined (see `documentation/autolisp-test-development-plan.org`).
- A first inventory of every operator and entity defined in the local AutoLISP / Visual LISP draft specification is captured at `harness/inventory.sexp` (976 entries: 938 functions, 19 special forms, 5 variables, 5 types, 7 reader-syntax entries, 1 distinguished object, 1 condition).
- The harness and first conformance corpus are not yet implemented.

## Conformance Model (summary)

The suite is adversarial to no implementation in particular. It tests the AutoLISP / Visual LISP language as defined by the local specification, against:

- `clautolisp`,
- AutoCAD releases,
- BricsCAD releases,
- future third-party implementations.

Three language-level **profiles**, each acting as a verdict target:

- `STRICT`   — behaviour intended to hold on AutoCAD AND BricsCAD;
- `AUTOCAD`  — behaviour attested or documented on AutoCAD only;
- `BRICSCAD` — behaviour attested or documented on BricsCAD only.

Two orthogonal axes carried by tags:

- `PLATFORM-TAGS` — `WINDOWS`, `LINUX`, `MACOS`;
- `RUNTIME-TAGS`  — `COM`, `VLA`, `VLAX`, `VLAX-CURVE`, `VLR`, `ARX`, `BRX`, `OBJECTDBX`, `DCL`, `GRAPHICS`, `USER-INPUT`, `EXPRESS-TOOLS`, `DOSLIB`.

A run produces a matrix of verdicts: `CONFORMS | DEVIATES (n failing) | NOT-APPLICABLE` per profile and per tag combination, computed from the test set whose required tags are satisfied by the detected target.

The harness is written in pure AutoLISP. No Common Lisp is required to run the suite. `clautolisp` simply executes the AutoLISP harness like any other implementation.

## Inventory and Classification Tasks

- [x] Extract the operator and function inventory from the current AutoLISP draft specification. (`harness/inventory.sexp`, 976 entries.)
- [x] Choose initial classification rules for every entry: profile defaults to `STRICT`, authority defaults to `DOCUMENTED`, tags assigned by name family.
- [ ] Refine `OBJECTDBX` tagging to cover `VLE-ENT*`, `VLE-TBL*`, `VLE-DICT*` and the `LAYOUT*`, `MODE_TILE`-adjacent gaps that the initial pass left untagged.
- [ ] Cross-check the inventory against the BricsCAD V26 / macOS probe results under `autolisp-spec/results/bricscad/macos/` and promote attested entries from `:authority documented` to `:authority tested-bricscad`.
- [ ] Acquire AutoCAD probes for the same entry set and promote attested entries to `:authority tested-autocad`. Promote to `:authority tested-both` when both vendor probes agree.
- [ ] Record explicit divergences as twin tests when a function's documented or attested behaviour differs between AutoCAD and BricsCAD.

## Harness Tasks

- [ ] Define `harness/rt.lsp`: the registration and run-time core.
  - `deftest`, `deftest-error`, `deftest-skip`, `deftest-versioned` macros.
  - `*tests*` registry table indexed by stable name.
  - Per-entry metadata: `:operator`, `:area`, `:profile`, `:platform-tags`, `:runtime-tags`, `:authority`, `:source-evidence`, `:expected-result` or `:expected-error`, `:tags`.
  - `(do-tests)`, `(do-test name)`, `(do-area area)`, `(do-tag tag)`, `(do-profile profile)` runners.
- [ ] Define `harness/profiles.lsp`: profile and tag definitions, applicability predicate `(test-applicable-p test descriptor)`, verdict-aggregation helpers.
- [ ] Define `harness/platform-detect.lsp`: detect platform (`getenv "OS"`, pathname probes, `(getvar "PLATFORM")`), runtime extensions (`(boundp 'vlax-create-object)`, `(boundp 'arx)`, etc.), and return an implementation descriptor.
- [ ] Define `harness/report.lsp`: produce simultaneously
  - a canonical s-expression report (`results/.../report.sexp`),
  - a human-readable text recap.
- [ ] Define `harness/expectations/` overlay loader: `expectations/<impl>/<version>/<host>.lsp` files merged at run-time.
- [ ] Add a top-level `harness/run.lsp` that any implementation can `(load "...")`.
- [ ] Provide a `clautolisp`-side driver that builds an ASDF wrapper around the AutoLISP harness for SBCL/CCL CI runs (the harness itself stays AutoLISP-only).

## Initial Corpus Tasks (Phase C: profile STRICT)

Order chosen to overlap with the implementation phase already complete in `clautolisp`, so regressions surface early.

- [ ] Special forms: `quote`, `setq`, `progn`, `if`, `cond`, `and`, `or`, `while`, `repeat`, `foreach`, `lambda`, `function`, `defun`, `defun-q`. One file per operator under `tests/special-forms/`. ≥30 cases each, covering evaluation order, short-circuit behaviour, scoping, AutoLISP-visible errors.
- [ ] Lists and equality: `cons`, `car`, `cdr`, `Cxxr` family up to four levels, `list`, `append`, `assoc`, `length`, `nth`, `reverse`, `last`, `member`, `subst`, `vl-list*`, `vl-consp`, `listp`, `null`, `atom`, `eq`, `equal` (including `fuzz`), `vl-list-length`, `vl-position`, `remove`, `vl-sort`, `vl-sort-i`.
- [ ] Numeric and comparison: `+`, `-`, `*`, `/`, `1+`, `1-`, `min`, `max`, `rem`, `gcd`, `lcm`, `~`, `logand`, `logior`, `logxor`, `lsh`, `boole`, `abs`, `fix`, `float`, `zerop`, `minusp`, `numberp`, `=`, `/=`, `<`, `<=`, `>`, `>=`. Math: `sqrt`, `exp`, `log`, `log10`, `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `expt`, `mod`, `floor`, `ceiling`, `round`, `random`.
- [ ] Strings: `strcat`, `strlen`, `substr`, `strcase`, `ascii`, `chr`, `atoi`, `atof`, `itoa`, `rtos`, `angtos`, `distof`, `angtof`, `wcmatch`, `xstrcase`, `vl-string-*`, `snvalid`.
- [ ] Symbols, namespaces, errors: `vl-symbolp`, `vl-symbol-name`, `vl-symbol-value`, `boundp`, `type`, `vl-bb-*`, `vl-doc-*`, `vl-catch-all-*`, `vl-exit-with-*`, `defun-q-list-*`, `*error*` hook.
- [ ] File I/O (reformulated from the existing file-compat scenarios): `open`, `close`, `read-line`, `read-char`, `write-line`, `write-char`, `findfile`, `findtrustedfile`, `vl-file-*`, `vl-filename-*`, `vl-directory-files`, `vl-mkdir`, `prin1`, `princ`, `print`, `terpri`, `vl-prin1-to-string`, `vl-princ-to-string`.
- [ ] Reader entries: 7 reader-syntax entries (literals, symbol, list, dotted-pair, quote) including strict-vs-lax cases.
- [ ] Variables and conditions: 5 variable entries and the catch-all condition entry.

## Phase D: Vendor-divergent Tests

- [ ] For each function whose documented or probed behaviour differs between AutoCAD and BricsCAD, write twin tests:
  - one `:profile autocad` with the AutoCAD result;
  - one `:profile bricscad` with the BricsCAD result;
  - the corresponding `:profile strict` test, if any, restricted to the common subset.
- [ ] Likely sources of early divergence (to triage first): printer framing (`print`, `terpri`), `read`/`atoi`/`atof` lex models, `or`/`and` return-value rule, command-loop, error mode, `*error*` invocation contract.

## Phase E: Platform-tagged and Runtime-tagged Coverage

- [ ] `:runtime-tag com / vla / vlax (excluding vlax-curve)`: ActiveX/COM bridge tests, marked `:platform-tag windows`. Fixtures under `fixtures/type-libraries/` declaratively describe the COM types used.
- [ ] `:runtime-tag vlax-curve`: geometry helpers without platform constraint.
- [ ] `:runtime-tag vlr`: reactor lifecycle and dispatch tests, no platform constraint.
- [ ] `:runtime-tag arx`: AutoCAD ObjectARX-specific entries (`arx`, `arxload`, `arxunload`, `autoarxload`, `vl-arx-import`).
- [ ] `:runtime-tag brx`: BricsCAD BRX-specific entries; reserved until probes surface them.
- [ ] `:runtime-tag objectdbx`: entity, selection-set, table, dictionary, layer-state, `xdroom`, `xdsize`, `regapp`, `nentsel`, `nentselp`. Backed by deterministic DXF fixtures under `fixtures/drawings/`.
- [ ] `:runtime-tag dcl`: dialog control language, against `.dcl` fixtures under `fixtures/dcl/`. Headless mock UI events drive assertions.
- [ ] `:runtime-tag graphics`: `GR*` primitives, screen-state functions.
- [ ] `:runtime-tag user-input`: `getpoint`, `initget`, etc., driven by scripted input.
- [ ] `:runtime-tag express-tools`: `ACET-*`/`ACET::*`. The portable subset (file/string/list/calc) covered first.
- [ ] `:runtime-tag doslib + :platform-tag windows`: `DOS_*`. NOT-APPLICABLE on non-Windows.

## Phase F: Reporting and CI

- [ ] Define the canonical s-expression report schema (`harness/report-schema.org`).
- [ ] Implement `tools/diff-reports.lisp` to align N reports and pinpoint each divergence with the offending test name and concerned profile/tag combination.
- [ ] Archive each official run under `results/<impl>/<version>/<host>/<timestamp>/`. Convention: one official AutoCAD or BricsCAD report per major version; one `clautolisp` report per release tag.
- [ ] Add a CI job running the harness against `clautolisp` on SBCL and CCL; attach the report as an artifact.
- [ ] Define the regression rule: a previously passing test that flips to fail without a matching expectation overlay update fails the pipeline.
- [ ] Mark `:undefined-function` failures (function in inventory but not implemented) as `unimplemented` in the report, distinct from `fail`.

## Open Questions

- Final list of reactor and ActiveX entries that should remain `:strict` versus those that need vendor-specific twin tests once probe data lands.
- Single canonical `BRX` runtime tag granularity, or split per BRX subsystem when probes start surfacing them.
- Policy for handling vendor-version drift inside one profile: per-test version qualifiers versus profile sub-versions (`autocad-2024`, `autocad-2026`, `bricscad-v25`, `bricscad-v26`).
