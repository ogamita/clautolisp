SUBPROJECTS := autolisp-spec clautolisp autolisp-test
CLAUTOLISP_CI_IMAGE ?= registry.gitlab.com/ogamita/clautolisp/clautolisp-ci:latest
CLAUTOLISP_CI_DOCKERFILE ?= clautolisp/docker/Dockerfile
CLAUTOLISP_CI_PLATFORM ?= linux/amd64

.PHONY: all documentation test clean-pdf docker-build-clautolisp-ci docker-push-clautolisp-ci $(SUBPROJECTS)

all: documentation

autolisp-spec:
	$(MAKE) -C autolisp-spec all

clautolisp:
	$(MAKE) -C clautolisp all

autolisp-test:
	$(MAKE) -C autolisp-test all

documentation:
	$(MAKE) -C autolisp-spec documentation
	$(MAKE) -C clautolisp documentation
	$(MAKE) -C autolisp-test documentation

test:
	$(MAKE) -C clautolisp test
	$(MAKE) -C autolisp-test test

clean-pdf:
	$(MAKE) -C autolisp-spec clean-pdf
	$(MAKE) -C clautolisp clean-pdf
	$(MAKE) -C autolisp-test clean-pdf

docker-build-clautolisp-ci:
	docker build \
		--platform "$(CLAUTOLISP_CI_PLATFORM)" \
		-f "$(CLAUTOLISP_CI_DOCKERFILE)" \
		-t "$(CLAUTOLISP_CI_IMAGE)" \
		.

docker-push-clautolisp-ci: docker-build-clautolisp-ci
	docker push "$(CLAUTOLISP_CI_IMAGE)"
