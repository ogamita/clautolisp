SUBPROJECTS := autolisp-spec clautolisp autolisp-test autolisp-front-end autolisp-benchmark
CLAUTOLISP_CI_IMAGE ?= registry.gitlab.com/ogamita/clautolisp/clautolisp-ci:latest
CLAUTOLISP_CI_DOCKERFILE ?= clautolisp/docker/Dockerfile
CLAUTOLISP_CI_PLATFORM ?= linux/amd64
DOCUMENTATION_BIN ?= $(shell sh scripts/resolve-documentation-bin.sh)
ifneq ($(DOCUMENTATION_BIN),)
export PATH := $(DOCUMENTATION_BIN):$(PATH)
endif

# Install destination. Override on the command line:
#   make install PREFIX=/usr/local
#   make install DESTDIR=/staging PREFIX=/opt/local      # packager use
#
# Installing is a two-step flow — build+stage as yourself, copy as root
# (see "Staging + install" below). `sudo make install' does both, the
# first as $SUDO_USER; the explicit form is:
#
#   make stage                                          # unprivileged
#   sudo make install                                   # pure copy
#
# Repo-wide install convention (every subproject's Makefile honours
# the same layout):
#
#   $(DESTDIR)$(PREFIX)/bin/                         user-facing executables
#                                                    (clautolisp-{sbcl,ccl},
#                                                     read-autolisp-{sbcl,ccl},
#                                                     clautolisp-gui-qt, alfe-{sbcl,ccl})
#   $(DESTDIR)$(PREFIX)/libexec/<subproject>/        support executables
#                                                    (run-file-compat,
#                                                     autolisp-test harness, …)
#   $(DESTDIR)$(PREFIX)/share/doc/<subproject>/      .org + .pdf docs + HTML
#                                                    + man pages (when present)
#   $(DESTDIR)$(PREFIX)/share/info/                  GNU Info manuals
#   $(DESTDIR)$(PREFIX)/share/<subproject>/          data files
#                                                    (autolisp-spec pages/)
#   $(DESTDIR)$(PREFIX)/share/emacs/site-lisp/<…>/   Emacs libraries
#   $(DESTDIR)$(PREFIX)/share/autolisp/site-lisp/<…>/  AutoLISP libraries
#   $(DESTDIR)$(PREFIX)/share/common-lisp/source/<subproject>/  ASDF systems
#                                                    (.lisp + .asd, tree layout)
#   $(DESTDIR)$(PREFIX)/share/common-lisp/systems/   .asd symlinks for ASDF's
#                                                    default source-registry
#   $(DESTDIR)$(PREFIX)/lib/<subproject>/<os>/<arch>/  native shared libraries
#   $(DESTDIR)$(PREFIX)/include/<subproject>/        public C headers
#
# The libraries phase is kept in lockstep with the release-libraries
# artefact: `make install-libraries' and unpacking
# clautolisp-<ver>-libraries-<os>-<arch>.tar.bz2 produce the same tree.
#
# /opt/local matches the MacPorts hierarchy; /usr/local and
# /usr are the common alternatives the override accepts.

PREFIX ?= /opt/local
DESTDIR ?=
INSTALL_INFO ?= install-info

# Which CL implementation the bare `clautolisp' / `read-autolisp' /
# `alfe' symlinks under $(PREFIX)/bin point at after install.
# Each subproject Makefile picks the first available Lisp on the
# host as its own default; passing DEFAULT_LISP on the command
# line forces every subproject to agree:
#
#   make install DEFAULT_LISP=ccl
#
# If neither sbcl nor ccl is on PATH, install errors out before
# the symlink step (the build-time probe-check guards against it).
DEFAULT_LISP ?=

# Help text comes from `## ` comments after each target name. Keep
# new targets self-documenting: any target whose recipe matters at
# the top level should carry a `## ...` description so it appears in
# `make help`.

.PHONY: help all clean build build-sbcl build-ccl documentation test clean-pdf clean-diagrams docker-build-clautolisp-ci docker-push-clautolisp-ci install install-programs install-libraries install-documentation uninstall $(SUBPROJECTS) \
        submodules build-documentation build-programs build-libraries \
        stage stage-programs stage-libraries stage-documentation clean-stage \
        release release-sources release-documentation release-programs release-libraries \
        verify-release-artefacts \
        probe probe-autocad probe-bricscad probe-clautolisp

# --- Release artefacts (see issues/open/release-artefacts.issue) -------
#
# VERSION is read from the single source of truth (the clautolisp
# version stamp). Artefacts are written into $(DIST).
VERSION := $(shell sed -n 's/.*\*version\* *"\([0-9.]*\)".*/\1/p' clautolisp/tools/clautolisp/source/version.lisp)
DIST    ?= $(CURDIR)/dist
# Downcased OS / arch for the per-target binary + native-lib layout.
# OS is normalised to linux/darwin/windows (uname on MSYS2/MinGW/Cygwin
# reports mingw64_nt-*/msys_nt-*/cygwin_nt-*); arch to the canonical
# x86-64 / arm64 (uname -m reports x86_64/amd64 and aarch64/arm64
# inconsistently). These MUST match dispatch.sh and
# drawing-dwg/source/bindings.lisp (%os / %arch).
REL_OS   := $(shell uname | tr 'A-Z' 'a-z' | sed -e 's/^mingw.*/windows/' -e 's/^msys.*/windows/' -e 's/^cygwin.*/windows/')
REL_ARCH := $(shell uname -m | tr 'A-Z' 'a-z' | sed -e 's/^x86_64$$/x86-64/' -e 's/^amd64$$/x86-64/' -e 's/^aarch64$$/arm64/')

# Which Lisp implementations the release lane builds + packages on this
# target. CCL has no arm64 build (its "linuxarm" is 32-bit Raspberry-Pi;
# Apple Silicon is unsupported), so arm64 targets are SBCL-only, while
# x86-64 ships both. The release CI lanes override this per target
# (x86-64 -> "sbcl ccl"); the default keeps everything else SBCL-only.
RELEASE_LISPS ?= sbcl

# Pack a staged tree into this target's per-target artefact, choosing the
# container by PLATFORM: Windows ships .zip, every other target .tar.bz2
# (pjb, 2026-08-16 — "fetch .zip from windows, not tar.bz2"). A Windows
# user should not need a tar that Explorer cannot open, and the Windows
# package has its own layout anyway (documentation/windows-package-spec.md).
#
# $(1) staged tree  $(2) kind (binaries|libraries)  $(3) version
# $(4) os           $(5) arch
#
# Both branches archive the tree's CONTENTS (cd + `.'), never a wrapper
# directory, so the artefact unpacks straight into $PREFIX.
# Test hook: pack an arbitrary staged tree, so the Windows branch can be
# exercised on a Unix developer machine instead of shipping unexecuted
# (scripts/tests/test-pack-release-artefact.sh). Not part of a release.
PACK_STAGE ?=
PACK_KIND  ?= binaries
PACK_VER   ?= 0.0.0
PACK_OS    ?= $(REL_OS)
PACK_ARCH  ?= $(REL_ARCH)
release-libraries-pack-only:  ## (test hook) Pack PACK_STAGE as PACK_KIND for PACK_OS/PACK_ARCH; exercises the Windows .zip branch off Windows.
	@test -n "$(PACK_STAGE)" || { echo "PACK_STAGE is required"; exit 1; }
	@mkdir -p "$(DIST)"
	@$(call pack-release-artefact,$(PACK_STAGE),$(PACK_KIND),$(PACK_VER),$(PACK_OS),$(PACK_ARCH))

