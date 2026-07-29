# AGENTS.md

General directives for this repository.

## Scope

- This file records project-wide directives and standing instructions.
- Add new persistent project directives here when they are decided.
- More detailed design and planning material belongs in the relevant subproject `documentation/` directory.
- Some normative rules are shared across projects and live in the [`informatimago/rules`](https://gitlab.com/informatimago/rules) repository — read the relevant one before the work it governs. In particular [`version-rules.md`](https://gitlab.com/informatimago/rules/-/blob/master/version-rules.md) governs version numbers, release tags, and branches (summarised under [Release tags and branches](#release-tags-and-branches)), and [`build-rules.md`](https://gitlab.com/informatimago/rules/-/blob/master/build-rules.md) governs the Makefile phases and install/release structure.

## Project Nature

- This project is a Common Lisp implementation of an AutoLISP runtime and related tooling.
- The goal is to run AutoLISP code faithfully while using Common Lisp as the implementation substrate.
- Preserve a clean separation between AutoLISP semantics and Common Lisp implementation details.

## Source Encoding and Text Handling

- Use UTF-8 encoding by default for repository files.
- Use Unix newlines (`LF`) by default.
- Input files may use other encodings and other line termination conventions.
- The program must correctly handle such input files.
- Text decoding and line-ending normalization must be treated as part of the reader/input boundary.
- Use Org mode as the default format for text documents in the repository.
- Use Markdown only for files that are primarily intended for AI agents or are conventionally maintained as Markdown, such as a GitLab `README.md`.

## Naming

- Use `-` in file names instead of `_`.
- Prefer clear, stable names over abbreviations unless the abbreviation is standard in the AutoLISP or Common Lisp domain.
- Keep naming consistent across ASDF systems, packages, source directories, and documentation.

## Paths in Project Files

- In documentation, Makefiles, scripts intended for the repository, and other project files, use relative pathnames rather than absolute pathnames.
- Prefer paths relative to the current directory or to the repository root.
- When a repository-root-relative path needs to be made explicit in prose or examples, `$SRC/relative/path` may be used.
- Avoid embedding machine-specific absolute paths in committed project files.
- Absolute pathnames are allowed only in temporary or disposable local tooling when no practical relative form is suitable.

## Language and Portability

- Favor portable Common Lisp where practical.
- Keep compatibility with both CCL and SBCL in mind.
- Avoid unnecessary implementation-specific behavior in core modules.
- If implementation-specific code is required, isolate it behind a narrow interface.

## Architecture

- AutoLISP is a distinct language layer and must not be treated as ordinary Common Lisp source.
- Preserve AutoLISP semantics explicitly instead of relying on accidental Common Lisp behavior.
- Keep reader, runtime, builtins, host integration, and UI concerns in separate modules.
- Prefer explicit runtime data structures for environments, symbols, and evaluation state.
- Keep CAD-specific behavior behind host abstraction layers.
- Support dialect differences explicitly when they matter, rather than scattering ad hoc conditionals.
- Separate CAD-product compatibility from operating-system compatibility.
- The runtime must be able to present a selected host environment profile independently of the actual operating system.
- In particular, the system may run on macOS or Linux while exposing a Windows-like host environment to AutoLISP / Visual LISP code when configured to do so.
- Platform-specific host services, including Windows-oriented facilities such as ActiveX / COM behavior, should be mediated through an emulation or compatibility layer rather than inferred directly from the native OS.
- The selected host environment profile should be controlled by explicit configuration or command-line options.
- Common Lisp conditions and errors must not leak directly into the AutoLISP environment.
- Each implemented AutoLISP / Visual LISP library function should catch underlying Common Lisp errors and route them through a wrapper that converts them into AutoLISP-visible errors.
- AutoLISP-visible error behavior should be centralized so that `*error*`, `vl-catch-all-apply`, and related mechanisms see consistent implementation-defined errors.

## Build and Delivery

- The project must be buildable with CCL.
- The project must be buildable with SBCL.
- The build should be able to produce a standalone executable.
- Command-line and batch execution are first-class use cases.

## Licensing

- The project is licensed under AGPL-3.0.
- Keep a top-level `COPYING` or `LICENSE` file containing the project license text.
- Free software dependencies and reused code are acceptable, including permissive licenses, GPL, and AGPL.
- When adopting external code, record the source and applicable license in documentation or source headers as appropriate.
- The specification document `autolisp-spec/documentation/autolisp-visual-lisp-specification-draft.org` must be licensed under CC-BY-SA.
- The specification may quote, summarize, and reference external source documents, but those source documents remain under their own copyright and license terms unless explicitly stated otherwise by their owners.

## Testing

- Testing is a core part of the architecture, not a later add-on.
- Prefer deterministic automated tests.
- Keep pure language tests separate from host-dependent integration tests.
- Ensure the core test suite runs on both SBCL and CCL.
- Add regression tests when fixing behavior or compatibility issues.
- Use test-driven development when fixing bugs or correcting issues: first identify an existing failing test or add a new failing test, then make the fix.

## Documentation

- Specifications converted from PDF should be maintained as Org mode files when added to the repository.
- Generated PDFs are build artefacts, not source: the canonical form is the `.org` (or man page), and the Makefiles render the `.pdf` at build/install time. Do not commit generated PDFs — `*.pdf` is gitignored. Keep the Makefile rules that build them. Existing already-tracked `.pdf` files are left in place (the ignore rule does not retro-remove them).
- Planning, architecture, and decision documents should be written in Org mode under the appropriate subproject `documentation/` directory.
- Each subproject must have a `PLAN.md` file at its root.
- Within the `clautolisp/` implementation subproject, each ASDF system should live in its own subdirectory, with its own `PLAN.md`, documentation, sources, and related module-local files.
- Actionable task lists, upcoming work, and backlog items belong in the subproject `PLAN.md`, not in the explanatory Org documents.
- Keep documentation aligned with actual architectural decisions and module boundaries.
- `autolisp-spec/documentation/autolisp-visual-lisp-specification-draft.org` has the short name `AutoLISP Spec`.
- `autolisp-spec/documentation/autolisp-visual-lisp-specification-draft.org` must carry an explicit document version.
- Any modification to `autolisp-spec/documentation/autolisp-visual-lisp-specification-draft.org` must increment that document version.

## External References and Candidate Dependencies

- Robert Strandh's modular Common Lisp work is a useful architectural reference, especially SICL and related libraries.
- Prefer borrowing architecture, protocols, and data-model ideas from SICL-related projects before borrowing code.
- Permissive, GPL, and AGPL dependencies are all acceptable for direct reuse in this project.

### Robert Strandh and S-Expressionists References

- `SICL`: reference for modular architecture, implementation-independent subsystems, and protocol-driven design.
- `Eclector`: strong reference for customizable reading, parse-result protocols, source-aware reading, error recovery, and separation between reader behavior and parse result construction.
- `Concrete-Syntax-Tree`: strong reference for attaching source information to syntax objects and preserving syntax structure independently of raw Lisp objects.
- `Clostrum`: reference for explicit first-class environment objects and clean protocol design around environments.
- `Trucler`: reference for environment query/update protocols and introspection-friendly environment modeling.
- `Ecclesia`: reference for utilities that operate on parsed Lisp code without collapsing structure too early.
- `Acclimation`: reference for structured condition reporting and user-facing diagnostics in portable Common Lisp systems.
- `Cleavir`: reference for protocol-based compiler architecture and explicit intermediate representations, even if this project does not adopt compiler infrastructure directly.
- `Iconoclast`: reference for parsing and syntax analysis techniques, especially where preserving structure matters.

### Quicklisp Candidates

- `alexandria`: acceptable default utility dependency for portable helpers.
- `uiop`: acceptable default portability dependency for filesystem, pathname, process, image, and command-line support.
- `babel`: candidate for explicit charset encoding and decoding support.
- `flexi-streams`: candidate for layered stream decoding when stream composition is useful.
- `trivial-gray-streams`: candidate when custom stream classes are needed portably.
- `bordeaux-threads`: candidate if asynchronous UI communication or background workers require portable threading primitives.
- `fiveam` or `parachute`: acceptable test framework candidates. Prefer one framework consistently across the project.
- `named-readtables`: acceptable for REPL tooling or optional developer syntax layers, but not as the foundation of the AutoLISP reader architecture.
- `inquisitor`: candidate for input encoding and end-of-line detection across implementations.
- `adopt`: candidate for command-line option parsing for the standalone executable.
- `closer-mop`: candidate only if portability of MOP-dependent abstractions becomes necessary.

### com.informatimago References

- `com.informatimago.rdp`: reference for recursive-descent parser structure and parser-generator ideas.
- `com.informatimago.common-lisp.parser`: reference for scanner/parser separation and parser error object structure.
- `com.informatimago.common-lisp.lisp-reader`: reference for customizable token parsing and reader decomposition.
- `com.informatimago.common-lisp.lisp-text.source-text`: reference for source-position tracking and source-aware syntax objects.
- `com.informatimago.common-lisp.lisp-sexp.source-form`: reference for explicit syntax-processing utilities over structured forms.
- `com.informatimago.clext.character-sets`: reference for portable external-format handling.

### Licensing Note

- Many `com.informatimago` components are AGPL-licensed.
- `com.informatimago` may be used both as a source of ideas and, where useful, as a direct dependency or source-reuse candidate.
- Before adding any `com.informatimago` code as a direct dependency, verify the exact license of the specific subsystem and record it.

### Current Adoption Guidance

- For the AutoLISP reader, prefer a dedicated lexer/parser with source-aware syntax objects.
- Use `Eclector` and `Concrete-Syntax-Tree` primarily as design references; direct reuse may be considered later for tooling or editor-oriented readers, but the project still needs an AutoLISP-specific reader.
- Consider `Clostrum` and `Trucler` as references for explicit environment objects and introspection protocols, not as direct semantic models of AutoLISP.
- Use Quicklisp libraries for portability and tooling support, not to outsource core AutoLISP semantics.
- Keep the project's core semantics independent from any single external library so the runtime remains understandable and portable.

## Documentation Synchronisation

Each subproject keeps four parallel documentation tracks that must
stay in lock-step. The matrix:

| Track            | Authoring             | Built artifacts           | Install location                          |
|------------------|-----------------------|---------------------------|-------------------------------------------|
| code             | source/, tools/       | binaries + `--help`       | `$(PREFIX)/bin/`, `$(PREFIX)/libexec/<s>` |
| specifications   | `documentation/*specifications.org` | `.pdf` + `.info` | `$(PREFIX)/share/doc/<subproject>/`       |
| user-manual      | `documentation/*user-manual.org`    | `.pdf` + `.info` | `$(PREFIX)/share/doc/<s>/` + `share/info` |
| man page         | `documentation/<bin>.1.man`         | `.1` (groff)     | `$(PREFIX)/share/man/man1/`               |

`.info` files for user-manuals install under `$(PREFIX)/share/info`
and the dir node is updated via `install-info --info-dir`.

**The synchronisation rule.** Any change to one track requires
matching changes in the others:

- A spec change → review code, user-manual, man page; bring them up.
- A code change adding/modifying an option → update the `--help`
  string, the man page (OPTIONS section), the user-manual, and the
  spec if the option carries semantic weight.
- A `--help` text change → mirror into the man page (it is the
  terse cousin of the user-manual and reads off the same option
  vocabulary).
- A new subproject → seed all four tracks at creation time (even
  if specifications and user-manual start as stubs that point at
  the README + PLAN.md).

The intent: a contributor opening any single track can trust the
others reflect the same world. Drift between code and docs is a
review-blocking defect, treated the same as a failing test.

**On the man-page convention.** Library subprojects (those without
a CLI binary) skip the man page — there is no `man 1` audience for
them — but still ship specs + user-manual (where "user" means a
Common Lisp developer integrating the library).

**On the `dir` update.** `make install` runs `install-info` after
copying the `.info` files so `info <doc>` works against the
standard top-level dir node. The accompanying `make uninstall`
runs `install-info --remove` to clean up. The staged tree carries a
`share/info/dir` of its own (staging goes through the same
`install-documentation` recipe); `install-documentation` excludes it
from the copy — it names only our manuals, so overwriting `$PREFIX`'s
would drop every other package's entries — and re-registers each
manual in the real dir node instead.

## Change Discipline

- Prefer small, composable modules.
- Avoid mixing speculative features into foundational modules.
- Record significant architectural decisions in documentation when they affect future work.
- Do not silently broaden scope; note new standing directives here when they become project policy.

## Dialect Divergence and Warnings

When implementing **any** `autolisp-spec` operator, system variable, or
behaviour, you MUST classify it against the dialects before writing the
code. The governing rules are normative in the specification:

> `autolisp-spec` Chapter 25, *Environment Profiles and Dialects* →
> *Normative Rules: Dialect Portability Warnings* →
> *Behavior versus warning, and the divergence taxonomy*.

Read that section and apply it. In brief:

- **Behaviour and warning are orthogonal.** Every value is accepted; the
  function does *something* (returns, or a non-local exit — an error can
  be the expected result). There is no "out-of-range / rejected" input.
  A warning is a separate advisory portability diagnostic on
  `*error-output*` that never changes the value channel.
- Classify each `(function, argument-shape)` into one of four cases and
  set behaviour + warning per dialect (`lax`, `--autocad`, `--bricscad`,
  `clautolisp`, `strict`) accordingly:
  0. **Common** — both reference docs agree, both products match → no warning.
  1. **Extension** — present in some implementations only → clautolisp
     runs it; warn under any dialect that isn't the owner (`lax` silent).
  2. **Divergence (resolved)** — vendors behave differently (the docs
     differ, *or* a product contradicts an agreed doc). The autolisp-spec
     **adopts one vendor as normative** (usually the better-specified —
     historically AutoCAD) and records which/why in the `*** clautolisp`
     note. The adopted-vendor dialect and `clautolisp` perform the
     normative behaviour silently; the **deviant** vendor's dialect
     reproduces the other behaviour and warns (*not condoned*); `strict`
     performs the normative behaviour but **also warns**; `lax` does the
     most useful thing, silently.
  3. **Divergence (unresolved, symmetric)** — the autolisp-spec adopts
     *neither* (genuinely irreconcilable) → **every dialect except `lax`
     warns** (a majority does not make it "right").
- **`strict` warns on *any* divergence** (case 2 or 3) — a divergence of
  any kind means the feature is unsafe to rely on. Code that runs clean
  under `strict` is portable.
- Distinguishing case 2 (resolved) from case 3 (unresolved) needs probe
  results matched against **both** vendor reference documents; until that
  evidence exists, treat the difference as case 3 (symmetric) so no vendor
  is wrongly blamed, and record the open question per *Unverified Spec
  Behaviour* below.
- Every function entry that has a per-vendor difference MUST state, in its
  `*** clautolisp` deviation note, which case it is and what each dialect
  does.

## Probes, Tests, and Benchmarks

Three distinct instruments — do not conflate them. Each one's result is a
function of the **dialect × version** combination it runs under:

- **Probe** — *exercise* a feature to compare its behaviour against the
  specification. A probe is an INSTRUMENT, not a judge: it runs the
  operation (including the divergent and edge cases) and REPORTS the
  *exhibited* behaviour; it does not itself decide pass/fail. The
  comparison against the spec's per-target expectation (and the
  CONFORMS / KNOWN-DIVERGENCE / UNEXPECTED verdict) is done by the
  runner, not baked into the probe. A probe that has been tuned to
  "always pass" has stopped probing.
