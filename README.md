# clautolisp

`clautolisp` is a Common Lisp project with two main goals:

1. formalize a standard-level AutoLISP / Visual LISP specification document;
2. develop an AutoLISP implementation in Common Lisp, intended in particular as a development, validation, and testing tool.

## Purpose

AutoLISP and Visual LISP are important Lisp dialects in the CAD world, but they do not have a single unified language standard comparable to the Common Lisp HyperSpec.

This project addresses that gap in two coordinated tracks:

- specification work:
  define a structured, source-backed, version-aware reference specification for AutoLISP / Visual LISP;
- implementation work:
  build a portable Common Lisp implementation that can execute and test AutoLISP code while making dialect, host, and compatibility choices explicit.

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

## Main Deliverables

### 1. AutoLISP Spec

The main specification draft is:

- `documentation/autolisp-visual-lisp-specification-draft.org`

Its short name is:

- `AutoLISP Spec`

This document aims to be a local reference document that can be used without constantly consulting external vendor documentation.

It includes:

- chaptered language specification text,
- dictionary-style entries for functions, variables, syntax classes, and runtime objects,
- source notes for specification elements,
- version and dialect notes,
- explicit identification of documented, inferred, and still under-specified behavior.

### 2. Common Lisp Implementation

The implementation track aims to provide:

- an AutoLISP reader and parser,
- an evaluator and runtime,
- compatibility layers for AutoCAD / BricsCAD host behavior,
- strict and lax compatibility modes,
- test tooling for compatibility probes,
- a standalone executable built with SBCL or CCL.

The implementation is written in portable Common Lisp as far as practical.

## Repository Layout

- `AGENTS.md`
  project-wide standing directives
- `COPYING`
  GNU AGPL-3.0 license text
- `Makefile`
  project automation for tests and document conversion
- `documentation/`
  planning documents, specification work, development notes, and test plans
- `specifications/`
  converted source material and specification-related documents

## Documentation

The repository uses Org mode as the default format for project documentation.

The main documents currently include:

- `documentation/autolisp-visual-lisp-specification-draft.org`
- `documentation/specification-resolution-plan.org`
- `documentation/development-plan.org`
- `autolisp-test/documentation/autolisp-test-development-plan.org`

Markdown is used only where it is the conventional or most practical format, such as this `README.md`.

## Build and Tooling

The project is intended to work with:

- SBCL
- CCL

The long-term build target is a standalone executable.

The `Makefile` also provides targets for:

- running tests,
- building PDF output from Org documents through `pandoc`.

## Testing

Testing is a core part of the project, not a late addition.

The testing strategy includes:

- pure language tests,
- compatibility probes against real AutoCAD and BricsCAD behavior,
- regression tests for reader, evaluator, and host-interface behavior,
- portability testing on both SBCL and CCL.

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

- `documentation/autolisp-visual-lisp-specification-draft.org` is intended to be licensed under `CC-BY-SA`.
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
