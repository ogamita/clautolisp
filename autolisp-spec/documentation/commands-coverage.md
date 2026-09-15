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
drawing model; every other specified command is recorded on the command log
without side effects until its category is implemented
(`issues/open/autolisp-spec-alref-commands.issue`).

## Status

| Milestone | Commands specified | Implemented (cador) |
|---|---:|---:|
| Pilot (2026-09-14) | 25 | 10 |
| **Both-vendor core (2026-09-15)** | **563** | **10** |
| Full catalogue (enumerated) | 1621 | 10 |

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

## Implemented in cador (10)

LINE, CIRCLE, TEXT, DONUT, SOLID (draw/text) and ERASE, MOVE, COPY, ROTATE
(modify) and BLOCK/-BLOCK (block) — `%execute-command-tokens`. Everything
else is specified but records its tokens without side effects.

## Next (Phase 4 — implement the categories cador/cadtui need)

- **file** (NEW, OPEN, QSAVE, QNEW): cadtui NEW/OPEN → create a `ui-drawing`.
- **customization** (MENULOAD/MENUUNLOAD, CUILOAD/CUIUNLOAD): populate `bands`.
- **view** (ZOOM, PAN, REGEN): map onto the cadtui viewport verbs.
- **modify/draw** extensions to the cador drawing-command dispatch.
- spec §5.6 rule 3: a bare command name at the `cad>` console dispatches.