- **Test** — *validate* that a feature works as specified/expected. Here a
  fixed expected result is correct, and the outcome is pass/fail (the
  FiveAM suites).
- **Benchmark** — *measure how fast* a feature works (the
  autolisp-benchmark harness).

### Probe observation model (autolisp-spec ch.25)

Conformance probes under `autolisp-front-end/tests/scenarios/` emit one
machine-readable line per observation:

    OBSERVE <name> <token>

where `<name>` is a stable dotted key and `<token>` is a single
whitespace-free word recording the *exhibited* behaviour (a `yes`/`no`
property for portable behaviour, or the distinguishing raw value for a
divergent one — e.g. `payload` vs `payload2`). The probe ends with
`OBSERVATIONS <n>`. Each scenario `.sexp` carries `:expected-observations`
— `(NAME EXPECTED-TOKEN &optional NORMATIVE-TOKEN)` per target, derived
from the spec (see `generate-schms-scenarios.lisp`). The runner
(`alfe.conformance`) compares exhibited vs expected and gates on
`UNEXPECTED` / missing observations; a `KNOWN-DIVERGENCE` (expected
differs from the normative token) is reported but green. Divergences are
EXERCISED and REPORTED, never hidden. When adding or changing a probe,
supply the per-target expectations from the § Dialect Divergence
resolution, not a single "correct" answer.

