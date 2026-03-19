# Specification Authoring Rules

This file defines the formatting rules for the AutoLISP / Visual LISP specification documents in this repository.

The intent is to emulate the useful structural properties of the Common Lisp HyperSpec, while adapting them to the AutoLISP / Visual LISP domain and to the fact that our sources are incomplete, versioned, and vendor-specific.

## Source Model

When writing specification text, every normative statement must be tagged implicitly or explicitly as one of:

- `Documented`: directly supported by an official Autodesk or Bricsys source.
- `Tested`: established by executable tests against a named product/version/platform.
- `Inferred`: derived from multiple sources, examples, or strong consistency arguments.
- `Implementation-defined`: a choice made by `clautolisp` because the source corpus is incomplete or divergent.
- `Under-specified`: not yet resolved.

Every section and every dictionary entry must end with a `Source Notes` subsection listing the relevant sources and the status of the entry.

## HyperSpec-Derived Entry Formats

The Common Lisp HyperSpec varies its entry format by defined-name kind. The AutoLISP specification should do the same.

### Function Entry

Use this structure for ordinary functions and host functions:

1. `Name`
2. `Class`
   - Example: `Function`, `Host Function`, `Visual LISP Function`
3. `Syntax`
4. `Arguments and Values`
5. `Description`
6. `Return Values`
7. `Side Effects`
8. `Affected By`
9. `Exceptional Situations`
10. `Examples`
11. `Compatibility`
12. `Notes`
13. `Source Notes`

### Special Form Entry

Use this structure for special forms:

1. `Name`
2. `Class`
   - Example: `Special Form`
3. `Syntax`
4. `Arguments and Values`
5. `Description`
6. `Evaluation Rules`
7. `Return Values`
8. `Side Effects`
9. `Exceptional Situations`
10. `Examples`
11. `Compatibility`
12. `Notes`
13. `Source Notes`

### Variable Entry

Use this structure for variables, predefined variables, system variables exposed at language level, and special variables:

1. `Name`
2. `Class`
   - Example: `Variable`, `Predefined Variable`, `System Variable`
3. `Value Type`
4. `Initial Value` or `Initial Binding`
5. `Description`
6. `Affected By`
7. `Exceptional Situations`
8. `Examples`
9. `Compatibility`
10. `Notes`
11. `Source Notes`

### Type Entry

Use this structure for runtime-visible types:

1. `Name`
2. `Class`
   - Example: `Type`, `Host Type`, `Visual LISP Type`
3. `Supertypes` or `Related Types`
4. `Description`
5. `Representation`
6. `Valid Operations`
7. `Examples`
8. `Compatibility`
9. `Notes`
10. `Source Notes`

### Condition / Error Entry

Use this structure for AutoLISP-visible error classes, `ERRNO` classes, or `clautolisp` condition mappings:

1. `Name`
2. `Class`
3. `Triggering Situations`
4. `Reported Form`
   - message text, error object, or `ERRNO` class
5. `Recovery and Handling`
6. `Compatibility`
7. `Notes`
8. `Source Notes`

### Reader or Syntax Entry

Use this structure for lexical and syntactic constructs:

1. `Name`
2. `Class`
   - Example: `Reader Syntax`, `Lexical Syntax`, `Token Class`
3. `Concrete Syntax`
4. `Constituents`
5. `Description`
6. `Acceptance Rules`
7. `Strict/Lax Policy`
8. `Examples`
9. `Compatibility`
10. `Notes`
11. `Source Notes`

## Chapter Format

Each chapter should use a consistent structure modeled after HyperSpec chapters:

1. `Overview`
2. `Definitions`
3. `Normative Rules`
4. `Implementation Guidance`
5. `Compatibility`
6. `Dictionary Entries`
7. `Source Notes`

Not every chapter needs all subsections, but the order should remain stable.

## Chapter List Model

The Common Lisp HyperSpec chapter list is:

1. Introduction
2. Syntax
3. Evaluation and Compilation
4. Types and Classes
5. Data and Control Flow
6. Iteration
7. Objects
8. Structures
9. Conditions
10. Symbols
11. Packages
12. Numbers
13. Characters
14. Conses
15. Arrays
16. Strings
17. Sequences
18. Hash Tables
19. Filenames
20. Files
21. Streams
22. Printer
23. Reader
24. System Construction
25. Environment
26. Glossary

The adapted AutoLISP / Visual LISP chapter list should be:

1. Introduction
2. Syntax
3. Evaluation and Execution
4. Types and Runtime Classes
5. Data and Control Flow
6. Iteration
7. Symbols and Bindings
8. Numbers
9. Characters and Strings
10. Lists, Dotted Pairs, and Association Lists
11. Filenames, Paths, and Files
12. Streams and Text Input
13. Reader
14. Printer and External Representations
15. Errors and Recovery
16. Host Interaction
17. Selection Sets and Entity Access
18. DCL
19. Visual LISP Core Extensions
20. ActiveX, COM, and Automation
21. Reactors and Event Integration
22. Packaging, Compilation, and Namespaces
23. Environment Profiles and Dialects
24. System Construction and Delivery
25. Version Compatibility and Portability
26. Glossary

## Prompt Rules For Future Expansion

When generating a new chapter:

- follow the adapted chapter list in order,
- provide a chapter overview,
- define the normative scope of the chapter,
- extract or synthesize dictionary entries for all symbols whose primary home is that chapter,
- end with source notes and unresolved issues.

When generating a new symbol entry:

- choose the entry format by symbol kind,
- keep syntax in a dedicated subsection,
- distinguish return values from side effects,
- include compatibility notes for AutoCAD, BricsCAD, platform differences, and version drift,
- include strict/lax behavior where acceptance is ambiguous,
- include explicit source notes.

When resolving under-specified behavior:

- prefer `Documented` over `Tested`,
- prefer `Tested` over `Inferred`,
- prefer `Inferred` over `Implementation-defined`,
- never leave a normative statement without a `Source Notes` subsection.

## Repository-Specific Rules

- Specification source files should use Org mode by default.
- Paths inside specification files should be relative paths or `$SRC/...` forms, not absolute paths.
- `SPEC.md` is intentionally Markdown because it is a process/control document for AI-assisted specification authoring.
