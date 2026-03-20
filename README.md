# clautolisp

`clautolisp` is organized as three coordinated subprojects:

1. formalize a standard-level AutoLISP / Visual LISP specification document;
2. develop an AutoLISP implementation in Common Lisp, intended in particular as a development, validation, and testing tool.
3. build `autolisp-test`, a conformance-oriented test suite for AutoLISP implementations and host profiles.

## Purpose

AutoLISP and Visual LISP are important Lisp dialects in the CAD world, but they do not have a single unified language standard comparable to the Common Lisp HyperSpec.

This project addresses that gap through three coordinated subprojects:

- specification work:
  define a structured, source-backed, version-aware reference specification for AutoLISP / Visual LISP;
- implementation work:
  build a portable Common Lisp implementation that can execute and test AutoLISP code while making dialect, host, and compatibility choices explicit.
- conformance-testing work:
  build a specification-oriented test corpus and harness that can be run against `clautolisp` and real AutoLISP implementations to produce versioned test reports.

The implementation is not meant only as a runtime. It is also intended to serve as:

- a compatibility laboratory,
- a conformance-testing tool,
- a reader and evaluator research platform,
- a host-emulation testbed for AutoCAD- and BricsCAD-like behavior.

## Project Status

The project is currently in a specification-first phase.

The specification document has been substantially expanded into a HyperSpec-style draft reference, and the remaining work is now mostly:

- closure of a few under-specified points,
- executable validation against real AutoCAD and BricsCAD behavior,
- progressive implementation of the language runtime and host layers.

## Subproject Status

- `autolisp-spec`:
  active and currently the most mature subproject; the specification draft exists and the remaining work is mainly gap-closure and validation.
- `clautolisp`:
  early implementation stage; the reader subsystem is implemented and has already read a real AutoLISP corpus of 663 `.lsp` files, 100583 lines, and 3508077 characters successfully, the first runtime and builtin layers exist, and the file-compatibility harness now executes 69 declarative file, pathname, stream, mutation, and printer scenarios with 140 checks on both SBCL and CCL, with product-runner adapters in place for later AutoCAD and BricsCAD audits.
- `autolisp-test`:
  conformance-suite planning stage; the subproject structure and development plan exist, but the harness and first projected tests still need to be implemented.

## Main Deliverables

### 1. autolisp-spec

The main specification draft is:

- `autolisp-spec/documentation/autolisp-visual-lisp-specification-draft.org`

Its short name is:

- `AutoLISP Spec`

This document aims to be a local reference document that can be used without constantly consulting external vendor documentation.

It includes:

- chaptered language specification text,
- dictionary-style entries for functions, variables, syntax classes, and runtime objects,
- source notes for specification elements,
- version and dialect notes,
- explicit identification of documented, inferred, and still under-specified behavior.

### 2. clautolisp

The implementation track aims to provide:

- an AutoLISP reader and parser,
- an evaluator and runtime,
- compatibility layers for AutoCAD / BricsCAD host behavior,
- strict and lax compatibility modes,
- test tooling for compatibility probes,
- a standalone executable built with SBCL or CCL.

Current implementation highlights include:

- `autolisp-reader`
  source-aware reader with strict/lax token modes, comment-preserving concrete reading, and standalone reader-validation tools;
- `autolisp-runtime`
  initial runtime object model and reader-to-runtime literal mapping;
- `autolisp-builtins-core`
  first numeric, list, string, file, and printer builtin families;
- `autolisp-file-compat`
  declarative compatibility harness for roundtrip and builtin-driven file/path/printer scenarios with machine-readable reports.

The implementation is written in portable Common Lisp as far as practical.

### 3. autolisp-test

`autolisp-test` is the third subproject of the project.

Its role is to provide an AutoLISP analogue of Common Lisp `ansi-tests`: a specification-oriented conformance suite that tests language behavior rather than implementation-specific extensions.

This branch aims to provide:

- a reusable test harness,
- a corpus of specification-backed tests grouped by language area,
- expected-failure overlays for specific implementation/version/host combinations,
- comparable conformance reports across `clautolisp`, AutoCAD, BricsCAD, and future implementations.

The planning document for this branch is:

- `autolisp-test/PLAN.md`

The design-rationale document for this branch is:

- `autolisp-test/documentation/autolisp-test-development-plan.org`

## Repository Layout

- `AGENTS.md`
  project-wide standing directives
- `COPYING`
  GNU AGPL-3.0 license text
- `Makefile`
  global dispatcher for subproject builds and documentation targets
- `autolisp-spec/`
  specification subproject, including the main specification and source-material conversions