# COPYFILE_DISABLE=1 / --no-xattrs / --exclude='._*': keep macOS metadata
# out of the artefacts. On macOS, bsdtar stores a file's extended
# attributes as an AppleDouble `._NAME' member plus LIBARCHIVE.xattr.*
# pax headers, so the darwin artefact shipped 23 `._*' files and made GNU
# tar print "Ignoring unknown extended header keyword" on every extraction
# elsewhere. They are not part of the product, no manifest accounts for
# them, and they reached the -all.zip (whose zip branch, unlike every tar
# branch here, had no exclusion). The variable is inert on Linux and
# Windows, so this is one rule for every platform rather than a macOS
# special case. --no-xattrs is PROBED rather than assumed: it is what
# suppresses the pax headers, GNU tar and bsdtar spell their options
# differently, and a tar that rejected it would take the darwin release
# lane down with it -- COPYFILE_DISABLE and --exclude already do the
# visible half of the job on any tar.
define pack-release-artefact
	if [ "$(4)" = windows ]; then \
	  command -v zip >/dev/null 2>&1 || { \
	    echo "ERROR: zip is required to package the Windows artefact"; exit 1; }; \
	  out="$(DIST)/clautolisp-$(3)-$(2)-$(4)-$(5).zip"; \
	  rm -f "$$out"; \
	  ( cd "$(1)" && zip -qr "$$out" . -x '._*' '*/._*' ); \
	else \
	  out="$(DIST)/clautolisp-$(3)-$(2)-$(4)-$(5).tar.bz2"; \
	  xattrs=""; tar --no-xattrs --version >/dev/null 2>&1 && xattrs="--no-xattrs"; \
	  COPYFILE_DISABLE=1 tar -C "$(1)" $$xattrs --exclude='._*' -cjf "$$out" .; \
	fi; \
	echo "wrote $$out"
endef

help:  ## Show this message (list available targets and their purpose).
	@awk 'BEGIN { \
	    FS = ":.*?## "; \
	    printf "Usage: make <target>\n\nTop-level targets:\n"; \
	  } \
	  /^[a-zA-Z_][a-zA-Z0-9_-]*:.*?## / { \
	    printf "  %-32s %s\n", $$1, $$2; \
	  } \
	  END { \
	    printf "\nSubprojects (forwarded by `make <name>`): %s\n", \
	      "$(SUBPROJECTS)"; \
	    printf "Each subproject has its own Makefile with finer-grained\n"; \
	    printf "targets; see e.g. `make -C clautolisp help` once those\n"; \
	    printf "Makefiles grow their own help target.\n"; \
	    printf "\nFor the test×dialect×platform matrix forwarded at the root,\n"; \
	    printf "see `make help-test-matrix`.\n"; \
	  }' $(MAKEFILE_LIST)

all: build  ## Default target: build programs + libraries (NOT docs). Documentation is a separate phase: `make build-documentation`.


autolisp-spec:  ## Build the autolisp-spec subproject (delegates to its Makefile).
	"$(MAKE)" -C autolisp-spec all

clautolisp:  ## Build the clautolisp subproject — runtime, executables, GUI driver, docs.
	"$(MAKE)" -C clautolisp all

autolisp-test:  ## Build the autolisp-test conformance harness subproject.
	"$(MAKE)" -C autolisp-test all

autolisp-front-end:  ## Build the autolisp-front-end (alfe) subproject — unified CLI front-end for clautolisp + CAD-resident REPLs.
	"$(MAKE)" -C autolisp-front-end all

autolisp-benchmark:  ## Build the autolisp-benchmark subproject (AutoLISP performance suite; docs only — the suite is loaded into an engine).
	"$(MAKE)" -C autolisp-benchmark all

documentation:  ## Rebuild every subproject's PDF documentation (org → LaTeX → PDF) + the top-level diagrams (dot → svg/png).
	"$(MAKE)" -C autolisp-spec documentation
	"$(MAKE)" -C clautolisp documentation
	"$(MAKE)" -C autolisp-test documentation
	"$(MAKE)" -C autolisp-front-end documentation
	"$(MAKE)" -C autolisp-benchmark documentation
	"$(MAKE)" -C documentation diagrams
	"$(MAKE)" -C documentation documentation

build: build-programs build-libraries  ## Build the program binaries + native libraries (NO docs). `make stage` goes one step further and lays them out ready to install. Documentation is a separate phase: `make build-documentation`.

build-sbcl:  ## Strictly build SBCL images across subprojects (errors if sbcl is missing).
	"$(MAKE)" -C clautolisp         build-sbcl
	"$(MAKE)" -C autolisp-front-end build-sbcl

build-ccl:  ## Strictly build CCL images across subprojects (errors if ccl is missing).
	"$(MAKE)" -C clautolisp         build-ccl
	"$(MAKE)" -C autolisp-front-end build-ccl

test:  ## Run the clautolisp test suite plus the autolisp-test conformance corpus.
	"$(MAKE)" -C clautolisp test
	"$(MAKE)" -C autolisp-test test
	"$(MAKE)" -C autolisp-front-end test
	"$(MAKE)" -C autolisp-benchmark test

# --- CAD ground-truth probes (see probes/README.org) -------------------
#
# Run the project-wide probe suite (probes/sources/) inside a real CAD
# — or the bundled clautolisp binary — and commit the captured records
# under probe-results/<product>/<platform>/<timestamp>/results.sexp, to
# be diffed against clautolisp. `make probe` is the one-liner to run on
# a CAD workstation; it auto-detects an installed AutoCAD or BricsCAD
# (honouring the AUTOCAD_*/BRICSCAD_* env overrides) and falls back to
# the clautolisp baseline when no CAD is present. Set PROBE_NO_COMMIT=1
# to skip the auto-commit.

probe:  ## Run CAD ground-truth probes on this host (auto-detect AutoCAD/BricsCAD, else clautolisp) and commit results under probe-results/.
	@if   bash probes/scripts/detect-cad.sh autocad  >/dev/null 2>&1; then "$(MAKE)" probe-autocad; \
	 elif bash probes/scripts/detect-cad.sh bricscad >/dev/null 2>&1; then "$(MAKE)" probe-bricscad; \
	 else echo "make probe: no AutoCAD/BricsCAD detected — running the clautolisp baseline."; "$(MAKE)" probe-clautolisp; fi

probe-autocad:  ## Probe AutoCAD (accoreconsole/acad; override AUTOCAD_ACCORECONSOLE / AUTOCAD_EXE / AUTOCAD_RUNNER).
	bash probes/scripts/run-probes.sh autocad

probe-bricscad:  ## Probe BricsCAD (override BRICSCAD_EXE / BRICSCAD_RUNNER).
	bash probes/scripts/run-probes.sh bricscad

probe-clautolisp:  ## Probe the bundled clautolisp binary (headless baseline column for diffing).
	bash probes/scripts/run-probes.sh clautolisp

# --- Build phases, split by artefact kind ------------------------------

build-documentation:  ## Build all PDF docs + the autolisp-spec paged split (HTML/info/pages — the slow part).
	"$(MAKE)" documentation
	"$(MAKE)" -C autolisp-spec paged

build-programs:  ## Build the host program binaries (clautolisp, alfe, …) for each Lisp in RELEASE_LISPS (default sbcl; x86-64 release sets "sbcl ccl").
	@for l in $(RELEASE_LISPS); do "$(MAKE)" build-$$l || exit $$?; done

