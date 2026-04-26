# autolisp-spec Plan

## Purpose

This file is the canonical task tracker for the `autolisp-spec` subproject.

The Org documents in `documentation/` remain the place for specification text, evidence notes, and design rationale. Actionable work items should be recorded here.

## Current Status

- The main specification draft has 974 dictionary entries (Function, Special Form, Reader Syntax, Type, Variable). 597 carry full Phase-3 bodies; 377 are Phase-2 follow-up stubs added on 2026-04-26 after walking the BricsCAD V26 TOC inside Chrome.
- Document version bumped to `0.4.0`.
- Phase 1 (vendor inventory and delta): complete and revisited 2026-04-26 — the BricsCAD V26 LISP TOC was extracted live from the JS-built `chmtop.c2wtopf.TITEMS` array, recovering 941 in-scope entries (vs. the 96 visible to the original raw-HTTP fetch). See `documentation/vendor-inventory-2026.org` §3.2, §4, §8.13.
- Phase 2 (index closure): complete and extended on 2026-04-26 — original 266 stubs (Phase 2.0) plus the new 377 BricsCAD-only stubs (Phase 2 follow-up) in chapter 24 under a new "Phase-2 Follow-up Catalogue" sub-section grouped by family.
- Phase 3 (body fill): complete for the original Phase-2 stubs (265 / 266; `grclear` retained as legacy). The 377 Phase-2-follow-up stubs are body-pending and remain in scope for a future Phase-3 iteration.
- Remaining work: body-fill the 377 new BricsCAD stubs, then divergence reconciliation (Phase 4) and closure of long-running `atof` / `atoi` / `vl-member-if-not` / `exit` vs `quit` / printer-surface items (Phase 5).

## Phasing

- Phase 1 (done; revisited 2026-04-26) — Vendor inventory, delta, divergence list. Live-DOM walk inside Chrome recovered the full 941-entry BricsCAD V26 LISP catalogue.
- Phase 2 (done; extended 2026-04-26) — Index closure: original 266 stubs + 377 Phase-2-follow-up stubs in chapter 24.
- Phase 3 (done for original 266 stubs; new 377 stubs pending) — Body fill: full HyperSpec-style entries for stubbed symbols.
- Phase 4 — Divergence reconciliation against the items listed in `vendor-inventory-2026.org` §10 (e.g. `layerstate-*` vs `vl-layerstates-*`, `vl-position` vs `position`, BricsCAD `open` `ccs=` modes). Each pair must carry an explicit *See also* cross-reference plus a normative note in either chapter 23 / 24 about which family is canonical for the active dialect.
- Phase 5 — Validation closure: `atof`, `atoi` lex edges, `vl-member-if-not`, printer surface, `exit` vs `quit`.

## Near-Term Tasks

### Phase 3 follow-up — body-fill the 377 new BricsCAD stubs (next)

