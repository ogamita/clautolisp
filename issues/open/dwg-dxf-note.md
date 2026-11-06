# DWG vs DXF — fundamental differences, and which sysvars are saved

*Note, 2026-09-25. Reference note, not a formal tracked issue.*

## The fundamentals

| | **DWG** | **DXF** |
|---|---|---|
| Role | Native storage format | Interchange / exchange format |
| Encoding | Proprietary binary | ASCII (group-code / value text) *or* Binary DXF |
| Spec | Undocumented (reverse-engineered: ODA/Teigha, libredwg) | Publicly documented by Autodesk |
| Fidelity | Full native database | Documented subset — can be lossy |
| Size / speed | Compact, fast, indexed | Large, slower, but diff-able / greppable / scriptable |

Key point: **DWG is the whole database; DXF is the documented lowest-common-denominator view of it.** DXF captures most entities, tables, dictionaries, xrecords and XDATA, but proprietary / custom objects, proxy objects, ACIS solids (SAB), graphics caches, thumbnails, encryption, and some app-specific object data are omitted or embedded as opaque blobs. A DWG -> DXF -> DWG round-trip can degrade content that a DWG -> DWG copy preserves.

## Do CAD apps write sysvars to DXF too?

Yes — but with a distinction that trips people up: **not every "system variable" is a *drawing* variable.** Each AutoCAD sysvar has a "saved in" attribute:

- **Saved in *drawing*** (CLAYER, INSUNITS, LUNITS, LTSCALE, DIMSCALE, `$ACADVER`, `$HANDSEED`, ...). These are the drawing's **header variables**. They live in the `HEADER` section of **both** formats — in ASCII DXF as `9\n$VARNAME` + value groups, in DWG as the header record. The drawing-scoped sysvar set written to DXF is the *same* set written to DWG.
- **Saved in *registry / profile / preference*** (FILEDIA, PICKBOX, and — relevant to us — BricsCAD's **`SAVEFORMAT`**, which is `:scope :preference`). User / environment settings, **not drawing content** -> written to *neither* DWG nor DXF.
- **Not saved** (session-only or read-only / computed, e.g. DWGNAME). Never in the file.

So it is **not** that DWG stores a richer *sysvar* set than DXF — the header-variable set is shared. What DWG stores that DXF may not is the richer *object / entity* database.

Two caveats:

1. **Version-gating.** A file written to an older release omits header variables (and objects) introduced later — the `$ACADVER` axis. This is exactly why `SAVEFORMAT` couples container *and* version, and why per-version output is a real codec concern.
2. A handful of header variables are marked internal / not-written in Autodesk's DXF reference, so the overlap is ~complete but not literally 1:1.

## clautolisp mapping

- `drawing-header-variables` / `drawing-variable` = the drawing-scoped (header) sysvars the DXF codec emits, including `$ACADVER` from `drawing-version`.
- A cell like `SAVEFORMAT` with `:scope :preference` is a setting the engine reads, never serialized into the drawing file. `CLAUTOLISPDEFAULTDRAWINGFORMAT` is the same category (a write-format preference), not a header variable.
- Per-version codec output is still a stub: the DXF/DWG writers record the requested version ($ACADVER / drawing-version) but emit a fixed one — tracked by `issues/open/drawing-codec-version-output.issue`.
