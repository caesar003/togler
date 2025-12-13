#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

VERSION=$(cat VERSION)

print_header() {
  echo -e "${BLUE}================================${NC}"
  echo -e "${BLUE}  Togler Build Script v${VERSION}${NC}"
  echo -e "${BLUE}================================${NC}"
  echo ""
}

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

print_info() {
  echo -e "${YELLOW}→${NC} $1"
}

check_dependencies() {
  print_info "Checking dependencies..."

  local missing_deps=()

  if ! command -v dpkg-deb &>/dev/null; then
    missing_deps+=("dpkg-deb")
  fi

  if ! command -v gzip &>/dev/null; then
    missing_deps+=("gzip")
  fi

  if [ ${#missing_deps[@]} -ne 0 ]; then
    print_error "Missing dependencies: ${missing_deps[*]}"
    echo ""
    echo "Install with:"
    echo "  sudo apt-get install dpkg gzip"
    exit 1
  fi

  print_success "All dependencies found"
}

build_package() {
  print_info "Building Debian package..."

  if make deb; then
    print_success "Package built successfully!"
    echo ""
    echo "Package location: build/togler_${VERSION}_all.deb"
    echo ""
    echo "To install:"
    echo "  sudo dpkg -i build/togler_${VERSION}_all.deb"
    echo ""
    echo "Or use apt to handle dependencies:"
    echo "  sudo apt install ./build/togler_${VERSION}_all.deb"
  else
    print_error "Build failed!"
    exit 1
  fi
}

clean_build() {
  print_info "Cleaning build directory..."
  make clean
  print_success "Clean complete"
}

show_help() {
  cat <<EOF
Usage: ./build.sh [OPTION]

Build script for Togler package

Options:
  -b, --build     Build the Debian package (default)
  -c, --clean     Clean build artifacts
  -h, --help      Show this help message
  -v, --version   Show version

Examples:
  ./build.sh              # Build package
  ./build.sh --clean      # Clean build directory
EOF
}

main() {
  print_header

  case "${1:-build}" in
  -b | --build | build)
    check_dependencies
    build_package
    ;;
  -c | --clean | clean)
    clean_build
    ;;
  -v | --version | version)
    echo "Togler v${VERSION}"
    ;;
  -h | --help | help)
    show_help
    ;;
  *)
    print_error "Unknown option: $1"
    echo ""
    show_help
    exit 1
    ;;
  esac
}

main "$@"
