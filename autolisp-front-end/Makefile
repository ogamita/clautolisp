# Documentation is exported to PDF via Emacs's native org-mode LaTeX
# exporter rather than pandoc (consistent with the other subprojects).
# The LaTeX compiler defaults to xelatex for UTF-8 codepoint coverage;
# both variables are overridable.
EMACS          ?= emacs
MAKEINFO       ?= makeinfo
INSTALL_INFO   ?= install-info
LATEX_COMPILER ?= xelatex
SBCL   ?= sbcl
CCL    ?= ccl
LISP   ?= $(SBCL)

ROOT_DIR := $(shell pwd)
CLAUTOLISP_ROOT := $(ROOT_DIR)/../clautolisp
CLAUTOLISP_ASD := $(CLAUTOLISP_ROOT)/clautolisp.asd
ALFE_ASD := $(ROOT_DIR)/autolisp-front-end.asd
ALFE_TOOL_DIR := tools/alfe
ALFE_BIN_DIR := $(ALFE_TOOL_DIR)/bin
ALFE_SBCL := $(ALFE_BIN_DIR)/alfe-sbcl
ALFE_CCL  := $(ALFE_BIN_DIR)/alfe-ccl
# The build script lives under tools/alfe/ alongside source/ and bin/.
ALFE_GENERATE := $(ALFE_TOOL_DIR)/generate-alfe.lisp
# Honour the parent project's shared cache so ASDF reuses fasls
# between subprojects. Falls back to a local .cache directory if
# the parent hasn't set XDG_CACHE_HOME.
XDG_CACHE_HOME ?= $(CLAUTOLISP_ROOT)/.cache

# Install destination. Override on the command line:
#   make install PREFIX=/usr/local DESTDIR=/staging
# Default /opt/local matches the MacPorts hierarchy and the
# repo-wide convention documented in the root Makefile.
PREFIX ?= /opt/local
DESTDIR ?=
SUBPROJECT_NAME := autolisp-front-end

# ---------------------------------------------------------------------
# Available Common Lisp implementations (probed at Make-parse time).
# Same convention as clautolisp/Makefile: the user-facing 'build' and
# 'install' walk this list; per-impl 'build-sbcl' / 'build-ccl'
# variants are strict (error when their impl is missing).
HAVE_SBCL := $(shell command -v $(SBCL) >/dev/null 2>&1 && echo yes)
HAVE_CCL  := $(shell command -v $(CCL)  >/dev/null 2>&1 && echo yes)
AVAILABLE_IMPLEMENTATIONS :=
ifeq ($(HAVE_SBCL),yes)
  AVAILABLE_IMPLEMENTATIONS += sbcl
endif
ifeq ($(HAVE_CCL),yes)
  AVAILABLE_IMPLEMENTATIONS += ccl
endif

# DEFAULT_LISP picks the implementation the bare `alfe' symlink
# in $(PREFIX)/bin points at after install. Defaults to the first
# implementation found on the host (SBCL wins over CCL because of
# the order we append above). Override on the command line to pin
# a different one, e.g.
#
#   make install DEFAULT_LISP=ccl
#
# Mirrors clautolisp/Makefile's variable of the same name; when
# the root forwards `make install', a single CLI override flows
# through both subprojects so the bare `clautolisp' and `alfe'
# symlinks always agree on the underlying CL.
DEFAULT_LISP ?= $(firstword $(AVAILABLE_IMPLEMENTATIONS))

# Host OS detection — used by the per-platform alfe-backend test
# targets below (test-alfe-{sbcl,ccl}-{bricscad,autocad}-*). Wrong-
# platform targets call require-os-* which prints a [skip] line and
# exits 0 per the policy in issues/closed/test-targets.issue.
HOST_OS := $(shell uname -s)
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

