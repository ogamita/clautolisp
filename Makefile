LISP ?= sbcl
CCL ?= ccl
PANDOC ?= pandoc

TEST_SYSTEM ?= clautolisp-tests
EXECUTABLE ?= bin/clautolisp

DOCUMENTATION_ORG := $(wildcard documentation/*.org)
SPECIFICATIONS_ORG := $(wildcard specifications/*.org)
ORG_FILES := $(DOCUMENTATION_ORG) $(SPECIFICATIONS_ORG)
PDF_FILES := $(ORG_FILES:.org=.pdf)

.PHONY: all test test-sbcl test-ccl documentation clean-pdf

all: $(EXECUTABLE)

$(EXECUTABLE):
	: write the sbcl command to load and compile clautolisp.asd and generate an executable from it.

test: test-sbcl

test-sbcl:
	$(LISP) --noinform --non-interactive \
		--eval '(require :asdf)' \
		--eval '(asdf:load-asd "clautolisp.asd")' \
		--eval '(asdf:test-system "$(TEST_SYSTEM)")'

test-ccl:
	$(CCL) --no-init --batch \
		--eval '(require :asdf)' \
		--eval '(asdf:load-asd "clautolisp.asd")' \
		--eval '(asdf:test-system "$(TEST_SYSTEM)")'

documentation: $(PDF_FILES)

%.pdf: %.org
	$(PANDOC) --from=org --to=pdf --output="$@" "$<"

clean-pdf:
	rm -f $(PDF_FILES)
