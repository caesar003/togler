.PHONY: all build install uninstall clean deb help

# Read version from VERSION file
VERSION := $(shell cat VERSION)
PACKAGE_NAME := togler
DEB_FILE := $(PACKAGE_NAME)_$(VERSION)_all.deb

# Installation directories
PREFIX ?= /usr
BINDIR := $(PREFIX)/bin
MANDIR := $(PREFIX)/share/man/man1
COMPLETIONDIR := /etc/bash_completion.d
EXTENSIONDIR := $(PREFIX)/share/gnome-shell/extensions/togler@local

# Build directory structure
BUILDDIR := build
PKG_ROOT := $(BUILDDIR)/$(PACKAGE_NAME)_$(VERSION)

# Date for man page
BUILD_DATE := $(shell date +"%B %Y")

all: help

help:
	@echo "Togler v$(VERSION) - Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  make deb        - Build Debian package (.deb)"
	@echo "  make build      - Prepare build directory"
	@echo "  make install    - Install directly to system (requires sudo)"
	@echo "  make uninstall  - Uninstall from system (requires sudo)"
	@echo "  make clean      - Clean build artifacts"
	@echo "  make help       - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make deb                    # Build .deb package"
	@echo "  sudo make install           # Direct installation"
	@echo "  sudo dpkg -i $(DEB_FILE)    # Install .deb package"

build:
	@echo "Building togler v$(VERSION)..."
	@mkdir -p $(PKG_ROOT)
	@mkdir -p $(PKG_ROOT)/DEBIAN
	@mkdir -p $(PKG_ROOT)$(BINDIR)
	@mkdir -p $(PKG_ROOT)$(MANDIR)
	@mkdir -p $(PKG_ROOT)$(COMPLETIONDIR)
	@mkdir -p $(PKG_ROOT)$(EXTENSIONDIR)
	
	# Copy and process main script
	@echo "Processing main script..."
	@sed 's/__VERSION__/$(VERSION)/g' src/togler > $(PKG_ROOT)$(BINDIR)/togler
	@chmod +x $(PKG_ROOT)$(BINDIR)/togler
	
	# Copy and process man page
	@echo "Processing man page..."
	@sed -e 's/__VERSION__/$(VERSION)/g' \
	     -e 's/__DATE__/$(BUILD_DATE)/g' \
	     man/togler.1 > $(PKG_ROOT)$(MANDIR)/togler.1
	@gzip -f $(PKG_ROOT)$(MANDIR)/togler.1
	
	# Copy bash completion
	@echo "Installing bash completion..."
	@cp completions/togler.bash $(PKG_ROOT)$(COMPLETIONDIR)/togler
	
	# Copy and process GNOME Shell extension
	@echo "Installing GNOME Shell extension..."
	@cp gnome-shell-extension/extension.js $(PKG_ROOT)$(EXTENSIONDIR)/
	@sed 's/__VERSION__/$(VERSION)/g' \
	     gnome-shell-extension/metadata.json > $(PKG_ROOT)$(EXTENSIONDIR)/metadata.json
	
	# Copy and process DEBIAN control files
	@echo "Processing Debian control files..."
	@sed 's/__VERSION__/$(VERSION)/g' DEBIAN/control > $(PKG_ROOT)/DEBIAN/control
	@cp DEBIAN/postinst $(PKG_ROOT)/DEBIAN/postinst
	@cp DEBIAN/postrm $(PKG_ROOT)/DEBIAN/postrm
	@chmod +x $(PKG_ROOT)/DEBIAN/postinst
	@chmod +x $(PKG_ROOT)/DEBIAN/postrm
	
	@echo "Build complete: $(PKG_ROOT)"

deb: build
	@echo "Creating Debian package..."
	@dpkg-deb --build $(PKG_ROOT) $(BUILDDIR)/$(DEB_FILE)
	@echo ""
	@echo "✓ Package created: $(BUILDDIR)/$(DEB_FILE)"
	@echo ""
	@echo "To install, run:"
	@echo "  sudo dpkg -i $(BUILDDIR)/$(DEB_FILE)"

install: build
	@echo "Installing togler v$(VERSION)..."
	@install -m 755 $(PKG_ROOT)$(BINDIR)/togler $(BINDIR)/togler
	@install -m 644 $(PKG_ROOT)$(MANDIR)/togler.1.gz $(MANDIR)/togler.1.gz
	@install -m 644 $(PKG_ROOT)$(COMPLETIONDIR)/togler $(COMPLETIONDIR)/togler
	@mkdir -p $(EXTENSIONDIR)
	@cp -r $(PKG_ROOT)$(EXTENSIONDIR)/* $(EXTENSIONDIR)/
	@echo ""
	@echo "✓ Togler installed successfully!"
	@echo ""
	@echo "Enable the GNOME Shell extension:"
	@echo "  gnome-extensions enable togler@local"
	@echo ""
	@echo "Run 'togler --help' for usage information."

uninstall:
	@echo "Uninstalling togler..."
	@rm -f $(BINDIR)/togler
	@rm -f $(MANDIR)/togler.1.gz
	@rm -f $(COMPLETIONDIR)/togler
	@rm -rf $(EXTENSIONDIR)
	@echo ""
	@echo "✓ Togler uninstalled."
	@echo ""
	@echo "To remove user configurations:"
	@echo "  rm -rf ~/.config/togler"

clean:
	@echo "Cleaning build directory..."
	@rm -rf $(BUILDDIR)
	@echo "✓ Clean complete."

version:
	@echo $(VERSION)
