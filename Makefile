SUBPROJECTS := autolisp-spec clautolisp autolisp-test autolisp-front-end
CLAUTOLISP_CI_IMAGE ?= registry.gitlab.com/ogamita/clautolisp/clautolisp-ci:latest
CLAUTOLISP_CI_DOCKERFILE ?= clautolisp/docker/Dockerfile
CLAUTOLISP_CI_PLATFORM ?= linux/amd64

# Install destination. Override on the command line:
#   make install PREFIX=/usr/local
#   make install DESTDIR=/staging PREFIX=/opt/local      # packager use
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
#
# /opt/local matches the MacPorts hierarchy; /usr/local and
# /usr are the common alternatives the override accepts.

PREFIX ?= /opt/local
DESTDIR ?=

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

.PHONY: help all clean build build-sbcl build-ccl documentation test clean-pdf docker-build-clautolisp-ci docker-push-clautolisp-ci install install-programs install-libraries install-documentation uninstall $(SUBPROJECTS) \
        build-documentation build-programs build-libraries \
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

all: documentation  ## Default target: build full documentation across all subprojects.


autolisp-spec:  ## Build the autolisp-spec subproject (delegates to its Makefile).
	$(MAKE) -C autolisp-spec all

clautolisp:  ## Build the clautolisp subproject — runtime, executables, GUI driver, docs.
	$(MAKE) -C clautolisp all

autolisp-test:  ## Build the autolisp-test conformance harness subproject.
	$(MAKE) -C autolisp-test all

autolisp-front-end:  ## Build the autolisp-front-end (alfe) subproject — unified CLI front-end for clautolisp + CAD-resident REPLs.
	$(MAKE) -C autolisp-front-end all

documentation:  ## Rebuild every subproject's PDF documentation (org → LaTeX → PDF).
	$(MAKE) -C autolisp-spec documentation
	$(MAKE) -C clautolisp documentation
	$(MAKE) -C autolisp-test documentation
	$(MAKE) -C autolisp-front-end documentation

build:  ## Build every subproject's artefacts (executables + docs + paged derivatives) — what `install` then copies. Run this WITHOUT sudo, then `sudo make install`.
	$(MAKE) -C autolisp-spec      build
	$(MAKE) -C clautolisp         build
	$(MAKE) -C autolisp-test      build
	$(MAKE) -C autolisp-front-end build

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

build-libraries:  ## Build the releasable libraries (the drawing/drawing-dwg native libdwg).
	$(MAKE) -C clautolisp build-libredwg

# --- Release packaging -------------------------------------------------
#
# release-sources is platform-independent and fully implemented here.
# release-{documentation,programs,libraries} build their kind then stage
# + archive it; the multi-target (6 platforms) combination is assembled
# by CI from per-target artefacts (see the issue).

release: release-sources release-documentation release-programs release-libraries  ## Produce every release artefact for this host.

release-sources:  ## Produce the source tarball + zip (tracked files incl. submodules).
	@mkdir -p "$(DIST)"
	@prefix=clautolisp-$(VERSION); \
	stage=$$(mktemp -d); dest="$$stage/$$prefix"; mkdir -p "$$dest"; \
	git ls-files --recurse-submodules -z | tar -cf - --null -T - | tar -C "$$dest" -xf -; \
	tar -C "$$stage" -cjf "$(DIST)/$$prefix-sources.tar.bz2" "$$prefix"; \
	( cd "$$stage" && zip -qr "$(DIST)/$$prefix-sources.zip" "$$prefix" ); \
	rm -rf "$$stage"; \
	echo "wrote $(DIST)/$$prefix-sources.tar.bz2"; \
	echo "wrote $(DIST)/$$prefix-sources.zip"

release-documentation: build-documentation  ## Package the documentation artefact: the spec (pdf/org + prebuilt paged HTML/info/pages) + alref, unpacks into $PREFIX.
	@mkdir -p "$(DIST)"
	@ver="$(VERSION)"; stage=$$(mktemp -d); \
	$(MAKE) -C autolisp-spec install DESTDIR="$$stage" PREFIX= >/dev/null; \
	tar -C "$$stage" -cjf "$(DIST)/clautolisp-$$ver-documentation.tar.bz2" .; \
	rm -rf "$$stage"; \
	echo "wrote $(DIST)/clautolisp-$$ver-documentation.tar.bz2"

release-programs: build-programs  ## Build programs and package this host's per-target binaries artefact (unpacks into $PREFIX). CI unions the unix targets.
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
	for d in clautolisp/documentation/clautolisp-user-manual.info \
	         clautolisp/documentation/clautolisp-user-manual.pdf \
	         autolisp-front-end/documentation/alfe-user-manual.info \
	         autolisp-front-end/documentation/alfe-user-manual.pdf; do \
	  if [ -f "$$d" ]; then cp "$$d" "$$docdir"/; fi; \
	done; \
	tar -C "$$stage" -cjf "$(DIST)/clautolisp-$$ver-binaries-$$os-$$arch.tar.bz2" .; \
	rm -rf "$$stage"; \
	echo "wrote $(DIST)/clautolisp-$$ver-binaries-$$os-$$arch.tar.bz2"

