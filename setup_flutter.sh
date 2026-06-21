#!/bin/bash
set -e

INSTALL_DIR="$HOME/flutter-sdk"
FLUTTER_BIN="$INSTALL_DIR/bin/flutter"

echo "=================================================="
echo "         Flutter Linux Setup Script               "
echo "=================================================="

# 1. Install System Dependencies
echo "[1/3] Checking system dependencies..."
DEPS="git curl unzip xz-utils zip libglu1-mesa clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev"

MISSING_DEPS=""
for dep in $DEPS; do
    if ! dpkg -l | grep -q "^ii  $dep " && ! which $dep >/dev/null 2>&1; then
        # Check dev packages separately as dpkg -l is safer
        if ! dpkg -s "$dep" >/dev/null 2>&1; then
            MISSING_DEPS="$MISSING_DEPS $dep"
        fi
    fi
done

if [ -n "$MISSING_DEPS" ]; then
    echo "The following dependencies are missing: $MISSING_DEPS"
    echo "Attempting to install dependencies. This requires sudo privileges..."
    if [ "$EUID" -ne 0 ]; then
        sudo apt-get update && sudo apt-get install -y $MISSING_DEPS
    else
        apt-get update && apt-get install -y $MISSING_DEPS
    fi
else
    echo "All system dependencies are already satisfied."
fi

# 2. Download and Setup Flutter SDK
if [ -f "$FLUTTER_BIN" ]; then
    echo "[2/3] Flutter SDK is already present at $INSTALL_DIR."
else
    echo "[2/3] Flutter SDK not found. Installing to $INSTALL_DIR..."
    mkdir -p "$HOME/temp_flutter"
    cd "$HOME/temp_flutter"
    
    echo "Fetching the latest stable version of Flutter..."
    # Fetch latest stable branch release info from GitHub or use static url
    # Using git clone is often the most robust way to ensure we get the correct architecture and channel
    git clone https://github.com/flutter/flutter.git -b stable "$INSTALL_DIR"
    
    cd "$PROJECT_ROOT"
    rm -rf "$HOME/temp_flutter"
fi

# 3. Configure Flutter
echo "[3/3] Configuring Flutter..."
export PATH="$INSTALL_DIR/bin:$PATH"

"$FLUTTER_BIN" doctor
"$FLUTTER_BIN" config --enable-linux-desktop

# Export PATH suggestions
echo "=================================================="
echo "Flutter setup completed successfully!"
echo "Please add Flutter to your PATH by adding the following line to your ~/.bashrc or ~/.zshrc file:"
echo "  export PATH=\"\$PATH:$INSTALL_DIR/bin\""
echo "=================================================="