submodules:  ## Check out the git submodules (the vendored libredwg used by the DWG codec). Idempotent; runs automatically as part of build-libraries so a fresh clone builds directly.
	git submodule update --init --recursive

build-libraries:  ## Build the releasable libraries (the drawing/drawing-dwg native libdwg). Checks out the libredwg submodule first if needed.
	"$(MAKE)" -C clautolisp build-libredwg

# --- Release packaging -------------------------------------------------
#
# release-sources is platform-independent and fully implemented here.
# release-{documentation,programs,libraries} build their kind then stage
# + archive it; the multi-target (6 platforms) combination is assembled
# by CI from per-target artefacts (see the issue).

check-versions:  ## Audit the release tags / version-* pointers against the shared version rules (see AGENTS.md; run `git fetch --prune --tags` first).
	sh scripts/check-versions.sh

# The user-visible rule (AGENTS.md, Documentation Synchronisation) is a
# review rule, and review is exactly what stops happening under pressure.
# This reads the surface out of the code -- CLI option specs, the CLAL-
# builtin registrations -- and fails when a name reaches no manual. It
# needs neither a build nor a CAD, so it belongs in the documentation lane.
check-user-visible-documentation:  ## Fail if a user-visible surface (CLI option, CLAL- builtin) is missing from the manuals.
	python3 scripts/check-user-visible-documentation.py

# The release set was found incomplete by RUNNING collect-artefacts, not
# by reading it (release-artefact-set-incomplete.issue): 7 of the 10
# specified artefacts were missing. These two keep it that way only if
# someone re-breaks it deliberately. Neither needs a build.
check-release-artefact-set:  ## Fail unless collect-artefacts produces the specified release artefact set (incl. the -all union).
	sh scripts/check-release-artefact-set.sh

check-release-collect-needs:  ## Fail if a release:* job's artefacts never reach collect:release.
	sh scripts/check-release-collect-needs.sh

check-ci-dotenv-rules:  ## Fail if a parent-pipeline job is gated on a dotenv variable (never true at rules time).
	sh scripts/check-ci-dotenv-rules.sh

check-release-lane-integrity:  ## Fail if a release lane could go green without producing its artefacts.
	python3 scripts/check-release-lane-integrity.py

# Needs fontconfig (fc-list) to ask which families actually have a glyph.
# Where fc-list is absent the check reports every codepoint as unavailable,
# which would be a false alarm, so it skips instead -- with a word, never
# silently: a check that says nothing is indistinguishable from one that
# passed, and that is the exact failure mode this check exists to remove.
check-doc-glyph-coverage:  ## Fail if a documentation source uses a glyph the PDF build would silently drop.
	@command -v fc-list >/dev/null 2>&1 || { \
	  echo "skip: fc-list (fontconfig) is not installed, so glyph coverage"; \
	  echo "      cannot be checked on this host -- install fontconfig to"; \
	  echo "      run it."; exit 0; }; \
	python3 scripts/check-doc-glyph-coverage.py

check-nightly-sweep-isolation:  ## Fail if a scheduled pipeline would contain anything but the nightly sweep.
	python3 scripts/check-nightly-sweep-isolation.py

check-release: check-release-artefact-set check-release-collect-needs check-ci-dotenv-rules check-release-lane-integrity check-nightly-sweep-isolation  ## Every release-packaging check.

# avec-bash.ps1 drives the Windows release lane and cannot run on this host
# (no PowerShell, pjb 2026-08-16: do not install it). A container gives the
# only off-Windows coverage there is -- syntax, argument passing, and the
# EXIT-CODE PROPAGATION that is the launcher's whole reason to exist. It is
# NOT part of check-release: that one must stay dependency-free so the CI
# documentation lane can run it; this needs a docker daemon.
POWERSHELL_IMAGE ?= mcr.microsoft.com/powershell:debian-12
check-avec-bash:  ## Test scripts/avec-bash.ps1 in a PowerShell container (needs docker).
	@command -v docker >/dev/null 2>&1 || { \
	  echo "docker is required: this test runs pwsh in $(POWERSHELL_IMAGE)"; exit 1; }
	docker run --rm -v "$(CURDIR):/w" -w /w $(POWERSHELL_IMAGE) \
	       pwsh -NoProfile -File scripts/tests/test-avec-bash.ps1

release: release-sources release-documentation release-programs release-libraries  ## Produce every release artefact for this host.

# The sources unpack under src/clautolisp-<ver>/, not clautolisp-<ver>/
# (pjb, 2026-08-18). Every other artefact unpacks into $PREFIX -- bin/,
# lib/, share/ -- and the -all union puts them all in one tree, where a
# bare clautolisp-<ver>/ sat as a sibling of the install directories with
# nothing to say it was a source tree. src/ says it.
#
# The layout IS part of the artefact, so the recipe checks it: nothing may
# fall outside src/. An archive nobody looks inside is how this release
# series lost three files without a single red job.
release-sources:  ## Produce the source tarball + zip (tracked files incl. submodules).
	@mkdir -p "$(DIST)"
	@prefix=clautolisp-$(VERSION); \
	stage=$$(mktemp -d); dest="$$stage/src/$$prefix"; mkdir -p "$$dest"; \
	git ls-files --recurse-submodules -z | tar -cf - --null -T - | tar -C "$$dest" -xf -; \
	sh scripts/make-manifest.sh sources > "$$dest/manifest-sources.txt"; \
	tar -C "$$stage" -cjf "$(DIST)/$$prefix-sources.tar.bz2" src; \
	( cd "$$stage" && zip -qr "$(DIST)/$$prefix-sources.zip" src -x '._*' '*/._*' ); \
	rm -rf "$$stage"; \
	stray=$$(tar -tjf "$(DIST)/$$prefix-sources.tar.bz2" | grep -v '^src/' | head -1); \
	if [ -n "$$stray" ]; then \
	  echo "ERROR: $$prefix-sources.tar.bz2 has '$$stray' outside src/"; exit 1; \
	fi; \
	if command -v unzip >/dev/null 2>&1; then \
	  stray=$$(unzip -Z1 "$(DIST)/$$prefix-sources.zip" | grep -v '^src/' | head -1); \
	  if [ -n "$$stray" ]; then \
	    echo "ERROR: $$prefix-sources.zip has '$$stray' outside src/"; exit 1; \
	  fi; \
	fi; \
	echo "wrote $(DIST)/$$prefix-sources.tar.bz2 (src/$$prefix/)"; \
	echo "wrote $(DIST)/$$prefix-sources.zip (src/$$prefix/)"

release-documentation: stage-documentation  ## Package the documentation artefact for EVERY subproject (pdf/org/info + the spec's paged HTML/info/pages + alref), from the same $(STAGE)/documentation tree install-documentation installs. Unpacks into $PREFIX.
	@mkdir -p "$(DIST)"
	@ver="$(VERSION)"; \
	tar -C "$(STAGE_DOCUMENTATION)" -cjf "$(DIST)/clautolisp-$$ver-documentation.tar.bz2" .; \
	echo "wrote $(DIST)/clautolisp-$$ver-documentation.tar.bz2"

