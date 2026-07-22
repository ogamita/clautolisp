# Renders the Graphviz diagrams in this directory (each .dot to .svg
# and .png, requires graphviz). The rendered files are generated
# artefacts: gitignored, never committed — commit the .dot source and
# keep this render rule (same convention as the PDFs).

DOTS := $(wildcard *.dot)
SVGS := $(DOTS:.dot=.svg)
PNGS := $(DOTS:.dot=.png)

.PHONY: all diagrams clean

all: diagrams  ## Render every .dot diagram to .svg + .png.

diagrams: $(SVGS) $(PNGS)

%.svg: %.dot
	dot -Tsvg $< -o $@

%.png: %.dot
	dot -Tpng -Gdpi=110 $< -o $@

clean:  ## Remove the rendered diagrams (keeps the .dot sources).
	rm -f $(SVGS) $(PNGS)
