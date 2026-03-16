BINARY = calkit
SOURCES = $(shell find Sources -name '*.swift')
INSTALL_PATH = /usr/local/bin/$(BINARY)

.PHONY: build clean install test

build: $(SOURCES)
	swiftc -o $(BINARY) \
		Sources/calkit/main.swift \
		Sources/calkit/CLI/*.swift \
		-framework EventKit \
		-framework Foundation \
		-O

clean:
	rm -f $(BINARY)

install: build
	cp $(BINARY) $(INSTALL_PATH)

test: build
	bash Tests/smoke.sh
