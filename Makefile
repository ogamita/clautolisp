SUBPROJECTS := autolisp-spec clautolisp autolisp-test
CLAUTOLISP_CI_IMAGE ?= registry.gitlab.com/ogamita/clautolisp/clautolisp-ci:latest
CLAUTOLISP_CI_DOCKERFILE ?= clautolisp/docker/Dockerfile
CLAUTOLISP_CI_PLATFORM ?= linux/amd64

# Help text comes from `## ` comments after each target name. Keep
# new targets self-documenting: any target whose recipe matters at
# the top level should carry a `## ...` description so it appears in
# `make help`.

.PHONY: help all documentation test clean-pdf docker-build-clautolisp-ci docker-push-clautolisp-ci $(SUBPROJECTS)

help:  ## Show this message (list available targets and their purpose).
	@awk 'BEGIN { \
	    FS = ":.*?## "; \
	    printf "Usage: make <target>\n\nTop-level targets:\n"; \
	  } \
	  /^[a-zA-Z_][a-zA-Z0-9_-]*:.*?## / { \
	    printf "  %-32s %s\n", $$1, $$2; \
	  } \
	  END { \
	    printf "\nSubprojects (forwarded by `make <name>`): %s\n", \
	      "$(SUBPROJECTS)"; \
	    printf "Each subproject has its own Makefile with finer-grained\n"; \
	    printf "targets; see e.g. `make -C clautolisp help` once those\n"; \
	    printf "Makefiles grow their own help target.\n"; \
	  }' $(MAKEFILE_LIST)

all: documentation  ## Default target: build full documentation across all subprojects.

autolisp-spec:  ## Build the autolisp-spec subproject (delegates to its Makefile).
	$(MAKE) -C autolisp-spec all

clautolisp:  ## Build the clautolisp subproject — runtime, executables, GUI driver, docs.
	$(MAKE) -C clautolisp all

autolisp-test:  ## Build the autolisp-test conformance harness subproject.
	$(MAKE) -C autolisp-test all

documentation:  ## Rebuild every subproject's PDF documentation (org → LaTeX → PDF).
	$(MAKE) -C autolisp-spec documentation
	$(MAKE) -C clautolisp documentation
	$(MAKE) -C autolisp-test documentation

test:  ## Run the clautolisp test suite plus the autolisp-test conformance corpus.
	$(MAKE) -C clautolisp test
	$(MAKE) -C autolisp-test test

clean-pdf:  ## Remove every generated PDF across subprojects (keeps .org sources).
	$(MAKE) -C autolisp-spec clean-pdf
	$(MAKE) -C clautolisp clean-pdf
	$(MAKE) -C autolisp-test clean-pdf

docker-build-clautolisp-ci:  ## Build the GitLab-CI Docker image used to run clautolisp tests.
	docker build \
		--platform "$(CLAUTOLISP_CI_PLATFORM)" \
		-f "$(CLAUTOLISP_CI_DOCKERFILE)" \
		-t "$(CLAUTOLISP_CI_IMAGE)" \
		.

docker-push-clautolisp-ci: docker-build-clautolisp-ci  ## Build and push the CI image to the configured registry.
	docker push "$(CLAUTOLISP_CI_IMAGE)"