- [ ] Walk `bricscad-stubs-data.tsv` (Phase-2-follow-up generator input) in family order — Standard/Misc → BricsCAD System → Generic Properties → Error Control → Visual LISP Extension → Viewport-Layer → ActiveX Extension → Reactor Extension → VLX Namespace (obsolete) → VLE Library (105) → ExpressTools API (208 + 8) → DOSLib (23).
- [ ] Fetch each per-symbol BricsCAD V26 page (URLs are already recorded in each stub's Source Notes line) and replace the placeholder Description / add Arguments and Values / Return Values / Side Effects / Examples blocks.
- [ ] Where a BricsCAD function has a clear AutoCAD analogue (e.g. `acet-*` ports, `dos_*` ↔ DOSLib, `vle-*` ↔ AutoLISP idioms), add a Phase-4 cross-reference.

### Phase 4 — Divergence reconciliation

- [ ] Cross-link every AutoCAD `layerstate-*` entry (chapter 17) with its BricsCAD `vl-layerstates-*` counterpart (chapter 24) via "See also" lines and a normative note about the parallel-family naming.
- [ ] Cross-link AutoCAD `vl-position` ↔ BricsCAD `position`, `vl-remove` ↔ `remove`, and any other pairs called out in `vendor-inventory-2026.org` §10.
- [ ] Add a divergence note to AutoCAD `open` (chapter 11) describing BricsCAD's extended `r,ccs=` / `w,ccs=` mode strings.
- [ ] Add a divergence note to AutoCAD `expt` (chapter 8) cross-referencing BricsCAD `power`; similarly `rem` ↔ `mod`, `log` ↔ `log10`.
- [ ] Reconcile `menucmd` (chapter 16) — AutoCAD documents the full menu-area surface; BricsCAD documents only `P0`/`P1`–`P16`.
- [ ] Reconcile `vlisp-compile` (chapter 22) — body already contains both signatures; verify Phase 5 product-test coverage notes the runtime mode-ignoring behaviour in BricsCAD.
- [ ] Reconcile `vl-vbaload` / `vl-vbarun` and `showhtmlmodalwindow` as AutoCAD-Windows-only with no BricsCAD counterpart.

### Phase 3 — Body fill (done)

- [x] Walk Autodesk's feature-category pages and replace each Phase-2 stub body with the canonical signature, return-value, side-effect, examples, and per-symbol vendor URL.
- [x] Replace the alphabetical-letter-page URL fallback with the per-symbol GUID for each filled entry.
- [x] Convert the `acet-*` and `acad_*` Express Tools stubs (chapter 23) to full bodies sourced from the six Express Tools category pages.
- [x] Fill BricsCAD Extension bodies (chapter 24) from BricsCAD V26 catalogue pages. Per-symbol pages are not separately published for most BricsCAD-only extensions; entries cite the catalogue page they came from.

### Phase 5 — long-running closure items (carried forward)

- [ ] Create a reader-questions ledger for unresolved syntax and reader behaviors.
- [ ] Add explicit ledger rows for `atoi`, `atof`, and `vl-member-if-not`.
- [ ] Collect dedicated vendor pages for every core special form.
- [ ] Search older Autodesk documentation for a dedicated `vl-member-if-not` page.
- [ ] Search BricsCAD documentation for explicit `atoi` and `atof` lexical-acceptance details.

## Validation Tasks

- [x] Build a minimal syntax probe suite for AutoCAD and BricsCAD.
- [x] Implement numeric probes for `atoi`.
- [x] Implement numeric probes for `atof`.
- [x] Implement output-format probes for `prin1`, `princ`, `print`, `terpri`, and `prompt`.
- [ ] Run the probes on at least one recent AutoCAD release.
- [ ] Run the probes on at least one recent BricsCAD release.
- [ ] Record results with product name, version, platform, and relevant configuration.

## Corpus and Comparison Tasks

- [ ] Assemble a representative public AutoLISP corpus.
- [ ] Index reader-adjacent syntax, quote usage, lambda usage, `function`, `defun-q`, and error-handling idioms.
- [ ] Read VeLisp and extract reader and evaluator assumptions that should become explicit hypotheses or tests.

## Closure Tasks

- [ ] Update the `atoi` entry with version-qualified tested behavior.
- [ ] Update the `atof` entry with version-qualified tested behavior.
- [ ] Close `vl-member-if-not` either with direct citation or tested symmetry.
- [ ] Convert remaining “worth testing” notes into tested facts, documented divergence, or explicit implementation-defined choices.

## Open structural questions for Phase 2

- Where should Express Tools (`acet-*`, `acad_*`, `acad-*`) live? Either a dedicated chapter (recommended) or a tagged sub-section in chapter 16 "Host Interaction".
- Should the 14 `layerstate-*` entries (AutoCAD) and the 10 `vl-layerstates-*` entries (BricsCAD) be merged into a single dictionary section with availability tags, or kept as parallel families with cross-references? Recommend the latter to mirror vendor naming.
- Should the spec adopt a per-entry `Availability` block now, or only when Phase 3 fills the body? Recommend now (added at stub time) so the index pass already encodes the dialect data.
