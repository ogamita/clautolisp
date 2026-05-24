# alfe conformance scenarios

This tree is the scenario corpus the alfe.conformance runner walks
on every `make -C autolisp-front-end test`. Each `.sexp` file
declares one scenario as a property list; the runner spawns alfe's
in-process CLI, captures stdout/stderr/exit-code, and compares them
against the expectations in the file.

See `../../source/conformance.lisp` for the full scenario-plist
spec.

## Layout

```
scenarios/
├── cli/           — argument parsing, exit codes, --help / --version
├── actions/       — -x / -l / --main / --quit behaviour
├── encoding/      — UTF-8 / ISO-8859-1 / Windows-1252 × LF/CRLF
├── clautolisp/    — clautolisp-backend-specific invariants
├── bricscad/      — BricsCAD-specific (skipped if no BricsCAD)
└── autocad/       — AutoCAD-specific (skipped if not on Windows)
```

## Classifications

| Classification     | Runs when                                                                 |
|--------------------+---------------------------------------------------------------------------|
| `:portable`        | Always (no backend required).                                             |
| `:clautolisp-only` | The clautolisp backend is registered (the default).                       |
| `:bricscad-only`   | BricsCAD's `detect` succeeds on the host.                                 |
| `:autocad-only`    | AutoCAD's `detect` succeeds — i.e. running on Windows.                    |
| `:parity`          | `$AUTOLISP_LEGACY` points at a co-located legacy bash wrapper.            |

Scenarios that can't run on the current host return `:skipped`
rather than failing — the runner reports them separately in its
summary.

## Adding a scenario

1. Pick the right subdirectory (see Layout above).
2. Drop a `.sexp` file with a property list of the documented
   shape.
3. Re-run `make test`. New scenarios are picked up automatically by
   the directory walk; no manual registration needed.
4. If your scenario exercises a new CLI option, add the option's
   spelling to `:covers-options` — the spec-coverage check uses
   that to assert every option in the spec has at least one
   scenario covering it.
