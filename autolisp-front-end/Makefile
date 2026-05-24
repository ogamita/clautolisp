# Documentation is exported to PDF via Emacs's native org-mode LaTeX
# exporter rather than pandoc (consistent with the other subprojects).
# The LaTeX compiler defaults to xelatex for UTF-8 codepoint coverage;
# both variables are overridable.
EMACS          ?= emacs
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
PDF_FILES := $(DOCUMENTATION_ORG:.org=.pdf)

# The aggregate ASDF test system. Keeping it in a variable mirrors
# the clautolisp Makefile so additional images (alfe-mac, alfe-win,
# etc.) can be added with one extra line each.
TEST_SYSTEM ?= autolisp-front-end

.PHONY: help all documentation test test-sbcl test-ccl \
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

all: documentation build-alfe-sbcl  ## Default: docs + the SBCL alfe binary.

documentation: $(PDF_FILES)  ## Render every documentation/*.org into a PDF via Emacs org-export.

%.pdf: %.org
	$(EMACS) --batch \
	    --eval "(setq org-confirm-babel-evaluate nil)" \
	    --eval "(setq org-latex-pdf-process '(\"$(LATEX_COMPILER) -interaction=nonstopmode -output-directory=%o %f\" \"$(LATEX_COMPILER) -interaction=nonstopmode -output-directory=%o %f\"))" \
	    "$<" \
	    --funcall org-latex-export-to-pdf

clean-pdf:  ## Remove every generated PDF (keeps .org sources).
	rm -f $(PDF_FILES)

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
