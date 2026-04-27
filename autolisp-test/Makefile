PANDOC ?= pandoc
SBCL   ?= sbcl
CCL    ?= ccl

ROOT_DIR := $(shell pwd)
CLAUTOLISP_ROOT := $(ROOT_DIR)/../clautolisp
CLAUTOLISP_ASD := $(CLAUTOLISP_ROOT)/clautolisp.asd
AUTOLISP_TEST_ASD := $(ROOT_DIR)/autolisp-test.asd
CLAUTOLISP_SBCL := $(CLAUTOLISP_ROOT)/tools/clautolisp/bin/clautolisp-sbcl
CLAUTOLISP_CCL  := $(CLAUTOLISP_ROOT)/tools/clautolisp/bin/clautolisp-ccl
XDG_CACHE_HOME ?= $(CLAUTOLISP_ROOT)/.cache

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

.PHONY: all documentation test test-clautolisp-sbcl test-clautolisp-ccl \
        test-clautolisp-sbcl-debug test-clautolisp-ccl-debug \
        test-asdf-sbcl test-asdf-ccl \
        test-asdf-sbcl-debug test-asdf-ccl-debug \
        build-clautolisp-sbcl build-clautolisp-ccl clean-pdf

all: documentation

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
	$(PANDOC) --from=org --to=pdf --output="$@" "$<"

clean-pdf:
	rm -f $(PDF_FILES)
