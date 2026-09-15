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
  vendor references, for the commands specified so far.

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
| **cador command engine (2026-09-15)** | **563** | **18** | **6** |
| Full catalogue (enumerated) | 1621 | 18 | 6 |

The **563** specified now = the 561 commands present in BOTH AutoCAD 2026 and
BricsCAD V25 (the portable core, most relevant to cador/cadtui) plus MENULOAD
and MENUUNLOAD. The remaining catalogued commands (352 AutoCAD-only, 708
BricsCAD-only — many BricsCAD-specific verticals: civil, mechanical, BIM,
point-cloud) are enumerated in `command-names.sexp` but not yet detailed.

## Specified commands by category (563)

| Category | Count | Category | Count |
|---|---:|---|---:|
| modify | 65 | text | 22 |
| view | 58 | edit | 21 |
| file | 44 | inquiry | 16 |
| 3d | 40 | render | 15 |
| system | 36 | annotation | 15 |
| draw | 36 | attribute | 14 |
| customization | 34 | plot | 12 |
| block | 32 | other | 12 |
| dimension | 28 | selection | 8 |
| parametric | 24 | table | 8 |
| layer | 23 | | |

## Availability (of the 563 specified)

| Availability | Count |
|---|---:|
| both (AutoCAD & BricsCAD) | 561 |
| BricsCAD-only | 2 (MENULOAD, MENUUNLOAD) |
| AutoCAD-only | 0 |

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
