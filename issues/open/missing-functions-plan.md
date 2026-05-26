# Missing-functions implementation plan

Working document for the `missing-functions` branch. Covers the
four families the user prioritised:

  * Special forms (4)
  * Core / miscellaneous (106)
  * Visual LISP Extensions (VLE-*) (123)
  * Visual LISP IDE (VLISP-*) (5)

Total in-scope: **238 functions**. Priority is native-implementable
first (no host coupling, no separate phase work).

The categorisation below sorts each family into three tiers:

  * **NATIVE** — full implementation with no host coupling. Cribs
    from existing CL/uiop facilities or trivially derived from
    existing helpers.
  * **STUB** — register the name, return the spec-documented
    no-op / nil / empty-list answer with a docstring noting why
    the full behaviour is out of scope for clautolisp's
    in-process engine. Lets caller code that probes `boundp` or
    catches errors keep running.
  * **DEFER** — needs the entity DB, dictionary store, pickset
    machinery, ActiveX bridge, or other multi-phase work tracked
    in `clautolisp/implementation-roadmap.org`. Leave in
    `missing-functions.issue`'s tail; do not stub.

Each NATIVE function gets:
  * a `make-core-builtin-subr "NAME" #'builtin-name` entry in
    `autolisp-builtins-core/source/api.lisp`,
  * a CL implementation,
  * at least one test under `autolisp-builtins-core/tests/`,
  * (eventually) a Function Entry in autolisp-spec.

Each STUB function gets the registration + a one-line CL function
returning the documented no-op + a brief test that calling it
doesn't raise. No spec entry.

DEFER functions don't appear in any milestone of this plan.

---

## Foundation (audited 2026-05-25)

  * Registration: `(make-core-builtin-subr "NAME" #'builtin-name)`
    in `autolisp-builtins-core/source/api.lisp`. Arity / type
    checks live inline in the CL body via `require-number`,
    `require-string`, etc.
  * Special operator: add `(cons "NAME" #'eval-NAME-form)` to
    `*special-operator-dispatch*` in
    `autolisp-runtime/source/api.lisp`; signature
    `(arguments context)`; dispatch goes through
    `special-operator-function` / `eval-special-operator`.
  * Trace hook: `*autolisp-trace-p*` flag in autolisp-runtime,
    checked in `call-autolisp-function-in-context` (api.lisp
    line 1367). Per-session, not per-function. TRACE/UNTRACE
    will add a per-symbol filter table the same hook consults.
  * uiop already in scope: file ops in builtins-core, `getenv`
    in terminal-color.lisp. Safe to add `uiop:getenv`,
    `uiop:getcwd`, `uiop:run-program`, `sleep` calls anywhere.
  * Vector primitives: `builtin-distance` / `builtin-angle` /
    `builtin-polar` / `builtin-inters` already implement the
    point math (points = lists, coords coerced to double-float,
    missing Z → 0). VLE-VECTOR-* can compose these.
  * ACI/RGB conversion table: NOT present in the repo. The 256-
    entry palette must be shipped as a new data table (constant
    in builtins-core).
  * Tests: `autolisp-builtins-core/tests/builtin-tests.lisp`
    (FiveAM, `install-core-builtins` once per test).

---

## Milestone 1 — Special forms (4) [LANDED 1.0.57]