# The one artefact whose layout is NOT the install tree: the binaries
# tarball ships a bin/ of dispatch.sh wrappers over
# libexec/clautolisp/binaries/<os>/<arch>/, so CI can union several
# targets into one multi-platform archive (see collect-artefacts).
#
# THE COPY TESTS .exe FIRST AND NAMES ITS DESTINATION, and both halves are
# load-bearing on Windows.
#
# The obvious order -- test the bare name, fall back to .exe -- is a trap
# under MSYS2, whose POSIX layer opens `foo' when only `foo.exe' exists.
# `[ -f "$b" ]' is therefore TRUE for a file that is only there as .exe,
# the first branch wins, and `cp "$b" "$bindir"/' writes the DESTINATION
# under the bare name: the .exe branch below it is dead code on the one
# platform it was written for. release-1.9.0 shipped that way -- its
# archive holds libexec/.../windows/x86-64/clautolisp-sbcl with no
# extension, while both launchers open <prog>-<lisp>.exe (dispatch.cmd
# refuses with "no binary for windows/..." and exit 127). So the Windows
# products did not run. See windows-release-binaries-lose-exe.issue.
#
# Naming the destination explicitly is the belt to that braces: it does
# not matter what name the source resolved through, the file lands as
# <prog>-<lisp>.exe.
# `make install-programs' installs this host's binaries directly into
# bin/ instead, along with the pieces no end-user tarball carries (the
# test/benchmark harnesses, run-file-compat, the GUI). Hence its own
# staging, kept here rather than under $(STAGE).
release-programs: build-programs  ## Build programs and package this host's per-target binaries artefact (dispatch-wrapper layout, unpacks into $PREFIX). CI unions the unix targets.
	@mkdir -p "$(DIST)"
	@ver="$(VERSION)"; os="$(REL_OS)"; arch="$(REL_ARCH)"; \
	stage=$$(mktemp -d); \
	bindir="$$stage/libexec/clautolisp/binaries/$$os/$$arch"; mkdir -p "$$bindir"; \
	for l in $(RELEASE_LISPS); do \
	  for b in clautolisp/tools/clautolisp/bin/clautolisp-$$l \
	           clautolisp/autolisp-reader/tools/read-autolisp/bin/read-autolisp-$$l \
	           autolisp-front-end/tools/alfe/bin/alfe-$$l; do \
	    n=$$(basename "$$b"); \
	    if [ -f "$$b.exe" ]; then cp "$$b.exe" "$$bindir/$$n.exe"; \
	    elif [ -f "$$b" ]; then cp "$$b" "$$bindir/$$n"; fi; \
	  done; \
	done; \
	mkdir -p "$$stage/bin"; \
	for p in clautolisp alfe read-autolisp; do \
	  cp clautolisp/tools/packaging/dispatch.sh "$$stage/bin/$$p"; chmod +x "$$stage/bin/$$p"; \
	done; \
	if [ "$$os" = windows ]; then \
	  for p in clautolisp alfe read-autolisp; do \
	    sed 's/\r*$$/\r/' clautolisp/tools/packaging/dispatch.cmd > "$$stage/bin/$$p.cmd"; \
	  done; \
	fi; \
	mandir="$$stage/share/man/man1"; mkdir -p "$$mandir"; \
	find clautolisp autolisp-front-end -path '*/documentation/man/*.1' -exec cp {} "$$mandir"/ \; 2>/dev/null || true; \
	docdir="$$stage/share/doc/clautolisp"; mkdir -p "$$docdir"; \
	for d in clautolisp/build/documentation/clautolisp-user-manual.info \
	         clautolisp/build/documentation/clautolisp-user-manual.pdf \
	         autolisp-front-end/build/documentation/alfe-user-manual.info \
	         autolisp-front-end/build/documentation/alfe-user-manual.pdf; do \
	  if [ -f "$$d" ]; then cp "$$d" "$$docdir"/; fi; \
	done; \
	mkdir -p "$$stage/$(MANIFEST_DIR)"; \
	sh scripts/make-manifest.sh programs > "$$stage/$(MANIFEST_DIR)/manifest-programs.txt"; \
	$(call pack-release-artefact,$$stage,binaries,$$ver,$$os,$$arch); \
	rm -rf "$$stage"

# REQUIRE_NATIVE_LIBRARIES=1: a published artefact must be complete, so a
# missing LibreDWG codec is an error here, even though it is only a
# warning for a plain `make install' (see clautolisp/Makefile). Staging is
# invoked as a sub-make rather than a prerequisite so the override reaches
# it -- command-line variables propagate through MAKEFLAGS.
release-libraries:  ## Package this host's per-target libraries artefact (ASDF systems + native libdwg + header) from the same $(STAGE)/libraries tree install-libraries installs. CI unions the targets into clautolisp-<ver>-libraries.tar.bz2.
	"$(MAKE)" stage-libraries REQUIRE_NATIVE_LIBRARIES=1
	@mkdir -p "$(DIST)"
	@ver="$(VERSION)"; os="$(REL_OS)"; arch="$(REL_ARCH)"; \
	$(call pack-release-artefact,$(STAGE_LIBRARIES),libraries,$$ver,$$os,$$arch)

