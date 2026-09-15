# CAD Command Coverage

Generated against `autolisp-visual-lisp-specification-draft.org` (Commands
chapter) and the cador command engine
(`clautolisp/cador/source/command-api.lisp`). Companion to
`builtins-coverage.md` (functions) — this one tracks **CAD commands**
(invoked via `(command "NAME" …)` or the command prompt), a namespace
distinct from AutoLISP functions and system variables.

Sources of truth:
- `command-names.sexp` — the full enumerated catalogue: **1621** distinct
  AutoCAD 2026 + BricsCAD V25 command names (both 561, AutoCAD-only 352,
  BricsCAD-only 708), from the vendors' machine-readable indexes.
- `commands-inventory.sexp` — the per-command detail (options, argument
  sequence, aliases, description, provenance URLs) harvested from the online
  vendor references. **All 1621 are now detailed** — the catalogue is complete.
  29 are obsolete/removed names the vendor index still lists but that have no
  live reference page (BricsCAD `AI_*`/`AMPOWERDIM_*`/`POINTCLOUDPOINTSIZE_*`);
  these carry name + category + availability only, with source NIL.

"Implemented" means the cador MockHost executes the command against the
drawing model. A second tier, "recognised no-op", is consumed by the dispatch
so a driven command sequence keeps flowing but has no drawing-model effect
(viewport/coordinate context or external process). Every other specified
command is recorded on the command log without side effects until its category
is implemented (`issues/open/autolisp-spec-alref-commands.issue`).

## Status

| Milestone | Commands specified | Executed (cador) | Recognised no-op |
|---|---:|---:|---:|
| Pilot (2026-09-14) | 25 | 10 | 0 |
| Both-vendor core (2026-09-15) | 563 | 10 | 0 |
| cador command engine (2026-09-15) | 563 | 18 | 6 |
| + AutoCAD-only (2026-09-15) | 915 | 18 | 6 |
| **+ BricsCAD-only — COMPLETE (2026-09-15)** | **1621** | **18** | **6** |

The catalogue is now **complete**: all 1621 AutoCAD 2026 + BricsCAD V25 commands
are specified — 561 present in both vendors, 352 AutoCAD-only, 708 BricsCAD-only
(heavy on BricsCAD verticals: BIM, mechanical/sheet-metal, civil, point-cloud,
direct-modeling). Implementation in cador (18 executed + 6 recognised no-ops)
covers all 21 commands the SCHMS+ corpus drives; the rest are specified and
recorded-only until their category is implemented.

## Specified commands by category (1621)

| Category | Count | Category | Count |
|---|---:|---|---:|
| 3d | 298 | annotation | 49 |
| view | 177 | render | 45 |
| file | 130 | layer | 43 |
| block | 118 | text | 40 |
| system | 111 | edit | 36 |
| modify | 109 | selection | 32 |
| other | 72 | plot | 29 |
| customization | 66 | table | 20 |
| draw | 64 | attribute | 18 |
| parametric | 57 | dimension | 56 |
| inquiry | 51 | | |

## Availability (of the 1621 specified)

| Availability | Count |
|---|---:|
| both (AutoCAD & BricsCAD) | 561 |
| AutoCAD-only | 352 |
| BricsCAD-only | 708 |

## Implemented in cador (`%execute-command-tokens`)

**Executed against the drawing model (18):** LINE, CIRCLE, ARC, TEXT, MTEXT,
DONUT, SOLID, PLINE, WIPEOUT (draw/text); ERASE, MOVE, COPY, ROTATE, MIRROR
(modify); INSERT/-INSERT (block); LAYER/-LAYER, LINETYPE/-LINETYPE (tables).

**Recognised model-only no-ops (6):** ZOOM, UCS (viewport/coordinate context —
cador is model-only, WCS); BROWSER, SHELL (external processes, inert headless);
PEDIT, BREAK (edit geometry deferred). These consume their input so a driven
sequence keeps flowing.

Everything else is specified but records its tokens without side effects. This
covers all 21 commands the SCHMS+ corpus drives via `(command …)`
(`issues/open/schms-call-inventory.md` §9).

## Next (Phase 4 — the categories cadtui needs, and deferred refinements)

- **file** (NEW, OPEN, QSAVE, QNEW): cadtui NEW/OPEN → create a `ui-drawing`.
- **customization** (MENULOAD/MENUUNLOAD, CUILOAD/CUIUNLOAD): populate `bands`.
- INSERT **attribute** modelling (needs the block's attdef tags), PLINE arc
  **bulges**, and PEDIT/BREAK **edit geometry** — the documented deferrals.
- spec §5.6 rule 3: a bare command name at the `cad>` console dispatches.
