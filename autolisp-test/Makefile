PANDOC ?= pandoc

DOCUMENTATION_ORG := $(wildcard documentation/*.org) $(wildcard harness/*.org) $(wildcard tests/*.org)
PDF_FILES := $(DOCUMENTATION_ORG:.org=.pdf)

.PHONY: all documentation test clean-pdf

all: documentation

documentation: $(PDF_FILES)

test:
	: no autolisp-test runner is implemented yet

%.pdf: %.org
	$(PANDOC) --from=org --to=pdf --output="$@" "$<"

clean-pdf:
	rm -f $(PDF_FILES)