# CI collect phase: union the per-target artefacts (gathered by the
# pipeline into COLLECT_IN) into the final combined release set in
# COLLECT_OUT. Pure repackaging — no build, no rebuild. The combined
# binaries/libraries tarballs merge each target's libexec/<os>/<arch>/
# and lib/<os>/<arch>/ subtrees (the shared bin/, lisp sources, include/
# overwrite identically); sources + documentation pass through once.
#
# Every per-target artefact ALSO passes through unchanged, by glob rather
# than by a list of platforms: a release publishes both the merged
# multi-platform pair and one tarball per target, and a new runner's
# artefact joins the set with no edit here (pjb, 2026-08-16 — "et tout
# autre binaires que nous pourrions builder a l'avenir avec des runners
# supplementaires"). The former special case that copied `*windows*'
# through is gone, subsumed by that glob; it also used to copy the
# Windows lane's STUB .txt into the release set.
#
# WINDOWS SHIPS .zip, NOT .tar.bz2 (pjb, 2026-08-16). Its per-target
# artefacts pass through and join the -all union like any other, but they
# are NOT fed to the merged multi-platform binaries/libraries tarballs:
# those are a $PREFIX-shaped unix tree, and the Windows package has its
# own layout (documentation/windows-package-spec.md). Keeping it out is
# the point, not an oversight.
#
# The -all artefact is the UNPACKED UNION (pjb's ruling): every artefact
# extracted over one tree, so a user unpacks one file and has everything
# installed at once. It is not an archive of archives. sources.tar.bz2
# joins the union safely because it unpacks under its own
# clautolisp-<ver>/ prefix, alongside — not into — bin/, lib/, libexec/
# and share/; the Windows zip likewise carries its own single top-level
# directory. sources.zip is deliberately left out: same content as the
# tarball, so including it would duplicate the source tree.
COLLECT_IN  ?= $(DIST)
COLLECT_OUT ?= $(DIST)/combined
# A release job that builds nothing must not pass for a job that built
# everything. GitLab uploads whatever `paths:' matches -- an empty dist/
# included -- and reports success, so a build that never ran looks exactly
# like a build that worked, until the collected release set turns out to
# be short a platform. release-1.8.46 lost its linux-arm32 artefacts that
# way: a guard in before_script did `exit 0', which ended the whole job
# green in 35 seconds.
#
# So every per-target release lane asserts, as its last step, that this
# target's two artefacts exist and are not husks. The size floor is
# deliberately low -- it is there to catch "empty", not to police size.
# Checking the artefact EXISTS is not checking it works, and this target
# used to do only the first: a file over 10 000 bytes passed. That is how
# release-1.9.0 shipped Windows binaries the shipped launcher cannot open
# -- libexec/.../windows/x86-64/clautolisp-sbcl, with no .exe, while both
# dispatch.cmd and dispatch.sh append .exe on windows. The archive was
# 42 MB and perfectly well-formed; only its NAMES were wrong, and nothing
# looked at them (windows-release-binaries-lose-exe.issue).
#
# So the artefact is now opened and the entries the launcher will actually
# reach for are required to be there. It reads the archive rather than the
# staging directory on purpose: what ships is what was packed, and the
# 1.9.0 defect happened during the packing.
#
# THEN IT ASKS THE BINARIES WHAT THEY ARE, because a correct name is not a
# correct build. On the same tag the Windows images were dumped from an
# ASDF fasl cache that had survived the runner's clean, so nothing
# recompiled -- the whole build took three seconds and the log holds not
# one `; compiling' line -- and the published binaries reported clautolisp
# 1.8.56 and read-autolisp 1.8.0 from inside an archive named 1.9.0. No
# check on names or sizes can see that. Running the program can.
verify-release-artefacts:  ## Fail unless this target's binaries+libraries artefacts were really written into DIST, and the binaries carry the names the launchers open.
	@ver="$(VERSION)"; os="$(REL_OS)"; arch="$(REL_ARCH)"; \
	if [ "$$os" = windows ]; then ext=zip; else ext=tar.bz2; fi; \
	status=0; \
	for kind in binaries libraries; do \
	  f="$(DIST)/clautolisp-$$ver-$$kind-$$os-$$arch.$$ext"; \
	  if [ ! -f "$$f" ]; then \
	    echo "FAIL: $$f was not produced -- this lane built nothing."; \
	    status=1; \
	  else \
	    sz=$$(wc -c < "$$f"); \
	    if [ "$$sz" -lt 10000 ]; then \
	      echo "FAIL: $$f is only $$sz bytes -- an empty artefact."; \
	      status=1; \
	    else \
	      echo "ok  $$(basename "$$f") ($$sz bytes)"; \
	    fi; \
	  fi; \
	done; \
	f="$(DIST)/clautolisp-$$ver-binaries-$$os-$$arch.$$ext"; \
	if [ -f "$$f" ]; then \
	  if [ "$$ext" = zip ]; then names=$$(unzip -Z1 "$$f"); \
	  else names=$$(tar -tjf "$$f"); fi; \
	  if [ "$$os" = windows ]; then suffix=.exe; else suffix=; fi; \
	  for l in $(RELEASE_LISPS); do \
	    for p in clautolisp read-autolisp alfe; do \
	      want="libexec/clautolisp/binaries/$$os/$$arch/$$p-$$l$$suffix"; \
	      if printf '%s\n' "$$names" | grep -qxF "$$want" || \
	         printf '%s\n' "$$names" | grep -qxF "./$$want"; then \
	        echo "ok  $$p-$$l$$suffix is where the launcher opens it"; \
	      else \
	        echo "FAIL: the artefact has no $$want"; \
	        got=$$(printf '%s\n' "$$names" | grep "binaries/$$os/$$arch/$$p-$$l" || true); \
	        if [ -n "$$got" ]; then \
	          echo "      it holds this instead:"; \
	          printf '        %s\n' $$got; \
	          echo "      which neither launcher will open: dispatch.cmd and"; \
	          echo "      dispatch.sh both append .exe on windows, so the"; \
	          echo "      release installs and then refuses to run (exit 127)."; \
	        fi; \
	        status=1; \
	      fi; \
	    done; \
	  done; \
	fi; \
	for l in $(RELEASE_LISPS); do \
	  for b in clautolisp/tools/clautolisp/bin/clautolisp-$$l \
	           clautolisp/autolisp-reader/tools/read-autolisp/bin/read-autolisp-$$l \
	           autolisp-front-end/tools/alfe/bin/alfe-$$l; do \
	    x="$$b"; [ -f "$$x.exe" ] && x="$$x.exe"; \
	    if [ ! -f "$$x" ]; then \
	      echo "FAIL: $$b was never built -- nothing to verify."; status=1; continue; \
	    fi; \
	    got=$$("$$x" --version 2>&1 | head -1 || true); \
	    case "$$got" in \
	      *"$$ver"*) echo "ok  $$(basename "$$x") reports $$ver" ;; \
	      *) echo "FAIL: $$(basename "$$x") reports [$$got], not $$ver."; \
	         echo "      The image was dumped from another commit's fasls, so"; \
	         echo "      this release would ship a binary that is not its own"; \
	         echo "      source. Clear the ASDF cache and rebuild."; \
	         status=1 ;; \
	    esac; \
	  done; \
	done; \
	exit $$status

