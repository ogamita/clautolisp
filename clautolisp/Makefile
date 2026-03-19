CCL  ?= ccl
SBCL ?= sbcl
LISP ?= $(SBCL)
PANDOC ?= pandoc
ROOT_DIR := $(shell pwd)
ASD_FILE := $(ROOT_DIR)/clautolisp.asd
XDG_CACHE_HOME ?= $(ROOT_DIR)/.cache

TEST_SYSTEM ?= clautolisp
EXECUTABLE ?= bin/clautolisp

DOCUMENTATION_ORG := $(wildcard documentation/*.org)
PDF_FILES := $(DOCUMENTATION_ORG:.org=.pdf)

.PHONY: all test test-sbcl test-ccl documentation clean-pdf

all: documentation

test: test-sbcl

test-sbcl:
	env XDG_CACHE_HOME="$(XDG_CACHE_HOME)" \
	$(SBCL) --noinform --no-userinit --non-interactive \
		--eval '(require :asdf)' \
		--eval '(asdf:load-asd "$(ASD_FILE)")' \
		--eval '(asdf:test-system "$(TEST_SYSTEM)" :verbose t)'

test-ccl:
	env XDG_CACHE_HOME="$(XDG_CACHE_HOME)" \
	ccl --no-init --quiet \
		--eval '(require :asdf)' \
		--eval '(asdf:load-asd "$(ASD_FILE)")' \
		--eval '(asdf:test-system "$(TEST_SYSTEM)" :verbose t)' \
		--eval '(ccl:quit)'


documentation: $(PDF_FILES)

%.pdf: %.org
	$(PANDOC) --from=org --to=pdf --output="$@" "$<"

clean-pdf:
	rm -f $(PDF_FILES)