DOCUMENTATION_ORG := $(wildcard documentation/*.org)
NESTED_DOC_ORG := $(wildcard tools/*/documentation/*.org)
ALL_ORG_FILES := $(DOCUMENTATION_ORG) $(NESTED_DOC_ORG)
PDF_FILES := $(ALL_ORG_FILES:.org=.pdf)
INFO_FILES := $(ALL_ORG_FILES:.org=.info)
MAN_FILES := $(wildcard documentation/man/*.1) \
             $(wildcard tools/*/documentation/man/*.1)

# The aggregate ASDF test system. Keeping it in a variable mirrors
# the clautolisp Makefile so additional images (alfe-mac, alfe-win,
# etc.) can be added with one extra line each.
TEST_SYSTEM ?= autolisp-front-end

.PHONY: help all documentation test test-sbcl test-ccl \
        build build-sbcl build-ccl probe-check \
        build-alfe-sbcl build-alfe-ccl clean-pdf clean \
        conformance check-spec-coverage \
        test-alfe-sbcl-clautolisp test-alfe-ccl-clautolisp \
        test-alfe-sbcl-bricscad-macos test-alfe-ccl-bricscad-macos \
        test-alfe-sbcl-bricscad-windows test-alfe-ccl-bricscad-windows \
        test-alfe-sbcl-autocad-windows test-alfe-ccl-autocad-windows

help:  ## Show this message (list available targets and their purpose).
	@awk 'BEGIN { \
	    FS = ":.*?## "; \
	    printf "Usage: make <target>\n\nautolisp-front-end targets:\n"; \
	  } \
	  /^[a-zA-Z_][a-zA-Z0-9_-]*:.*?## / { \
	    printf "  %-32s %s\n", $$1, $$2; \
	  }' $(MAKEFILE_LIST)

all: documentation build  ## Default: docs + alfe binaries for every available CL implementation.

# ---------------------------------------------------------------------
# build / build-<impl> — user-facing build entry points.
# Same shape as clautolisp/Makefile: `build` covers every available
# implementation, the per-impl aliases are strict.

BUILD_TARGETS := $(foreach impl,$(AVAILABLE_IMPLEMENTATIONS),build-alfe-$(impl))

build: probe-check $(BUILD_TARGETS) documentation  ## Build alfe binaries + docs (everything `install` ships) for every available CL implementation.

probe-check:
	@if [ -z "$(strip $(AVAILABLE_IMPLEMENTATIONS))" ]; then \
	  echo "Error: no Common Lisp implementation found on PATH"; \
	  echo "  Tried: sbcl ($(SBCL)), ccl ($(CCL))"; \
	  echo "  Override via 'make build SBCL=/path/to/sbcl' or 'CCL=/path/to/ccl'."; \
	  exit 2; \
	fi
	@echo "Building alfe with: $(AVAILABLE_IMPLEMENTATIONS)"

build-sbcl:  ## Strictly build the SBCL alfe image (errors if sbcl is missing).
	@if [ "$(HAVE_SBCL)" != "yes" ]; then \
	  echo "Error: sbcl not found in PATH (looked for '$(SBCL)')"; \
	  exit 2; \
	fi
	$(MAKE) build-alfe-sbcl

build-ccl:  ## Strictly build the CCL alfe image (errors if ccl is missing).
	@if [ "$(HAVE_CCL)" != "yes" ]; then \
	  echo "Error: ccl not found in PATH (looked for '$(CCL)')"; \
	  exit 2; \
	fi
	$(MAKE) build-alfe-ccl

documentation: $(PDF_FILES) $(INFO_FILES)  ## Render every documentation/*.org into a PDF and .info via Emacs org-export.

%.pdf: %.org
	$(EMACS) --batch \
	    --eval "(setq org-confirm-babel-evaluate nil)" \
	    --eval "(setq org-export-with-broken-links t)" \
	    --eval "(setq org-latex-pdf-process '(\"$(LATEX_COMPILER) -interaction=nonstopmode -output-directory=%o %f\" \"$(LATEX_COMPILER) -interaction=nonstopmode -output-directory=%o %f\"))" \
	    "$<" \
	    --funcall org-latex-export-to-pdf

%.texi: %.org
	$(EMACS) --batch \
	    --eval '(progn (require (quote ox-texinfo)) (setq org-export-with-broken-links t))' \
	    --visit "$<" \
	    --funcall org-texinfo-export-to-texinfo

%.info: %.texi
	$(MAKEINFO) --no-split -o $@ $<

clean-pdf:  ## Remove every generated PDF / .info / .texi (keeps .org sources).
	rm -f $(PDF_FILES) $(INFO_FILES) $(ALL_ORG_FILES:.org=.texi)

# ---------------------------------------------------------------------
# Test targets — mirror clautolisp/Makefile so both subprojects share
# a `make test` invocation pattern. The clautolisp.asd is loaded first
# so the front-end's :depends-on entries resolve.

test: test-sbcl  ## Run the alfe FiveAM suite under SBCL.

test-sbcl:  ## Run the alfe FiveAM suite under SBCL.
	env XDG_CACHE_HOME="$(XDG_CACHE_HOME)" \
	$(SBCL) --noinform --no-userinit --non-interactive \
		--eval '(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname)))) (when (probe-file ql) (load ql)))' \
		--eval '(when (find-package :ql) (ql:quickload "fiveam" :silent t))' \
		--eval '(when (find-package :ql) (ql:quickload "bordeaux-threads" :silent t))' \
		--eval '(when (find-package :ql) (ql:quickload "trivial-gray-streams" :silent t))' \
		--eval '(require :asdf)' \
		--eval '(asdf:load-asd "$(CLAUTOLISP_ASD)")' \
		--eval '(asdf:load-asd "$(ALFE_ASD)")' \
		--eval '(asdf:test-system "$(TEST_SYSTEM)" :verbose t)'

test-ccl:  ## Run the alfe FiveAM suite under CCL.
	env XDG_CACHE_HOME="$(XDG_CACHE_HOME)" \
	$(CCL) --no-init --quiet \
		--eval '(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname)))) (when (probe-file ql) (load ql)))' \
		--eval '(when (find-package :ql) (ql:quickload "fiveam" :silent t))' \
		--eval '(when (find-package :ql) (ql:quickload "bordeaux-threads" :silent t))' \
		--eval '(when (find-package :ql) (ql:quickload "trivial-gray-streams" :silent t))' \
		--eval '(require :asdf)' \
		--eval '(asdf:load-asd "$(CLAUTOLISP_ASD)")' \
		--eval '(asdf:load-asd "$(ALFE_ASD)")' \
		--eval '(asdf:test-system "$(TEST_SYSTEM)" :verbose t)' \
		--eval '(ccl:quit)'

# ---------------------------------------------------------------------
# Executable build — mirrors clautolisp/Makefile's build-clautolisp-*
# targets. The build script under tools/alfe/generate-alfe.lisp reuses
# the same generator (autolisp-reader/tools/read-autolisp/generate.lisp)
# the other CLI tools use, so the save-image path is identical across
# read-autolisp, clautolisp, and alfe.

build-alfe-sbcl:  ## Build tools/alfe/bin/alfe-sbcl via save-lisp-and-die.
	env XDG_CACHE_HOME="$(XDG_CACHE_HOME)" \
	$(SBCL) --noinform --no-userinit --non-interactive \
		--eval '(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname)))) (when (probe-file ql) (load ql)))' \
		--eval '(require :asdf)' \
		--load "$(ALFE_GENERATE)" \
		--eval '(sb-ext:quit)'

build-alfe-ccl:  ## Build tools/alfe/bin/alfe-ccl via save-application.
	env XDG_CACHE_HOME="$(XDG_CACHE_HOME)" \
	$(CCL) --no-init --quiet \
		--eval '(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname)))) (when (probe-file ql) (load ql)))' \
		--eval '(require :asdf)' \
		--load "$(ALFE_GENERATE)" \
		--eval '(ccl:quit)'

# ---------------------------------------------------------------------
# Conformance lane. `make test` already invokes the conformance runner
# inside the FiveAM suite (see tests/conformance-tests.lisp); this
# target lets a developer (or CI) drive the corpus on its own,
# producing a focused summary without the surrounding unit-test
# output.

conformance:  ## Run the alfe scenario corpus and exit non-zero on any failure.
	env XDG_CACHE_HOME="$(XDG_CACHE_HOME)" \
	$(SBCL) --noinform --no-userinit --non-interactive \
		--eval '(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname)))) (when (probe-file ql) (load ql)))' \
		--eval '(when (find-package :ql) (ql:quickload "fiveam" :silent t))' \
		--eval '(when (find-package :ql) (ql:quickload "bordeaux-threads" :silent t))' \
		--eval '(when (find-package :ql) (ql:quickload "trivial-gray-streams" :silent t))' \
		--eval '(require :asdf)' \
		--eval '(asdf:load-asd "$(CLAUTOLISP_ASD)")' \
		--eval '(asdf:load-asd "$(ALFE_ASD)")' \
		--eval '(asdf:load-system "autolisp-front-end/tool-run-alfe-conformance")' \
		--eval '(alfe.tools.run-alfe-conformance:main nil)'

check-spec-coverage:  ## Assert every CLI option in the spec is covered by ≥1 scenario.
	env XDG_CACHE_HOME="$(XDG_CACHE_HOME)" \
	$(SBCL) --noinform --no-userinit --non-interactive \
		--load scripts/check-spec-coverage.lisp

clean: clean-pdf  ## Remove built executables and generated PDFs.
	rm -f $(ALFE_SBCL) $(ALFE_CCL)

# ---------------------------------------------------------------------
# Per-backend smoke tests for the built alfe binaries.
#
# Each target drives a built alfe binary (either alfe-sbcl or
# alfe-ccl) with one of the documented backend selectors and
# checks that the binary exits 0 on a simple workload. The CAD
# targets are gated on the host OS via REQUIRE_OS_*; without the
# right OS they print a [skip] line and exit 0 (the "wrong
# platform is a no-op" policy from issues/closed/test-targets.issue).
#
# These targets do NOT replace the FiveAM suite (`make test`) or
# the scenario corpus (`make conformance`). They are smoke checks
# for the *built* artefacts — the lane a tester walks when they
# want to verify a fresh alfe-sbcl actually runs end-to-end against
# a chosen backend, separate from "the test image works".
#
# The CAD targets assume the matching engine + env vars (e.g.
# $BRICSCAD_EXE) are configured. If alfe's DETECT phase can't
# find an engine, it exits 3 and the make target reports failure;
# the OS guard only handles the "obviously wrong platform" case.

test-alfe-sbcl-clautolisp: $(ALFE_SBCL)  ## alfe-sbcl --clautolisp smoke test (any OS).
	"$(ALFE_SBCL)" --clautolisp -x '(+ 1 2)'

test-alfe-ccl-clautolisp: $(ALFE_CCL)  ## alfe-ccl --clautolisp smoke test (any OS).
	"$(ALFE_CCL)" --clautolisp -x '(+ 1 2)'

test-alfe-sbcl-bricscad-macos: $(ALFE_SBCL)  ## alfe-sbcl --bricscad smoke test (macOS).
	@$(call require-os-darwin,$@); \
	 "$(ALFE_SBCL)" --bricscad -x '(princ (+ 1 2))'

test-alfe-ccl-bricscad-macos: $(ALFE_CCL)  ## alfe-ccl --bricscad smoke test (macOS).
	@$(call require-os-darwin,$@); \
	 "$(ALFE_CCL)" --bricscad -x '(princ (+ 1 2))'

test-alfe-sbcl-bricscad-windows: $(ALFE_SBCL)  ## alfe-sbcl --bricscad smoke test (Windows).
	@$(call require-os-windows,$@); \
	 "$(ALFE_SBCL)" --bricscad -x '(princ (+ 1 2))'

test-alfe-ccl-bricscad-windows: $(ALFE_CCL)  ## alfe-ccl --bricscad smoke test (Windows).
	@$(call require-os-windows,$@); \
	 "$(ALFE_CCL)" --bricscad -x '(princ (+ 1 2))'

test-alfe-sbcl-autocad-windows: $(ALFE_SBCL)  ## alfe-sbcl --autocad smoke test (Windows).
	@$(call require-os-windows,$@); \
	 "$(ALFE_SBCL)" --autocad -x '(princ (+ 1 2))'

test-alfe-ccl-autocad-windows: $(ALFE_CCL)  ## alfe-ccl --autocad smoke test (Windows).
	@$(call require-os-windows,$@); \
	 "$(ALFE_CCL)" --autocad -x '(princ (+ 1 2))'

# Dependencies — if the alfe binary doesn't exist, build it first.
# Use the existing build-alfe-* targets so the recipe stays in one
# place. The .PHONY build targets force a rebuild when invoked
# directly; the binary file targets here are real files, so make
# rebuilds only when missing.
$(ALFE_SBCL):
	$(MAKE) build-alfe-sbcl

$(ALFE_CCL):
	$(MAKE) build-alfe-ccl

# ---------------------------------------------------------------------
# Install / uninstall.
#
# Layout follows the repo-wide convention (see the root Makefile):
#
#   $(PREFIX)/bin/                                  alfe-sbcl, alfe-ccl
#   $(PREFIX)/libexec/autolisp-front-end/           run-alfe-conformance
#                                                   (shell driver — built lazily
#                                                    via the existing make target)
#   $(PREFIX)/share/doc/autolisp-front-end/         .org + .pdf documentation
#
# install depends on `build`, which builds for every CL
# implementation found on the host; an SBCL-only host installs the
# SBCL image and skips ccl naturally because AVAILABLE_IMPLEMENTATIONS
# doesn't include it.

BIN_INSTALL_DIR     := $(DESTDIR)$(PREFIX)/bin
LIBEXEC_INSTALL_DIR := $(DESTDIR)$(PREFIX)/libexec/$(SUBPROJECT_NAME)
DOC_INSTALL_DIR     := $(DESTDIR)$(PREFIX)/share/doc/$(SUBPROJECT_NAME)
INFO_INSTALL_DIR    := $(DESTDIR)$(PREFIX)/share/info
MAN_INSTALL_DIR     := $(DESTDIR)$(PREFIX)/share/man/man1

INSTALL_BINARIES_sbcl := $(ALFE_SBCL)
INSTALL_BINARIES_ccl  := $(ALFE_CCL)
INSTALL_BINARIES := $(foreach impl,$(AVAILABLE_IMPLEMENTATIONS),$(INSTALL_BINARIES_$(impl)))

.PHONY: install uninstall

install: build  ## Install built alfe binaries + docs into $$PREFIX (run `make build` first so this can be sudo'd cleanly).
	install -d $(BIN_INSTALL_DIR)
	install -d $(LIBEXEC_INSTALL_DIR)
	install -d $(DOC_INSTALL_DIR)
	@for exe in $(INSTALL_BINARIES); do \
	  if [ -x "$$exe" ]; then \
	    install -m 0755 "$$exe" $(BIN_INSTALL_DIR)/ ; \
	    echo "installed: $$exe -> $(BIN_INSTALL_DIR)/" ; \
	  else \
	    echo "Error: $$exe missing after build (unexpected)" ; \
	    exit 1 ; \
	  fi ; \
	done
	@for f in documentation/*.org documentation/*.pdf; do \
	  if [ -f "$$f" ]; then install -m 0644 "$$f" $(DOC_INSTALL_DIR)/ ; fi ; \
	done
	install -d $(INFO_INSTALL_DIR)
	@for f in documentation/*.info; do \
	  if [ -f "$$f" ]; then \
	    install -m 0644 "$$f" $(INFO_INSTALL_DIR)/ ; \
	    echo "installed: $$f -> $(INFO_INSTALL_DIR)/" ; \
	    $(INSTALL_INFO) --info-dir="$(INFO_INSTALL_DIR)" "$$f" 2>/dev/null \
	      || echo "[skip] install-info dir update for $$f" ; \
	  fi ; \
	done
	install -d $(MAN_INSTALL_DIR)
	@for f in documentation/man/*.1 tools/*/documentation/man/*.1; do \
	  if [ -f "$$f" ]; then \
	    install -m 0644 "$$f" $(MAN_INSTALL_DIR)/ ; \
	    echo "installed: $$f -> $(MAN_INSTALL_DIR)/" ; \
	  fi ; \
	done
	@# Bare-name `alfe' symlink pointing at the user's preferred
	@# CL impl. Relative target so the install tree stays
	@# relocatable across machines/staging dirs.
	@if [ -n "$(DEFAULT_LISP)" ]; then \
	  target="alfe-$(DEFAULT_LISP)" ; \
	  if [ -x "$(BIN_INSTALL_DIR)/$$target" ]; then \
	    ln -sf "$$target" "$(BIN_INSTALL_DIR)/alfe" ; \
	    echo "linked:    $(BIN_INSTALL_DIR)/alfe -> $$target" ; \
	  else \
	    echo "[skip]     $(BIN_INSTALL_DIR)/alfe (target $$target not installed)" ; \
	  fi ; \
	else \
	  echo "[skip]     bare alfe symlink (DEFAULT_LISP is empty)" ; \
	fi
	@echo "alfe install complete: PREFIX=$(PREFIX) DESTDIR=$(DESTDIR)"

uninstall:  ## Remove the alfe install from $$PREFIX.
	rm -f $(BIN_INSTALL_DIR)/alfe $(BIN_INSTALL_DIR)/alfe-sbcl $(BIN_INSTALL_DIR)/alfe-ccl
	@for f in documentation/*.info; do \
	  if [ -f "$$f" ]; then \
	    $(INSTALL_INFO) --remove --info-dir="$(INFO_INSTALL_DIR)" "$$f" 2>/dev/null \
	      || true ; \
	    rm -f "$(INFO_INSTALL_DIR)/$$(basename $$f)" ; \
	  fi ; \
	done
	@for f in documentation/man/*.1 tools/*/documentation/man/*.1; do \
	  if [ -f "$$f" ]; then rm -f "$(MAN_INSTALL_DIR)/$$(basename $$f)" ; fi ; \
	done
	rm -rf $(LIBEXEC_INSTALL_DIR) $(DOC_INSTALL_DIR)
