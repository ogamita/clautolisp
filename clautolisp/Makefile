CCL  ?= ccl
SBCL ?= sbcl
LISP ?= $(SBCL)
# Documentation is exported to PDF via Emacs's native org-mode LaTeX
# exporter rather than pandoc; pandoc's org reader trips on a number
# of legitimate AutoLISP-spec constructs (e.g. `\"' inside backticks)
# that org-mode parses correctly. The LaTeX compiler is set to
# xelatex so arbitrary UTF-8 codepoints (such as set-theoretic `∩')
# render without missing-glyph errors. Both variables are
# overridable, e.g. `make documentation LATEX_COMPILER=lualatex'.
EMACS          ?= emacs
LATEX_COMPILER ?= xelatex
ROOT_DIR := $(shell pwd)
ASD_FILE := $(ROOT_DIR)/clautolisp.asd
XDG_CACHE_HOME ?= $(ROOT_DIR)/.cache

# Install destination. Override on the command line:
#   make install PREFIX=/usr/local DESTDIR=/staging
# Default /opt/local matches the MacPorts hierarchy and the
# repo-wide convention documented in the root Makefile.
PREFIX ?= /opt/local
DESTDIR ?=
SUBPROJECT_NAME := clautolisp

# ---------------------------------------------------------------------
# Available Common Lisp implementations (probed at Make-parse time).
#
# The user-facing 'build' / 'install' targets walk this list and
# build for every implementation that's on the host. Per-impl
# targets (build-sbcl / build-ccl / install-sbcl / install-ccl)
# fail loudly when their implementation is missing — that's the
# strict path.
#
# Adding a new implementation (ecl, abcl, clisp, …): probe its
# binary into HAVE_<IMPL>, append a token to
# AVAILABLE_IMPLEMENTATIONS, define a build-<impl> alias, and add
# the matching file-target rules.
HAVE_SBCL := $(shell command -v $(SBCL) >/dev/null 2>&1 && echo yes)
HAVE_CCL  := $(shell command -v $(CCL)  >/dev/null 2>&1 && echo yes)
AVAILABLE_IMPLEMENTATIONS :=
ifeq ($(HAVE_SBCL),yes)
  AVAILABLE_IMPLEMENTATIONS += sbcl
endif
ifeq ($(HAVE_CCL),yes)
  AVAILABLE_IMPLEMENTATIONS += ccl
endif

# Host OS detection — used by the per-platform run-file-compat
# targets below. Wrong-platform recipes call require-os-* which
# prints a [skip] line and exits 0 per the policy in
# issues/closed/test-targets.issue.
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

TEST_SYSTEM ?= clautolisp
EXECUTABLE ?= bin/clautolisp
READ_AUTOLISP_TOOL_DIR := autolisp-reader/tools/read-autolisp
READ_AUTOLISP_BIN_DIR := $(READ_AUTOLISP_TOOL_DIR)/bin
READ_AUTOLISP_SBCL := $(READ_AUTOLISP_BIN_DIR)/read-autolisp-sbcl
READ_AUTOLISP_CCL := $(READ_AUTOLISP_BIN_DIR)/read-autolisp-ccl
CLAUTOLISP_TOOL_DIR := tools/clautolisp
CLAUTOLISP_BIN_DIR := $(CLAUTOLISP_TOOL_DIR)/bin
CLAUTOLISP_SBCL := $(CLAUTOLISP_BIN_DIR)/clautolisp-sbcl
CLAUTOLISP_CCL := $(CLAUTOLISP_BIN_DIR)/clautolisp-ccl
RUN_FILE_COMPAT := autolisp-file-compat/tools/run-file-compat/run-file-compat
FILE_COMPAT_SCENARIOS ?= autolisp-file-compat/scenarios
FILE_COMPAT_ARGS ?=
FILE_COMPAT_OUTPUT ?=
FILE_COMPAT_PRODUCT_SCENARIOS ?= autolisp-file-compat/scenarios/mutations autolisp-file-compat/scenarios/streams autolisp-file-compat/scenarios/printers

