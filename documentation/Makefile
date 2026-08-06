# Renders the generated artefacts in this directory: the Graphviz
# diagrams (each .dot to .svg and .png, requires graphviz) and the
# demo PDFs (each demo/*.org to a .pdf next to it, via Emacs's
# org-mode LaTeX exporter + xelatex — the same toolchain as the
# subproject documentation). The rendered files are generated
# artefacts: gitignored, never committed — commit the .dot/.org
# sources and keep these render rules.

EMACS          ?= $(shell sh ../scripts/resolve-emacs.sh)
LATEX_COMPILER ?= xelatex
DOCUMENTATION_BIN ?= $(shell sh ../scripts/resolve-documentation-bin.sh)
ifneq ($(DOCUMENTATION_BIN),)
export PATH := $(DOCUMENTATION_BIN):$(PATH)
endif

DOTS := $(wildcard *.dot)
SVGS := $(DOTS:.dot=.svg)
PNGS := $(DOTS:.dot=.png)

DEMO_ORG := $(wildcard demo/*.org)
DEMO_PDF := $(DEMO_ORG:.org=.pdf)

# clautolisp-doc-preamble.sty gives xelatex the fonts for the Unicode
# glyphs Latin Modern lacks. Unlike the subprojects (which each carry
# their own copy so they stay self-contained), this directory only
# exists inside the full repo checkout, so it reuses the copy in
# clautolisp/documentation/ via TEXINPUTS.
ifneq ($(filter MINGW% MSYS% CYGWIN%,$(shell uname -s)),)
TEX_PATH_SEPARATOR := ;
TEX_PREAMBLE_SEARCH := $(shell cygpath -m "$(CURDIR)/../clautolisp/documentation")
else
TEX_PATH_SEPARATOR := :
TEX_PREAMBLE_SEARCH := $(CURDIR)/../clautolisp/documentation
endif

.PHONY: all diagrams documentation clean clean-pdf

all: diagrams documentation  ## Render every .dot diagram + every demo PDF.

diagrams: $(SVGS) $(PNGS)

documentation: $(DEMO_PDF)  ## Render each demo/*.org to a PDF next to it (demo/alref.pdf, …).

%.svg: %.dot
	dot -Tsvg $< -o $@

%.png: %.dot
	dot -Tpng -Gdpi=110 $< -o $@

# org export writes its outputs next to the .org, which is where the
# PDF belongs; only the intermediate .tex is cleaned up afterwards.
%.pdf: %.org
	TEXINPUTS="$(TEX_PREAMBLE_SEARCH)$(TEX_PATH_SEPARATOR)$$TEXINPUTS" $(EMACS) --batch \
		--eval '(progn (require (quote ox-latex)) (setq org-latex-compiler "$(LATEX_COMPILER)") (setq org-export-with-broken-links t) (add-to-list (quote org-latex-packages-alist) (quote ("" "clautolisp-doc-preamble" t ("xelatex" "lualatex"))) t) (setq org-latex-pdf-process (list (concat "$(LATEX_COMPILER)" " -interaction nonstopmode -output-directory %o %f") (concat "$(LATEX_COMPILER)" " -interaction nonstopmode -output-directory %o %f"))))' \
		--visit "$<" \
		--funcall org-latex-export-to-pdf
	@rm -f "$(<:.org=.tex)"

clean: clean-pdf  ## Remove the rendered diagrams + demo PDFs (keeps the sources).
	rm -f $(SVGS) $(PNGS)

clean-pdf:  ## Remove the rendered demo PDFs (keeps the .org sources).
	rm -f $(DEMO_PDF)
