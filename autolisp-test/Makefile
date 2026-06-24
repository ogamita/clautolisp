# Documentation is exported to PDF via Emacs's native org-mode LaTeX
# exporter rather than pandoc; pandoc's org reader trips on a number
# of legitimate AutoLISP-spec constructs (e.g. `\"' inside backticks)
# that org-mode parses correctly. The LaTeX compiler is set to
# xelatex so arbitrary UTF-8 codepoints render without missing-glyph
# errors. Both variables are overridable, e.g.
# `make documentation LATEX_COMPILER=lualatex'.
EMACS          ?= $(shell sh ../scripts/resolve-emacs.sh)
LATEX_COMPILER ?= xelatex
SBCL   ?= sbcl
CCL    ?= ccl

# Host OS detection — used by the per-platform CAD targets below
# (BricsCAD/AutoCAD on macOS/Windows). The "wrong platform is a
# no-op" policy from issues/closed/test-targets.issue is enforced
# by `$(call require-os-darwin,$@)` at the top of each gated recipe.
HOST_OS := $(shell uname -s)

# require-os-darwin / require-os-windows — Make function macros.
# Used as `$(call require-os-darwin,$@)` from a recipe; the call
# expands to a shell `if` that prints a [skip] line and exit 0s
# when the host doesn't match. $@ is the calling target; we have to
# pass it explicitly because Make does not re-expand $@ inside a
# variable's stored value.
define require-os-darwin
if [ "$(HOST_OS)" != "Darwin" ]; then \
  echo "[skip] $(1): macOS-only (current: $(HOST_OS))"; \
  exit 0; \
fi
endef
define require-os-windows
case "$(HOST_OS)" in MINGW*|MSYS*|CYGWIN*) :;; *) \
  echo "[skip] $(1): Windows-only (current: $(HOST_OS))"; \
  exit 0;; \
esac
endef

ROOT_DIR := $(shell pwd)

# Path to alfe-sbcl / alfe-ccl. Used by the CAD-driven targets that
# load the harness through a real BricsCAD/AutoCAD engine via the
# file-IPC protocol Phase 3 wired up. Defined AFTER ROOT_DIR so the
# `:=` expansion sees the resolved working directory.
ALFE_ROOT := $(ROOT_DIR)/../autolisp-front-end
ALFE_SBCL := $(ALFE_ROOT)/tools/alfe/bin/alfe-sbcl
ALFE_CCL  := $(ALFE_ROOT)/tools/alfe/bin/alfe-ccl
CLAUTOLISP_ROOT := $(ROOT_DIR)/../clautolisp
CLAUTOLISP_ASD := $(CLAUTOLISP_ROOT)/clautolisp.asd
AUTOLISP_TEST_ASD := $(ROOT_DIR)/autolisp-test.asd
CLAUTOLISP_SBCL := $(CLAUTOLISP_ROOT)/tools/clautolisp/bin/clautolisp-sbcl
CLAUTOLISP_CCL  := $(CLAUTOLISP_ROOT)/tools/clautolisp/bin/clautolisp-ccl
XDG_CACHE_HOME ?= $(CLAUTOLISP_ROOT)/.cache

# Install destination. Override on the command line:
#   make install PREFIX=/usr/local DESTDIR=/staging
# Default /opt/local matches the MacPorts hierarchy and the
# repo-wide convention documented in the root Makefile.
PREFIX ?= /opt/local
DESTDIR ?=
SUBPROJECT_NAME := autolisp-test

