# Windows Distribution Package Specification

A formal, executable specification for laying out a software distribution into a
**native-Windows** `.zip` archive. The inputs are: a few command-line
executables, documentation, native libraries (DLLs), and Common Lisp sources
organised as ASDF systems.

Requirement keywords (MUST / SHOULD / MAY) follow RFC 2119.

---

## 1. Goals & invariants

1. **Relocatable.** The archive MUST work after extraction to *any* directory:
   `%ProgramFiles%\<Vendor>\<App>\`, `%LOCALAPPDATA%\Programs\<App>\`, a USB
   stick, or a scratch path. No absolute path may appear in any shipped file,
   launcher, or config.
2. **Self-contained.** The package MUST NOT depend on the user's
   `~/common-lisp/`, a global ASDF source-registry, `PATH`, or any
   pre-installed runtime other than what is documented in §7.
3. **No installer.** A zip is a portable distribution: extraction is the
   install step. There is no MSI, no registry writes, no per-machine state.
4. **Native conventions only.** No FHS `share/doc`, no MSYS/MinGW `bin`-holds-
   DLLs-via-import-lib split. DLL resolution relies on the Windows loader's
   default search order.

---

## 2. Output archive

- Filename: `<App>-<version>-win-<arch>.zip`, e.g. `tdedt-1.4.2-win-x64.zip`.
  `<arch>` is `x64` or `x86` and MUST match the bitness of every shipped `.exe`
  and `.dll` (see §7.2).
- The archive MUST contain **exactly one** top-level directory, `<App>\`
  (no version in the directory name, so shortcuts and `PATH` entries survive
  upgrades). All other entries live beneath it. Loose files at archive root
  ("tarbomb") are forbidden.
- The extracted root directory `<App>\` is the **PREFIX**. Everything is
  addressed relative to it.

---

## 3. Directory layout

```
<App>/
├─ bin/                         executables + every DLL they load
│  ├─ <cmd>.exe
│  ├─ <cmd2>.exe
│  └─ <name>.dll …             native libs, ADJACENT to the exes
├─ lib/
│  └─ common-lisp/             ASDF source tree (registered as :tree)
│     ├─ <system-a>/
│     │  ├─ <system-a>.asd
│     │  └─ *.lisp
│     └─ <system-b>/
│        ├─ <system-b>.asd
│        └─ *.lisp
├─ doc/                         README, LICENSE, manuals
│  ├─ README.html
│  ├─ LICENSE.txt
│  └─ *.txt | *.chm | *.pdf
├─ etc/                         OPTIONAL config/data, relocatable
└─ VERSION                      single line: the version string
```

`lib/`, `doc/`, `etc/` MAY be omitted if their inputs are empty. `bin/` MUST
exist.

---

## 4. File classification → destination

Classify each input file by what it **is**, not by where it sat in the tarball,
then map it:

- `*.exe` → `bin/`.
- `*.dll` (runtime, linked or `LoadLibrary`-loaded by a shipped exe) → `bin/`,
  in the **same directory** as the exe(s) that load it. See §5.
- An ASDF system: a directory containing one or more `*.asd` plus its sources
  (`*.lisp`, `*.cl`, `*.asd`, data files) → copied verbatim, preserving its
  internal structure, to `lib/common-lisp/<system>/`. One system directory per
  `.asd` family. Do **not** flatten.
- Documentation — `README*`, `LICENSE*`, `COPYING*`, `NEWS*`, `ChangeLog*`,
  `*.txt`, `*.md`, `*.html`, `*.chm`, `*.pdf` → `doc/`. `*.md` MAY be rendered
  to `*.html` for users without a Markdown viewer; if so, keep the source too.
- Configuration / runtime data not covered above → `etc/`.
- Build-time-only artefacts — import libraries (`*.lib`, `*.exp`), C headers
  (`*.h`, `*.hpp`), `*.dll.a`, `*.pc`, static archives (`*.a`) → **excluded**
  from a runtime distribution. (If a developer SDK variant is wanted, place
  them under `sdk/` instead, but that is out of scope here.)
- Anything unclassified → halt and report; do not guess.

---

## 5. Native libraries (DLLs)

- A DLL that a shipped exe links against or loads MUST sit in the **same
  directory as that exe** (`bin/`). The default Windows search order checks the
  loading module's own directory first, so adjacency means resolution works
  with **no** `PATH` edits and **no** launcher.
- App-private DLLs MUST NOT be copied to `C:\Windows\System32` or any shared
  system location.
- If one DLL is needed by exes in different directories, the spec keeps all exes
  in `bin/`, so a single copy in `bin/` suffices. Do not split exes across dirs.
- Plugin DLLs loaded dynamically at runtime from a non-`bin/` directory MUST be
  reached via an explicit `SetDllDirectory` / `AddDllDirectory` call by the app,
  with the directory computed relative to the install root — never hardcoded.

---

## 6. ASDF source-registry wiring

The bundled systems live at `lib/common-lisp/` and MUST be found without any
user or global configuration. The application configures the source-registry at
startup, relative to the **computed** install root. This is the only place the
"where" of the Lisp sources is bound, and it is computed, not hardcoded.

Assuming the delivered Lisp image resides in `bin/` (so the install root is the
parent of the image's directory):

```lisp
(defun application-root ()
  "Directory the distribution was extracted to (parent of bin/)."
  (uiop:pathname-parent-directory-pathname
   (uiop:pathname-directory-pathname
    (truename (or #+sbcl sb-ext:*core-pathname*   ; the .exe for :executable t
                  (uiop:argv0))))))

