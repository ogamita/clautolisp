# Documentation is exported to PDF via Emacs's native org-mode LaTeX
# exporter rather than pandoc; pandoc's org reader trips on a number
# of legitimate AutoLISP-spec constructs (e.g. `\"' inside backticks)
# that org-mode parses correctly. The LaTeX compiler is set to
# xelatex so arbitrary UTF-8 codepoints render without missing-glyph
# errors. Both variables are overridable, e.g.
# `make documentation LATEX_COMPILER=lualatex'.
EMACS          ?= emacs
LATEX_COMPILER ?= xelatex
AUTOCAD_RUNNER ?=
BRICSCAD_RUNNER ?=

DOCUMENTATION_ORG := $(wildcard documentation/*.org)
SPECIFICATIONS_ORG := $(wildcard specifications/*.org)
ORG_FILES := $(DOCUMENTATION_ORG) $(SPECIFICATIONS_ORG)
PDF_FILES := $(ORG_FILES:.org=.pdf)

# Source-of-truth org file the paged builds slice up.
SPEC_ORG := documentation/autolisp-visual-lisp-specification-draft.org
BUILD_DIR := build
PAGES_DIR := $(BUILD_DIR)/pages
HTML_DIR  := $(BUILD_DIR)/html
INFO_DIR  := $(BUILD_DIR)/info

# Install destination. Override on the command line:
#   make install PREFIX=/usr/local
PREFIX ?= /opt
DESTDIR ?=

.PHONY: all documentation clean-pdf probe-autocad probe-bricscad probes \
        pages html info paged install uninstall clean-build

all: documentation

documentation: $(PDF_FILES)

# ---------------------------------------------------------------------
# Paged spec build — splits the canonical org file into per-section
# pages, then renders HTML and Info from the same split source.

pages:  ## Emit one .txt per * chapter and ** subsection under build/pages/.
	$(EMACS) --batch --script scripts/build-paged-spec.el \
		$(SPEC_ORG) $(PAGES_DIR) text

html: $(BUILD_DIR)/.org-stamp
	$(EMACS) --batch --script scripts/build-paged-html.el $(BUILD_DIR)

info: $(BUILD_DIR)/.org-stamp
	@echo "info: see Phase C follow-up."

paged: pages html info  ## Build every paged derivative (pages + html + info).

# Intermediate: emit the per-section .org pages that HTML and Info
# both consume. The stamp file pegs the rebuild trigger to the spec
# org's mtime.
$(BUILD_DIR)/.org-stamp: $(SPEC_ORG) scripts/build-paged-spec.el
	$(EMACS) --batch --script scripts/build-paged-spec.el \
		$(SPEC_ORG) $(BUILD_DIR)/org org
	@mkdir -p $(BUILD_DIR)
	@touch $@

clean-build:  ## Remove every paged derivative under build/.
	rm -rf $(BUILD_DIR)

# ---------------------------------------------------------------------
# Install / uninstall the paged spec into $PREFIX/share/autolisp-spec/.
# Sibling install paths (per the issue):
#   $PREFIX/share/emacs/site-lisp/autolisp-spec/     — alref.el
#   $PREFIX/share/autolisp/site-lisp/autolisp-spec/  — alref.lsp

DATA_INSTALL_DIR  := $(DESTDIR)$(PREFIX)/share/autolisp-spec
EMACS_INSTALL_DIR := $(DESTDIR)$(PREFIX)/share/emacs/site-lisp/autolisp-spec
LISP_INSTALL_DIR  := $(DESTDIR)$(PREFIX)/share/autolisp/site-lisp/autolisp-spec

install: paged  ## Install pages, HTML, Info, PDFs, alref libs into $$PREFIX.
	install -d $(DATA_INSTALL_DIR)/pages
	install -d $(DATA_INSTALL_DIR)/html
	install -d $(DATA_INSTALL_DIR)/info
	@if [ -d $(PAGES_DIR) ]; then cp -R $(PAGES_DIR)/. $(DATA_INSTALL_DIR)/pages/; fi
	@if [ -d $(HTML_DIR)  ]; then cp -R $(HTML_DIR)/.  $(DATA_INSTALL_DIR)/html/;  fi
	@if [ -d $(INFO_DIR)  ]; then cp -R $(INFO_DIR)/.  $(DATA_INSTALL_DIR)/info/;  fi
	@for f in documentation/autolisp-visual-lisp-specification-draft.org \
	          documentation/autolisp-visual-lisp-specification-draft.pdf \
	          documentation/autolisp-reference-notes.org \
	          documentation/autolisp-reference-notes.pdf; do \
	  if [ -f $$f ]; then install -m 0644 $$f $(DATA_INSTALL_DIR)/; fi; \
	done
	@if [ -d emacs ]; then \
	  install -d $(EMACS_INSTALL_DIR); \
	  for f in emacs/*.el; do [ -f "$$f" ] && install -m 0644 "$$f" $(EMACS_INSTALL_DIR)/; done; \
	fi
	@if [ -d autolisp ]; then \
	  install -d $(LISP_INSTALL_DIR); \
	  for f in autolisp/*.lsp; do [ -f "$$f" ] && install -m 0644 "$$f" $(LISP_INSTALL_DIR)/; done; \
	fi

uninstall:  ## Remove the paged spec from $$PREFIX.
	rm -rf $(DATA_INSTALL_DIR) $(EMACS_INSTALL_DIR) $(LISP_INSTALL_DIR)

# Runner templates must contain:
# - __PROBE_FILE__ for the generated probe wrapper
# - __RESULT_DIR__ for the output directory
#
# Example:
# make probe-bricscad BRICSCAD_RUNNER='"/Applications/BricsCAD.app/Contents/MacOS/bricscad" "__PROBE_FILE__"'

%.pdf: %.org
	$(EMACS) --batch \
		--eval '(progn (require (quote ox-latex)) (setq org-latex-compiler "$(LATEX_COMPILER)") (setq org-latex-pdf-process (list (concat "$(LATEX_COMPILER)" " -interaction nonstopmode -output-directory %o %f") (concat "$(LATEX_COMPILER)" " -interaction nonstopmode -output-directory %o %f"))))' \
		--visit "$<" \
		--funcall org-latex-export-to-pdf

clean-pdf:
	rm -f $(PDF_FILES)

probe-autocad:
	@if [ -z "$(AUTOCAD_RUNNER)" ]; then \
		echo "AUTOCAD_RUNNER is required."; \
		echo 'Example: make probe-autocad AUTOCAD_RUNNER='\''/path/to/autocad __PROBE_FILE__'\'''; \
		exit 2; \
	fi
	@RUNNER_TEMPLATE='$(AUTOCAD_RUNNER)' bash scripts/run-probes.sh autocad

probe-bricscad:
	@if [ -z "$(BRICSCAD_RUNNER)" ]; then \
		echo "BRICSCAD_RUNNER is required."; \
		echo 'Example: make probe-bricscad BRICSCAD_RUNNER='\''/path/to/bricscad __PROBE_FILE__'\'''; \
		exit 2; \
	fi
	@RUNNER_TEMPLATE='$(BRICSCAD_RUNNER)' bash scripts/run-probes.sh bricscad

probes: probe-autocad probe-bricscad
