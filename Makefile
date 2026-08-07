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
	$(MAKE) -C autolisp-spec all

clautolisp:  ## Build the clautolisp subproject — runtime, executables, GUI driver, docs.
	$(MAKE) -C clautolisp all

autolisp-test:  ## Build the autolisp-test conformance harness subproject.
	$(MAKE) -C autolisp-test all

autolisp-front-end:  ## Build the autolisp-front-end (alfe) subproject — unified CLI front-end for clautolisp + CAD-resident REPLs.
	$(MAKE) -C autolisp-front-end all

autolisp-benchmark:  ## Build the autolisp-benchmark subproject (AutoLISP performance suite; docs only — the suite is loaded into an engine).
	$(MAKE) -C autolisp-benchmark all

documentation:  ## Rebuild every subproject's PDF documentation (org → LaTeX → PDF) + the top-level diagrams (dot → svg/png).
	$(MAKE) -C autolisp-spec documentation
	$(MAKE) -C clautolisp documentation
	$(MAKE) -C autolisp-test documentation
	$(MAKE) -C autolisp-front-end documentation
	$(MAKE) -C autolisp-benchmark documentation
	$(MAKE) -C documentation diagrams
	$(MAKE) -C documentation documentation

build: build-programs build-libraries  ## Build the program binaries + native libraries (NO docs). `make stage` goes one step further and lays them out ready to install. Documentation is a separate phase: `make build-documentation`.

build-sbcl:  ## Strictly build SBCL images across subprojects (errors if sbcl is missing).
	$(MAKE) -C clautolisp         build-sbcl
	$(MAKE) -C autolisp-front-end build-sbcl

build-ccl:  ## Strictly build CCL images across subprojects (errors if ccl is missing).
	$(MAKE) -C clautolisp         build-ccl
	$(MAKE) -C autolisp-front-end build-ccl

test:  ## Run the clautolisp test suite plus the autolisp-test conformance corpus.
	$(MAKE) -C clautolisp test
	$(MAKE) -C autolisp-test test
	$(MAKE) -C autolisp-front-end test
	$(MAKE) -C autolisp-benchmark test

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
	@if   bash probes/scripts/detect-cad.sh autocad  >/dev/null 2>&1; then $(MAKE) probe-autocad; \
	 elif bash probes/scripts/detect-cad.sh bricscad >/dev/null 2>&1; then $(MAKE) probe-bricscad; \
	 else echo "make probe: no AutoCAD/BricsCAD detected — running the clautolisp baseline."; $(MAKE) probe-clautolisp; fi

probe-autocad:  ## Probe AutoCAD (accoreconsole/acad; override AUTOCAD_ACCORECONSOLE / AUTOCAD_EXE / AUTOCAD_RUNNER).
	bash probes/scripts/run-probes.sh autocad

probe-bricscad:  ## Probe BricsCAD (override BRICSCAD_EXE / BRICSCAD_RUNNER).
	bash probes/scripts/run-probes.sh bricscad

probe-clautolisp:  ## Probe the bundled clautolisp binary (headless baseline column for diffing).
	bash probes/scripts/run-probes.sh clautolisp

# --- Build phases, split by artefact kind ------------------------------

build-documentation:  ## Build all PDF docs + the autolisp-spec paged split (HTML/info/pages — the slow part).
	$(MAKE) documentation
	$(MAKE) -C autolisp-spec paged

build-programs:  ## Build the host program binaries (clautolisp, alfe, …) for each Lisp in RELEASE_LISPS (default sbcl; x86-64 release sets "sbcl ccl").
	@for l in $(RELEASE_LISPS); do $(MAKE) build-$$l || exit $$?; done

submodules:  ## Check out the git submodules (the vendored libredwg used by the DWG codec). Idempotent; runs automatically as part of build-libraries so a fresh clone builds directly.
	git submodule update --init --recursive

build-libraries:  ## Build the releasable libraries (the drawing/drawing-dwg native libdwg). Checks out the libredwg submodule first if needed.
	$(MAKE) -C clautolisp build-libredwg

# --- Release packaging -------------------------------------------------
#
# release-sources is platform-independent and fully implemented here.
# release-{documentation,programs,libraries} build their kind then stage
# + archive it; the multi-target (6 platforms) combination is assembled
# by CI from per-target artefacts (see the issue).

