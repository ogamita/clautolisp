# autolisp-spec Plan

## Purpose

This file is the canonical task tracker for the `autolisp-spec` subproject.

The Org documents in `documentation/` remain the place for specification text, evidence notes, and design rationale. Actionable work items should be recorded here.

## Current Status

- The main specification draft has 974 dictionary entries, all body-filled (642 Phase-3 status markers; 0 stubs remaining).
- Document version bumped to `0.7.0`.
- Phase 1 (vendor inventory and delta): complete and revisited 2026-04-26.
- Phase 2 (index closure): complete and extended on 2026-04-26.
- Phase 3 (body fill): complete for the original 266 Phase-2 stubs *and* for the 377 Phase-2-follow-up stubs added 2026-04-26. The Phase-3 follow-up scraped each BricsCAD V26 per-symbol page directly via curl, parsed the chm2web tabular layout (Arguments, Return, Example, Remarks), and replaced each chapter-24 stub with the structured body. 316/377 entries received a non-trivial parsed signature; 134/377 received explicit Arguments; 134/377 received explicit Return; 98/377 received Examples; 83/377 received Remarks. The remaining entries kept a sensible default body where the vendor page was a one-line description.
- Phase 4 (divergence reconciliation): complete.
- Phase 5 (validation closure): complete. Five long-running items — `atoi`, `atof`, `vl-member-if-not`, `exit` vs `quit`, and the printer surface (`prin1` / `princ` / `print` / `terpri` / `prompt`) — closed at the *documented* level via direct citation of the BricsCAD V26 per-symbol pages reached through Claude-in-Chrome MCP. See `documentation/specification-resolution-plan.org` for the closure record.
- Remaining work: when a local AutoCAD or BricsCAD is available, run `scripts/run-probes.sh` to upgrade the implementation-defined lex-edge entries on `atoi` / `atof` from *implementation-defined* to *tested*.

## Phasing

- Phase 1 (done; revisited 2026-04-26) — Vendor inventory, delta, divergence list. Live-DOM walk inside Chrome recovered the full 941-entry BricsCAD V26 LISP catalogue.
- Phase 2 (done; extended 2026-04-26) — Index closure: original 266 stubs + 377 Phase-2-follow-up stubs in chapter 24.
- Phase 3 (done) — Body fill: full HyperSpec-style entries for stubbed symbols. Original 266 Phase-2 stubs filled in the first Phase-3 pass; the 377 Phase-2-follow-up stubs filled in the Phase-3 follow-up via direct scrape of BricsCAD V26 per-symbol pages.
- Phase 4 (done) — Divergence reconciliation: bidirectional *See Also* blocks added on 47 entries covering every pair listed in `vendor-inventory-2026.org` §10 plus the BricsCAD-only numeric helpers that have portable AutoLISP idioms (acos / asin / tan / ceiling / floor / round).
- Phase 5 (done) — Validation closure: `atoi`, `atof`, `vl-member-if-not`, `exit` vs `quit`, printer surface (`prin1` / `princ` / `print` / `terpri` / `prompt`) closed at *documented* level via direct BricsCAD V26 per-symbol citations. Lex-edge unknowns on `atoi` / `atof` recorded as *implementation-defined* with the existing probe suite as the path to *tested*.

## Near-Term Tasks

### Phase 3 follow-up — body-fill the 377 new BricsCAD stubs (done)

- [x] Bulk-fetch every per-symbol BricsCAD V26 page (377 pages in 16-way parallel curl).
- [x] Parse the chm2web tabular layout (Arguments / Return / Example / Remarks) and the inline signature line.
- [x] Replace each chapter-24 stub with a fully-structured body. 316/377 received a non-trivial signature; 134 Arguments; 134 Return; 98 Examples; 83 Remarks.
- [ ] Where a BricsCAD function has a clear AutoCAD analogue (e.g. `acet-*` ports, `dos_*` ↔ DOSLib, `vle-*` ↔ AutoLISP idioms), add a Phase-4 cross-reference. Carrying this over as future work since most pairs are already covered by the Phase-4 sweep.

### Phase 4 — Divergence reconciliation (done)

- [x] Cross-link every AutoCAD `layerstate-*` entry (chapter 17) with its BricsCAD `vl-layerstates-*` counterpart (chapter 24).
- [x] Cross-link AutoCAD `vl-position` ↔ BricsCAD `position`, `vl-remove` ↔ `remove`, AutoCAD `expt` ↔ BricsCAD `power`, `rem` ↔ `mod`, with a portable-idiom note for `log10` (no AutoCAD analogue).
- [x] Divergence note on AutoCAD `open` describing BricsCAD's extended `r,ccs=` / `w,ccs=` mode strings.
- [x] Reconcile `menucmd` — AutoCAD documents the full menu-area surface; BricsCAD documents only `P0`/`P1`–`P16`.
- [x] Reconcile `vlisp-compile` (body already contains both signatures; *See Also* now points at the divergence summary).
- [x] Mark `vl-vbaload`, `vl-vbarun`, `showhtmlmodalwindow` as AutoCAD-Windows-only with no BricsCAD counterpart.
- [x] Flip `vlax-typeinfo-available-p` Availability from "AutoCAD-Windows + parity TBD" to "Both", reflecting confirmation in the live BricsCAD V26 TOC.
- [x] Portable-idiom *See Also* notes on BricsCAD-only `acos`, `asin`, `tan`, `ceiling`, `floor`, `round`.

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

## Closure Tasks (Phase 5, done)

- [x] Close `atoi` lex-edge entry: BricsCAD V26 per-symbol citation added; remaining lex edges marked *implementation-defined*; `clautolisp` choices recorded in the entry; probe suite cross-referenced.
- [x] Close `atof` lex-edge entry: BricsCAD V26 per-symbol citation added; remaining lex edges marked *implementation-defined*; probe suite cross-referenced.
- [x] Close `vl-member-if-not` with the BricsCAD V26 dedicated per-symbol page (more explicit than Autodesk's family-table prose).
- [x] Close `exit` vs `quit`: BricsCAD V26 confirms identical signature, abort-channel message, and effect; spec records the historical distinction as not-supported.
- [x] Close printer surface (`prin1` / `princ` / `print` / `terpri` / `prompt`): BricsCAD V26 per-symbol citations added; control-character escape rules, leading-newline / trailing-space framing of `print`, zero-arity command-line-only behaviour of `terpri`, and Bricsys's preferred-channel guidance for `prompt` all recorded.
- [ ] Promote any *implementation-defined* lex edge to *tested* by running `scripts/run-probes.sh` against a real AutoCAD or BricsCAD installation when one becomes available.

## Open structural questions for Phase 2

- Where should Express Tools (`acet-*`, `acad_*`, `acad-*`) live? Either a dedicated chapter (recommended) or a tagged sub-section in chapter 16 "Host Interaction".
- Should the 14 `layerstate-*` entries (AutoCAD) and the 10 `vl-layerstates-*` entries (BricsCAD) be merged into a single dictionary section with availability tags, or kept as parallel families with cross-references? Recommend the latter to mirror vendor naming.
- Should the spec adopt a per-entry `Availability` block now, or only when Phase 3 fills the body? Recommend now (added at stub time) so the index pass already encodes the dialect data.
