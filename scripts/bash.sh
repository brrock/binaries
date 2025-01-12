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
BUILD_DIR="/tmp/build-bash"
INSTALL_DIR="$(pwd)/$ARCH/"
SRC_DIR="$BUILD_DIR/bash-src"
PREFIX_DIR="$BUILD_DIR/build"

# Clean up previous builds
if ls $ARCH/bash* 1> /dev/null 2>&1; then
        rm $ARCH/bash*
fi

if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
fi

# removing bash
if sudo ls $PREFIX_DIR/bin/bash* 1> /dev/null 2>&1; then
        sudo rm $PREFIX_DIR/bin/bash*
fi

# Install required dependencies
echo "Installing dependencies..."
if [[ -x "$(command -v apt)" ]]; then
    sudo apt update
    sudo apt install -y build-essential autoconf libtool pkg-config
elif [[ -x "$(command -v pacman)" ]]; then
    sudo pacman -Syu --noconfirm base-devel autoconf libtool
else
    echo "Unsupported package manager. Install build tools and dependencies manually."
    exit 1
fi

# Clone Bash source code
echo "Cloning Bash source code..."
git clone https://git.savannah.gnu.org/git/bash.git "$SRC_DIR"
cd "$SRC_DIR"
git checkout $(git describe --tags $(git rev-list --tags --max-count=1)) # Checkout the latest tag

# Configure build options
echo "Configuring build for $ARCH..."
BUILD_ARCH=$([[ "$ARCH" == "amd64" ]] && echo "x86_64" || echo "aarch64")
./configure --prefix="$PREFIX_DIR" \
                        --host="$BUILD_ARCH-linux-gnu" \
                        --disable-shared \
                        --enable-static \
                        --disable-debug \
                        --disable-dependency-tracking

# Compile and install
echo "Building Bash for $ARCH..."
make -j$(nproc)
make install

# Final message
echo "Bash built successfully for $ARCH!"
echo "Binaries are located in $INSTALL_DIR/"
cp $PREFIX_DIR/bin/* $INSTALL_DIR