(asdf:initialize-source-registry
 `(:source-registry
   (:tree ,(merge-pathnames "lib/common-lisp/" (application-root)))
   :ignore-inherited-configuration))
```

- `:tree` scans `lib/common-lisp/` recursively, so each `<system>/` subdirectory
  is discovered automatically.
- `:ignore-inherited-configuration` is REQUIRED for reproducibility: it prevents
  a user's `~/common-lisp/` or a global registry from shadowing bundled systems.
  Drop it (or append `:inherit-configuration`) only if the app is meant to also
  pick up user-installed systems — document that choice if so.
- `(uiop:argv0)` resolution is implementation-dependent and may yield a bare
  name when the exe is found via `PATH`; prefer the implementation's own image
  path (`sb-ext:*core-pathname*` on SBCL). Adjust the `#+`/`#-` set to the
  delivered implementation(s).

A `.cmd`/launcher is **not** required for DLL or ASDF resolution given the
layout above. Add one under `bin/` only if the app needs extra environment
setup, and have it derive paths from `%~dp0` (its own location), never absolute.

---

## 7. Runtime dependencies

### 7.1 C runtime (app-local deployment)
If any shipped exe or DLL is built against the MSVC runtime, either:
- ship the redistributable DLLs **app-locally** in `bin/` (e.g.
  `vcruntime140.dll`, `vcruntime140_1.dll`, `msvcp140.dll`) — permitted by
  Microsoft's app-local CRT deployment, and consistent with §5 adjacency; or
- document a hard requirement on the matching "Microsoft Visual C++
  Redistributable" version in `doc/README`.
Pure-SBCL deliverables generally need neither, but verify the actual link
dependencies of every shipped binary before deciding.

### 7.2 Bitness
All `.exe` and `.dll` in the package MUST share one architecture, matching
`<arch>` in the archive name. Never mix x64 and x86 binaries in one package.

---

## 8. Archive construction rules

- Use forward-slash-free or forward-slash paths consistently; store entries with
  `/` separators (the standard zip convention) — Windows extractors handle them.
- No symbolic links and no Unix permission bits are relied upon (meaningless on
  native Windows).
- Preserve filename case exactly; do not normalise.
- Text files: do not re-encode or alter line endings of source/data files;
  ship them byte-for-byte as classified.
- Keep total extracted path length within the legacy `MAX_PATH` (260 chars)
  budget where practical — shallow `lib/common-lisp/<system>/…` trees help.
  Do not depend on long-path (`\\?\`) support being enabled.
- Include `VERSION` and a `doc/LICENSE*` in every build.

---

## 9. Distribution caveats (informative)

- A zip downloaded from the network carries the Mark-of-the-Web; extracted,
  unsigned `.exe` files will trigger SmartScreen / Defender prompts. Authenticode
  signing removes this but is out of scope for the layout. In a managed
  environment (locked-down corporate Windows), unsigned binaries may be blocked
  outright — flag this to the recipient.

---

## 10. Acceptance checklist

- [ ] Exactly one top-level directory `<App>/`; no loose root entries.
- [ ] Every `.exe` in `bin/`; every runtime `.dll` adjacent in `bin/`.
- [ ] No DLL in System32; no app-private DLL outside `bin/`.
- [ ] Each ASDF system under `lib/common-lisp/<system>/` with its `.asd`,
      structure preserved.
- [ ] Docs in `doc/`; `LICENSE*` and `VERSION` present.
- [ ] Build-time-only artefacts (`.lib`, `.h`, `.dll.a`, `.a`) excluded.
- [ ] No absolute path in any shipped file, launcher, or config.
- [ ] Source-registry configured relative to a computed root, inherited config
      ignored (unless intentionally inherited and documented).
- [ ] Single architecture throughout; archive named
      `<App>-<version>-win-<arch>.zip`.
- [ ] CRT dependency either shipped app-local in `bin/` or documented.