# COLLECT_IN/COLLECT_OUT are resolved to ABSOLUTE paths before anything
# else. The -all.zip branch archives from inside a `cd' into the staging
# tree, so a relative output path would resolve against that tree and the
# archive would land where nobody looks -- while the log still says
# "wrote ... all.zip". That is precisely how release 1.8.46 shipped
# without clautolisp-1.8.46-all.zip: CI passes COLLECT_OUT=dist/combined,
# relative. The tar branch escapes it only because `tar -C' does not move
# the shell's own working directory.
collect-artefacts:  ## Union the per-target artefacts from COLLECT_IN into the combined release set in COLLECT_OUT.
	@ver="$(VERSION)"; in="$(COLLECT_IN)"; out="$(COLLECT_OUT)"; mkdir -p "$$out"; \
	out=$$(cd "$$out" && pwd); in=$$(cd "$$in" && pwd); \
	bstage=$$(mktemp -d); n=0; \
	for t in "$$in"/clautolisp-$$ver-binaries-*.tar.bz2; do \
	  [ -f "$$t" ] || continue; echo "merge $$(basename "$$t")"; tar -C "$$bstage" -xjf "$$t"; n=$$((n+1)); \
	done; \
	if [ "$$n" -gt 0 ]; then \
	  tar -C "$$bstage" --exclude='._*' --owner=0 --group=0 --numeric-owner -cjf "$$out/clautolisp-$$ver-binaries.tar.bz2" .; \
	  echo "wrote $$out/clautolisp-$$ver-binaries.tar.bz2 (from $$n target(s))"; \
	else echo "WARNING: no per-target binaries artefacts in $$in"; fi; \
	rm -rf "$$bstage"; \
	lstage=$$(mktemp -d); n=0; \
	for t in "$$in"/clautolisp-$$ver-libraries-*.tar.bz2; do \
	  [ -f "$$t" ] || continue; echo "merge $$(basename "$$t")"; tar -C "$$lstage" -xjf "$$t"; n=$$((n+1)); \
	done; \
	if [ "$$n" -gt 0 ]; then \
	  tar -C "$$lstage" --exclude='._*' --owner=0 --group=0 --numeric-owner -cjf "$$out/clautolisp-$$ver-libraries.tar.bz2" .; \
	  echo "wrote $$out/clautolisp-$$ver-libraries.tar.bz2 (from $$n target(s))"; \
	else echo "WARNING: no per-target libraries artefacts in $$in"; fi; \
	rm -rf "$$lstage"; \
	for f in "$$in"/clautolisp-$$ver-sources.tar.bz2 \
	         "$$in"/clautolisp-$$ver-sources.zip \
	         "$$in"/clautolisp-$$ver-documentation.tar.bz2; do \
	  [ -f "$$f" ] && cp "$$f" "$$out"/ && echo "passthrough $$(basename "$$f")"; \
	done; \
	for f in "$$in"/clautolisp-$$ver-binaries-*.tar.bz2 \
	         "$$in"/clautolisp-$$ver-libraries-*.tar.bz2 \
	         "$$in"/clautolisp-$$ver-binaries-windows-*.zip \
	         "$$in"/clautolisp-$$ver-libraries-windows-*.zip; do \
	  [ -f "$$f" ] || continue; cp "$$f" "$$out"/ && echo "per-target $$(basename "$$f")"; \
	done; \
	astage=$$(mktemp -d); n=0; \
	for t in "$$in"/clautolisp-$$ver-binaries-*.tar.bz2 \
	         "$$in"/clautolisp-$$ver-libraries-*.tar.bz2 \
	         "$$in"/clautolisp-$$ver-documentation.tar.bz2 \
	         "$$in"/clautolisp-$$ver-sources.tar.bz2; do \
	  [ -f "$$t" ] || continue; echo "all: union $$(basename "$$t")"; \
	  tar -C "$$astage" -xjf "$$t"; n=$$((n+1)); \
	done; \
	for z in "$$in"/clautolisp-$$ver-binaries-windows-*.zip \
	         "$$in"/clautolisp-$$ver-libraries-windows-*.zip; do \
	  [ -f "$$z" ] || continue; \
	  command -v unzip >/dev/null 2>&1 || { \
	    echo "ERROR: $$(basename "$$z") is present but unzip is missing;"; \
	    echo "       the -all union would silently omit Windows. Install unzip."; \
	    exit 1; }; \
	  echo "all: union $$(basename "$$z")"; \
	  unzip -q -o "$$z" -d "$$astage"; n=$$((n+1)); \
	done; \
	if [ "$$n" -gt 0 ]; then \
	  tar -C "$$astage" --exclude='._*' --owner=0 --group=0 --numeric-owner \
	      -cjf "$$out/clautolisp-$$ver-all.tar.bz2" .; \
	  echo "wrote $$out/clautolisp-$$ver-all.tar.bz2 (union of $$n artefact(s))"; \
	  command -v zip >/dev/null 2>&1 || { \
	    echo "ERROR: zip is missing, so the -all.zip our Windows users need"; \
	    echo "       would be skipped without failing. Install zip."; \
	    exit 1; }; \
	  ( cd "$$astage" && zip -qr "$$out/clautolisp-$$ver-all.zip" . -x '._*' '*/._*' ); \
	  echo "wrote $$out/clautolisp-$$ver-all.zip (same union, for Windows)"; \
	  if command -v unzip >/dev/null 2>&1; then \
	    junk=$$(unzip -Z1 "$$out/clautolisp-$$ver-all.zip" \
	            | grep -E '(^|/)\._' | head -1); \
	    if [ -n "$$junk" ]; then \
	      echo "ERROR: clautolisp-$$ver-all.zip carries the macOS metadata file '$$junk'."; \
	      echo "       The .tar.bz2 of this same union excludes it, so the two"; \
	      echo "       containers would not unpack to the same tree -- which is"; \
	      echo "       the one property an -all artefact exists to provide."; \
	      exit 1; \
	    fi; \
	  fi; \
	else echo "WARNING: nothing to union into the -all artefact"; fi; \
	rm -rf "$$astage"; \
	: ; \
	: "The collected set names itself, so publishing the release does not"; \
	: "have to guess it. scripts/make-gitlab-release.py reads this one"; \
	: "small file over the raw artefact URL and attaches exactly what was"; \
	: "collected -- a new platform therefore joins the published release"; \
	: "with no edit anywhere, and a missing one is visible as a short"; \
	: "manifest rather than as a link nobody thought to add."; \
	( cd "$$out" && ls -1 | grep -v '^manifest-release-assets.txt$$' ) \
	  > "$$out/manifest-release-assets.txt"; \
	echo "wrote $$out/manifest-release-assets.txt ($$(wc -l < "$$out/manifest-release-assets.txt" | tr -d ' ') asset(s))"; \
	targets=$$(ls "$$in" 2>/dev/null \
	           | sed -n "s/^clautolisp-$$ver-binaries-\(.*\)\.tar\.bz2$$/\1/p" \
	           | sort -u | tr '\n' ' '); \
	echo "--- targets whose binaries reached this collect: $${targets:-(none)}"; \
	echo "    a platform missing from that list built nothing, or its job"; \
	echo "    is not in collect:release's needs — the release set is then"; \
	echo "    smaller than specified, and that is not visible from ls alone."; \
	echo "--- combined release set ($$out) ---"; ls -l "$$out"

clean:: clean-pdf
clean-pdf:  ## Remove every generated PDF across subprojects (keeps .org sources).
	"$(MAKE)" -C autolisp-spec clean-pdf
	"$(MAKE)" -C clautolisp clean-pdf
	"$(MAKE)" -C autolisp-test clean-pdf
	"$(MAKE)" -C autolisp-front-end clean-pdf
	"$(MAKE)" -C autolisp-benchmark clean-pdf
	"$(MAKE)" -C documentation clean-pdf

clean:: clean-diagrams
clean-diagrams:  ## Remove the rendered top-level diagrams (keeps the .dot sources).
	"$(MAKE)" -C documentation clean

clean:: clean-backups
clean-backups:
	@printf 'Cleaning backup files.\n'
	@find . -name \*~ -exec rm -f {} \;

# --- Staging + install -------------------------------------------------
#
# `make install' NEVER builds. A build run as root (the classic
# `sudo make install' on a tree where something is missing) compiles
# fasls, cmake trees and PDFs as root, right inside the working
# checkout, and the user can no longer overwrite them. So the two
# halves are separated:
#
#   1. STAGE — unprivileged. Build each artefact kind and lay it out
#      under $(STAGE)/<kind>/ exactly as it must appear below $PREFIX.
#      This is the same staging the release-* artefacts are packaged
#      from, so what you install is what a release ships.
#   2. INSTALL — privileged. Copy $(STAGE)/<kind>/ into
#      $(DESTDIR)$(PREFIX)/. No compiler runs; nothing is written into
#      the source tree.
#
# `sudo make install' remains the one-liner it was: when the install
# half finds itself running as root under sudo it drops back to
# $SUDO_USER to run the staging half.
#
# Both halves are split the same way — programs / libraries /
# documentation — plus a global target (`stage', `install').
STAGE ?= $(DIST)/stage
STAGE_PROGRAMS      := $(STAGE)/programs
STAGE_LIBRARIES     := $(STAGE)/libraries
STAGE_DOCUMENTATION := $(STAGE)/documentation

# Forwards DEFAULT_LISP to every subproject so a single CLI override
# (e.g. `make install DEFAULT_LISP=ccl') flows through. When the user
# does not set DEFAULT_LISP, each subproject falls back to its own
# (firstword $(AVAILABLE_IMPLEMENTATIONS)) — so an SBCL-only host
# stages SBCL symlinks, etc. PREFIX is deliberately empty while
# staging: nothing bakes it into installed content, and the stage is
# a $PREFIX-rooted tree of its own.
LISP_VARS := $(if $(DEFAULT_LISP),DEFAULT_LISP=$(DEFAULT_LISP))
INSTALL_VARS := PREFIX=$(PREFIX) DESTDIR=$(DESTDIR) $(LISP_VARS)
STAGE_VARS := STAGE=$(STAGE) RELEASE_LISPS='$(RELEASE_LISPS)' $(LISP_VARS)

