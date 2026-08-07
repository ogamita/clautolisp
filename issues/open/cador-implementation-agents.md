# cador implementation — agent directives

Directives for sessions implementing the rest of the `cador` host —
commands, functions, ActiveX object model. Background, rationale and
pitfalls: [cador-implementation-knowledge.md](cador-implementation-knowledge.md).
Project-wide rules stay in the repository root `AGENTS.md`; this file
adds only what is specific to cador work.

- **The SCHMS corpus is the acceptance driver.** Before implementing or
  "fixing" anything a SCHMS suite exercises, obtain the exact corpus
  source for the failing path (fixture + checker + the library functions
  between them). Do not iterate on the error message alone: the sigfic
  saga (2026-08-07, ten rounds) showed that a locally passing
  reconstruction proves nothing about the corpus path.
- **Command-name resolution:** strip only the `.` (English) and `_`
  (non-localized) prefixes. A leading `-` is part of the NAME — `-FOO`
  is a distinct, explicitly-defined command whose UI is projected on the
  console TUI (pjb, 2026-08-07). Register each dash form explicitly in
  `%execute-command-tokens`.
- **The command engine never signals.** Unknown commands and malformed
  input degrade to record-only (the command log is always written).
  Entities are created through `%host-add-entity` so reactors, `entlast`
  and the collections see them, on the current CLAYER/TEXTSTYLE.
- **COMMAND tokens may be non-strings:** a live selection set is a valid
  argument wherever a command prompts for object selection; parsers must
  guard with `stringp` before string operations.
- **Transform every point-group occurrence** (10/11/12/13) via
  `%entity-map-point-groups` — a LWPOLYLINE has one 10 group per vertex —
  and preserve point arity (2D vertices stay 2D).
- **Angles:** entity data (entget/entmod/COM `Rotation`) is radians;
  command-line angular INPUT is parsed as decimal degrees (AUNITS 0
  assumption, SPEC-UNCERTAIN — probe before changing either side).
- **ActiveX value shapes:** point properties return VARIANT(SAFEARRAY);
  `GetBoundingBox` output symbols receive BARE safearrays; object-array
  methods (GetAttributes) return VARIANT(SAFEARRAY of objects);
  `vlax-invoke`/`vlax-get`/`vlax-put` speak plain lists. Cross the
  cador↔builtins boundary only through the runtime `*com-…-hook*`
  variables — cador must never depend on autolisp-builtins-core.
- **Text boxes follow the vertical justification** (73 TEXT / 74
  ATTRIB-ATTDEF; `_TL` grows DOWNWARD from its anchor). SCHMS drawing
  checks are TOPOLOGICAL (per-element bbox y-midpoint ordering), so box
  direction matters more than glyph metrics.
- **Every increment ships whole:** DEVELOP bump in
  `tools/clautolisp/source/version.lisp`, RELEASE_NOTES + user-manual
  sync, a cador-layer regression test, an end-to-end `.lsp` run on the
  built binary (`clautolisp-sbcl --host cador --dcl tui`), full umbrella
  suite green.
