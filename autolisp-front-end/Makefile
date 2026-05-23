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
XDG_CACHE_HOME ?= $(CLAUTOLISP_ROOT)/.cache

DOCUMENTATION_ORG := $(wildcard documentation/*.org)
PDF_FILES := $(DOCUMENTATION_ORG:.org=.pdf)

.PHONY: help all documentation test build-alfe-sbcl build-alfe-ccl clean-pdf

help:  ## Show this message (list available targets and their purpose).
	@awk 'BEGIN { \
	    FS = ":.*?## "; \
	    printf "Usage: make <target>\n\nautolisp-front-end targets:\n"; \
	  } \
	  /^[a-zA-Z_][a-zA-Z0-9_-]*:.*?## / { \
	    printf "  %-32s %s\n", $$1, $$2; \
	  }' $(MAKEFILE_LIST)

all: documentation  ## Default: rebuild documentation (executable build comes in alfe-skeleton.issue).

documentation: $(PDF_FILES)  ## Render every documentation/*.org into a PDF via Emacs org-export.

%.pdf: %.org
	$(EMACS) --batch \
	    --eval "(setq org-confirm-babel-evaluate nil)" \
	    --eval "(setq org-latex-pdf-process '(\"$(LATEX_COMPILER) -interaction=nonstopmode -output-directory=%o %f\" \"$(LATEX_COMPILER) -interaction=nonstopmode -output-directory=%o %f\"))" \
	    "$<" \
	    --funcall org-latex-export-to-pdf

clean-pdf:  ## Remove every generated PDF (keeps .org sources).
	rm -f $(PDF_FILES)

test:  ## Placeholder until alfe-skeleton.issue and alfe-conformance.issue land their suites.
	@echo "[alfe] no tests yet; see ../issues/open/alfe-skeleton.issue and alfe-conformance.issue"

build-alfe-sbcl:  ## Placeholder; image build wired in alfe-skeleton.issue.
	@echo "[alfe] build-alfe-sbcl not yet implemented; see alfe-skeleton.issue"

build-alfe-ccl:  ## Placeholder; image build wired in alfe-skeleton.issue.
	@echo "[alfe] build-alfe-ccl not yet implemented; see alfe-skeleton.issue"
