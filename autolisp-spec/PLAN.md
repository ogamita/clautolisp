# autolisp-spec Plan

## Purpose

This file is the canonical task tracker for the `autolisp-spec` subproject.

The Org documents in `documentation/` remain the place for specification text, evidence notes, and design rationale. Actionable work items should be recorded here.

## Current Status

- The main specification draft exists and is broadly chapter-complete.
- Remaining work is mainly validation, citation closure, and conversion of hypotheses into tested facts.
- The highest-priority unresolved areas currently include `atof`, `atoi` lexical edge behavior, `vl-member-if-not`, printer surface details, and `exit` versus `quit`.

## Near-Term Tasks

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
