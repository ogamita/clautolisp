# clautolisp / cador — project knowledge

What the sessions have learned about implementing the `cador` host,
beyond what the code and the git history already say. Updated by
`capture-session-knowledge` (rules repo, `prompts/`). Companion
directive file: [cador-implementation-agents.md](cador-implementation-agents.md).

Last updated: 2026-08-07

## 1. What this project is, and what it is not

- **cador is the deterministic headless CAD host** (ex mock-host; `--host
  mock` remains an alias of `--host cador`). It is not a recorder: since
  1.8.14 it EXECUTES the drawing/editing commands the corpus uses. The
  old design statement "MockHost has no command engine" is obsolete.
- **The SCHMS corpus defines "done".** The 2026-08-07 campaign
  (1.8.10 → 1.8.20, ten SCHMS rounds) took `make test-cad-clautolisp`
  ([sigfic-cad], host=cador, dcl=tui) from 6/6 ERROR to 6/6 OK. The next
  cador milestones are the other SCHMS CAD suites; expect each to expose
  its own layer of missing surface, in the same way.

## 2. Layout, entry points, and how the pieces fit

- `clautolisp/cador/source/command-api.lisp` — command log + echo + the
  drawing-command engine (`%execute-command-tokens`; one `%cmd-…` per
  command; `%command-selection` for object-selection input).
- `clautolisp/cador/source/entity-api.lisp` — entmake/entget/entmod…,
  the entmake BLOCK/ENDBLK block-definition path, the shared entity
  utilities (`%entity-group-value/-set-group`, `%entity-map-point-groups`,
  `%entity-translate`, `%entity-rotate-one`, `%entity-subentity-handles`,
  `%clone-entity-with-run`, `main-space-entity-p`,
  `table-record-al-view+extras`). Loaded BEFORE selection/table/command
  APIs: shared helpers belong here, not in vlax-api (cross-file forward
  references warn at compile).
- `clautolisp/cador/source/vlax-api.lisp` — loaded LAST: COM objects,
  live collections (`%blocks-collection`, `%block-object`,
  `live-collection-members`), the entity COM property/method bridge
  (`*entity-com-properties*`, `%entity-fallback-method`),
  `%insert-block`, `%entity-bounding-box`.
- **How SCHMS builds a block** (`creation_blocs.lsp`, observed
  2026-08-07): draw via `command` (`._donut ._line ._text ._solid`),
  collect entnext-after-marker into a selection set, optionally
  `command-s "_.rotate"`, then `command-s "_.-block" nom pt sel ""`.
  The entmake BLOCK/ENDBLK pair runs ONLY when nothing was drawn (empty
  block). `schms_inserer_bloc` = `vla-insertblock` on the ModelSpace,
  then `(vlax-ename->vla-object (entlast))`.
- **How SCHMS reads a block back**: the `-2` group of
  `(tblsearch "BLOCK" nom)` (also used by `schms_emplacement_tatouage_bloc`),
  then `entnext` within the block; metadata via XData
  (`entget ename '("SCHMSPLUS" …)`), not via ATTDEF/ATTRIB.

## 3. How to build, run, and test

All from `clautolisp/` (the subproject directory — running ASDF from the
repo root fails with `Component "clautolisp" not found`):

```sh
# cador suite alone (fast inner loop)
env XDG_CACHE_HOME="$PWD/.cache" sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:load-asd (merge-pathnames "clautolisp.asd" (uiop:getcwd)))' \
  --eval '(asdf:test-system "clautolisp/cador" :verbose t)'

# full umbrella suite (same form, system "clautolisp")
# build the binary, then end-to-end:
make build-clautolisp-sbcl
tools/clautolisp/bin/clautolisp-sbcl --host cador --dcl tui scenario.lsp
```

- **Without Quicklisp** (fresh Debian/Ubuntu container): `apt-get install
  sbcl cl-fiveam cl-bordeaux-threads cl-cffi cl-trivial-gray-streams`
  suffices for the suite and the binary — but `make test-sbcl` still
  fails there: its `--eval '(… (ql:quickload …))'` breaks at READ time
  (`Package QL does not exist`) even though the form is guarded by
  `(when (find-package :ql) …)` — the reader resolves `ql:` before any
  evaluation. Use the direct sbcl command above instead. *Candidate for
  promotion to a rules document (generic CL pitfall): a package-guarded
  form still needs `read-from-string`/`uiop:symbol-call` to survive the
  reader.*

## 4. Conventions and invariants

- **Dash commands are distinct commands.** `-FOO` is explicitly defined,
  its UI projected on the console TUI; `-` is not a modifier. Only `.`
  and `_` strip during name resolution (pjb, 2026-08-07).
- **The engine never signals; recording is unconditional.** Every
  `(command …)` lands on the command log whatever else happens.
- **Main-space discipline:** block-definition contents never appear in
  `ssget "X"`, `entlast`, or the top-level `entnext`; `entlast` also
  skips subentities (ATTRIB/VERTEX/SEQEND) — "last MAIN entity".
  `entnext` walks per-container; from a table-record ename it enters the
  block.
