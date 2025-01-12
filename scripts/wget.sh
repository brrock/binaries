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
BUILD_DIR="/tmp/build-wget"
INSTALL_DIR="$(pwd)/$ARCH/"
SRC_DIR="$BUILD_DIR/wget-src"
PREFIX_DIR="$BUILD_DIR/build"

# Clean up previous builds
if ls $ARCH/wget* 1> /dev/null 2>&1; then
    rm $ARCH/wget*
fi

if [ -d "$BUILD_DIR" ]; then
    rm -rf "$BUILD_DIR"
fi

# removing wget
if sudo ls $PREFIX_DIR/bin/wget* 1> /dev/null 2>&1; then
    sudo rm $PREFIX_DIR/bin/wget*
fi

# Install required dependencies
echo "Installing dependencies..."
if [[ -x "$(command -v apt)" ]]; then
    sudo apt update
    sudo apt install -y build-essential autoconf libtool pkg-config zlib1g-dev libssl-dev libpcre3-dev
elif [[ -x "$(command -v pacman)" ]]; then
    sudo pacman -Syu --noconfirm base-devel autoconf libtool zlib openssl pcre
else
    echo "Unsupported package manager. Install build tools and dependencies manually."
    exit 1
fi

# Clone wget source code
echo "Cloning wget source code..."
git clone https://git.savannah.gnu.org/git/wget.git "$SRC_DIR"
cd "$SRC_DIR"
git checkout $(git describe --tags $(git rev-list --tags --max-count=1)) # Checkout the latest tag

# Configure build options
echo "Configuring build for $ARCH..."
BUILD_ARCH=$([[ "$ARCH" == "amd64" ]] && echo "x86_64" || echo "aarch64")
autoreconf -fi
./configure --prefix="$PREFIX_DIR" \
            --host="$BUILD_ARCH-linux-gnu" \
            --with-ssl=openssl \
            --disable-shared \
            --enable-static \
            --disable-debug \
            --disable-dependency-tracking

# Compile and install
echo "Building wget for $ARCH..."
make -j$(nproc)
make install

# Final message
echo "wget built successfully for $ARCH!"
echo "Binaries are located in $INSTALL_DIR/"
cp $PREFIX_DIR/bin/wget* $INSTALL_DIR