DOCUMENTATION_ORG := $(wildcard documentation/*.org) $(wildcard harness/*.org) $(wildcard tests/*.org)
PDF_FILES := $(DOCUMENTATION_ORG:.org=.pdf)

# Inline AutoLISP snippet that the standalone clautolisp executables
# evaluate to launch the conformance harness. Sets *clautolisp-version*
# so platform-detect identifies the implementation as clautolisp,
# clears *autolisp-test-debug-p* so harness errors are caught and
# reported (rather than dropping into the debugger), then loads
# run.lsp and invokes (autolisp-test-run-all).
HARNESS_SNIPPET := \
  (setq *clautolisp-version* "0.x") \
  (setq *autolisp-test-debug-p* nil) \
  (setq *autolisp-test-root* "$(ROOT_DIR)/") \
  (load (strcat *autolisp-test-root* "harness/run.lsp")) \
  (autolisp-test-run-all)

# Debug variant: enables both the harness-side and CL-side guards
# bypass so any escaped error trips the host debugger. Use only for
# interactive investigation.
HARNESS_DEBUG_SNIPPET := \
  (setq *clautolisp-version* "0.x") \
  (setq *autolisp-test-debug-p* T) \
  (setq *autolisp-test-root* "$(ROOT_DIR)/") \
  (load (strcat *autolisp-test-root* "harness/run.lsp")) \
  (autolisp-test-run-all)

# Source files the standalone clautolisp executable depends on.
# When any of these is newer than the binary, the test targets below
# rebuild the binary first so a `make test-clautolisp-sbcl' run after
# editing runtime source never executes a stale binary.
CLAUTOLISP_SOURCES := \
  $(wildcard $(CLAUTOLISP_ROOT)/autolisp-reader/source/*.lisp) \
  $(wildcard $(CLAUTOLISP_ROOT)/autolisp-runtime/source/*.lisp) \
  $(wildcard $(CLAUTOLISP_ROOT)/autolisp-builtins-core/source/*.lisp) \
  $(wildcard $(CLAUTOLISP_ROOT)/autolisp-file-compat/source/*.lisp) \
  $(wildcard $(CLAUTOLISP_ROOT)/tools/clautolisp/source/*.lisp) \
  $(CLAUTOLISP_ROOT)/clautolisp.asd

.PHONY: all build documentation test test-clautolisp-sbcl test-clautolisp-ccl \
        test-clautolisp-sbcl-debug test-clautolisp-ccl-debug \
        test-asdf-sbcl test-asdf-ccl \
        test-asdf-sbcl-debug test-asdf-ccl-debug \
        build-clautolisp-sbcl build-clautolisp-ccl clean-pdf \
        test-clautolisp-sbcl-strict test-clautolisp-sbcl-clautolisp \
        test-clautolisp-sbcl-bricscad test-clautolisp-sbcl-autocad \
        test-clautolisp-ccl-strict  test-clautolisp-ccl-clautolisp \
        test-clautolisp-ccl-bricscad test-clautolisp-ccl-autocad \
        test-clautolisp-sbcl-all test-clautolisp-ccl-all test-clautolisp-all \
        test-bricscad-macos test-bricscad-macos-strict test-bricscad-macos-bricscad \
        test-bricscad-windows test-bricscad-windows-strict test-bricscad-windows-bricscad \
        test-autocad-windows test-autocad-windows-strict test-autocad-windows-autocad

all: documentation

# `build` is a convenience alias for `documentation` so the
# repo-wide `make build && sudo make install` pattern works
# uniformly across subprojects — autolisp-test ships only docs +
# AutoLISP source (no compiled executables), so there's nothing
# else to produce before install.
build: documentation  ## Build everything `install` would ship (docs only — no executables for this subproject).

documentation: $(PDF_FILES)

# `test' is the umbrella target invoked by the parent Makefile. It
# runs the canonical SBCL path (via the standalone executable) so the
# implementation identification matches what AutoCAD and BricsCAD
# would report when they load run.lsp themselves.
test: test-clautolisp-sbcl

# --- Path 1: the standalone clautolisp executable ------------------
# The executables under clautolisp/tools/clautolisp/bin/ are built
# (or rebuilt) automatically when any clautolisp source file is newer
# than the existing binary. This avoids running stale binaries after
# a runtime fix.

$(CLAUTOLISP_SBCL): $(CLAUTOLISP_SOURCES)
	$(MAKE) -C $(CLAUTOLISP_ROOT) build-clautolisp-sbcl

$(CLAUTOLISP_CCL): $(CLAUTOLISP_SOURCES)
	$(MAKE) -C $(CLAUTOLISP_ROOT) build-clautolisp-ccl

build-clautolisp-sbcl: $(CLAUTOLISP_SBCL)
build-clautolisp-ccl:  $(CLAUTOLISP_CCL)

test-clautolisp-sbcl: $(CLAUTOLISP_SBCL)
	"$(CLAUTOLISP_SBCL)" -x '$(HARNESS_SNIPPET)'

test-clautolisp-sbcl-debug: $(CLAUTOLISP_SBCL)
	"$(CLAUTOLISP_SBCL)" -x '$(HARNESS_DEBUG_SNIPPET)'

test-clautolisp-ccl: $(CLAUTOLISP_CCL)
	"$(CLAUTOLISP_CCL)" -x '$(HARNESS_SNIPPET)'

test-clautolisp-ccl-debug: $(CLAUTOLISP_CCL)
	"$(CLAUTOLISP_CCL)" -x '$(HARNESS_DEBUG_SNIPPET)'

# --- Path 2: SBCL/CCL + ASDF driver --------------------------------
# Loads the autolisp-test/clautolisp-driver system, which installs
# the core builtins, exports *clautolisp-version*, and invokes the
# AutoLISP harness inside a fresh runtime session. No executable
# build is required.

test-asdf-sbcl:
	env XDG_CACHE_HOME="$(XDG_CACHE_HOME)" \
	$(SBCL) --noinform --no-userinit --non-interactive \
		--eval '(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname)))) (when (probe-file ql) (load ql)))' \
		--eval '(require :asdf)' \
		--eval '(asdf:load-asd "$(CLAUTOLISP_ASD)")' \
		--eval '(asdf:load-asd "$(AUTOLISP_TEST_ASD)")' \
		--eval '(asdf:load-system "autolisp-test/clautolisp-driver")' \
		--eval '(autolisp-test.clautolisp-driver:run-autolisp-test-suite)'

test-asdf-sbcl-debug:
	env XDG_CACHE_HOME="$(XDG_CACHE_HOME)" \
	$(SBCL) --noinform --no-userinit \
		--eval '(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname)))) (when (probe-file ql) (load ql)))' \
		--eval '(require :asdf)' \
		--eval '(asdf:load-asd "$(CLAUTOLISP_ASD)")' \
		--eval '(asdf:load-asd "$(AUTOLISP_TEST_ASD)")' \
		--eval '(asdf:load-system "autolisp-test/clautolisp-driver")' \
		--eval '(autolisp-test.clautolisp-driver:run-autolisp-test-suite :debug t)'

test-asdf-ccl:
	env XDG_CACHE_HOME="$(XDG_CACHE_HOME)" \
	$(CCL) --no-init --quiet \
		--eval '(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname)))) (when (probe-file ql) (load ql)))' \
		--eval '(require :asdf)' \
		--eval '(asdf:load-asd "$(CLAUTOLISP_ASD)")' \
		--eval '(asdf:load-asd "$(AUTOLISP_TEST_ASD)")' \
		--eval '(asdf:load-system "autolisp-test/clautolisp-driver")' \
		--eval '(autolisp-test.clautolisp-driver:run-autolisp-test-suite)' \
		--eval '(ccl:quit)'

test-asdf-ccl-debug:
	env XDG_CACHE_HOME="$(XDG_CACHE_HOME)" \
	$(CCL) --no-init --quiet \
		--eval '(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname)))) (when (probe-file ql) (load ql)))' \
		--eval '(require :asdf)' \
		--eval '(asdf:load-asd "$(CLAUTOLISP_ASD)")' \
		--eval '(asdf:load-asd "$(AUTOLISP_TEST_ASD)")' \
		--eval '(asdf:load-system "autolisp-test/clautolisp-driver")' \
		--eval '(autolisp-test.clautolisp-driver:run-autolisp-test-suite :debug t)'

%.pdf: %.org
	$(EMACS) --batch \
		--eval '(progn (require (quote ox-latex)) (setq org-latex-compiler "$(LATEX_COMPILER)") (setq org-export-with-broken-links t) (setq org-latex-pdf-process (list (concat "$(LATEX_COMPILER)" " -interaction nonstopmode -output-directory %o %f") (concat "$(LATEX_COMPILER)" " -interaction nonstopmode -output-directory %o %f"))))' \
		--visit "$<" \
		--funcall org-latex-export-to-pdf

clean-pdf:
	rm -f $(PDF_FILES)

# ---------------------------------------------------------------------
# autolisp-test × clautolisp × dialect matrix
# ---------------------------------------------------------------------
# Per issues/closed/test-targets.issue, expose eight leaf targets
# (2 implementations × 4 dialects) plus three aggregate targets so a
# tester can drive a single combination or run the whole grid with
# one command.
#
# The dialect is selected via clautolisp-sbcl's --dialect CLI flag,
# whose accepted values are documented in
# clautolisp/tools/clautolisp/source/main.lisp: strict,
# autocad-2026, bricscad-v26. The :clautolisp dialect the alfe
# runtime exposes is internally an alias for :strict — the
# standalone clautolisp executable does not accept "clautolisp" at
# the --dialect flag, so the -clautolisp targets below pass
# `--dialect strict` and rely on the documented alias. Kept as a
# separate target name (rather than dropped) so the tester-facing
# surface matches what the test-targets issue requested.
#
# All targets re-use the existing HARNESS_SNIPPET so a change in
# the harness entry point only needs editing one place.

test-clautolisp-sbcl-strict: $(CLAUTOLISP_SBCL)
	"$(CLAUTOLISP_SBCL)" --dialect strict -x '$(HARNESS_SNIPPET)'

test-clautolisp-sbcl-clautolisp: $(CLAUTOLISP_SBCL)
	"$(CLAUTOLISP_SBCL)" --dialect strict -x '$(HARNESS_SNIPPET)'

test-clautolisp-sbcl-bricscad: $(CLAUTOLISP_SBCL)
	"$(CLAUTOLISP_SBCL)" --dialect bricscad-v26 -x '$(HARNESS_SNIPPET)'

test-clautolisp-sbcl-autocad: $(CLAUTOLISP_SBCL)
	"$(CLAUTOLISP_SBCL)" --dialect autocad-2026 -x '$(HARNESS_SNIPPET)'

test-clautolisp-ccl-strict: $(CLAUTOLISP_CCL)
	"$(CLAUTOLISP_CCL)" --dialect strict -x '$(HARNESS_SNIPPET)'

test-clautolisp-ccl-clautolisp: $(CLAUTOLISP_CCL)
	"$(CLAUTOLISP_CCL)" --dialect strict -x '$(HARNESS_SNIPPET)'

test-clautolisp-ccl-bricscad: $(CLAUTOLISP_CCL)
	"$(CLAUTOLISP_CCL)" --dialect bricscad-v26 -x '$(HARNESS_SNIPPET)'

test-clautolisp-ccl-autocad: $(CLAUTOLISP_CCL)
	"$(CLAUTOLISP_CCL)" --dialect autocad-2026 -x '$(HARNESS_SNIPPET)'

# Aggregate: every dialect against one implementation.
test-clautolisp-sbcl-all: \
    test-clautolisp-sbcl-strict \
    test-clautolisp-sbcl-clautolisp \
    test-clautolisp-sbcl-bricscad \
    test-clautolisp-sbcl-autocad

test-clautolisp-ccl-all: \
    test-clautolisp-ccl-strict \
    test-clautolisp-ccl-clautolisp \
    test-clautolisp-ccl-bricscad \
    test-clautolisp-ccl-autocad

# Aggregate: every (dialect, implementation) pair.
test-clautolisp-all: test-clautolisp-sbcl-all test-clautolisp-ccl-all

# ---------------------------------------------------------------------
# autolisp-test × real-CAD matrix (BricsCAD/AutoCAD via alfe)
# ---------------------------------------------------------------------
# These targets drive the autolisp-test harness inside a real
# BricsCAD or AutoCAD engine via alfe's file-IPC protocol (Phase 3
# of the alfe rollout). Each is gated on the host OS — running a
# macOS target on Linux prints a [skip] line and exits 0, matching
# the "wrong platform is a no-op" policy from the issue.
#
# The recipes assume alfe-sbcl is built (see autolisp-front-end's
# build-alfe-sbcl). The actual real-CAD drive is itself gated by
# the matching $BRICSCAD_EXE / $AUTOCAD_EXE; without those, alfe's
# DETECT phase will exit 3 and the test reports the engine as
# unavailable.

# alfe driving the autolisp-test harness inside a CAD engine.
# Loads harness/run.lsp (which the runtime then runs through its
# autolisp-test-run-all entry) and asks alfe to evaluate the entry
# point. The CAD-side runtime publishes status transitions; alfe's
# eval-plan waits for DONE between each action.
ALFE_HARNESS_LOAD := -l "$(ROOT_DIR)/harness/run.lsp"
ALFE_HARNESS_RUN  := -x "(autolisp-test-run-all)"

test-bricscad-macos-strict:
	@$(call require-os-darwin,$@); \
	 "$(ALFE_SBCL)" --bricscad --dialect strict $(ALFE_HARNESS_LOAD) $(ALFE_HARNESS_RUN)

test-bricscad-macos-bricscad:
	@$(call require-os-darwin,$@); \
	 "$(ALFE_SBCL)" --bricscad --dialect bricscad-v26 $(ALFE_HARNESS_LOAD) $(ALFE_HARNESS_RUN)

test-bricscad-macos: test-bricscad-macos-strict test-bricscad-macos-bricscad

test-bricscad-windows-strict:
	@$(call require-os-windows,$@); \
	 "$(ALFE_SBCL)" --bricscad --dialect strict $(ALFE_HARNESS_LOAD) $(ALFE_HARNESS_RUN)

test-bricscad-windows-bricscad:
	@$(call require-os-windows,$@); \
	 "$(ALFE_SBCL)" --bricscad --dialect bricscad-v26 $(ALFE_HARNESS_LOAD) $(ALFE_HARNESS_RUN)

test-bricscad-windows: test-bricscad-windows-strict test-bricscad-windows-bricscad

test-autocad-windows-strict:
	@$(call require-os-windows,$@); \
	 "$(ALFE_SBCL)" --autocad --dialect strict $(ALFE_HARNESS_LOAD) $(ALFE_HARNESS_RUN)

test-autocad-windows-autocad:
	@$(call require-os-windows,$@); \
	 "$(ALFE_SBCL)" --autocad --dialect autocad-2026 $(ALFE_HARNESS_LOAD) $(ALFE_HARNESS_RUN)

test-autocad-windows: test-autocad-windows-strict test-autocad-windows-autocad

# ---------------------------------------------------------------------
# Install / uninstall.
#
# Layout follows the repo-wide convention (see the root Makefile):
#
#   $(PREFIX)/libexec/autolisp-test/                harness/*.lsp +
#                                                   tests/*.lsp — the
#                                                   actual conformance
#                                                   AutoLISP source the
#                                                   user runs via
#                                                   `clautolisp -l
#                                                    <…>/harness/run.lsp`
#   $(PREFIX)/share/doc/autolisp-test/              .org + .pdf docs
#
# autolisp-test ships no user-facing executables — the harness is
# loaded INTO a running AutoLISP engine (AutoCAD / BricsCAD /
# clautolisp-sbcl) rather than spawned as its own process. So the
# 'libexec' slot houses the harness + test files for the engine to
# load. The 'bin' install dir stays empty for this subproject.

LIBEXEC_INSTALL_DIR := $(DESTDIR)$(PREFIX)/libexec/$(SUBPROJECT_NAME)
DOC_INSTALL_DIR     := $(DESTDIR)$(PREFIX)/share/doc/$(SUBPROJECT_NAME)
INFO_INSTALL_DIR    := $(DESTDIR)$(PREFIX)/share/info
INSTALL_INFO        ?= install-info

.PHONY: install uninstall

install: build  ## Install harness + tests + docs into $$PREFIX (run `make build` first so this can be sudo'd cleanly).
	install -d $(LIBEXEC_INSTALL_DIR)/harness
	install -d $(LIBEXEC_INSTALL_DIR)/tests
	install -d $(DOC_INSTALL_DIR)
	@if [ -d harness ]; then \
	  for f in harness/*.lsp; do \
	    [ -f "$$f" ] && install -m 0644 "$$f" $(LIBEXEC_INSTALL_DIR)/harness/ ; \
	  done ; \
	fi
	@if [ -d tests ]; then \
	  for f in tests/*.lsp tests/*/*.lsp; do \
	    if [ -f "$$f" ]; then \
	      target="$(LIBEXEC_INSTALL_DIR)/$$f" ; \
	      mkdir -p "$$(dirname "$$target")" ; \
	      install -m 0644 "$$f" "$$target" ; \
	    fi ; \
	  done ; \
	fi
	@for f in documentation/*.org documentation/*.pdf; do \
	  if [ -f "$$f" ]; then install -m 0644 "$$f" $(DOC_INSTALL_DIR)/ ; fi ; \
	done
	install -d $(INFO_INSTALL_DIR)
	@for f in documentation/*.info; do \
	  if [ -f "$$f" ]; then \
	    install -m 0644 "$$f" $(INFO_INSTALL_DIR)/ ; \
	    installed="$(INFO_INSTALL_DIR)/$$(basename $$f)" ; \
	    $(INSTALL_INFO) --info-dir="$(INFO_INSTALL_DIR)" "$$installed" 2>/dev/null \
	      || echo "[skip] install-info dir update for $$installed" ; \
	  fi ; \
	done
	@echo "autolisp-test install complete: PREFIX=$(PREFIX) DESTDIR=$(DESTDIR)"

uninstall:  ## Remove the autolisp-test install from $$PREFIX.
	rm -rf $(LIBEXEC_INSTALL_DIR) $(DOC_INSTALL_DIR)
	@for f in documentation/*.info; do \
	  if [ -f "$$f" ]; then \
	    $(INSTALL_INFO) --remove --info-dir="$(INFO_INSTALL_DIR)" "$$f" 2>/dev/null \
	      || true ; \
	    rm -f "$(INFO_INSTALL_DIR)/$$(basename $$f)" ; \
	  fi ; \
	done
