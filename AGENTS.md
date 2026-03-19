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

## Documentation

- Specifications converted from PDF should be maintained as Org mode files when added to the repository.
- Planning, architecture, and decision documents should be written in Org mode under the appropriate subproject `documentation/` directory.
- Each subproject must have a `PLAN.md` file at its root.
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

## Change Discipline

- Prefer small, composable modules.
- Avoid mixing speculative features into foundational modules.
- Record significant architectural decisions in documentation when they affect future work.
- Do not silently broaden scope; note new standing directives here when they become project policy.
