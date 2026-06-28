# Documentation is exported to PDF via Emacs's native org-mode LaTeX
# exporter rather than pandoc; pandoc's org reader trips on a number
# of legitimate AutoLISP-spec constructs (e.g. `\"' inside backticks)
# that org-mode parses correctly. The LaTeX compiler is set to
# xelatex so arbitrary UTF-8 codepoints render without missing-glyph
# errors. Both variables are overridable, e.g.
# `make documentation LATEX_COMPILER=lualatex'.
EMACS          ?= $(shell sh ../scripts/resolve-emacs.sh)
LATEX_COMPILER ?= xelatex
MAKEINFO       ?= makeinfo
INSTALL_INFO   ?= install-info
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
# The default /opt/local matches the MacPorts hierarchy + the repo-
# wide convention documented in the root Makefile's install target.
PREFIX ?= /opt/local
DESTDIR ?=
SUBPROJECT_NAME := autolisp-spec

.PHONY: all build documentation clean-pdf probe-autocad probe-bricscad probes \
        pages html info paged install uninstall clean-build

all: documentation

# `build` is the repo-wide convention for "produce everything
# `install` would ship, but without copying it anywhere". For
# autolisp-spec that's the PDFs plus the paged derivatives (plain
# pages, HTML manual, Info manual). Splitting build from install
# means `sudo make install` only does file-copy — the heavy Emacs
# batch runs and xelatex passes happen earlier under the user's
# own UID where caches stay in $HOME.
build: paged documentation  ## Build PDFs + paged HTML/Info derivatives (everything `install` ships).

documentation: $(PDF_FILES)

# ---------------------------------------------------------------------
# Paged spec build — splits the canonical org file into per-section
# pages, then renders HTML and Info from the same split source.
#
# The convenience names (pages / html / info) are .PHONY aliases for
# the real-file stamp targets below. The stamps are what `paged`
# (and the install target) actually depend on, so a second
# `make install` against an up-to-date tree is near-instant —
# stale-checking is by file mtime, not by always re-running.

pages: $(PAGES_DIR)/.stamp  ## Emit one .txt per * chapter and ** subsection under build/pages/.

$(PAGES_DIR)/.stamp: $(SPEC_ORG) scripts/build-paged-spec.el
	$(EMACS) --batch --script scripts/build-paged-spec.el \
		$(SPEC_ORG) $(PAGES_DIR) text
	@touch $@

html: $(HTML_DIR)/.stamp  ## Render every section + the index/symbol pages as HTML.

$(HTML_DIR)/.stamp: $(BUILD_DIR)/.org-stamp scripts/build-paged-html.el
	$(EMACS) --batch --script scripts/build-paged-html.el $(BUILD_DIR)
	@touch $@

info: $(INFO_DIR)/autolisp-spec.info  ## Build the .info manual from the spec.

$(INFO_DIR)/autolisp-spec.texi: $(SPEC_ORG) scripts/build-paged-info.el
	$(EMACS) --batch --script scripts/build-paged-info.el \
		$(SPEC_ORG) $(BUILD_DIR)

$(INFO_DIR)/autolisp-spec.info: $(INFO_DIR)/autolisp-spec.texi
	# Strict build: --force / --no-validate are NOT needed any
	# more. The two-line acet-ui-m-get-names example whose multi-
	# line string literal continued onto column 0 with '*' (lines
	# 38191-38192 of the spec org pre-fix) has been wrapped in a
	# #+begin_example block with the leading stars comma-escaped
	# (',*'), which org's parser unescapes at export time.
	$(MAKEINFO) --no-split $< -o $@

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
# Install / uninstall.
#
# Layout follows the repo-wide convention documented in the root
# Makefile's install target:
#
#   $(PREFIX)/share/doc/autolisp-spec/           org + pdf reference docs
#   $(PREFIX)/share/doc/autolisp-spec/html/      HTML manual (browse-able)
#   $(PREFIX)/share/info/                        autolisp-spec.info (info dir)
#   $(PREFIX)/share/autolisp-spec/pages/         plain-text pages (data files
#                                                the alref libraries read)
#   $(PREFIX)/share/emacs/site-lisp/autolisp-spec/    alref.el
#   $(PREFIX)/share/autolisp/site-lisp/autolisp-spec/ alref.lsp
#
# pages/ stays under share/autolisp-spec/ rather than share/doc/
# because both alref libraries treat it as data (open it for read,
# parse the index, etc.), not as readable docs.

DOC_INSTALL_DIR   := $(DESTDIR)$(PREFIX)/share/doc/$(SUBPROJECT_NAME)
DATA_INSTALL_DIR  := $(DESTDIR)$(PREFIX)/share/$(SUBPROJECT_NAME)
INFO_INSTALL_DIR  := $(DESTDIR)$(PREFIX)/share/info
EMACS_INSTALL_DIR := $(DESTDIR)$(PREFIX)/share/emacs/site-lisp/$(SUBPROJECT_NAME)
LISP_INSTALL_DIR  := $(DESTDIR)$(PREFIX)/share/autolisp/site-lisp/$(SUBPROJECT_NAME)