| Operator  | Tier   | Status                                                                 |
|-----------|--------|------------------------------------------------------------------------|
| SET       | NATIVE | Landed. `eval-set-form` in autolisp-runtime/source/api.lisp. 4 tests.  |
| TRACE     | NATIVE | Landed. `eval-trace-form` + `*autolisp-traced-symbols*` hash table; consulted by new `autolisp-function-trace-p`. 3 tests. |
| UNTRACE   | NATIVE | Landed. `eval-untrace-form`; arg-less form clears all (clautolisp extension over Autodesk's single-symbol form). 2 tests. |
| COMMAND   | DEFER  | Deferred to host work. Will be filed as `deferred-command-special-form.issue` when HAL work begins. |

---

## Milestone 2 — Core / Misc native (~30) [LANDED 1.0.58]

  * 28 native builtins + 3 stubs registered in
    `autolisp-builtins-core/source/api.lisp` under a new
    "M2: Core / Misc native" section.
  * `*core-builtin-names*` extended; `core-builtins` registers the
    new names alongside the existing roster.
  * `lookup-variable` added to the package imports for VER /
    LISP$VERSION which read `*AUTOLISP-VERSION*`.
  * Tests: 22 new in `autolisp-builtins-core/tests/builtin-tests.lisp`,
    builtins-core suite 455 → 513 (100% green).



### 2a. OS / process / filesystem (12)

| Function           | Tier   | CL implementation                                                  |
|--------------------|--------|--------------------------------------------------------------------|
| GETENV             | NATIVE | `uiop:getenv NAME`.                                                |
| SETENV             | NATIVE | `(setf (uiop:getenv NAME) VALUE)`.                                 |
| GETPID             | NATIVE | `uiop:getpid` (with sb-ext / ccl fallback).                        |
| SLEEP              | NATIVE | `(sleep (/ ms 1000.0))` — AutoLISP SLEEP takes milliseconds.       |
| GC                 | NATIVE | `(sb-ext:gc)` / `(ccl:gc)`; returns nil.                           |
| STARTAPP           | NATIVE | `uiop:launch-program` (non-blocking) + return PID.                 |
| VL-GETCURRENTDIR   | NATIVE | `(namestring (uiop:getcwd))`.                                      |
| VL-SETCURRENTDIR   | NATIVE | `uiop:chdir`.                                                      |
| VL-GETSTARTUPDIR   | NATIVE | Captured at process start in a runtime parameter.                  |
| VL-RMDIR           | NATIVE | `uiop:delete-directory-tree :validate t`.                          |
| DOC_CLIPBOARD      | NATIVE | macOS: `pbpaste` / `pbcopy`; Linux: `xclip`. Stub on Windows for now. |
| FNSPLITL           | NATIVE | `(pathname-directory PATH) → list-of-components`.                  |

### 2b. Version / inspection (5)

| Function     | Tier   | Notes                                                              |
|--------------|--------|--------------------------------------------------------------------|
| VER          | NATIVE | Returns `clautolisp.tools.clautolisp:*version*`.                   |
| MEM          | NATIVE | `(sb-ext:dynamic-space-size)` etc., normalised to AutoCAD shape.   |
| ALLOC        | NATIVE | No-op returning the new value (matches Autodesk docs for "doesn't apply"). |
| LISP$VERSION | NATIVE | Same as VER (legacy alias).                                        |
| HELP         | NATIVE | Prints a one-liner pointing at `info clautolisp` / `man clautolisp`. |

### 2c. Geometry / math (4)

| Function     | Tier   | Notes                                                              |
|--------------|--------|--------------------------------------------------------------------|
| TRANS        | NATIVE | Coordinate-system transform. Identity matrix when no host: all     |
|              |        | coordinate spaces collapse to WCS; documented limitation.          |
| TEXTBOX      | NATIVE | Approx via char-width × len, height = TEXT height. Stub-quality    |
|              |        | bounding box; real impl waits on font metrics.                     |
| VLE_G_VECTOL | NATIVE | Vector tolerance helper. Pure math.                                |
| CVUNIT       | DEFER  | Needs `acad.unt` definitions file shipped + a parser. Skip in M2.  |

### 2d. CLI no-ops (9)

These are graphics-screen / tablet / menu / view operators that
do nothing useful in a CLI. Register, return T (success), document.

| Function           | Tier | Notes                                              |
|--------------------|------|----------------------------------------------------|
| GRAPHSCR           | STUB | No graphics screen → no-op, return nil.            |
| TEXTSCR            | STUB | Same.                                              |
| TEXTPAGE           | STUB | Same.                                              |
| REDRAW             | STUB | No display → no-op.                                |
| SETVIEW            | STUB | No viewport → return nil.                          |
| TABLET             | STUB | No tablet device → return nil for every sub-call.  |
| MENUCMD            | STUB | No menu system → return "".                        |
| MENUGROUP          | STUB | No menu groups → return nil.                       |
| SHOWHTMLMODALWINDOW| STUB | No GUI → return nil.                               |

### 2e. Error-mode helpers (3)

| Function                       | Tier   | Notes                                       |
|--------------------------------|--------|---------------------------------------------|
| *PUSH-ERROR-USING-COMMAND*     | NATIVE | Pushes a frame on the error-handling stack. |
| *PUSH-ERROR-USING-STACK*       | NATIVE | Same family.                                |
| *POP-ERROR-MODE*               | NATIVE | Pops the top frame.                         |

These are documented as part of the *error* protocol; the
runtime can carry the stack as a session-level parameter.

**Milestone 2 estimated effort:** 1½ days. ~28 native + ~9 stubs + 2 deferred (CVUNIT, COMMAND-S).

---

## Milestone 3 — VLE-* (~123) [LANDED 1.0.65 - 1.0.68]

123 of 123 functions land across four sub-batches:

  * M3a (1.0.65): 47 list/predicate/number helpers — NTH0..NTH9,
    PUT-NTH, SUBST-NTH, REMOVE-{NTH,ALL,FIRST,LAST}, LIST-SPLIT,
    SUBLIST, LIST-{DIFF,INTERSECT,SUBTRACT,UNION},
    {CADR,CDR,SET-CDR,LIST-M}ASSOC, APPEND, MEMBER, SEARCH,
    {INTEGER,REAL,NUMBER,STRING,POINT,ENAME,PICKSET}P (native) +
    {VARIANT,SAFEARRAY,VLAOBJECT}P (stub), CEILING, FLOOR,
    ROUND, ROUNDTO, ATOI32, ITOA32, INT64TO32, TAN.

  * M3b (1.0.66): 30 vector-math operators — ADD, SUB, NEGATE,
    SCALE, MIDPOINT, GET, NORMALISE, DOTPRODUCT, CROSSPRODUCT,
    ANGLETO, ANGLETOREF, LENGTH{,2D,2DXZ,2DYZ},
    ISUNITLENGTH, ISEQUAL, ISZEROLENGTH, ISPARALLEL,
    ISCODIRECTIONAL, ISPERPENDICULAR, IS{X,Y,Z}AXIS,
    GETPERPVECTOR, GETUCS, TO2D, TO3D, GET/SETTOLERANCE.
    New private `coerce-vec3` / `vec3-*` helpers underlie all
    of them.

  * M3c (1.0.67): 12 string/file/color/misc — STRING-{REPLACE,
    SPLIT}, FILE->LIST, FILEP, FILE-ENCODING (stub),
    ACI2RGB / RGB2ACI (partial 16-entry palette;
    SPEC-UNCERTAIN for indices 10-249), STARTAPP,
    PING-ALIVE, OPTIMISER/OPTIMIZER/FASTCOM (stubs).

  * M3d (1.0.68): 34 CAD / COM / UI stubs — ALERT (native print
    fallback), ENT* / DICT* / TABLE* / TBL* (entity DB family),
    DISPLAY* / EDITTEXTINPLACE / *PROMPTMENU (UI),
    *-TRANSACTION (transactions), COLLECTION-/
    SELECTIONSET-/SAFEARRAY->LIST (COM bridge),
    LICENSELEVEL / LISPINSTALL / LISPVERSION /
    EXTENSIONS-ACTIVE / ENABLESERVERBUSY (info / flags),
    COMPILE-SHAPE, SUNID, NTH<X>.

Tests: 39 new FiveAM tests, 172 new checks; builtins-core
suite 455 -> 685 over the four sub-batches, 100% green.
SPEC-UNCERTAIN markers: 5 (SUBST-NTH, LIST-SPLIT, MEMBER,
NORMALISE zero-length, GETUCS near-vertical, STRING-REPLACE,
STRING-SPLIT empty-tokens, ACI2RGB 10-249 range, RGB2ACI
argument shape — entries in deferred-spec-research.issue).
STUB markers: 6 new in M3c-d, all enumerated in
deferred-stubbed-functions.issue § VLE-* CAD/COM/UI stubs.



Three sub-batches: list/predicate/number helpers (fast), vector
math (volume work), string/file/color (medium).

### 3a. List + predicate + number helpers (~45)

All trivial — usually 3-5 lines of CL each.

  * Nth shortcuts (12): VLE-NTH0 .. VLE-NTH9, VLE-NTH<X>,
    VLE-PUT-NTH, VLE-SUBST-NTH, VLE-REMOVE-NTH.
  * List mutators (5): VLE-REMOVE-ALL, VLE-REMOVE-FIRST,
    VLE-REMOVE-LAST, VLE-LIST-SPLIT, VLE-SUBLIST.
  * Set ops (4): VLE-LIST-DIFF, VLE-LIST-INTERSECT,
    VLE-LIST-SUBTRACT, VLE-LIST-UNION.
  * Assoc family (4): VLE-CADRASSOC, VLE-CDRASSOC,
    VLE-SET-CDRASSOC, VLE-LIST-MASSOC.
  * Other list (2): VLE-APPEND, VLE-MEMBER.
  * Type preds (5 native + 4 stub): VLE-INTEGERP, VLE-REALP,
    VLE-NUMBERP, VLE-STRINGP, VLE-POINTP, VLE-ENAMEP +
    VLE-VARIANTP / VLE-SAFEARRAYP / VLE-VLAOBJECTP /
    VLE-PICKSETP (stubs returning nil — those types don't exist
    yet).
  * Number conv (8): VLE-CEILING, VLE-FLOOR, VLE-ROUND,
    VLE-ROUNDTO, VLE-ATOI32, VLE-ITOA32, VLE-INT64TO32, VLE-TAN.

### 3b. Vector math (~32)

All compose `builtin-distance` / `builtin-angle` / `builtin-polar`
or are pure list-of-3 arithmetic.

  * Arithmetic (6): VLE-VECTOR-ADD, VLE-VECTOR-SUB,
    VLE-VECTOR-NEGATE, VLE-VECTOR-SCALE, VLE-VECTOR-MIDPOINT,
    VLE-VECTOR-NORMALISE.
  * Products (3): VLE-VECTOR-DOTPRODUCT,
    VLE-VECTOR-CROSSPRODUCT, VLE-VECTOR-ANGLETO.
  * Length / norms (5): VLE-VECTOR-LENGTH,
    VLE-VECTOR-LENGTH2D, VLE-VECTOR-LENGTH2DXZ,
    VLE-VECTOR-LENGTH2DYZ, VLE-VECTOR-ISUNITLENGTH.
  * Comparisons (6): VLE-VECTOR-ISEQUAL,
    VLE-VECTOR-ISCODIRECTIONAL, VLE-VECTOR-ISPARALLEL,
    VLE-VECTOR-ISPERPENDICULAR, VLE-VECTOR-ANGLETOREF,
    VLE-VECTOR-ISZEROLENGTH.
  * Axis tests (4): VLE-VECTOR-ISXAXIS, VLE-VECTOR-ISYAXIS,
    VLE-VECTOR-ISZAXIS, VLE-VECTOR-GETPERPVECTOR.
  * Accessors / coercion (5): VLE-VECTOR-GET,
    VLE-VECTOR-TO2D, VLE-VECTOR-TO3D, VLE-VECTOR-GETUCS (stub),
    VLE-VECTOR-GETTOLERANCE / VLE-VECTOR-SETTOLERANCE (session
    parameter).

### 3c. String / file / color / misc (~8 + 4)

  * Strings (3): VLE-STRING-REPLACE, VLE-STRING-SPLIT,
    VLE-SEARCH (substring index).
  * Files (3): VLE-FILE->LIST (slurp lines), VLE-FILEP
    (`uiop:file-exists-p`), VLE-FILE-ENCODING (returns the
    current `*autolisp-file-encoding*`).
  * Color (2): VLE-RGB2ACI, VLE-ACI2RGB. **Requires shipping a
    256-entry ACI table** as a new constant in builtins-core —
    write the table once, reuse in both directions.
  * Misc (4): VLE-STARTAPP (alias of STARTAPP from M2),
    VLE-PING-ALIVE (always T on a single-process engine),
    VLE-OPTIMISER / VLE-OPTIMIZER (stub returning nil — no
    bytecode optimizer in clautolisp).

### 3d. VLE stubs (~40)

CAD-coupled or session-state functions that have no in-process
meaning. Register + return documented no-op:

  * Entity DB: VLE-ENTGET, VLE-ENTGET-M, VLE-ENTGET-MASSOC,
    VLE-ENTMOD, VLE-ENTMOD-M (return nil; entity DB lands later).
  * Dictionary: VLE-DICTIONARY-LIST, VLE-DICTOBJNAME,
    VLE-DICTSEARCH (return nil).
  * UI: VLE-DISPLAYPAUSE, VLE-DISPLAYUPDATE,
    VLE-EDITTEXTINPLACE, VLE-ENABLESERVERBUSY,
    VLE-HIDEPROMPTMENU, VLE-SHOWPROMPTMENU (return T).
  * Transactions: VLE-START-TRANSACTION,
    VLE-END-TRANSACTION (return T / nil).
  * Pickset / collection: VLE-COLLECTION->LIST,
    VLE-SELECTIONSET->LIST, VLE-SAFEARRAY->LIST (return nil).
  * Curve / shape / table: VLE-CURVE-GETPERIMETER,
    VLE-COMPILE-SHAPE, VLE-IS-CURVE, VLE-TABLE-LIST,
    VLE-TABLE-LIST-ALL, VLE-TBLSEARCH, VLE-GETGEOMEXTENTS,
    VLE-SUNID (return nil).
  * License / install: VLE-LICENSELEVEL, VLE-LISPINSTALL,
    VLE-LISPVERSION, VLE-FASTCOM, VLE-EXTENSIONS-ACTIVE
    (return sensible static values).
  * Entity name / valid: VLE-ENAME-VALID (always nil; no DB),
    VLE-ALERT (delegate to `*error-output*` `format`).

**Milestone 3 estimated effort:** 3 days. ~85 native + ~38 stubs.

---

## Milestone 4 — VLISP-* (5) [LANDED 1.0.69]

All 5 VLISP-* functions ship as register-and-stub.

  * VLISP-COMPILE — returns nil (no separate compile step).
  * VLISP-EXPORT-SYMBOL — records names in
    *vlisp-exported-symbols* (observable but ungated); returns T.
  * VLISP-IMPORT-SYMBOL — no-op T.
  * VLISP-IMPORT-EXSUBRS — no-op T.
  * VLISP-OPTIMIZER — no-op nil.

Tests: 6 new (20 checks); builtins-core suite 685 -> 705.



All five are IDE-level operations with no in-process meaning.
Stub with a documented warning at first use; return nil on
success.

  * VLISP-COMPILE — stub. (Future: emit a FASL via
    `compile-file` when clautolisp grows a separate compile
    step.)
  * VLISP-EXPORT-SYMBOL / VLISP-IMPORT-SYMBOL — record into a
    session-level table; lookup is no-op for now.
  * VLISP-IMPORT-EXSUBRS — stub returning nil.
  * VLISP-OPTIMIZER — stub returning the previous value (no
    optimizer to toggle).

**Milestone 4 estimated effort:** ½ day. 5 stubs.

---

## Milestone 5 — Core / Misc rest (~71) [LANDED 1.0.70]

~71 functions land: 8 native + 6 session-state record-only +
57 stubs. CVUNIT, COMMAND-S, and UNTIL stay deferred (per the
M2/M5 plan and the deferred-spec-research / deferred-stubbed-
functions issues).

  * Native (8): VL-INIT, VL-LOAD-COM, VL-LOAD-REACTORS,
    VL-LOAD-ALL (all return T), VL-ENABLE-USER-CANCEL,
    LAYOUTLIST (returns ("Model")), ACDIMENABLEUPDATE (T),
    VPORTS (default-singleton).
  * Session-state (6): VL-REGISTRY-{READ,WRITE,DELETE,
    DESCENDENTS} backed by a session hash; GETCFG / SETCFG
    same. State doesn't persist across processes; upgrade path
    (JSON file / INI file) catalogued in
    deferred-stubbed-functions.issue.
  * Stubs (57): VL-* management, VL-LOCAL-UNDO-* (5),
    VL-ANNOTATIVE-* (11), VL-SUBENT-* (5), VL-VPLAYER-* (9),
    ActiveX property accessors (6), BricsCAD-specific (4),
    INSPECTOR / DLG-SYSVARS / etc. All carry STUB markers;
    catalog entries in deferred-stubbed-functions.issue
    § Core/misc rest stubs.

Tests: 8 new FiveAM cases (112 new checks). The
m5-all-stubs-registered test asserts every stub-family name
binds a callable SUBR (62 names checked). builtins-core suite:
705 -> 817, 100% green.



The rest of the Core/Misc 106 functions, all CAD-coupled or
deferred-to-roadmap. Stub each with a docstring noting why the
full behaviour is out of scope:

  * VL-LOAD-COM / VL-LOAD-REACTORS / VL-LOAD-ALL / VL-INIT —
    no-op returning T (we don't have separate VL/COM modules).
  * VL-LIST-LOADED-LISP / VL-LIST-LOADED-VLX /
    VL-VLX-LOADED-P / VL-UNLOAD-VLX / VL-LIST-EXPORTED-FUNCTIONS
    — return nil / empty list.
  * VL-VBALOAD / VL-VBARUN / VL-CMDF / VL-ACAD-DEFUN /
    VL-ACAD-UNDEFUN / VL-GET-RESOURCE — stub.
  * VL-HIDEPROMPTMENU / VL-SHOWPROMPTMENU — return T.
  * VL-LOCAL-UNDO-* (5) — session-state stack; record-only
    implementation possible (no rollback support).
  * VL-REGISTRY-DELETE / DESCENDENTS / READ / WRITE — Windows
    registry; cross-platform stub backed by a per-user JSON file
    under `~/.config/clautolisp/registry.json` (so persistent
    state survives, even if the keyspace is fake).
  * VL-ANNOTATIVE-* (11) — annotative-scale; CAD-only, all stub.
  * VL-SUBENT-* (5) — subentity ops; defer.
  * VL-VPLAYER-* (9) — viewport-layer; defer.
  * VL-VECTOR-PROJECT-POINTTOENTITY — needs entity DB; defer.
  * VL-ENABLE-USER-CANCEL — interrupt control; native via SIGINT
    handler.
  * VMON — Visual LISP memory monitor; stub returning nil.
  * VPORTS — viewport list; return `((1 (0 0) (1 1)))` (single
    default viewport).
  * _VLAX-SAFEARRAY-MODE — internal ActiveX mode; stub.
  * COMMAND-S — sync form of COMMAND; same DEFER.
  * INSPECTOR / DLG-SYSVARS — IDE / dialog; stub returning nil.
  * LISP$INSTALL / LISP$ENABLEFASTCOM — install/optimizer; stub.
  * LISTALLPROPERTIES / DUMPALLPROPERTIES / ISPROPERTYREADONLY /
    ISPROPERTYVALID / GETPROPERTYVALUE / SETPROPERTYVALUE —
    ActiveX property accessors; stub.
  * LAYOUTLIST — return `("Model")`.
  * INITDIA — return nil.
  * ADS — return nil.
  * BPOLY — boundary polyline; stub.
  * ACDIMENABLEUPDATE — return T.
  * BCAD$DISABLE-EXTENDED-ERROR / BCAD$LICENSELEVELS — BricsCAD
    flags; stub.
  * UNTIL — investigate first; might be a special form already
    implemented under another name (we have WHILE / REPEAT /
    FOREACH).
  * SETCFG / GETCFG — config-file accessors; native via INI file
    under `~/.config/clautolisp/cfg.ini` (uses `iniparse` if we
    have it, else hand-rolled).

**Milestone 5 estimated effort:** 2 days. Mostly bulk
registration + light tests.

---

## Total scope summary

| Milestone | NATIVE | STUB | DEFER | Total |
|-----------|--------|------|-------|-------|
| M1 special forms | 3 | 0 | 1 | 4 |
| M2 core/misc native | 28 | 9 | 2 | 39 (out of 106) |
| M3 VLE-* | 85 | 38 | 0 | 123 |
| M4 VLISP-* | 0 | 5 | 0 | 5 |
| M5 core/misc rest | 8 | 59 | ~4 | 71 |
| **Total** | **124** | **111** | **7** | **242** |

The 4-vs-7-vs-238 gap comes from a handful of legitimately
deferred functions (COMMAND, COMMAND-S, CVUNIT pending unit
file, BPOLY, VL-VECTOR-PROJECT-POINTTOENTITY, VL-SUBENT-* / VL-
VPLAYER-* tracked back into `missing-functions.issue`).

## Merge cadence

Each milestone lands as one merge commit back to master. The
branch stays open between milestones. Version bumps once per
merge.

  * M1 lands → bump → merge.
  * M2 lands → bump → merge.
  * M3 lands → bump → merge.
  * M4 lands → bump → merge.
  * M5 lands → bump → merge → close `missing-functions.issue`
    (or shrink it to its remaining DEFER tail).

This document lives on the branch and is updated as milestones
complete. Once the issue closes, it becomes the merged
post-mortem in `issues/closed/missing-functions-plan.md`.
