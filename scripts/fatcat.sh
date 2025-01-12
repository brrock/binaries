#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Check architecture argument
ARCH=${1:-amd64} # Default to amd64
if [[ "$ARCH" != "amd64" && "$ARCH" != "arm64" ]]; then
    echo "Unsupported architecture: $ARCH"
    echo "Usage: $0 [amd64|arm64]"
    exit 1
fi

# Set up directories
BUILD_DIR="/tmp/build-fatcat"
INSTALL_DIR="$(pwd)/$ARCH/"
SRC_DIR="$BUILD_DIR/fatcat-src"
PREFIX_DIR="$BUILD_DIR/build"

# Clean up previous builds
if ls $ARCH/fatcat* 1> /dev/null 2>&1; then
    rm $ARCH/fatcat*
fi

if [ -d "$BUILD_DIR" ]; then
    rm -rf "$BUILD_DIR"
fi

# removing fatcat
if sudo ls $PREFIX_DIR/bin/fatcat* 1> /dev/null 2>&1; then
    sudo rm $PREFIX_DIR/bin/fatcat*
fi

# Install required dependencies
echo "Installing dependencies..."
if [[ -x "$(command -v apt)" ]]; then
    sudo apt update
    sudo apt install -y build-essential cmake
elif [[ -x "$(command -v pacman)" ]]; then
    sudo pacman -Syu --noconfirm base-devel cmake
else
    echo "Unsupported package manager. Install build tools and dependencies manually."
    exit 1
fi

# Clone Fatcat source code
echo "Cloning Fatcat source code..."
git clone https://github.com/Gregwar/fatcat.git "$SRC_DIR"
cd "$SRC_DIR"
git checkout $(git describe --tags $(git rev-list --tags --max-count=1)) # Checkout the latest tag

# Create build directory
mkdir -p "$PREFIX_DIR"
cd "$PREFIX_DIR"

# Configure build options
echo "Configuring build for $ARCH..."
BUILD_ARCH=$([[ "$ARCH" == "amd64" ]] && echo "x86_64" || echo "aarch64")
cmake "$SRC_DIR" -DCMAKE_INSTALL_PREFIX="$PREFIX_DIR" -DCMAKE_BUILD_TYPE=Release -DCMAKE_SYSTEM_PROCESSOR="$BUILD_ARCH"

# Compile and install
echo "Building Fatcat for $ARCH..."
make  --j$(nproc)
make install

# Final message
echo "Fatcat built successfully for $ARCH!"
echo "Binaries are located in $INSTALL_DIR/"
cp $PREFIX_DIR/bin/* $INSTALL_DIR
