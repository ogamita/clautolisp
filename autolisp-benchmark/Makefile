# autolisp-benchmark — Makefile
#
# The benchmark is pure AutoLISP source loaded INTO a running engine
# (clautolisp / BricsCAD / AutoCAD), exactly like autolisp-test. There
# is no compiled executable to build for this subproject; `build` just
# produces the documentation PDFs.
#
# Documentation is exported to PDF via Emacs's org-mode LaTeX exporter
# (xelatex) — same toolchain as the sibling subprojects.
EMACS          ?= $(shell sh ../scripts/resolve-emacs.sh)
LATEX_COMPILER ?= xelatex
SBCL   ?= sbcl
CCL    ?= ccl

HOST_OS := $(shell uname -s)

# require-os-darwin / require-os-windows — used by the real-CAD targets
# to no-op on the wrong host (matches autolisp-test's policy).
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

ALFE_ROOT := $(ROOT_DIR)/../autolisp-front-end
ALFE_SBCL := $(ALFE_ROOT)/tools/alfe/bin/alfe-sbcl
ALFE_CCL  := $(ALFE_ROOT)/tools/alfe/bin/alfe-ccl
CLAUTOLISP_ROOT := $(ROOT_DIR)/../clautolisp
CLAUTOLISP_SBCL := $(CLAUTOLISP_ROOT)/tools/clautolisp/bin/clautolisp-sbcl
CLAUTOLISP_CCL  := $(CLAUTOLISP_ROOT)/tools/clautolisp/bin/clautolisp-ccl
XDG_CACHE_HOME ?= $(CLAUTOLISP_ROOT)/.cache

PREFIX ?= /opt/local
DESTDIR ?=
SUBPROJECT_NAME := autolisp-benchmark

