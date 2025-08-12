# Makefile

VERSION := $(shell cat VERSION)
BUILD_DIR := build/togler_$(VERSION)_all
BIN_DIR := $(BUILD_DIR)/usr/bin
LIB_DIR := $(BUILD_DIR)/usr/lib/togler
MAN_DIR := $(BUILD_DIR)/usr/share/man/man1
COMPLETION_DIR := $(BUILD_DIR)/usr/share/bash-completion/completions
EXTENSION_DIR := $(BUILD_DIR)/usr/share/togler/extension

all: $(BUILD_DIR).deb

$(BUILD_DIR).deb: prepare substitute build-deb

prepare:
	@echo "Creating build directories for version $(VERSION)..."
	mkdir -p $(BIN_DIR)
	mkdir -p $(LIB_DIR)
	mkdir -p $(BUILD_DIR)/usr/share/man/man1
	mkdir -p $(COMPLETION_DIR)
	mkdir -p $(EXTENSION_DIR)
	cp -r DEBIAN $(BUILD_DIR)/
	cp src/togler $(BIN_DIR)/togler
	cp src/lib/* $(LIB_DIR)/
	cp man/togler.1 $(MAN_DIR)/togler.1
	cp completions/togler $(COMPLETION_DIR)/togler
	cp extensions/* $(EXTENSION_DIR)/

substitute:
	@echo "Replacing version placeholders with $(VERSION)..."
	sed -i 's/__VERSION__/$(VERSION)/g' $(BIN_DIR)/togler
	sed -i 's/__VERSION__/$(VERSION)/g' $(LIB_DIR)/*.sh
	sed -i 's/__VERSION__/$(VERSION)/g' $(MAN_DIR)/togler.1
	sed -i 's/__VERSION__/$(VERSION)/g' $(EXTENSION_DIR)/metadata.json
	sed -i 's/0.0.0/$(VERSION)/g' $(BUILD_DIR)/DEBIAN/control
	chmod +x $(BIN_DIR)/togler

build-deb:
	@echo "Building .deb package..."
	dpkg-deb --build $(BUILD_DIR) $(BUILD_DIR).deb

clean:
	@echo "Cleaning up..."
	rm -rf $(BUILD_DIR) $(BUILD_DIR).deb

# Development helpers
install-extension-dev:
	@echo "Installing extension for development..."
	mkdir -p ~/.local/share/gnome-shell/extensions/togler@local
	cp extensions/* ~/.local/share/gnome-shell/extensions/togler@local/
	@echo "Extension installed. Restart GNOME Shell with Alt+F2, 'r', Enter"

uninstall-extension-dev:
	@echo "Removing development extension..."
	rm -rf ~/.local/share/gnome-shell/extensions/togler@local
	@echo "Extension removed."