## Unverified Spec Behaviour

When an implementation chooses behaviour that the spec doesn't
explicitly pin down (edge cases, missing-host shortcuts,
character-width ratios, etc.), record the uncertainty in two
places so it doesn't get lost:

1. **In the source**, as an inline `;;; SPEC-UNCERTAIN:` marker
   in the function's comment block, naming what's unverified.
   Greppable from the repo with

       grep -rnE "SPEC-UNCERTAIN" clautolisp/

2. **In `issues/open/deferred-spec-research.issue`**, as a
   section under the function's name with concrete probe
   questions. Lets us run one focused vendor-validation pass
   over many functions at a time instead of rediscovering each
   uncertainty separately.

Once a probe resolves the uncertainty, replace the
`SPEC-UNCERTAIN` marker with a concrete `;;; Vendor: ...` cite
(the matching `autolisp-spec` Tested Behaviour line, or the
probe script that produced the answer), and move the issue
entry to the issue's Resolved tail.

## Stubbed Implementations

Operators registered as "name exists, body returns the documented
no-op (nil or "")" — so portable user code that calls or
boundp-checks them keeps running, but the actual behaviour
is deferred — follow the same two-place pattern as
SPEC-UNCERTAIN, with a different marker:

1. **In the source**, an inline `;;; STUB: <one-line summary>`
   marker pointing at the catalog entry. Greppable with

       grep -rnE "STUB:" clautolisp/

