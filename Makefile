SUBPROJECTS := autolisp-spec clautolisp autolisp-test autolisp-front-end
CLAUTOLISP_CI_IMAGE ?= registry.gitlab.com/ogamita/clautolisp/clautolisp-ci:latest
CLAUTOLISP_CI_DOCKERFILE ?= clautolisp/docker/Dockerfile
CLAUTOLISP_CI_PLATFORM ?= linux/amd64

# Install destination. Override on the command line:
#   make install PREFIX=/usr/local
#   make install DESTDIR=/staging PREFIX=/opt/local      # packager use
#
# Repo-wide install convention (every subproject's Makefile honours
# the same layout):
#
#   $(DESTDIR)$(PREFIX)/bin/                         user-facing executables
#                                                    (clautolisp-{sbcl,ccl},
#                                                     read-autolisp-{sbcl,ccl},
#                                                     clautolisp-gui-qt, alfe-{sbcl,ccl})
#   $(DESTDIR)$(PREFIX)/libexec/<subproject>/        support executables
#                                                    (run-file-compat,
#                                                     autolisp-test harness, …)
#   $(DESTDIR)$(PREFIX)/share/doc/<subproject>/      .org + .pdf docs + HTML
#                                                    + man pages (when present)
#   $(DESTDIR)$(PREFIX)/share/info/                  GNU Info manuals
#   $(DESTDIR)$(PREFIX)/share/<subproject>/          data files
#                                                    (autolisp-spec pages/)
#   $(DESTDIR)$(PREFIX)/share/emacs/site-lisp/<…>/   Emacs libraries
#   $(DESTDIR)$(PREFIX)/share/autolisp/site-lisp/<…>/  AutoLISP libraries
#
# /opt/local matches the MacPorts hierarchy; /usr/local and
# /usr are the common alternatives the override accepts.

PREFIX ?= /opt/local
DESTDIR ?=

# Help text comes from `## ` comments after each target name. Keep
# new targets self-documenting: any target whose recipe matters at
# the top level should carry a `## ...` description so it appears in
# `make help`.

.PHONY: help all documentation test clean-pdf docker-build-clautolisp-ci docker-push-clautolisp-ci install uninstall $(SUBPROJECTS)

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
	    printf "\nFor the test×dialect×platform matrix forwarded at the root,\n"; \
	    printf "see `make help-test-matrix`.\n"; \
	  }' $(MAKEFILE_LIST)

all: documentation  ## Default target: build full documentation across all subprojects.

autolisp-spec:  ## Build the autolisp-spec subproject (delegates to its Makefile).
	$(MAKE) -C autolisp-spec all

clautolisp:  ## Build the clautolisp subproject — runtime, executables, GUI driver, docs.
	$(MAKE) -C clautolisp all

autolisp-test:  ## Build the autolisp-test conformance harness subproject.
	$(MAKE) -C autolisp-test all

autolisp-front-end:  ## Build the autolisp-front-end (alfe) subproject — unified CLI front-end for clautolisp + CAD-resident REPLs.
	$(MAKE) -C autolisp-front-end all

documentation:  ## Rebuild every subproject's PDF documentation (org → LaTeX → PDF).
	$(MAKE) -C autolisp-spec documentation
	$(MAKE) -C clautolisp documentation
	$(MAKE) -C autolisp-test documentation
	$(MAKE) -C autolisp-front-end documentation

test:  ## Run the clautolisp test suite plus the autolisp-test conformance corpus.
	$(MAKE) -C clautolisp test
	$(MAKE) -C autolisp-test test
	$(MAKE) -C autolisp-front-end test

clean-pdf:  ## Remove every generated PDF across subprojects (keeps .org sources).
	$(MAKE) -C autolisp-spec clean-pdf
	$(MAKE) -C clautolisp clean-pdf
	$(MAKE) -C autolisp-test clean-pdf
	$(MAKE) -C autolisp-front-end clean-pdf

install:  ## Install every subproject's built artefacts into $$PREFIX (default /opt/local).
	$(MAKE) -C autolisp-spec      install PREFIX=$(PREFIX) DESTDIR=$(DESTDIR)
	$(MAKE) -C clautolisp         install PREFIX=$(PREFIX) DESTDIR=$(DESTDIR)
	$(MAKE) -C autolisp-test      install PREFIX=$(PREFIX) DESTDIR=$(DESTDIR)
	$(MAKE) -C autolisp-front-end install PREFIX=$(PREFIX) DESTDIR=$(DESTDIR)

uninstall:  ## Remove every subproject's install from $$PREFIX.
	$(MAKE) -C autolisp-spec      uninstall PREFIX=$(PREFIX) DESTDIR=$(DESTDIR)
	$(MAKE) -C clautolisp         uninstall PREFIX=$(PREFIX) DESTDIR=$(DESTDIR)
	$(MAKE) -C autolisp-test      uninstall PREFIX=$(PREFIX) DESTDIR=$(DESTDIR)
	$(MAKE) -C autolisp-front-end uninstall PREFIX=$(PREFIX) DESTDIR=$(DESTDIR)

