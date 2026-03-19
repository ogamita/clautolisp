LISP ?= sbcl
CCL ?= ccl
PANDOC ?= pandoc

TEST_SYSTEM ?= clautolisp-tests
EXECUTABLE ?= bin/clautolisp

DOCUMENTATION_ORG := $(wildcard documentation/*.org)
PDF_FILES := $(DOCUMENTATION_ORG:.org=.pdf)

.PHONY: all test test-sbcl test-ccl documentation clean-pdf

all: documentation

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