2. **In `issues/open/deferred-stubbed-functions.issue`**, a
   section per stubbed operator (or per stubbed-family group)
   with concrete upgrade paths sorted lightest → heaviest.
   The catalog distinguishes "could never reasonably be more
   than a no-op" (TABLET) from "trivially upgradable" (HELP
   → exec info) from "ambitious but feasible"
   (SHOWHTMLMODALWINDOW → embed a WebView).

When a stub is promoted to a real implementation, delete the
`STUB:` marker, replace it with a normal docstring describing
the real behaviour, and move the issue entry to the issue's
Resolved tail.

## Release notes

- The repo-root file `RELEASE_NOTES.org` records every user-visible
  feature shipped by the programs that `make install` places under
  `$PREFIX` (clautolisp, alfe, read-autolisp, autolisp-spec docs,
  the autolisp-test harness).
- `RELEASE_NOTES.org` MUST be updated in the same commit as any
  change that affects the user experience. That includes:
  - new features, options, dialect modes, builtins;
  - changes to existing user-visible behaviour (output format,
    error / diagnostic codes, default values);
  - observable performance improvements (faster startup, lower
    memory, narrower output) — list these as "Optimisations"
    under the relevant subproject;
  - new files or directories produced by `make install`;
  - new docs that ship under `share/doc/`.