# Run a staging target unprivileged. Under sudo we know who to drop to
# ($SUDO_USER); -H so the build's caches (ASDF fasls under
# $XDG_CACHE_HOME, quicklisp) land in that user's home and not root's.
# Bare root with no SUDO_USER is the packager/container case: there is
# nobody to drop to and a root-owned tree is harmless there, so warn
# and carry on rather than refuse.
define stage-as-user
if [ "$$(id -u)" != 0 ]; then \
  $(MAKE) $(1) $(STAGE_VARS) ; \
elif [ -n "$(SUDO_USER)" ] && [ "$(SUDO_USER)" != root ]; then \
  echo "==> staging as $(SUDO_USER) (dropping root for the build half)" ; \
  sudo -H -u "$(SUDO_USER)" $(MAKE) $(1) $(STAGE_VARS) ; \
else \
  echo "WARNING: running as root with no SUDO_USER; $(1) will build with root" ; \
  echo "         privileges and leave root-owned artefacts in the source tree." ; \
  echo "         In a working checkout, run 'make $(1)' as yourself first." ; \
  $(MAKE) $(1) $(STAGE_VARS) ; \
fi
endef

# Copy a staged tree into $(DESTDIR)$(PREFIX). tar rather than cp so
# symlinks (bin/clautolisp -> clautolisp-sbcl, the systems/*.asd link)
# and modes survive and the copy merges into an existing prefix;
# --no-same-owner so the installed files belong to the installing user
# (root), not to whoever staged them. $(2) is an optional --exclude.
define copy-stage
dest="$(DESTDIR)$(PREFIX)" ; \
if [ -z "$$dest" ]; then \
  echo "install: PREFIX and DESTDIR are both empty — nothing to install into" >&2 ; \
  exit 1 ; \
fi ; \
if [ ! -d "$(1)" ]; then \
  echo "install: staging area $(1) is missing (run the matching stage-* target)" >&2 ; \
  exit 1 ; \
fi ; \
install -d "$$dest" ; \
tar -C "$(1)" -cf - $(2) . | tar -C "$$dest" --no-same-owner -xf - ; \
echo "installed: $(1)/ -> $$dest/"
endef

# Every staged tree carries a manifest naming the commit it was built
# from — nothing else installed does. RELEASE_NOTES.org says what the
# release contains; this says which build you have. One per phase,
# because the phases can be staged and installed separately.
# share/doc/clautolisp is the project's doc directory (the repo is named
# for its flagship program); SUBPROJECT_NAME exists only in the
# subproject Makefiles, not here.
MANIFEST_DIR = share/doc/clautolisp
define stage-manifest
install -d "$(1)/$(MANIFEST_DIR)" ; \
sh scripts/make-manifest.sh $(2) > "$(1)/$(MANIFEST_DIR)/manifest-$(2).txt" ; \
echo "staged: $(1)/$(MANIFEST_DIR)/manifest-$(2).txt"
endef

stage: stage-programs stage-libraries stage-documentation  ## Build + stage everything under $(STAGE)/ (unprivileged; this is the half that compiles).

stage-programs: build-programs  ## Build the programs and stage them (bin/, libexec/, the harnesses and the alref libs) under $(STAGE)/programs.
	rm -rf "$(STAGE_PROGRAMS)"
	install -d "$(STAGE_PROGRAMS)"
	"$(MAKE)" -C autolisp-spec      install-programs PREFIX= DESTDIR=$(STAGE_PROGRAMS) $(LISP_VARS)
	"$(MAKE)" -C clautolisp         install-programs PREFIX= DESTDIR=$(STAGE_PROGRAMS) $(LISP_VARS)
	"$(MAKE)" -C autolisp-test      install-programs PREFIX= DESTDIR=$(STAGE_PROGRAMS) $(LISP_VARS)
	"$(MAKE)" -C autolisp-front-end install-programs PREFIX= DESTDIR=$(STAGE_PROGRAMS) $(LISP_VARS)
	"$(MAKE)" -C autolisp-benchmark install-programs PREFIX= DESTDIR=$(STAGE_PROGRAMS) $(LISP_VARS)
	@$(call stage-manifest,$(STAGE_PROGRAMS),programs)
	@echo "staged: $(STAGE_PROGRAMS)"

stage-libraries: build-libraries  ## Build the native libraries and stage them with the ASDF systems + header under $(STAGE)/libraries.
	rm -rf "$(STAGE_LIBRARIES)"
	install -d "$(STAGE_LIBRARIES)"
	"$(MAKE)" -C clautolisp         install-libraries PREFIX= DESTDIR=$(STAGE_LIBRARIES) $(LISP_VARS)
	@$(call stage-manifest,$(STAGE_LIBRARIES),libraries)
	@echo "staged: $(STAGE_LIBRARIES)"

stage-documentation: build-documentation  ## Render the documentation and stage it (share/doc, share/info, share/man, the spec's HTML/pages) under $(STAGE)/documentation.
	rm -rf "$(STAGE_DOCUMENTATION)"
	install -d "$(STAGE_DOCUMENTATION)"
	"$(MAKE)" -C autolisp-spec      install-documentation PREFIX= DESTDIR=$(STAGE_DOCUMENTATION) $(LISP_VARS)
	"$(MAKE)" -C clautolisp         install-documentation PREFIX= DESTDIR=$(STAGE_DOCUMENTATION) $(LISP_VARS)
	"$(MAKE)" -C autolisp-test      install-documentation PREFIX= DESTDIR=$(STAGE_DOCUMENTATION) $(LISP_VARS)
	"$(MAKE)" -C autolisp-front-end install-documentation PREFIX= DESTDIR=$(STAGE_DOCUMENTATION) $(LISP_VARS)
	"$(MAKE)" -C autolisp-benchmark install-documentation PREFIX= DESTDIR=$(STAGE_DOCUMENTATION) $(LISP_VARS)
	@$(call stage-manifest,$(STAGE_DOCUMENTATION),documentation)
	@echo "staged: $(STAGE_DOCUMENTATION)"

install: install-programs install-libraries install-documentation  ## Install everything into $$PREFIX (default /opt/local) by copying the staged trees — stages first (as $$SUDO_USER when run under sudo), never builds as root.
	@printf '\n'
	@printf '  Installed from %s into %s\n' "$(STAGE)" "$(DESTDIR)$(PREFIX)"
	@printf '\n'

# Independent install phases mirroring stage-programs / stage-libraries /
# stage-documentation, so a consumer can install only what it needs. CI
# that exercises the programs uses `make install-programs' and skips the
# slow documentation phase entirely — as must any host that lacks the
# documentation toolchain (Emacs + TeX/xelatex + makeinfo), since the
# global `install' target now covers all three phases.
install-programs:  ## Install only the program binaries (clautolisp/alfe/read-autolisp + the test harness) + the alref reference libs — no docs. The CI fast path.
	@$(call stage-as-user,stage-programs)
	@$(call copy-stage,$(STAGE_PROGRAMS))

install-libraries:  ## Install only the libraries — the same tree release-libraries packages: ASDF systems (share/common-lisp), native libdwg/CFFI shim (lib/<os>/<arch>), libredwg header (include/), drawing spec + libredwg licence (share/doc).
	@$(call stage-as-user,stage-libraries)
	@$(call copy-stage,$(STAGE_LIBRARIES))