DOCUMENTATION_ORG := $(wildcard documentation/*.org)
# Generated documentation is written under build/ mirroring the source
# sub-hierarchy, so the source tree stays free of build artefacts and nothing
# PDF-shaped is tracked in git. install-documentation collects from here.
BUILD_DIR := build
PDF_FILES := $(patsubst %.org,$(BUILD_DIR)/%.pdf,$(DOCUMENTATION_ORG))

# Wall-clock budget per operation class. Override on the command line:
#   make run BENCH_SECONDS=10.0
BENCH_SECONDS       ?= 5.0
# Fast budget for the `test` smoke check (verifies the suite loads and
# every workload runs without error; not a measurement).
BENCH_SMOKE_SECONDS ?= 0.2

# Inline AutoLISP snippet a standalone clautolisp executable evaluates
# to run the whole suite. Sets the suite root and the per-class budget,
# loads run.lsp, then invokes (autolisp-benchmark-run-all). Detection of
# the implementation is automatic via (ver), so nothing else is needed.
define BENCH_SNIPPET_template
  (setq *autolisp-benchmark-root* "$(ROOT_DIR)/") \
  (setq *bench-seconds* $(1)) \
  (load (strcat *autolisp-benchmark-root* "harness/run.lsp")) \
  (autolisp-benchmark-run-all)
endef
BENCH_SNIPPET       := $(call BENCH_SNIPPET_template,$(BENCH_SECONDS))
BENCH_SMOKE_SNIPPET := $(call BENCH_SNIPPET_template,$(BENCH_SMOKE_SECONDS))

# Source files the standalone clautolisp executable depends on; when any
# is newer than the binary the run/test targets rebuild it first so a
# run after a runtime fix never executes a stale binary.
CLAUTOLISP_SOURCES := \
  $(wildcard $(CLAUTOLISP_ROOT)/autolisp-reader/source/*.lisp) \
  $(wildcard $(CLAUTOLISP_ROOT)/autolisp-runtime/source/*.lisp) \
  $(wildcard $(CLAUTOLISP_ROOT)/autolisp-builtins-core/source/*.lisp) \
  $(wildcard $(CLAUTOLISP_ROOT)/autolisp-mock-host/source/*.lisp) \
  $(wildcard $(CLAUTOLISP_ROOT)/drawing/source/*.lisp) \
  $(wildcard $(CLAUTOLISP_ROOT)/tools/clautolisp/source/*.lisp) \
  $(CLAUTOLISP_ROOT)/clautolisp.asd

.PHONY: all build documentation test \
        run run-clautolisp-sbcl run-clautolisp-ccl \
        run-clautolisp-sbcl-strict run-clautolisp-sbcl-bricscad run-clautolisp-sbcl-autocad \
        run-clautolisp-ccl-strict  run-clautolisp-ccl-bricscad  run-clautolisp-ccl-autocad \
        run-bricscad-macos run-bricscad-windows run-autocad-windows \
        build-clautolisp-sbcl build-clautolisp-ccl clean-pdf \
        install install-programs install-documentation uninstall

all: documentation

# `build` is a convenience alias for `documentation` so the repo-wide
# `make build && sudo make install` pattern works uniformly — this
# subproject ships only docs + AutoLISP source, no executables.
build: documentation  ## Build everything `install` would ship (docs only — no executables).

documentation: $(PDF_FILES)

# `test` is the umbrella target invoked by the parent Makefile. For a
# benchmark, "test" is a fast smoke run: it proves the harness loads and
# every workload executes end-to-end without error. It is NOT a
# measurement — use `make run` for that.
test: run-smoke

.PHONY: run-smoke
run-smoke: $(CLAUTOLISP_SBCL)
	@echo "[autolisp-benchmark] smoke run ($(BENCH_SMOKE_SECONDS)s/class)"
	"$(CLAUTOLISP_SBCL)" -x '$(BENCH_SMOKE_SNIPPET)'

# --- The standalone clautolisp executable --------------------------

$(CLAUTOLISP_SBCL): $(CLAUTOLISP_SOURCES)
	$(MAKE) -C $(CLAUTOLISP_ROOT) build-clautolisp-sbcl

$(CLAUTOLISP_CCL): $(CLAUTOLISP_SOURCES)
	$(MAKE) -C $(CLAUTOLISP_ROOT) build-clautolisp-ccl

build-clautolisp-sbcl: $(CLAUTOLISP_SBCL)
build-clautolisp-ccl:  $(CLAUTOLISP_CCL)

# The canonical run: clautolisp via SBCL, default dialect.
run: run-clautolisp-sbcl

run-clautolisp-sbcl: $(CLAUTOLISP_SBCL)
	"$(CLAUTOLISP_SBCL)" -x '$(BENCH_SNIPPET)'

run-clautolisp-ccl: $(CLAUTOLISP_CCL)
	"$(CLAUTOLISP_CCL)" -x '$(BENCH_SNIPPET)'

# Dialect variants. The benchmark uses only cross-dialect operators, so
# the dialect should not change timings; these exist for completeness so
# a run can be pinned to the same dialect as a CAD comparison.
run-clautolisp-sbcl-strict: $(CLAUTOLISP_SBCL)
	"$(CLAUTOLISP_SBCL)" --dialect strict -x '$(BENCH_SNIPPET)'

run-clautolisp-sbcl-bricscad: $(CLAUTOLISP_SBCL)
	"$(CLAUTOLISP_SBCL)" --dialect bricscad-v26 -x '$(BENCH_SNIPPET)'

run-clautolisp-sbcl-autocad: $(CLAUTOLISP_SBCL)
	"$(CLAUTOLISP_SBCL)" --dialect autocad-2026 -x '$(BENCH_SNIPPET)'

run-clautolisp-ccl-strict: $(CLAUTOLISP_CCL)
	"$(CLAUTOLISP_CCL)" --dialect strict -x '$(BENCH_SNIPPET)'

run-clautolisp-ccl-bricscad: $(CLAUTOLISP_CCL)
	"$(CLAUTOLISP_CCL)" --dialect bricscad-v26 -x '$(BENCH_SNIPPET)'

run-clautolisp-ccl-autocad: $(CLAUTOLISP_CCL)
	"$(CLAUTOLISP_CCL)" --dialect autocad-2026 -x '$(BENCH_SNIPPET)'

# --- Real CAD via alfe ---------------------------------------------
# Drive the benchmark inside a real BricsCAD / AutoCAD engine via alfe's
# file-IPC backend, on the SAME hardware, for a direct comparison with
# the clautolisp numbers. Gated on host OS (see autolisp-test). The
# per-class budget and suite root are set with -x actions before the
# load, so the CAD-side engine finds the sources and honours BENCH_SECONDS.
ALFE_SET_ROOT    := -x "(setq *autolisp-benchmark-root* \"$(ROOT_DIR)/\")"
ALFE_SET_SECONDS := -x "(setq *bench-seconds* $(BENCH_SECONDS))"
ALFE_LOAD        := -l "$(ROOT_DIR)/harness/run.lsp"
ALFE_RUN         := -x "(autolisp-benchmark-run-all)"
ALFE_ACTIONS      = $(ALFE_SET_ROOT) $(ALFE_SET_SECONDS) $(ALFE_LOAD) $(ALFE_RUN)

run-bricscad-macos:
	@$(call require-os-darwin,$@); \
	 "$(ALFE_SBCL)" --bricscad $(ALFE_ACTIONS)

run-bricscad-windows:
	@$(call require-os-windows,$@); \
	 "$(ALFE_SBCL)" --bricscad $(ALFE_ACTIONS)

run-autocad-windows:
	@$(call require-os-windows,$@); \
	 "$(ALFE_SBCL)" --autocad $(ALFE_ACTIONS)

# Very large org docs can exceed TeX's default main_memory and abort with "TeX
# capacity exceeded". A repo-local web2c/texmf.cnf raises the memory parameters;
# we build a private xelatex format with them into a cache dir (TEXMFVAR) so no
# machine-wide texmf.cnf edit or root access is needed. The trailing empty
# component on TEXMFCNF appends the system search path.
TEX_WEB2C    := $(ROOT_DIR)/documentation/web2c
TEXFMT_CACHE := $(XDG_CACHE_HOME)/texmf-var
export TEXMFCNF := $(TEX_WEB2C):
export TEXMFVAR := $(TEXFMT_CACHE)
ifeq ($(LATEX_COMPILER),xelatex)
TEX_FMT_DEP := $(TEXFMT_CACHE)/web2c/xetex/xelatex.fmt
$(TEX_FMT_DEP): $(TEX_WEB2C)/texmf.cnf
	@mkdir -p $(TEXFMT_CACHE)
	fmtutil -user --byfmt xelatex
else
TEX_FMT_DEP :=
endif

# clautolisp-doc-preamble.sty gives xelatex the fonts for the Unicode glyphs
# Latin Modern lacks (see documentation/clautolisp-doc-preamble.sty); injected
# via org-latex-packages-alist, with TEXINPUTS pointing at documentation/.
# org export writes next to the .org; we move the result under build/ (mirroring
# the source path) and delete the intermediate .tex so the source tree stays clean.
$(BUILD_DIR)/%.pdf: %.org | $(TEX_FMT_DEP)
	@mkdir -p $(@D)
	TEXINPUTS="$(ROOT_DIR)/documentation:$$TEXINPUTS" $(EMACS) --batch \
		--eval '(progn (require (quote ox-latex)) (setq org-latex-compiler "$(LATEX_COMPILER)") (setq org-export-with-broken-links t) (add-to-list (quote org-latex-packages-alist) (quote ("" "clautolisp-doc-preamble" t ("xelatex" "lualatex"))) t) (setq org-latex-pdf-process (list (concat "$(LATEX_COMPILER)" " -interaction nonstopmode -output-directory %o %f") (concat "$(LATEX_COMPILER)" " -interaction nonstopmode -output-directory %o %f"))))' \
		--visit "$<" \
		--funcall org-latex-export-to-pdf
	@mv -f "$(<:.org=.pdf)" "$@"
	@rm -f "$(<:.org=.tex)"

clean-pdf:
	rm -rf $(BUILD_DIR)

# --- Install / uninstall -------------------------------------------
# Layout follows the repo-wide convention: the AutoLISP source the
# engine loads goes under libexec/, docs under share/doc/. No bin/,
# since nothing here is a standalone executable.

LIBEXEC_INSTALL_DIR := $(DESTDIR)$(PREFIX)/libexec/$(SUBPROJECT_NAME)
DOC_INSTALL_DIR     := $(DESTDIR)$(PREFIX)/share/doc/$(SUBPROJECT_NAME)
INFO_INSTALL_DIR    := $(DESTDIR)$(PREFIX)/share/info
INSTALL_INFO        ?= install-info

install: build  ## Install harness + benchmarks + docs into $$PREFIX (build first; sudo-friendly).
	$(MAKE) install-programs
	$(MAKE) install-documentation

install-programs:  ## Install just the autolisp-benchmark harness + benchmarks (no docs).
	install -d $(LIBEXEC_INSTALL_DIR)/harness
	install -d $(LIBEXEC_INSTALL_DIR)/benchmarks
	@if [ -d harness ]; then \
	  for f in harness/*.lsp; do \
	    [ -f "$$f" ] && install -m 0644 "$$f" $(LIBEXEC_INSTALL_DIR)/harness/ ; \
	  done ; \
	fi
	@if [ -d benchmarks ]; then \
	  for f in benchmarks/*.lsp; do \
	    [ -f "$$f" ] && install -m 0644 "$$f" $(LIBEXEC_INSTALL_DIR)/benchmarks/ ; \
	  done ; \
	fi
	@echo "programs installed: PREFIX=$(PREFIX) DESTDIR=$(DESTDIR)"

install-documentation:  ## Install just the autolisp-benchmark documentation.
	install -d $(DOC_INSTALL_DIR)
	@for f in documentation/*.org $(BUILD_DIR)/documentation/*.pdf; do \
	  if [ -f "$$f" ]; then install -m 0644 "$$f" $(DOC_INSTALL_DIR)/ ; fi ; \
	done
	install -d $(INFO_INSTALL_DIR)
	@for f in $(BUILD_DIR)/documentation/*.info; do \
	  if [ -f "$$f" ]; then \
	    install -m 0644 "$$f" $(INFO_INSTALL_DIR)/ ; \
	    installed="$(INFO_INSTALL_DIR)/$$(basename $$f)" ; \
	    $(INSTALL_INFO) --info-dir="$(INFO_INSTALL_DIR)" "$$installed" 2>/dev/null \
	      || echo "[skip] install-info dir update for $$installed" ; \
	  fi ; \
	done
	@echo "documentation installed: PREFIX=$(PREFIX) DESTDIR=$(DESTDIR)"

uninstall:  ## Remove the autolisp-benchmark install from $$PREFIX.
	rm -rf $(LIBEXEC_INSTALL_DIR) $(DOC_INSTALL_DIR)
	@for f in $(BUILD_DIR)/documentation/*.info; do \
	  if [ -f "$$f" ]; then \
	    $(INSTALL_INFO) --remove --info-dir="$(INFO_INSTALL_DIR)" "$$f" 2>/dev/null \
	      || true ; \
	    rm -f "$(INFO_INSTALL_DIR)/$$(basename $$f)" ; \
	  fi ; \
	done
