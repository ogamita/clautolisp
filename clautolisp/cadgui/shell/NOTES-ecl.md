# cadgui shell on ECL — avoiding the clautolisp reload

The cadgui shell embeds ECL (`cl_boot`) and must get `clautolisp/cadgui`
initialized. Doing that with `asdf:load-system` at runtime costs **~96 s** every
run (full native compile through the C compiler). This note records what was
measured on this box (ECL 24.5.10, Debian trixie, `apt` packaging) and what the
fast path is. Integrates the `ecl` skill (`~/src/public/rules/skills/ecl`).

## Measured facts (2026-11-17)

1. **A warm ECL fasl cache cannot be reused here.** `asdf:load-system` against a
   populated `~/.cache/common-lisp/ecl-*` cache overflows the C stack in the
   planner:

       The slot ASDF/PLAN::STAMP in the object #<action-status ...>
       C-STACK stack overflow. Stack cannot grow any further.

   Measured under **both** Quicklisp's ASDF 3.3.7.3 and ECL's bundled 3.1.8.8,
   with a 256 MB C stack (`ulimit -s 262144`). So the skill's EC1 reordering
   (`(require :asdf)` before Quicklisp) does **not** help here — and in this
   environment Quicklisp upgrades ASDF to 3.3.7.3 regardless of order anyway.
   Consequence: a fresh `cl_boot` + `load-system` must start from a **cold**
   cache (`run.sh` clears it) and pays the full compile. Cold compile = ~96 s.

2. **This Debian ECL ships no static libraries.** `libcmp.a` and `libecl.a` are
   absent (only `libecl.so`). So the skill's **image-op** (dev image, EC10) and
   **program-op** (standalone executable, EC7) recipes **cannot link here** —
   both statically link `libcmp.a`:

       /usr/bin/ld: cannot find .../ecl-24.5.10/libcmp.a: No such file

   `cadgui-dev.asd` + `build-dev-image.{lisp,sh}` are the correct recipe and
   work where ECL ships static libs. On this box, blocked on the apt ECL only by
   the missing `libcmp.a` (the whole closure compiles cleanly before the link);
   **RESOLVED by building ECL 24.5.10 from source** (see "For Lisp-side
   iteration" below) — the dev image then builds and boots.

## The fast path that works here: a monolithic static library

A monolithic static library (`make-build :type :static-library :monolithic t`)
is just `ar` over the already-compiled objects — **no link, so no `libcmp.a`**.
The C++ shell archives it in and links `libecl.so` dynamically (`ecl-config`),
then initializes the engine from C with `ecl_init_module` instead of
`asdf:load-system`. No ASDF planner at runtime => no warm-cache overflow and no
~96 s recompile; the engine is frozen into the binary.

**Measured: a frozen `--render` / multi-threaded `--demo` run starts in ~1.76 s
(vs ~96 s cold), exit 0, correct render.** ~55x faster.

Workflow:
1. Build the library once (cold): `bash build-cadgui-lib.sh` ->
   `clautolisp--cadgui--all-systems.a` (~43 MB). It also writes
   `cadgui-lib-init.h` with the init symbol (ECL randomises it per build:
   `init_lib__<tag>`, extracted via `nm`, so nothing is hardcoded).
2. Build the frozen shell: `CADGUI_USE_LIB=1 bash build.sh` (add
   `CADGUI_TRACE=1` for the cross-thread runner trace).
3. Run fast: `bash run-frozen.sh [--demo|--render|...]` — no cache, no compile.

Two init subtleties the shell handles (both ecl skill EC9 / §1):
- The bundle references `uiop:`/`asdf:` symbols but does NOT contain ASDF/UIOP
  (they are ECL built-ins). The shell creates those packages before init.
- They must be the SAME ASDF/UIOP the library was COMPILED against — Quicklisp's
  3.3.7.3 (UIOP 3.3.7, with `UIOP/LAUNCH-PROGRAM` &c), not ECL's bundled 3.1.8.8.
  So the frozen branch loads Quicklisp before `ecl_init_module` (it compiles
  only ASDF, never clautolisp — still ~instant).

Rebuild the library after editing any engine (Lisp) source. The shell falls back
to the runtime `asdf:load-system` path when built without `CADGUI_USE_LIB`.

## For Lisp-side iteration: the dev image (EC10) — VALIDATED

`build-dev-image.sh` builds `cadgui-dev.image`: an ECL REPL with the whole
clautolisp/cadgui closure (25 systems) frozen in. Iterate with
`(load "edited.lisp")` — bytecodes, instant (EC12); the engine never recompiles.

image-op links `libcmp.a`, which the apt ECL does NOT ship, so build a
source-built ECL once and point the recipe at it:

    # build ECL 24.5.10 from source with static libs (one-time, ~15 min):
    #   - Debian orig tarball ecl_24.5.10+ds.orig.tar.xz strips the bundled
    #     gmp/bdwgc/libffi AND the autotools aux files (install-sh, config.*).
    #   - supply the aux files in src/gmp/ and src/bdwgc/ (from automake), and
    #     configure against the SYSTEM libs:
    #   ./configure --prefix=$HOME/opt/ecl-24.5.10 --enable-threads \
    #       --enable-boehm=system --with-gmp-prefix=/usr --with-libffi-prefix=/usr
    #   make && make install            # installs lib/ecl-24.5.10/libcmp.a
    ECL=$HOME/opt/ecl-24.5.10/bin/ecl bash build-dev-image.sh
    bash run-dev-image.sh              # boots the ECL REPL, engine frozen in

VALIDATED (2026-11-17): the image boots on the ECL REPL (banner + `>` prompt +
stdin eval), `clautolisp.cadgui`/`clautolisp.cador` are present, and the frozen
engine runs from the REPL (made a session, drew a line + circle, exported a
2-prim display list) with no ASDF and no compile. `run-dev-image.sh` sets the
finite stack and `LD_LIBRARY_PATH` to the source ECL's `libecl.so`.

(In the dev image you do NOT `asdf:load-system` the frozen engine -- there is no
`.asd` on the runtime registry; you `(load "file.lisp")` the file under work,
per EC11. Leave the system(s) you are editing OUT of the image.)
