BINARY = calkit
SOURCES = $(shell find Sources -name '*.swift')
INSTALL_PATH = /usr/local/bin/$(BINARY)

.PHONY: build clean install test test-unit test-smoke test-integration

build: $(SOURCES)
	swiftc -o $(BINARY) \
		Sources/calkit/main.swift \
		Sources/calkit/CLI/*.swift \
		Sources/calkit/Commands/*.swift \
		Sources/calkit/Services/*.swift \
		Sources/calkit/Models/*.swift \
		Sources/calkit/Output/*.swift \
		-framework EventKit \
		-framework Foundation \
		-O

clean:
	rm -f $(BINARY) calkit-tests

install: build
	cp $(BINARY) $(INSTALL_PATH)

XCODE_PATH = $(shell xcode-select -p)
PLATFORM_PATH = $(XCODE_PATH)/Platforms/MacOSX.platform/Developer
XCTEST_FW = $(PLATFORM_PATH)/Library/Frameworks
XCTEST_RPATH = $(PLATFORM_PATH)/Library/Frameworks

test-unit:
	swiftc \
		-framework EventKit \
		-framework Foundation \
		Sources/calkit/Models/*.swift \
		Sources/calkit/Output/*.swift \
		Sources/calkit/Services/*.swift \
		Tests/unit/FormatterTests.swift \
		-o ./calkit-tests && ./calkit-tests

test-smoke: build
	bash Tests/smoke.sh

test-integration: build
	bash Tests/integration/calendars_list.sh

test: test-unit test-smoke test-integration