DOCUMENTATION_ORG := $(wildcard documentation/*.org)
PDF_FILES := $(DOCUMENTATION_ORG:.org=.pdf)

.PHONY: all test test-sbcl test-ccl build build-sbcl build-ccl probe-check \
        build-read-autolisp-sbcl build-read-autolisp-ccl \
        build-clautolisp-sbcl build-clautolisp-ccl \
        run-file-compat run-file-compat-sbcl run-file-compat-ccl \
        run-file-compat-autocad run-file-compat-bricscad \
        audit-file-compat-autocad audit-file-compat-bricscad \
        documentation user-manual clean-pdf specifications builtins-coverage \
        run-file-compat-bricscad-macos run-file-compat-bricscad-windows \
        run-file-compat-autocad-windows

all: documentation build clautolisp/tools/clautolisp-gui-qt/build/clautolisp-gui-qt

# ---------------------------------------------------------------------
# build / build-<impl> — the user-facing build entry points.
#
#   make build       builds every implementation found on the host
#                    (errors if zero are found).
#   make build-sbcl  builds the SBCL images strictly (errors if sbcl
#                    is missing).
#   make build-ccl   builds the CCL images strictly (errors if ccl
#                    is missing).
#
# Why this shape: install/all depend on `build`, not on a single
# implementation. A host with both sbcl and ccl gets both pairs of
# binaries; a host with only one still installs cleanly; a host with
# neither fails loudly at probe-check (we don't quietly skip the
# build step when there's no Lisp at all).
#
# The strict variants are for the test-matrix and for users who
# explicitly want a single image: `make build-sbcl` on a host
# without sbcl is an error, not a no-op, because the caller asked
# for that specific implementation.

BUILD_TARGETS := $(foreach impl,$(AVAILABLE_IMPLEMENTATIONS),build-$(impl))

build: probe-check $(BUILD_TARGETS) documentation  ## Build executables + docs (everything `install` ships) for every available CL implementation.

probe-check:
	@if [ -z "$(strip $(AVAILABLE_IMPLEMENTATIONS))" ]; then \
	  echo "Error: no Common Lisp implementation found on PATH"; \
	  echo "  Tried: sbcl ($(SBCL)), ccl ($(CCL))"; \
	  echo "  Override via 'make build SBCL=/path/to/sbcl' or 'CCL=/path/to/ccl'."; \
	  exit 2; \
	fi
	@echo "Building with: $(AVAILABLE_IMPLEMENTATIONS)"

build-sbcl:  ## Strictly build the SBCL clautolisp + read-autolisp images (errors if sbcl is missing).
	@if [ "$(HAVE_SBCL)" != "yes" ]; then \
	  echo "Error: sbcl not found in PATH (looked for '$(SBCL)')"; \
	  exit 2; \
	fi
	$(MAKE) build-read-autolisp-sbcl
	$(MAKE) build-clautolisp-sbcl

build-ccl:  ## Strictly build the CCL clautolisp + read-autolisp images (errors if ccl is missing).
	@if [ "$(HAVE_CCL)" != "yes" ]; then \
	  echo "Error: ccl not found in PATH (looked for '$(CCL)')"; \
	  exit 2; \
	fi
	$(MAKE) build-read-autolisp-ccl
	$(MAKE) build-clautolisp-ccl

test: test-sbcl

test-sbcl:
	env XDG_CACHE_HOME="$(XDG_CACHE_HOME)" \
	$(SBCL) --noinform --no-userinit --non-interactive \
		--eval '(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname)))) (when (probe-file ql) (load ql)))' \
		--eval '(when (find-package :ql) (ql:quickload "fiveam" :silent t))' \
		--eval '(require :asdf)' \
		--eval '(asdf:load-asd "$(ASD_FILE)")' \
		--eval '(asdf:test-system "$(TEST_SYSTEM)" :verbose t)'

test-ccl:
	env XDG_CACHE_HOME="$(XDG_CACHE_HOME)" \
	ccl --no-init --quiet \
		--eval '(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname)))) (when (probe-file ql) (load ql)))' \
		--eval '(when (find-package :ql) (ql:quickload "fiveam" :silent t))' \
		--eval '(require :asdf)' \
		--eval '(asdf:load-asd "$(ASD_FILE)")' \
		--eval '(asdf:test-system "$(TEST_SYSTEM)" :verbose t)' \
		--eval '(ccl:quit)'

build-read-autolisp-sbcl:
	env XDG_CACHE_HOME="$(XDG_CACHE_HOME)" \
	$(SBCL) --noinform --no-userinit --non-interactive \
		--eval '(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname)))) (when (probe-file ql) (load ql)))' \
		--eval '(require :asdf)' \
		--load "$(READ_AUTOLISP_TOOL_DIR)/generate-read-autolisp.lisp" \
		--eval '(sb-ext:quit)'

build-read-autolisp-ccl:
	env XDG_CACHE_HOME="$(XDG_CACHE_HOME)" \
	ccl --no-init --quiet \
		--eval '(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname)))) (when (probe-file ql) (load ql)))' \
		--eval '(require :asdf)' \
		--load "$(READ_AUTOLISP_TOOL_DIR)/generate-read-autolisp.lisp" \
		--eval '(ccl:quit)'

build-clautolisp-sbcl:
	env XDG_CACHE_HOME="$(XDG_CACHE_HOME)" \
	$(SBCL) --noinform --no-userinit --non-interactive \
		--eval '(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname)))) (when (probe-file ql) (load ql)))' \
		--eval '(require :asdf)' \
		--load "$(CLAUTOLISP_TOOL_DIR)/generate-clautolisp.lisp" \
		--eval '(sb-ext:quit)'

build-clautolisp-ccl:
	env XDG_CACHE_HOME="$(XDG_CACHE_HOME)" \
	ccl --no-init --quiet \
		--eval '(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname)))) (when (probe-file ql) (load ql)))' \
		--eval '(require :asdf)' \
		--load "$(CLAUTOLISP_TOOL_DIR)/generate-clautolisp.lisp" \
		--eval '(ccl:quit)'

# File-target rules — installing the binaries needs the file to
# exist, not just to have run a .PHONY build step. These delegate
# back to the strict per-impl entry points so probe-check fires
# when the implementation is missing.
$(CLAUTOLISP_SBCL):
	$(MAKE) build-clautolisp-sbcl

$(CLAUTOLISP_CCL):
	$(MAKE) build-clautolisp-ccl

$(READ_AUTOLISP_SBCL):
	$(MAKE) build-read-autolisp-sbcl

$(READ_AUTOLISP_CCL):
	$(MAKE) build-read-autolisp-ccl

run-file-compat: run-file-compat-sbcl

run-file-compat-sbcl:
	$(RUN_FILE_COMPAT) --sbcl $(FILE_COMPAT_ARGS) $(FILE_COMPAT_SCENARIOS)

run-file-compat-ccl:
	$(RUN_FILE_COMPAT) --ccl $(FILE_COMPAT_ARGS) $(FILE_COMPAT_SCENARIOS)

run-file-compat-autocad:
	$(RUN_FILE_COMPAT) --autocad $(FILE_COMPAT_ARGS) $(FILE_COMPAT_SCENARIOS)

run-file-compat-bricscad:
	$(RUN_FILE_COMPAT) --bricscad $(FILE_COMPAT_ARGS) $(FILE_COMPAT_SCENARIOS)

audit-file-compat-autocad:
	$(RUN_FILE_COMPAT) --autocad --report-format json $(FILE_COMPAT_ARGS) $(FILE_COMPAT_PRODUCT_SCENARIOS)

audit-file-compat-bricscad:
	$(RUN_FILE_COMPAT) --bricscad --report-format json $(FILE_COMPAT_ARGS) $(FILE_COMPAT_PRODUCT_SCENARIOS)

# ---------------------------------------------------------------------
# Per-platform run-file-compat targets.
#
# The platform-agnostic `run-file-compat-bricscad` / `-autocad`
# targets above stay for back-compat (some CI scripts already
# reference them). The new -macos / -windows variants add the
# host-OS gate the test-targets issue called for: trying to run
# the macOS-only target on Linux/Windows prints a [skip] line and
# exits 0, never errors.

run-file-compat-bricscad-macos:
	@$(call require-os-darwin,$@); \
	 $(RUN_FILE_COMPAT) --bricscad $(FILE_COMPAT_ARGS) $(FILE_COMPAT_SCENARIOS)

run-file-compat-bricscad-windows:
	@$(call require-os-windows,$@); \
	 $(RUN_FILE_COMPAT) --bricscad $(FILE_COMPAT_ARGS) $(FILE_COMPAT_SCENARIOS)

run-file-compat-autocad-windows:
	@$(call require-os-windows,$@); \
	 $(RUN_FILE_COMPAT) --autocad $(FILE_COMPAT_ARGS) $(FILE_COMPAT_SCENARIOS)


documentation: $(PDF_FILES)

user-manual: documentation/clautolisp-user-manual.pdf
specifications: documentation/clautolisp-specifications.pdf

%.pdf: %.org
	$(EMACS) --batch \
		--eval '(progn (require (quote ox-latex)) (setq org-latex-compiler "$(LATEX_COMPILER)") (setq org-export-with-broken-links t) (setq org-latex-pdf-process (list (concat "$(LATEX_COMPILER)" " -interaction nonstopmode -output-directory %o %f") (concat "$(LATEX_COMPILER)" " -interaction nonstopmode -output-directory %o %f"))))' \
		--visit "$<" \
		--funcall org-latex-export-to-pdf

clean-pdf:
	rm -f $(PDF_FILES)

builtins-coverage:
	@tools/builtins-coverage/coverage.sh > documentation/builtins-coverage.md
	@echo "wrote documentation/builtins-coverage.md"

clautolisp/tools/clautolisp-gui-qt/build/clautolisp-gui-qt:
	cd tools/clautolisp-gui-qt/ ; cmake --build build

# ---------------------------------------------------------------------
# Install / uninstall.
#
# Layout follows the repo-wide convention (see the root Makefile):
#
#   $(PREFIX)/bin/                                  user-facing executables
#                                                   clautolisp-{sbcl,ccl}
#                                                   read-autolisp-{sbcl,ccl}
#                                                   clautolisp-gui-qt (when built)
#   $(PREFIX)/libexec/clautolisp/                   support executables
#                                                   run-file-compat (shell driver)
#   $(PREFIX)/share/doc/clautolisp/                 .org + .pdf documentation
#
# install depends on `build`, which builds for every CL
# implementation found on the host (probe-check errors out if none
# are available, so a clean install can never fail silently with
# zero binaries shipped). Documentation is also a dependency so
# `make install` from a fresh clone produces a complete tree.
#
# INSTALL_BINARIES is computed from AVAILABLE_IMPLEMENTATIONS so a
# host without ccl doesn't try to install a ccl image; an
# SBCL-only host installs exactly the SBCL pair, never sees a
# [skip] for ccl. The GUI binary is shipped only when it's been
# built (cmake build is a separate concern, not gated on a Lisp).

BIN_INSTALL_DIR     := $(DESTDIR)$(PREFIX)/bin
LIBEXEC_INSTALL_DIR := $(DESTDIR)$(PREFIX)/libexec/$(SUBPROJECT_NAME)
DOC_INSTALL_DIR     := $(DESTDIR)$(PREFIX)/share/doc/$(SUBPROJECT_NAME)

CLAUTOLISP_GUI_QT_BIN := tools/clautolisp-gui-qt/build/clautolisp-gui-qt
RUN_FILE_COMPAT_BIN   := $(RUN_FILE_COMPAT)

INSTALL_BINARIES_sbcl := $(CLAUTOLISP_SBCL) $(READ_AUTOLISP_SBCL)
INSTALL_BINARIES_ccl  := $(CLAUTOLISP_CCL)  $(READ_AUTOLISP_CCL)
INSTALL_BINARIES := $(foreach impl,$(AVAILABLE_IMPLEMENTATIONS),$(INSTALL_BINARIES_$(impl)))

.PHONY: install uninstall

install: build  ## Install built executables, run-file-compat, and docs into $$PREFIX (run `make build` first so this can be sudo'd cleanly).
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
	@if [ -x "$(CLAUTOLISP_GUI_QT_BIN)" ]; then \
	  install -m 0755 "$(CLAUTOLISP_GUI_QT_BIN)" $(BIN_INSTALL_DIR)/ ; \
	  echo "installed: $(CLAUTOLISP_GUI_QT_BIN) -> $(BIN_INSTALL_DIR)/" ; \
	else \
	  echo "[skip] $(CLAUTOLISP_GUI_QT_BIN) not built (run 'cmake --build tools/clautolisp-gui-qt/build' first)" ; \
	fi
	@if [ -x "$(RUN_FILE_COMPAT_BIN)" ]; then \
	  install -m 0755 "$(RUN_FILE_COMPAT_BIN)" $(LIBEXEC_INSTALL_DIR)/ ; \
	  echo "installed: $(RUN_FILE_COMPAT_BIN) -> $(LIBEXEC_INSTALL_DIR)/" ; \
	fi
	@for f in documentation/*.org documentation/*.pdf; do \
	  if [ -f "$$f" ]; then install -m 0644 "$$f" $(DOC_INSTALL_DIR)/ ; fi ; \
	done
	@echo "clautolisp install complete: PREFIX=$(PREFIX) DESTDIR=$(DESTDIR)"

uninstall:  ## Remove the clautolisp install from $$PREFIX.
	rm -f $(BIN_INSTALL_DIR)/clautolisp-sbcl $(BIN_INSTALL_DIR)/clautolisp-ccl \
	      $(BIN_INSTALL_DIR)/read-autolisp-sbcl $(BIN_INSTALL_DIR)/read-autolisp-ccl \
	      $(BIN_INSTALL_DIR)/clautolisp-gui-qt
	rm -rf $(LIBEXEC_INSTALL_DIR) $(DOC_INSTALL_DIR)

