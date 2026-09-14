# CAD Command Coverage

Generated against `autolisp-visual-lisp-specification-draft.org` (Commands
chapter) and the cador command engine
(`clautolisp/cador/source/command-api.lisp`). Companion to
`builtins-coverage.md` (functions) — this one tracks **CAD commands**
(invoked via `(command "NAME" …)` or the command prompt), a namespace
distinct from AutoLISP functions and system variables.

Source of truth: `commands-inventory.sexp` (harvested from
help.autodesk.com 2026 ENU + help.bricsys.com V25). "Implemented" means the
cador MockHost executes the command against the drawing model; every other
specified command is recorded on the command log without side effects until
its category is implemented (see `issues/open/autolisp-spec-alref-commands.issue`).

## Status — pilot slice (2026-09-14)

The commands surface is being populated incrementally. This first slice
specifies **25** core commands end-to-end (inventory → Command Entry pages
→ paged build → this report). The full AutoCAD/BricsCAD surface (~1000+)
is future work.

| Category | Specified | Implemented (cador) |
|---|---:|---:|
| draw | 8 | 6 |
| modify | 6 | 3 |
| view | 3 | 0 |
| file | 4 | 0 |
| block | 2 | 1 |
| customization | 2 | 0 |
| **Total** | **25** | **10** |

Implemented (cador executes): LINE, CIRCLE, ARC?†, TEXT, DONUT, SOLID,
ERASE, MOVE, COPY, ROTATE, BLOCK. †ARC is specified but not yet executed —
the executed set is exactly LINE, CIRCLE, TEXT, DONUT, SOLID, ERASE, MOVE,
COPY, ROTATE, BLOCK/-BLOCK (10).

## Availability (of the 25 specified)

| Availability | Count | Commands |
|---|---:|---|
| both | 23 | (all except the two below) |
| BricsCAD-only | 2 | MENULOAD, MENUUNLOAD (AutoCAD 2026 has no command-reference page; it directs users to CUILOAD/CUIUNLOAD, MENU retained only for script compatibility) |
| AutoCAD-only | 0 | — |

## Not-yet-implemented, by need

- **file** (NEW, OPEN, QSAVE, QNEW) and **customization** (MENULOAD,
  MENUUNLOAD) are the commands the cadtui host needs first: NEW/OPEN should
  create a `ui-drawing`; MENULOAD/CUILOAD should populate `bands`. Tracked
  as Phase 4 of the commands initiative.
- **view** (ZOOM, PAN, REGEN) map onto the cadtui viewport verbs already in
  the tree model.
- **modify** (SCALE, OFFSET) and **draw** (ARC, PLINE, RECTANG) extend the
  existing cador drawing-command dispatch.