.PHONY: install install-programs install-documentation uninstall

install: build  ## Install the autolisp-spec documentation into $$PREFIX (build first; sudo-friendly).
	$(MAKE) install-programs
	$(MAKE) install-documentation

install-programs:  ## No-op: autolisp-spec ships documentation only.
	@echo "programs installed: PREFIX=$(PREFIX) DESTDIR=$(DESTDIR)"

install-documentation:  ## Install the autolisp-spec docs (.org/.pdf/HTML/Info/pages + alref libs).
	install -d $(DOC_INSTALL_DIR)/html
	install -d $(DATA_INSTALL_DIR)/pages
	install -d $(INFO_INSTALL_DIR)
	@if [ -d $(HTML_DIR)  ]; then cp -R $(HTML_DIR)/.  $(DOC_INSTALL_DIR)/html/;  fi
	@if [ -d $(PAGES_DIR) ]; then cp -R $(PAGES_DIR)/. $(DATA_INSTALL_DIR)/pages/; fi
	@if [ -f $(INFO_DIR)/autolisp-spec.info ]; then \
	  install -m 0644 $(INFO_DIR)/autolisp-spec.info $(INFO_INSTALL_DIR)/; \
	  $(INSTALL_INFO) --info-dir="$(INFO_INSTALL_DIR)" \
	    $(INFO_DIR)/autolisp-spec.info 2>/dev/null \
	    || echo "[skip] install-info dir update for autolisp-spec.info"; \
	fi
	@for f in documentation/autolisp-visual-lisp-specification-draft.org \
	          documentation/autolisp-visual-lisp-specification-draft.pdf \
	          documentation/autolisp-reference-notes.org \
	          documentation/autolisp-reference-notes.pdf \
	          documentation/autolisp-spec-user-manual.org; do \
	  if [ -f $$f ]; then install -m 0644 $$f $(DOC_INSTALL_DIR)/; fi; \
	done
	@if [ -d emacs ]; then \
	  install -d $(EMACS_INSTALL_DIR); \
	  for f in emacs/*.el; do [ -f "$$f" ] && install -m 0644 "$$f" $(EMACS_INSTALL_DIR)/; done; \
	fi
	@if [ -d autolisp ]; then \
	  install -d $(LISP_INSTALL_DIR); \
	  for f in autolisp/*.lsp; do [ -f "$$f" ] && install -m 0644 "$$f" $(LISP_INSTALL_DIR)/; done; \
	fi
	@echo "documentation installed: PREFIX=$(PREFIX) DESTDIR=$(DESTDIR)"

uninstall:  ## Remove the spec install from $$PREFIX.
	rm -rf $(DOC_INSTALL_DIR) $(DATA_INSTALL_DIR) \
	       $(EMACS_INSTALL_DIR) $(LISP_INSTALL_DIR)
	@$(INSTALL_INFO) --remove --info-dir="$(INFO_INSTALL_DIR)" \
	  autolisp-spec.info 2>/dev/null || true
	rm -f $(INFO_INSTALL_DIR)/autolisp-spec.info

# Runner templates must contain:
# - __PROBE_FILE__ for the generated probe wrapper
# - __RESULT_DIR__ for the output directory
#
# Example:
# make probe-bricscad BRICSCAD_RUNNER='"/Applications/BricsCAD.app/Contents/MacOS/bricscad" "__PROBE_FILE__"'

# The ~4600-page visual-lisp spec exceeds TeX's default main_memory and aborts
# with "TeX capacity exceeded". A repo-local web2c/texmf.cnf raises the memory
# parameters; we build a private xelatex format with them into a cache dir
# (TEXMFVAR) so no machine-wide texmf.cnf edit or root access is needed. The
# trailing empty component on TEXMFCNF appends the system search path.
TEX_WEB2C    := $(CURDIR)/documentation/web2c
TEXFMT_CACHE := $(CURDIR)/.cache/texmf-var
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
# via org-latex-packages-alist, with TEXINPUTS pointing at documentation/ so the
# .sty is found regardless of the .tex's directory.
%.pdf: %.org | $(TEX_FMT_DEP)
	TEXINPUTS="$(CURDIR)/documentation:$$TEXINPUTS" $(EMACS) --batch \
		--eval '(progn (require (quote ox-latex)) (setq org-latex-compiler "$(LATEX_COMPILER)") (setq org-export-with-broken-links t) (add-to-list (quote org-latex-packages-alist) (quote ("" "clautolisp-doc-preamble" t ("xelatex" "lualatex"))) t) (setq org-latex-pdf-process (list (concat "$(LATEX_COMPILER)" " -interaction nonstopmode -output-directory %o %f") (concat "$(LATEX_COMPILER)" " -interaction nonstopmode -output-directory %o %f"))))' \
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