# ---------------------------------------------------------------------
# Forwarded fine-grained test targets (see issues/closed/test-targets.issue).
#
# Each subproject Makefile owns its own grid of test×implementation×
# dialect×platform targets. The root re-exposes every one of those
# names as a passthrough so testers can write `make <target>` from
# the repo root without having to remember which subproject owns
# each combo. The lists below are the source of truth — adding a
# new target in a subproject Makefile requires a one-line append
# here to surface it at the root.
#
# `make help-test-matrix` prints the full forwarded inventory grouped
# by subproject.

# autolisp-test owns the harness-driven matrix: 4 dialects × 2 Lisp
# implementations against clautolisp, plus 6 dialect-on-CAD targets
# via alfe (BricsCAD on macOS/Windows, AutoCAD on Windows), plus
# the matching aggregates.
AUTOLISP_TEST_FORWARDED := \
  test-clautolisp-sbcl-strict     test-clautolisp-sbcl-clautolisp \
  test-clautolisp-sbcl-bricscad   test-clautolisp-sbcl-autocad \
  test-clautolisp-ccl-strict      test-clautolisp-ccl-clautolisp \
  test-clautolisp-ccl-bricscad    test-clautolisp-ccl-autocad \
  test-clautolisp-sbcl-all        test-clautolisp-ccl-all        test-clautolisp-all \
  test-bricscad-macos             test-bricscad-macos-strict     test-bricscad-macos-bricscad \
  test-bricscad-windows           test-bricscad-windows-strict   test-bricscad-windows-bricscad \
  test-autocad-windows            test-autocad-windows-strict    test-autocad-windows-autocad

# clautolisp owns the run-file-compat per-platform splits.
CLAUTOLISP_FORWARDED := \
  run-file-compat-bricscad-macos \
  run-file-compat-bricscad-windows \
  run-file-compat-autocad-windows

# autolisp-front-end owns the built-alfe per-backend smoke tests.
ALFE_FORWARDED := \
  test-alfe-sbcl-clautolisp        test-alfe-ccl-clautolisp \
  test-alfe-sbcl-bricscad-macos    test-alfe-ccl-bricscad-macos \
  test-alfe-sbcl-bricscad-windows  test-alfe-ccl-bricscad-windows \
  test-alfe-sbcl-autocad-windows   test-alfe-ccl-autocad-windows

.PHONY: $(AUTOLISP_TEST_FORWARDED) $(CLAUTOLISP_FORWARDED) $(ALFE_FORWARDED) \
        help-test-matrix

# Forwarding macro. $(call forward-target-to,TARGET-NAME,SUBPROJECT)
# generates a one-line rule that delegates to that subproject's
# Makefile. The $$@ inside the recipe defers expansion until rule
# evaluation so the right target name lands in the recursive
# $(MAKE) call.
define forward-target-to
$(1):
	$$(MAKE) -C $(2) $$@
endef

$(foreach t,$(AUTOLISP_TEST_FORWARDED), \
  $(eval $(call forward-target-to,$(t),autolisp-test)))
$(foreach t,$(CLAUTOLISP_FORWARDED), \
  $(eval $(call forward-target-to,$(t),clautolisp)))
$(foreach t,$(ALFE_FORWARDED), \
  $(eval $(call forward-target-to,$(t),autolisp-front-end)))

help-test-matrix:  ## List every fine-grained test target the root forwards.
	@printf "Forwarded test targets (run from the repo root via 'make <target>'):\n\n"
	@printf "  via autolisp-test/Makefile:\n"
	@for t in $(AUTOLISP_TEST_FORWARDED); do printf "    %s\n" "$$t"; done
	@printf "\n  via clautolisp/Makefile:\n"
	@for t in $(CLAUTOLISP_FORWARDED); do printf "    %s\n" "$$t"; done
	@printf "\n  via autolisp-front-end/Makefile:\n"
	@for t in $(ALFE_FORWARDED); do printf "    %s\n" "$$t"; done
	@printf "\nWrong-platform targets are no-ops (print [skip] and exit 0).\n"

docker-build-clautolisp-ci:  ## Build the GitLab-CI Docker image used to run clautolisp tests.
	docker build \
		--platform "$(CLAUTOLISP_CI_PLATFORM)" \
		-f "$(CLAUTOLISP_CI_DOCKERFILE)" \
		-t "$(CLAUTOLISP_CI_IMAGE)" \
		.

docker-push-clautolisp-ci: docker-build-clautolisp-ci  ## Build and push the CI image to the configured registry.
	docker push "$(CLAUTOLISP_CI_IMAGE)"