- **Vendor return contracts pinned this campaign:** entmake ENDBLK
  returns the block NAME; BLOCK tblsearch/tblnext/entget views carry
  `(-2 . first-entity)`; `entget` works on table-record enames;
  `-BLOCK` absorbs the selection translated so the base point becomes
  the definition origin (definition header 10 stored as 0,0,0 —
  InsertBlock's transform assumes base-relative coordinates).
- **ActiveX shapes:** properties like InsertionPoint =
  VARIANT(SAFEARRAY of doubles); GetBoundingBox out-symbols = BARE
  safearrays; GetAttributes = VARIANT(SAFEARRAY of vla-objects);
  `vlax-invoke`/`vlax-get`/`vlax-put` = plain nested lists both ways.
- **Live collections are identity-stable** (`cador-live-collection-ids`
  key strings: `"BLOCKS"`, `"BLOCK:<NAME>"`, …) and their members/Count
  recompute from the drawing on every access — never cache a member
  list.

## 5. Decisions

- **2026-08-07 — runtime hooks instead of moving `safearray-data`.**
  cador hands points/object-arrays across the layer boundary through
  `*com-point-wrap-hook*` / `*com-point-unwrap-hook*` /
  `*com-objects-wrap-hook*` (installed by autolisp-builtins-core, like
  `*vlax-collection-items-hook*`). Rejected: migrating the
  `safearray-data` struct from builtins-core down to the runtime —
  larger surface, no added faithfulness.
- **2026-08-07 — a real command engine in cador.** Rejected: staying
  record-only and porting the SCHMS factories to entmake — the corpus
  draws by `command` (70 `entlast` call sites follow that idiom) and is
  not ours to rewrite.
- **2026-08-07 — an entmake BLOCK header abandons a dangling open
  definition** instead of failing forever (one interrupted factory must
  not brick the session). SPEC-UNCERTAIN: vendor recovery behaviour
  unprobed; shipped as self-healing hardening (1.8.16) — it was NOT the
  sigfic bug.
- **2026-08-07 — command angular input parsed as decimal degrees**
  (AUNITS 0 assumption), stored radians per the entget convention.
  SPEC-UNCERTAIN: AUNITS/ANGDIR sensitivity unmodelled;
  `deferred-spec-research.issue`.

## 6. Pitfalls

- **"Item: no item named X in collection AutoCAD.Blocks"** after the
  factory ran → the block was created through a path the engine does not
  execute (historically: `-BLOCK` unknown → record-only). Check the
  engine's dispatch before suspecting the collections.
- **"attendu N <TYPE> … trouve 0 (types presents : )"** — empty block
  contents → the content was drawn through `command` calls the engine
  does not execute yet. The enumeration idioms were NOT the problem
  (three rounds lost there).
- **"VLAX-SAFEARRAY->LIST expects a SAFEARRAY, got #<VARIANT …>"** →
  something wrapped a value that the vendor hands bare (GetBoundingBox
  out-symbols was the case); the converse error means a bare value where
  the vendor wraps.
- **A side/topology check fails on ONE side only** (côté BAS ko, HAUT
  ok) → suspect a direction-dependent box/anchor rule: the text-height
  extension must follow the vertical justification (`_TL` grows DOWN).
- **Geometry subtly wrong after Move/Rotate/-BLOCK** → an entity kind
  with REPEATED point groups (LWPOLYLINE: one 10 per vertex) got only
  its first group transformed. Use `%entity-map-point-groups`.
- **`Component "clautolisp" not found`** → ASDF ran from the repo root;
  run from `clautolisp/`. (Shell `cd` state does not persist between
  tool calls in agent sessions — re-`cd` per command.)
- **Ten rounds for six tests.** The expensive failure mode was iterating
  on error messages against a reconstructed corpus. The three uploads
  that ended it: SIGFIC.LSP (drawing via `command`),
  creation_blocs.lsp (`-BLOCK` factory), test-cad-SIGFIC.lsp
  (topological oracle). *Candidate for promotion to a rules document:
  when emulating a platform under a third-party test corpus, get the
  corpus source for the exact failing path before the second blind
  iteration.*

## 7. Environment and tooling

- **The SCHMS suite runs on pjb's machine**, not in clautolisp CI:
  `cd ~/works/sncf-reseau/src/schms && make test-cad-clautolisp`
  (host=cador, dcl=tui; observed 2026-08-07, 6/6 OK at 1.8.20). Each
  clautolisp fix requires `make build-clautolisp-sbcl` + install on that
  machine before re-running.
- Verified green this campaign on SBCL only (2.2.9); the CCL lane was
  not exercised — see § 8.

## 8. Open questions and deferred work

- SPEC-UNCERTAIN probe backlog (vendor validation): command angular
  input vs AUNITS/ANGDIR; ENDBLK entity in the block entnext walk;
  entmakex on BLOCK/ENDBLK; vendor recovery from an abandoned entmake
  block pair; glyph-metric bounding boxes; MTEXT rotation units;
  EffectiveName on dynamic blocks — tracked in
  `vla-entity-property-bridge.issue` and `deferred-spec-research.issue`.
- Symbol-table ROW creation via entmake (LAYER/LTYPE/STYLE…) still
  deferred: `entmake-symbol-table-records.issue` (the BLOCK/ENDBLK
  definition path is done).
- CCL run of the post-1.8.10 surface: not yet done (`ci-github-ccl-lane`
  relates).
- Candidates for promotion to `<RULES_DIR>` once they have company
  (kept here per capture-session-knowledge §6.1): the corpus-source
  rule (§ 6 last entry) and the reader-vs-guard CL pitfall (§ 3).
