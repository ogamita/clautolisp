# Renders the generated artefacts in this directory: the Graphviz
# diagrams (each .dot to .svg and .png, requires graphviz) and the
# demo transcripts (each demo/*.org to a .html next to it). The
# rendered files are generated artefacts: gitignored, never committed
# — commit the .dot/.org sources and keep these render rules.

DOTS := $(wildcard *.dot)
SVGS := $(DOTS:.dot=.svg)
PNGS := $(DOTS:.dot=.png)

# Not yet. And alref.html is a source.
# DEMO_ORG  := $(wildcard demo/*.org)
# DEMO_HTML := $(DEMO_ORG:.org=.html)

.PHONY: all diagrams documentation clean clean-pdf clean-html

all: diagrams documentation  ## Render every .dot diagram + every demo transcript.

diagrams: $(SVGS) $(PNGS)

documentation: diagrams

%.svg: %.dot
	dot -Tsvg "$<" -o "$@"

%.png: %.dot
	dot -Tpng -Gdpi=110 "$<" -o "$@"

clean: clean-pdf clean-html  ## Remove the rendered diagrams + demo artefacts (keeps the sources).
	rm -f $(SVGS) $(PNGS)

clean-html:  ## Remove the rendered demo HTML (keeps the .org sources).
	rm -f $(DEMO_HTML)

# The demos used to be rendered to PDF (org → LaTeX → xelatex); the
# target remains so `make clean-pdf` from the repo root sweeps any
# stray in-place render.
clean-pdf:  ## Remove stray demo PDFs (keeps the .org sources).
	rm -f $(DEMO_ORG:.org=.pdf)