check-versions:  ## Audit the release tags / version-* pointers against the shared version rules (see AGENTS.md; run `git fetch --prune --tags` first).
	sh scripts/check-versions.sh

release: release-sources release-documentation release-programs release-libraries  ## Produce every release artefact for this host.

release-sources:  ## Produce the source tarball + zip (tracked files incl. submodules).
	@mkdir -p "$(DIST)"
	@prefix=clautolisp-$(VERSION); \
	stage=$$(mktemp -d); dest="$$stage/$$prefix"; mkdir -p "$$dest"; \
	git ls-files --recurse-submodules -z | tar -cf - --null -T - | tar -C "$$dest" -xf -; \
	sh scripts/make-manifest.sh sources > "$$dest/manifest-sources.txt"; \
	tar -C "$$stage" -cjf "$(DIST)/$$prefix-sources.tar.bz2" "$$prefix"; \
	( cd "$$stage" && zip -qr "$(DIST)/$$prefix-sources.zip" "$$prefix" ); \
	rm -rf "$$stage"; \
	echo "wrote $(DIST)/$$prefix-sources.tar.bz2"; \
	echo "wrote $(DIST)/$$prefix-sources.zip"

release-documentation: stage-documentation  ## Package the documentation artefact for EVERY subproject (pdf/org/info + the spec's paged HTML/info/pages + alref), from the same $(STAGE)/documentation tree install-documentation installs. Unpacks into $PREFIX.
	@mkdir -p "$(DIST)"
	@ver="$(VERSION)"; \
	tar -C "$(STAGE_DOCUMENTATION)" -cjf "$(DIST)/clautolisp-$$ver-documentation.tar.bz2" .; \
	echo "wrote $(DIST)/clautolisp-$$ver-documentation.tar.bz2"

# The one artefact whose layout is NOT the install tree: the binaries
# tarball ships a bin/ of dispatch.sh wrappers over
# libexec/clautolisp/binaries/<os>/<arch>/, so CI can union several
# targets into one multi-platform archive (see collect-artefacts).
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
	    if [ -f "$$b" ]; then cp "$$b" "$$bindir"/; \
	    elif [ -f "$$b.exe" ]; then cp "$$b.exe" "$$bindir"/; fi; \
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
	tar -C "$$stage" -cjf "$(DIST)/clautolisp-$$ver-binaries-$$os-$$arch.tar.bz2" .; \
	rm -rf "$$stage"; \
	echo "wrote $(DIST)/clautolisp-$$ver-binaries-$$os-$$arch.tar.bz2"

release-libraries: stage-libraries  ## Package this host's per-target libraries artefact (ASDF systems + native libdwg + header) from the same $(STAGE)/libraries tree install-libraries installs. CI unions the targets into clautolisp-<ver>-libraries.tar.bz2.
	@mkdir -p "$(DIST)"
	@ver="$(VERSION)"; os="$(REL_OS)"; arch="$(REL_ARCH)"; \
	tar -C "$(STAGE_LIBRARIES)" -cjf "$(DIST)/clautolisp-$$ver-libraries-$$os-$$arch.tar.bz2" .; \
	echo "wrote $(DIST)/clautolisp-$$ver-libraries-$$os-$$arch.tar.bz2"