release-libraries: build-libraries  ## Build libraries and package this host's per-target libraries artefact (asd sources + native libdwg). CI unions the targets into clautolisp-<ver>-libraries.tar.bz2.
	@mkdir -p "$(DIST)"
	@ver="$(VERSION)"; os="$(REL_OS)"; arch="$(REL_ARCH)"; \
	stage=$$(mktemp -d); \
	srcroot="$$stage/share/common-lisp/source/clautolisp"; mkdir -p "$$srcroot"; \
	( cd clautolisp && git ls-files -z '*.lisp' '*.asd' | tar -cf - --null -T - ) | tar -C "$$srcroot" -xf -; \
	mkdir -p "$$stage/share/common-lisp/systems"; \
	( cd "$$stage/share/common-lisp/systems" && ln -sf ../source/clautolisp/clautolisp.asd clautolisp.asd ); \
	libdir="$$stage/lib/clautolisp/$$os/$$arch"; mkdir -p "$$libdir"; \
	cp clautolisp/third-party/libredwg/build/libredwg.dylib \
	   clautolisp/third-party/libredwg/build/libredwg.so \
	   clautolisp/third-party/libredwg/build/libredwg.dll "$$libdir"/ 2>/dev/null || true; \
	cp clautolisp/drawing-dwg/source/clal_dwg.dylib \
	   clautolisp/drawing-dwg/source/clal_dwg.so \
	   clautolisp/drawing-dwg/source/clal_dwg.dll "$$libdir"/ 2>/dev/null || true; \
	mkdir -p "$$stage/include/clautolisp"; \
	cp clautolisp/third-party/libredwg/include/dwg.h "$$stage/include/clautolisp"/; \
	docdir="$$stage/share/doc/clautolisp"; mkdir -p "$$docdir"; \
	cp clautolisp/drawing/documentation/drawing-specifications.org "$$docdir"/ 2>/dev/null || true; \
	cp clautolisp/third-party/libredwg/COPYING "$$docdir"/libredwg-COPYING 2>/dev/null || true; \
	tar -C "$$stage" -cjf "$(DIST)/clautolisp-$$ver-libraries-$$os-$$arch.tar.bz2" .; \
	rm -rf "$$stage"; \
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
	  tar -C "$$bstage" -cjf "$$out/clautolisp-$$ver-binaries.tar.bz2" .; \
	  echo "wrote $$out/clautolisp-$$ver-binaries.tar.bz2 (from $$n target(s))"; \
	else echo "WARNING: no per-target binaries artefacts in $$in"; fi; \
	rm -rf "$$bstage"; \
	lstage=$$(mktemp -d); n=0; \
	for t in "$$in"/clautolisp-$$ver-libraries-*.tar.bz2; do \
	  [ -f "$$t" ] || continue; echo "merge $$(basename "$$t")"; tar -C "$$lstage" -xjf "$$t"; n=$$((n+1)); \
	done; \
	if [ "$$n" -gt 0 ]; then \
	  tar -C "$$lstage" -cjf "$$out/clautolisp-$$ver-libraries.tar.bz2" .; \
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

clean:: clean-backups
clean-backups:
	@printf 'Cleaning backup files.\n'
	@find . -name \*~ -exec rm -f {} \;

# Forwards PREFIX, DESTDIR, and DEFAULT_LISP to every subproject so a
# single CLI override (e.g. `make install DEFAULT_LISP=ccl') flows
# through. When the user does not set DEFAULT_LISP, each subproject
# falls back to its own (firstword $(AVAILABLE_IMPLEMENTATIONS)) —
# so an SBCL-only host installs SBCL symlinks, etc.
INSTALL_VARS := PREFIX=$(PREFIX) DESTDIR=$(DESTDIR)
ifneq ($(DEFAULT_LISP),)
  INSTALL_VARS += DEFAULT_LISP=$(DEFAULT_LISP)
endif

install:  ## Install every subproject's built artefacts into $$PREFIX (default /opt/local). Override the bare-name symlink target with DEFAULT_LISP=sbcl|ccl.
	$(MAKE) -C autolisp-spec      install $(INSTALL_VARS)
	$(MAKE) -C clautolisp         install $(INSTALL_VARS)
	$(MAKE) -C autolisp-test      install $(INSTALL_VARS)
	$(MAKE) -C autolisp-front-end install $(INSTALL_VARS)

# Independent install phases mirroring build-programs / build-libraries /
# build-documentation, so a consumer can install only what it needs. CI
# that exercises the programs uses `make install-programs' and skips the
# slow documentation build+install entirely.
install-programs: build-programs  ## Install only the program binaries (clautolisp/alfe/read-autolisp + the test harness) — no docs. The CI fast path.
	$(MAKE) -C clautolisp         install-programs $(INSTALL_VARS)
	$(MAKE) -C autolisp-test      install-programs $(INSTALL_VARS)
	$(MAKE) -C autolisp-front-end install-programs $(INSTALL_VARS)

install-libraries: build-libraries  ## Install only the native libraries (the drawing/drawing-dwg native libdwg + CFFI shim).
	$(MAKE) -C clautolisp         install-libraries $(INSTALL_VARS)

install-documentation: build-documentation  ## Install only the documentation (the slow phase: PDFs + the autolisp-spec paged HTML/info/pages).
	$(MAKE) -C autolisp-spec      install-documentation $(INSTALL_VARS)
	$(MAKE) -C clautolisp         install-documentation $(INSTALL_VARS)
	$(MAKE) -C autolisp-test      install-documentation $(INSTALL_VARS)
	$(MAKE) -C autolisp-front-end install-documentation $(INSTALL_VARS)

uninstall:  ## Remove every subproject's install from $$PREFIX.
	$(MAKE) -C autolisp-spec      uninstall $(INSTALL_VARS)
	$(MAKE) -C clautolisp         uninstall $(INSTALL_VARS)
	$(MAKE) -C autolisp-test      uninstall $(INSTALL_VARS)
	$(MAKE) -C autolisp-front-end uninstall $(INSTALL_VARS)

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
