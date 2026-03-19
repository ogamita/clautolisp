# autolisp-reader Plan

## Purpose

This file tracks actionable work for the `autolisp-reader` system.

Architecture and normative design notes belong in `documentation/specification.org`.

## Current Status

- An initial reader specification exists.
- A first concrete reader implementation now exists for strings, streams, and files.
- The current implementation covers source spans, reader options, tokenization, form parsing, concrete comment-preserving parsing, and a self-contained SBCL test suite.
- Strict and lax acceptance modes still need executable conformance tests against real products.

## Foundation Tasks

- [x] Define the ASDF system for `autolisp-reader`.
- [x] Establish package names and source-tree layout for lexer, parser, CST, and diagnostics.
- [x] Choose the concrete source-location representation used by tokens and parsed objects.
- [x] Define the initial reader options object used by the reader entry points.

## Syntax Tasks

- [x] Implement external-format-aware decoding at the reader boundary.
- [x] Implement line-ending normalization while preserving line/column source positions.
- [x] Implement tokenization for whitespace, comments, delimiters, strings, symbols, integers, and reals.
- [x] Implement list parsing, quote parsing, and dotted-pair parsing.
- [x] Implement strict and lax acceptance modes.
- [x] Implement optional comment retention in reader results.
- [x] Implement warning support for integer-shaped tokens reclassified as reals because of signed 32-bit overflow.

## Data Model Tasks

- [x] Define reader result types for symbols, strings, numbers, cons forms, and comments.
- [x] Preserve source spans and original lexemes where the specification requires them.
- [x] Provide separate form-oriented and concrete comment-preserving result views.
- [ ] Define the handoff format from reader objects to later runtime objects.

## Test Tasks

- [x] Add deterministic tokenization tests.
- [ ] Add syntax error diagnostics tests.
- [ ] Add file-based external-format and encoding corpus tests.
- [x] Add line-ending normalization tests.
- [x] Add strict versus lax acceptance tests.
- [x] Add fixtures for retained-comment output.
- [x] Add tests for integer-overflow reclassification warnings.
