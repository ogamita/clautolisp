SUBPROJECTS := autolisp-spec clautolisp autolisp-test

.PHONY: all documentation test clean-pdf $(SUBPROJECTS)

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