# CI collect phase: union the per-target artefacts (gathered by the
# pipeline into COLLECT_IN) into the final combined release set in
# COLLECT_OUT. Pure repackaging — no build, no rebuild. The combined
# binaries/libraries tarballs merge each target's libexec/<os>/<arch>/
# and lib/<os>/<arch>/ subtrees (the shared bin/, lisp sources, include/
# overwrite identically); sources + documentation pass through once;
# the Windows artefact is kept as-is.
COLLECT_IN  ?= $(DIST)
COLLECT_OUT ?= $(DIST)/combined
collect-artefacts:  ## Union the per-target artefacts from COLLECT_IN into the combined release set in COLLECT_OUT.
	@ver="$(VERSION)"; in="$(COLLECT_IN)"; out="$(COLLECT_OUT)"; mkdir -p "$$out"; \
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
	for f in "$$in"/*windows*; do \
	  [ -e "$$f" ] || continue; cp "$$f" "$$out"/ && echo "windows $$(basename "$$f")"; \
	done; \
	echo "--- combined release set ($$out) ---"; ls -l "$$out"

clean:: clean-pdf
clean-pdf:  ## Remove every generated PDF across subprojects (keeps .org sources).
	$(MAKE) -C autolisp-spec clean-pdf
	$(MAKE) -C clautolisp clean-pdf
	$(MAKE) -C autolisp-test clean-pdf
	$(MAKE) -C autolisp-front-end clean-pdf
	$(MAKE) -C autolisp-benchmark clean-pdf
	$(MAKE) -C documentation clean-pdf

clean:: clean-diagrams
clean-diagrams:  ## Remove the rendered top-level diagrams (keeps the .dot sources).
	$(MAKE) -C documentation clean

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
	$(MAKE) -C autolisp-spec      install-programs PREFIX= DESTDIR=$(STAGE_PROGRAMS) $(LISP_VARS)
	$(MAKE) -C clautolisp         install-programs PREFIX= DESTDIR=$(STAGE_PROGRAMS) $(LISP_VARS)
	$(MAKE) -C autolisp-test      install-programs PREFIX= DESTDIR=$(STAGE_PROGRAMS) $(LISP_VARS)
	$(MAKE) -C autolisp-front-end install-programs PREFIX= DESTDIR=$(STAGE_PROGRAMS) $(LISP_VARS)
	$(MAKE) -C autolisp-benchmark install-programs PREFIX= DESTDIR=$(STAGE_PROGRAMS) $(LISP_VARS)
	@$(call stage-manifest,$(STAGE_PROGRAMS),programs)
	@echo "staged: $(STAGE_PROGRAMS)"

stage-libraries: build-libraries  ## Build the native libraries and stage them with the ASDF systems + header under $(STAGE)/libraries.
	rm -rf "$(STAGE_LIBRARIES)"
	install -d "$(STAGE_LIBRARIES)"
	$(MAKE) -C clautolisp         install-libraries PREFIX= DESTDIR=$(STAGE_LIBRARIES) $(LISP_VARS)
	@$(call stage-manifest,$(STAGE_LIBRARIES),libraries)
	@echo "staged: $(STAGE_LIBRARIES)"

stage-documentation: build-documentation  ## Render the documentation and stage it (share/doc, share/info, share/man, the spec's HTML/pages) under $(STAGE)/documentation.
	rm -rf "$(STAGE_DOCUMENTATION)"
	install -d "$(STAGE_DOCUMENTATION)"
	$(MAKE) -C autolisp-spec      install-documentation PREFIX= DESTDIR=$(STAGE_DOCUMENTATION) $(LISP_VARS)
	$(MAKE) -C clautolisp         install-documentation PREFIX= DESTDIR=$(STAGE_DOCUMENTATION) $(LISP_VARS)
	$(MAKE) -C autolisp-test      install-documentation PREFIX= DESTDIR=$(STAGE_DOCUMENTATION) $(LISP_VARS)
	$(MAKE) -C autolisp-front-end install-documentation PREFIX= DESTDIR=$(STAGE_DOCUMENTATION) $(LISP_VARS)
	$(MAKE) -C autolisp-benchmark install-documentation PREFIX= DESTDIR=$(STAGE_DOCUMENTATION) $(LISP_VARS)
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
	$(MAKE) -C autolisp-spec      uninstall $(INSTALL_VARS)
	$(MAKE) -C clautolisp         uninstall $(INSTALL_VARS)
	$(MAKE) -C autolisp-test      uninstall $(INSTALL_VARS)
	$(MAKE) -C autolisp-front-end uninstall $(INSTALL_VARS)
	$(MAKE) -C autolisp-benchmark uninstall $(INSTALL_VARS)

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
	$$(MAKE) -C $(2) $$@
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
		$(ALFE) --$$backend --dialect=$$backend --mode batch \
			-Esource Windows-1252 \
			-norc \
			-l autolisp-spec/autolisp/dump-sysvars.lsp \
			-x "(dump-sysvars \"sysvars-alfe-$$(uname)-$${backend}.txt\")"  || true ;\
	done
	for dialect in $(SAVE_SYSVARS_DIALECTS) ; do \
		$(CLAUTOLISP) --dialect $$dialect \
			-norc \
			-l autolisp-spec/autolisp/dump-sysvars.lsp \
			-x "(dump-sysvars \"sysvars-clautolisp-$$(uname)-$${dialect}.txt\")"  || true ;\
	done