- Internal refactors with no user-visible effect (renamed CL
  functions, moved files, test-only changes, comment edits) do
  NOT require a `RELEASE_NOTES.org` entry.
- Each entry should be 1–3 lines. The full reference lives in the
  per-subproject `documentation/<name>-user-manual.org`; the
  entry just names the feature and links the manual section.
- Keep entries grouped under the subproject they ship in
  (clautolisp / alfe / autolisp-spec / autolisp-test). If a
  feature spans subprojects, mention it once in the most
  user-facing one and cross-link.

## Release tags and branches

The normative rules are shared across projects and live in
[`version-rules.md`](https://gitlab.com/informatimago/rules/-/blob/master/version-rules.md)
(repository: <https://gitlab.com/informatimago/rules>) — read it before
cutting a release. What follows is the summary and the parts specific
to this repository.

**The three kinds of ref, never mixed:**

- `release-M.m.d` — an **annotated tag**. A frozen feature set; never
  moves, never deleted. This is the ref a GitLab/GitHub Release is made
  from. `release-*` is a tag-only namespace: no branch may be named
  that way.
- `version-M.m` and `version-M` — **pointer branches**. Nothing is ever
  committed on them; they are only fast-forwarded onto a commit that
  carries a `release-*` tag, so checking one out always yields a
  released state. `version-1.6` is what a user tracking "1.6" follows.
- `master`, `maint-M.m`, `dev-M.m` — **development lines**, the only
  branches commits land on. `maint-M.m` is created on demand at the
  newest `release-M.m.d` when a fix must ship for a frozen series
  without dragging in trunk work; `dev-M.m` names a development line
  for an unreleased version when more than one future is in flight.
- `fix-<slug>`, `feat-<slug>` — **work branches**. Every change gets
  one, forked from the *oldest* line that could need it, one concern
  per branch, deleted once merged. This is what lets the destination be
  chosen at the end: a fix may ship in `release-1.2.3` while the
  feature it needed also goes to `dev-1.3`. Merges only ever flow
  forward, from older line to newer.

**Version numbers:** `M` = incompatible change, `m` = user-visible
feature change, `d` = bug fixes and changes with no user-visible
effect. `d` is monotonic within a series but need not be contiguous —
this repository couples it to clautolisp's DEVELOP counter, which is
why `release-1.6.0` is followed by `release-1.6.11`.

**Programs versus the release.** The release version is its own axis.
Each shipped program keeps its own version (clautolisp's
`version.lisp`, alfe, read-autolisp, autolisp-spec, …); a program
changed within a series must have `A.B = M.m`, and a program that has
not changed may stay at an older `A.B` and still ship. Programs are
**not** tagged separately: the `clautolisp-v*`, `alfe-*` and `alref-v*`
tag formats are **deprecated**. The existing tags stay (they are
published immutable refs), but no new ones are created — a program
version is read from its source.

**Cutting a release** (full procedure in `version-rules.md` § 5):

1. bump the shipped programs' stamps, update `RELEASE_NOTES.org`, commit;
2. `git tag -a release-M.m.d`;
3. fast-forward `version-M.m` and `version-M` onto that commit
   (creating `version-M.m` when `d = 0`);
4. push the tag and both pointers to `origin`;
5. post-release bump on master, so no untagged commit claims a released
   version;
6. `glab release create release-M.m.d`.

**Build, install and release structure.** The Makefile phases
(`programs` / `libraries` / `documentation`), the four verbs over them,
why `install` never compiles, and the provenance manifest every staged
tree carries are the shared
[`build-rules.md`](https://gitlab.com/informatimago/rules/-/blob/master/build-rules.md).
`scripts/make-manifest.sh` and `scripts/check-versions.sh` are vendored
copies from that repository — fix them there, then re-vendor;
`scripts/manifest-versions.sh` is the project-specific hook naming the
programs this repo ships.

**Verification.** `make check-versions` audits the repository against
the invariants; run `git fetch --prune --tags` first. It is expected to
pass on master at all times.

**Legacy refs.** Releases up to 1.6.11 were originally marked `vM.m.d`
with `release-M.m.d` / `release-M.m` *branches*; the branches are gone,
replaced by the tags and pointers above. The old `vM.m.d` tags are kept
as immutable aliases of the corresponding `release-M.m.d` tags: that
format is **deprecated**, not deleted — use `release-M.m.d` for every
new release. `release-1.3.1` not being an ancestor of
`release-1.4.0` is correct, not damage: it is a maintenance release cut
in parallel with trunk development (`version-rules.md` I4).
