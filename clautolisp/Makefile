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

.PHONY: all test test-sbcl test-ccl build-read-autolisp-sbcl build-read-autolisp-ccl build-clautolisp-sbcl build-clautolisp-ccl run-file-compat run-file-compat-sbcl run-file-compat-ccl run-file-compat-autocad run-file-compat-bricscad audit-file-compat-autocad audit-file-compat-bricscad documentation user-manual clean-pdf specifications builtins-coverage \
        run-file-compat-bricscad-macos run-file-compat-bricscad-windows \
        run-file-compat-autocad-windows

all: documentation build-clautolisp-sbcl clautolisp/tools/clautolisp-gui-qt/build/clautolisp-gui-qt

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
		--eval '(progn (require (quote ox-latex)) (setq org-latex-compiler "$(LATEX_COMPILER)") (setq org-latex-pdf-process (list (concat "$(LATEX_COMPILER)" " -interaction nonstopmode -output-directory %o %f") (concat "$(LATEX_COMPILER)" " -interaction nonstopmode -output-directory %o %f"))))' \
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
# install ships only what's already built — it doesn't depend on
# the build targets, so the user controls when the heavy executables
# are produced. A missing binary skips silently with a [no-op]
# trace; an interactive install run that wants all four binaries
# should do `make build-clautolisp-sbcl build-clautolisp-ccl
# build-read-autolisp-sbcl build-read-autolisp-ccl` first.

BIN_INSTALL_DIR     := $(DESTDIR)$(PREFIX)/bin
LIBEXEC_INSTALL_DIR := $(DESTDIR)$(PREFIX)/libexec/$(SUBPROJECT_NAME)
DOC_INSTALL_DIR     := $(DESTDIR)$(PREFIX)/share/doc/$(SUBPROJECT_NAME)

CLAUTOLISP_GUI_QT_BIN := tools/clautolisp-gui-qt/build/clautolisp-gui-qt
RUN_FILE_COMPAT_BIN   := $(RUN_FILE_COMPAT)

.PHONY: install uninstall

install:  ## Install built executables, run-file-compat, and docs into $$PREFIX.
	install -d $(BIN_INSTALL_DIR)
	install -d $(LIBEXEC_INSTALL_DIR)
	install -d $(DOC_INSTALL_DIR)
	@for exe in $(CLAUTOLISP_SBCL) $(CLAUTOLISP_CCL) \
	            $(READ_AUTOLISP_SBCL) $(READ_AUTOLISP_CCL) \
	            $(CLAUTOLISP_GUI_QT_BIN); do \
	  if [ -x "$$exe" ]; then \
	    install -m 0755 "$$exe" $(BIN_INSTALL_DIR)/ ; \
	    echo "installed: $$exe -> $(BIN_INSTALL_DIR)/" ; \
	  else \
	    echo "[skip] $$exe not built (run the matching build target first)" ; \
	  fi ; \
	done
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