# share/info/dir is a shared index, not our file: the staged copy names
# only our manuals, so copying it over $PREFIX's would drop every other
# package's entries. Exclude it, then let install-info re-register each
# manual in the real dir node.
install-documentation:  ## Install only the documentation (the slow phase: PDFs + the autolisp-spec paged HTML/info/pages).
	@$(call stage-as-user,stage-documentation)
	@$(call copy-stage,$(STAGE_DOCUMENTATION),--exclude=./share/info/dir)
	@for f in "$(STAGE_DOCUMENTATION)"/share/info/*.info; do \
	  [ -f "$$f" ] || continue ; \
	  installed="$(DESTDIR)$(PREFIX)/share/info/$$(basename "$$f")" ; \
	  $(INSTALL_INFO) --info-dir="$(DESTDIR)$(PREFIX)/share/info" "$$installed" 2>/dev/null \
	    || echo "[skip] install-info dir update for $$installed" ; \
	done

clean:: clean-stage
clean-stage:  ## Remove the install staging area ($(STAGE)).
	rm -rf "$(STAGE)"

uninstall:  ## Remove every subproject's install from $$PREFIX.
	"$(MAKE)" -C autolisp-spec      uninstall $(INSTALL_VARS)
	"$(MAKE)" -C clautolisp         uninstall $(INSTALL_VARS)
	"$(MAKE)" -C autolisp-test      uninstall $(INSTALL_VARS)
	"$(MAKE)" -C autolisp-front-end uninstall $(INSTALL_VARS)
	"$(MAKE)" -C autolisp-benchmark uninstall $(INSTALL_VARS)

# ---------------------------------------------------------------------
# Forwarded fine-grained test targets (see issues/closed/test-targets.issue).
#
# Each subproject Makefile owns its own grid of test×implementation×
# dialect×platform targets. The root re-exposes every one of those
# names as a passthrough so testers can write `make <target>` from
# the repo root without having to remember which subproject owns
# each combo. The lists below are the source of truth — adding a
# new target in a subproject Makefile requires a one-line append
# here to surface it at the root.
#
# `make help-test-matrix` prints the full forwarded inventory grouped
# by subproject.

# autolisp-test owns the harness-driven matrix: 4 dialects × 2 Lisp
# implementations against clautolisp, plus 6 dialect-on-CAD targets
# via alfe (BricsCAD on macOS/Windows, AutoCAD on Windows), plus
# the matching aggregates.
AUTOLISP_TEST_FORWARDED := \
  test-clautolisp-sbcl-strict     test-clautolisp-sbcl-clautolisp \
  test-clautolisp-sbcl-bricscad   test-clautolisp-sbcl-autocad \
  test-clautolisp-ccl-strict      test-clautolisp-ccl-clautolisp \
  test-clautolisp-ccl-bricscad    test-clautolisp-ccl-autocad \
  test-clautolisp-sbcl-all        test-clautolisp-ccl-all        test-clautolisp-all \
  test-bricscad-macos             test-bricscad-macos-strict     test-bricscad-macos-bricscad \
  test-bricscad-windows           test-bricscad-windows-strict   test-bricscad-windows-bricscad \
  test-autocad-windows            test-autocad-windows-strict    test-autocad-windows-autocad

# clautolisp owns the run-file-compat per-platform splits.
CLAUTOLISP_FORWARDED := \
  run-file-compat-bricscad-macos \
  run-file-compat-bricscad-windows \
  run-file-compat-autocad-windows

# autolisp-front-end owns the built-alfe per-backend smoke tests.
ALFE_FORWARDED := \
  test-alfe-sbcl-clautolisp        test-alfe-ccl-clautolisp \
  test-alfe-sbcl-bricscad-macos    test-alfe-ccl-bricscad-macos \
  test-alfe-sbcl-bricscad-windows  test-alfe-ccl-bricscad-windows \
  test-alfe-sbcl-autocad-windows   test-alfe-ccl-autocad-windows

.PHONY: $(AUTOLISP_TEST_FORWARDED) $(CLAUTOLISP_FORWARDED) $(ALFE_FORWARDED) \
        help-test-matrix

# Forwarding macro. $(call forward-target-to,TARGET-NAME,SUBPROJECT)
# generates a one-line rule that delegates to that subproject's
# Makefile. The $$@ inside the recipe defers expansion until rule
# evaluation so the right target name lands in the recursive
# $(MAKE) call.
define forward-target-to
$(1):
	$"$(MAKE)" -C $(2) $$@
endef

$(foreach t,$(AUTOLISP_TEST_FORWARDED), \
  $(eval $(call forward-target-to,$(t),autolisp-test)))
$(foreach t,$(CLAUTOLISP_FORWARDED), \
  $(eval $(call forward-target-to,$(t),clautolisp)))
$(foreach t,$(ALFE_FORWARDED), \
  $(eval $(call forward-target-to,$(t),autolisp-front-end)))

help-test-matrix:  ## List every fine-grained test target the root forwards.
	@printf "Forwarded test targets (run from the repo root via 'make <target>'):\n\n"
	@printf "  via autolisp-test/Makefile:\n"
	@for t in $(AUTOLISP_TEST_FORWARDED); do printf "    %s\n" "$$t"; done
	@printf "\n  via clautolisp/Makefile:\n"
	@for t in $(CLAUTOLISP_FORWARDED); do printf "    %s\n" "$$t"; done
	@printf "\n  via autolisp-front-end/Makefile:\n"
	@for t in $(ALFE_FORWARDED); do printf "    %s\n" "$$t"; done
	@printf "\nWrong-platform targets are no-ops (print [skip] and exit 0).\n"

docker-build-clautolisp-ci:  ## Build the GitLab-CI Docker image used to run clautolisp tests.
	docker build \
		--platform "$(CLAUTOLISP_CI_PLATFORM)" \
		-f "$(CLAUTOLISP_CI_DOCKERFILE)" \
		-t "$(CLAUTOLISP_CI_IMAGE)" \
		.

docker-push-clautolisp-ci: docker-build-clautolisp-ci  ## Build and push the CI image to the configured registry.
	docker push "$(CLAUTOLISP_CI_IMAGE)"

# Overridable so the clean-harvest CI job (harvest:sysvars:bricscad:* in
# .gitlab/native.yml) can point at a built-not-installed alfe binary and
# restrict the harvest to the bricscad backend/dialect. Defaults preserve
# the original all-backends behaviour for a plain `make save-sysvars`.
ALFE                  ?= alfe
CLAUTOLISP            ?= clautolisp
SAVE_SYSVARS_BACKENDS ?= clautolisp bricscad autocad
SAVE_SYSVARS_DIALECTS ?= strict autocad bricscad clautolisp lax

save-sysvars: ## Dumps the sysvars of various implementations and configuration in sysvars-*.txt files.
	for backend in $(SAVE_SYSVARS_BACKENDS) ; do \
		"$(ALFE)" --$$backend --dialect=$$backend --mode batch \
			-Esource Windows-1252 \
			-norc \
			-l autolisp-spec/autolisp/dump-sysvars.lsp \
			-x "(dump-sysvars \"sysvars-alfe-$$(uname)-$${backend}.txt\")"  || true ;\
	done
	for dialect in $(SAVE_SYSVARS_DIALECTS) ; do \
		"$(CLAUTOLISP)" --dialect $$dialect \
			-norc \
			-l autolisp-spec/autolisp/dump-sysvars.lsp \
			-x "(dump-sysvars \"sysvars-clautolisp-$$(uname)-$${dialect}.txt\")"  || true ;\
	done
