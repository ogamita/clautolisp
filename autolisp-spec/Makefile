PANDOC ?= pandoc
AUTOCAD_RUNNER ?=
BRICSCAD_RUNNER ?=

DOCUMENTATION_ORG := $(wildcard documentation/*.org)
SPECIFICATIONS_ORG := $(wildcard specifications/*.org)
ORG_FILES := $(DOCUMENTATION_ORG) $(SPECIFICATIONS_ORG)
PDF_FILES := $(ORG_FILES:.org=.pdf)

.PHONY: all documentation clean-pdf probe-autocad probe-bricscad probes

all: documentation

documentation: $(PDF_FILES)

# Runner templates must contain:
# - __PROBE_FILE__ for the generated probe wrapper
# - __RESULT_DIR__ for the output directory
#
# Example:
# make probe-bricscad BRICSCAD_RUNNER='"/Applications/BricsCAD.app/Contents/MacOS/bricscad" "__PROBE_FILE__"'

%.pdf: %.org
	$(PANDOC) --from=org --to=pdf --output="$@" "$<"

clean-pdf:
	rm -f $(PDF_FILES)

probe-autocad:
	@if [ -z "$(AUTOCAD_RUNNER)" ]; then \
		echo "AUTOCAD_RUNNER is required."; \
		echo 'Example: make probe-autocad AUTOCAD_RUNNER='\''/path/to/autocad __PROBE_FILE__'\'''; \
		exit 2; \
	fi
	@RUNNER_TEMPLATE='$(AUTOCAD_RUNNER)' bash scripts/run-probes.sh autocad

probe-bricscad:
	@if [ -z "$(BRICSCAD_RUNNER)" ]; then \
		echo "BRICSCAD_RUNNER is required."; \
		echo 'Example: make probe-bricscad BRICSCAD_RUNNER='\''/path/to/bricscad __PROBE_FILE__'\'''; \
		exit 2; \
	fi
	@RUNNER_TEMPLATE='$(BRICSCAD_RUNNER)' bash scripts/run-probes.sh bricscad

probes: probe-autocad probe-bricscad
