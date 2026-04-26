CCL  ?= ccl
SBCL ?= sbcl
LISP ?= $(SBCL)
PANDOC ?= pandoc
ROOT_DIR := $(shell pwd)
ASD_FILE := $(ROOT_DIR)/clautolisp.asd
XDG_CACHE_HOME ?= $(ROOT_DIR)/.cache

TEST_SYSTEM ?= clautolisp
EXECUTABLE ?= bin/clautolisp
READ_AUTOLISP_TOOL_DIR := autolisp-reader/tools/read-autolisp
READ_AUTOLISP_BIN_DIR := $(READ_AUTOLISP_TOOL_DIR)/bin
READ_AUTOLISP_SBCL := $(READ_AUTOLISP_BIN_DIR)/read-autolisp-sbcl
READ_AUTOLISP_CCL := $(READ_AUTOLISP_BIN_DIR)/read-autolisp-ccl
CLAUTOLISP_TOOL_DIR := tools/clautolisp
CLAUTOLISP_BIN_DIR := $(CLAUTOLISP_TOOL_DIR)/bin
CLAUTOLISP_SBCL := $(CLAUTOLISP_BIN_DIR)/clautolisp-sbcl
CLAUTOLISP_CCL := $(CLAUTOLISP_BIN_DIR)/clautolisp-ccl
RUN_FILE_COMPAT := autolisp-file-compat/tools/run-file-compat/run-file-compat
FILE_COMPAT_SCENARIOS ?= autolisp-file-compat/scenarios
FILE_COMPAT_ARGS ?=
FILE_COMPAT_OUTPUT ?=
FILE_COMPAT_PRODUCT_SCENARIOS ?= autolisp-file-compat/scenarios/mutations autolisp-file-compat/scenarios/streams autolisp-file-compat/scenarios/printers

DOCUMENTATION_ORG := $(wildcard documentation/*.org)
PDF_FILES := $(DOCUMENTATION_ORG:.org=.pdf)

.PHONY: all test test-sbcl test-ccl build-read-autolisp-sbcl build-read-autolisp-ccl build-clautolisp-sbcl build-clautolisp-ccl run-file-compat run-file-compat-sbcl run-file-compat-ccl run-file-compat-autocad run-file-compat-bricscad audit-file-compat-autocad audit-file-compat-bricscad documentation user-manual clean-pdf

all: documentation

test: test-sbcl

test-sbcl:
	env XDG_CACHE_HOME="$(XDG_CACHE_HOME)" \
	$(SBCL) --noinform --no-userinit --non-interactive \
		--eval '(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname)))) (when (probe-file ql) (load ql)))' \
		--eval '(when (find-package :ql) (ql:quickload "fiveam" :silent t))' \
		--eval '(require :asdf)' \
		--eval '(asdf:load-asd "$(ASD_FILE)")' \
		--eval '(asdf:test-system "$(TEST_SYSTEM)" :verbose t)'

test-ccl:
	env XDG_CACHE_HOME="$(XDG_CACHE_HOME)" \
	ccl --no-init --quiet \
		--eval '(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname)))) (when (probe-file ql) (load ql)))' \
		--eval '(when (find-package :ql) (ql:quickload "fiveam" :silent t))' \
		--eval '(require :asdf)' \
		--eval '(asdf:load-asd "$(ASD_FILE)")' \
		--eval '(asdf:test-system "$(TEST_SYSTEM)" :verbose t)' \
		--eval '(ccl:quit)'

build-read-autolisp-sbcl:
	env XDG_CACHE_HOME="$(XDG_CACHE_HOME)" \
	$(SBCL) --noinform --no-userinit --non-interactive \
		--eval '(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname)))) (when (probe-file ql) (load ql)))' \
		--eval '(require :asdf)' \
		--load "$(READ_AUTOLISP_TOOL_DIR)/generate-read-autolisp.lisp" \
		--eval '(sb-ext:quit)'

build-read-autolisp-ccl:
	env XDG_CACHE_HOME="$(XDG_CACHE_HOME)" \
	ccl --no-init --quiet \
		--eval '(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname)))) (when (probe-file ql) (load ql)))' \
		--eval '(require :asdf)' \
		--load "$(READ_AUTOLISP_TOOL_DIR)/generate-read-autolisp.lisp" \
		--eval '(ccl:quit)'

build-clautolisp-sbcl:
	env XDG_CACHE_HOME="$(XDG_CACHE_HOME)" \
	$(SBCL) --noinform --no-userinit --non-interactive \
		--eval '(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname)))) (when (probe-file ql) (load ql)))' \
		--eval '(require :asdf)' \
		--load "$(CLAUTOLISP_TOOL_DIR)/generate-clautolisp.lisp" \
		--eval '(sb-ext:quit)'

build-clautolisp-ccl:
	env XDG_CACHE_HOME="$(XDG_CACHE_HOME)" \
	ccl --no-init --quiet \
		--eval '(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname)))) (when (probe-file ql) (load ql)))' \
		--eval '(require :asdf)' \
		--load "$(CLAUTOLISP_TOOL_DIR)/generate-clautolisp.lisp" \
		--eval '(ccl:quit)'

run-file-compat: run-file-compat-sbcl

run-file-compat-sbcl:
	$(RUN_FILE_COMPAT) --sbcl $(FILE_COMPAT_ARGS) $(FILE_COMPAT_SCENARIOS)

run-file-compat-ccl:
	$(RUN_FILE_COMPAT) --ccl $(FILE_COMPAT_ARGS) $(FILE_COMPAT_SCENARIOS)

run-file-compat-autocad:
	$(RUN_FILE_COMPAT) --autocad $(FILE_COMPAT_ARGS) $(FILE_COMPAT_SCENARIOS)

run-file-compat-bricscad:
	$(RUN_FILE_COMPAT) --bricscad $(FILE_COMPAT_ARGS) $(FILE_COMPAT_SCENARIOS)

audit-file-compat-autocad:
	$(RUN_FILE_COMPAT) --autocad --report-format json $(FILE_COMPAT_ARGS) $(FILE_COMPAT_PRODUCT_SCENARIOS)

audit-file-compat-bricscad:
	$(RUN_FILE_COMPAT) --bricscad --report-format json $(FILE_COMPAT_ARGS) $(FILE_COMPAT_PRODUCT_SCENARIOS)


documentation: $(PDF_FILES)

user-manual: documentation/user-manual.pdf

%.pdf: %.org
	$(PANDOC) --from=org --to=pdf --output="$@" "$<"

clean-pdf:
	rm -f $(PDF_FILES)
