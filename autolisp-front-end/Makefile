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

DOCUMENTATION_ORG := $(wildcard documentation/*.org)
PDF_FILES := $(DOCUMENTATION_ORG:.org=.pdf)

# The aggregate ASDF test system. Keeping it in a variable mirrors
# the clautolisp Makefile so additional images (alfe-mac, alfe-win,
# etc.) can be added with one extra line each.
TEST_SYSTEM ?= autolisp-front-end

.PHONY: help all documentation test test-sbcl test-ccl \
        build-alfe-sbcl build-alfe-ccl clean-pdf clean

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

clean: clean-pdf  ## Remove built executables and generated PDFs.
	rm -f $(ALFE_SBCL) $(ALFE_CCL)
