# Makefile

VERSION := $(shell cat VERSION)
BUILD_DIR := build/togler_$(VERSION)_all
BIN_DIR := $(BUILD_DIR)/usr/bin
MAN_DIR := $(BUILD_DIR)/usr/share/man/man1

all: $(BUILD_DIR).deb

$(BUILD_DIR).deb: prepare substitute build-deb

prepare:
	@echo "Creating build directories for version $(VERSION)..."
	mkdir -p $(BIN_DIR)
	mkdir -p $(BUILD_DIR)/usr/share/man/man1
	cp -r DEBIAN $(BUILD_DIR)/
	cp src/togler $(BIN_DIR)/togler
	cp man/togler.1 $(MAN_DIR)/togler.1

substitute:
	@echo "Replacing version placeholders with $(VERSION)..."
	sed -i 's/__VERSION__/$(VERSION)/g' $(BIN_DIR)/togler
	sed -i 's/__VERSION__/$(VERSION)/g' $(MAN_DIR)/togler.1
	sed -i 's/0.0.0/$(VERSION)/g' $(BUILD_DIR)/DEBIAN/control
	chmod +x $(BIN_DIR)/togler

build-deb:
	@echo "Building .deb package..."
	dpkg-deb --build $(BUILD_DIR) $(BUILD_DIR).deb

clean:
	@echo "Cleaning up..."
	rm -rf $(BUILD_DIR) $(BUILD_DIR).deb