- `clautolisp/`
  implementation subproject, including the ASDF system and implementation planning
- `autolisp-test/`
  conformance-test subproject, including its own documentation, harness, and test corpus

## Documentation

The repository uses Org mode as the default format for project documentation.

The main documents currently include:

- `autolisp-spec/PLAN.md`
- `clautolisp/PLAN.md`
- `autolisp-test/PLAN.md`
- `autolisp-spec/documentation/autolisp-visual-lisp-specification-draft.org`
- `autolisp-spec/documentation/specification-resolution-plan.org`
- `clautolisp/documentation/development-plan.org`
- `autolisp-test/documentation/autolisp-test-development-plan.org`

Markdown is used only where it is the conventional or most practical format, such as this `README.md`.

## Build and Tooling

The implementation subproject is intended to work with:

- SBCL
- CCL

The long-term build target is a standalone executable.

The global `Makefile` and subproject `Makefile`s provide targets for:

- running tests,
- building PDF output from Org documents through `pandoc`.

The `clautolisp` subproject also includes dedicated tools for:

- batch-reading `.lsp` corpora through `autolisp-reader`,
- running declarative file/path/printer compatibility scenarios through `autolisp-file-compat`.

## CI and Container Image

GitLab CI is configured in:

- `.gitlab-ci.yml`

The CI jobs use a prebuilt container image published in the GitLab container registry:

- `registry.gitlab.com/ogamita/clautolisp/clautolisp-ci:latest`

That image is defined by:

- `clautolisp/docker/Dockerfile`

It is intended to provide a reproducible Linux test environment with:

- SBCL,
- CCL,
- Quicklisp,
- FiveAM.

The root `Makefile` provides helper targets for building and publishing that image:

- `make docker-build-clautolisp-ci`
- `make docker-push-clautolisp-ci`

The default image name can be overridden when needed:

- `make docker-build-clautolisp-ci CLAUTOLISP_CI_IMAGE=registry.gitlab.com/ogamita/clautolisp/clautolisp-ci:dev`

The CI image is not rebuilt on every pipeline. The image-build job is configured to run only when the relevant CI or container inputs change, while ordinary test pipelines use the published `latest` image.

## Testing

Testing is a core part of the project, not a late addition.

The testing strategy includes:

- pure language tests,
- compatibility probes against real AutoCAD and BricsCAD behavior,
- regression tests for reader, evaluator, and host-interface behavior,
- portability testing on both SBCL and CCL.

The current implementation already includes an executable compatibility harness for file-oriented behavior in:

- `clautolisp/autolisp-file-compat/`

That harness supports:

- roundtrip byte/text/newline scenarios,
- builtin-driven pathname/search-path scenarios,
- builtin-driven file-mutation scenarios,
- builtin-driven printer/read-back scenarios,
- multi-step stream and file-descriptor scenarios,
- machine-readable JSON or s-expression reports with aggregate summaries.

The current local file-compat corpus passes on both SBCL and CCL with:

- 69 scenarios
- 140 checks

GitLab CI also runs the local SBCL and CCL file-compat jobs and retains the
JSON reports as artifacts under `clautolisp/.artifacts/`.

Because some parts of AutoLISP / Visual LISP are under-documented, executable testing against real products is a primary source of truth.

## Design Principles

- Keep AutoLISP semantics distinct from Common Lisp semantics.
- Do not let raw Common Lisp errors leak into the AutoLISP environment.
- Make dialect and host choices explicit.
- Separate reader, evaluator, builtins, host API, and tooling concerns.
- Prefer source-backed and test-backed specification statements.
- Support Windows-like host behavior independently from the native OS when needed.

## License

This project is licensed under the GNU Affero General Public License, version 3.

See:

- `COPYING`

The specification document is separate in this respect:

- `autolisp-spec/documentation/autolisp-visual-lisp-specification-draft.org` is intended to be licensed under `CC-BY-SA`.
- The external source documents cited and summarized by the specification remain under their own copyright and license terms unless their owners state otherwise.

## Roadmap

Near-term priorities are:

1. close the remaining under-specified parts of the specification;
2. build and run compatibility probe suites against AutoCAD and BricsCAD;
3. establish the first implementation modules:
   reader, runtime, error layer, host abstraction, and test kit;
4. make the test and documentation build flow routine.

## Contributing

This repository is currently specification- and architecture-driven.

Contributions should preserve:

- source-backed documentation discipline,
- explicit handling of dialect and host variation,
- portability across Common Lisp implementations,
- clear separation between AutoLISP semantics and Common Lisp implementation strategy.
