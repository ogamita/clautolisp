PANDOC ?= pandoc

DOCUMENTATION_ORG := $(wildcard documentation/*.org)
SPECIFICATIONS_ORG := $(wildcard specifications/*.org)
ORG_FILES := $(DOCUMENTATION_ORG) $(SPECIFICATIONS_ORG)
PDF_FILES := $(ORG_FILES:.org=.pdf)

.PHONY: all documentation clean-pdf

all: documentation

documentation: $(PDF_FILES)

%.pdf: %.org
	$(PANDOC) --from=org --to=pdf --output="$@" "$<"

clean-pdf:
	rm -f $(PDF_FILES)
