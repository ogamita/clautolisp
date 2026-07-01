# AGENTS.md

General directives for this repository.

## Scope

- This file records project-wide directives and standing instructions.
- Add new persistent project directives here when they are decided.
- More detailed design and planning material belongs in the relevant subproject `documentation/` directory.

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
runs `install-info --remove` to clean up.

## Change Discipline

- Prefer small, composable modules.
- Avoid mixing speculative features into foundational modules.
- Record significant architectural decisions in documentation when they affect future work.
- Do not silently broaden scope; note new standing directives here when they become project policy.

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

The **release** is versioned on its own axis, independent of any single
program's version. A release is marked by an annotated (or lightweight)
tag `vM.m.d` on the release commit.

- The release version `vM.m.d` is NOT the version of any one program.
  Each shipped program keeps its own version (`clautolisp`'s
  `version.lisp`, `alfe`, `read-autolisp`, `autolisp-spec`, …), tagged
  under its own prefix (`clautolisp-vA.B.C`, `alfe-vA.B.C`,
  `alref-vA.B.C`).
- A program version `foo-A.B.C` shipped in a release must have its
  **major.minor match the release's**: any `foo-A.B.C` living in the
  commits between `vM.m.0` and the tip of `release-M.m` must have
  `A.B = M.m`. The development counter `C` is a per-program monotonic
  counter and need NOT match across programs or the release.
  - Exception: a program that has not changed may stay at an older
    `A.B.C` with `A.B < M.m` and still ship inside `release-M.m.d`.

**Only clean `vM.m.d` tags are release boundaries.** Ignore, for this
purpose: pre-release tags (`vM.m.d-rcN`), program-prefixed tags
(`clautolisp-v*`, `alfe-*`, `alref-v*`), and CI/misc tags (`ci-win`).

For every release tag `vM.m.d` there must be two branches:

- **`release-M.m.d`** — created on the same commit as `vM.m.d`. As a
  branch it advances onto the following commits until the next release
  tag `vM'.m'.d'` appears, at which point it is frozen (its tip is the
  commit just before that next tag). The patch branches thus tile the
  linear history: one contiguous segment each, no gap, no overlap.
- **`release-M.m`** — the branch that contains *every* `M.m.d` release,
  whatever the value of `d`. It advances and keeps advancing until a tag
  `vM'.m'.d'` with `M'.m' ≠ M.m` appears (the first release of a new
  minor), then it is frozen just before that tag. The current minor's
  `release-M.m` never freezes — it tracks the development line (master).

Concretely, when a new release tag `vM.m.d` is placed on commit `C`:

1. freeze the currently-live `release-*.*.* ` patch branch at `C^` and
   create `release-M.m.d` at `C`;
2. if `M.m` is unchanged, `release-M.m` keeps advancing; if `M.m` is new,
   freeze the previous `release-*.*` at `C^` and create `release-M.m`
   at `C`.

Between releases, fast-forward the two live branches (`release-M.m` and
the current `release-M.m.d`) as the development line advances. Push the
release branches to the canonical remote (`origin`).
