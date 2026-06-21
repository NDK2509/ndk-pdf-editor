#!/bin/bash
set -e

# Configuration
APP_NAME="pdf-editor"
BINARY_NAME="pdf_editor"
FLUTTER_BIN="$HOME/flutter-sdk/bin/flutter"
PROJECT_ROOT="$(pwd)"
BUILD_OUTPUT_DIR="$PROJECT_ROOT/build/packages"
TEMP_BUILD_DIR="$PROJECT_ROOT/build/packaging_temp"

echo "=================================================="
echo "         Packaging PDF Editor (.deb)              "
echo "=================================================="

# Ensure Flutter is built in release mode
echo "[1/3] Building Flutter project in release mode..."
if [ ! -f "$FLUTTER_BIN" ]; then
    if which flutter >/dev/null; then
        FLUTTER_BIN="flutter"
    else
        echo "Error: Flutter SDK not found at $FLUTTER_BIN or in PATH."
        exit 1
    fi
fi

$FLUTTER_BIN build linux --release

BUNDLE_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"
if [ ! -d "$BUNDLE_DIR" ]; then
    echo "Error: Release bundle directory not found at $BUNDLE_DIR"
    exit 1
fi

# Setup output folder
mkdir -p "$BUILD_OUTPUT_DIR"
rm -rf "$TEMP_BUILD_DIR"
mkdir -p "$TEMP_BUILD_DIR"

# Build Debian (.deb) Package
echo -e "\n[2/3] Packaging to Debian (.deb)..."
DEB_DIR="$TEMP_BUILD_DIR/deb"
mkdir -p "$DEB_DIR/DEBIAN"
mkdir -p "$DEB_DIR/usr/bin"
mkdir -p "$DEB_DIR/usr/share/$APP_NAME"
mkdir -p "$DEB_DIR/usr/share/applications"
mkdir -p "$DEB_DIR/usr/share/pixmaps"

# Copy Flutter release bundle files
cp -r "$BUNDLE_DIR"/* "$DEB_DIR/usr/share/$APP_NAME/"

# Copy Icon (create a fallback if not exists)
if [ -f "$PROJECT_ROOT/web/icons/Icon-512.png" ]; then
    cp "$PROJECT_ROOT/web/icons/Icon-512.png" "$DEB_DIR/usr/share/pixmaps/$APP_NAME.png"
else
    # Try web/favicon.png or any other icon if exists, or create a mock icon placeholder
    mkdir -p "$PROJECT_ROOT/web/icons"
    # Fallback to copy an icon or touch one
    touch "$DEB_DIR/usr/share/pixmaps/$APP_NAME.png"
fi

# Create launcher script
cat << EOF > "$DEB_DIR/usr/bin/$APP_NAME"
#!/bin/sh
# Launch PDF Editor from installation directory
exec /usr/share/$APP_NAME/$BINARY_NAME "\$@"
EOF
chmod +x "$DEB_DIR/usr/bin/$APP_NAME"

# Create .desktop file
cat << EOF > "$DEB_DIR/usr/share/applications/$APP_NAME.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=PDF Editor
Comment=A premium, dark-themed PDF editor and annotator by Flutter.
Exec=$APP_NAME %U
Icon=$APP_NAME
Terminal=false
MimeType=application/pdf;
Categories=Office;Utility;
EOF

# Create Debian control file
cat << EOF > "$DEB_DIR/DEBIAN/control"
Package: $APP_NAME
Version: 1.0.0
Architecture: amd64
Maintainer: NDK Developer <ndk@example.com>
Depends: libgtk-3-0, liblzma5, libglib2.0-0, zenity
Description: PDF Editor
 A beautiful, modern desktop PDF editor with shapes, freehand drawing, text, highlighting, and printing support.
EOF

# Build DEB
dpkg-deb --build "$DEB_DIR" "$BUILD_OUTPUT_DIR/${APP_NAME}_1.0.0_amd64.deb"
echo "Success: Debian package created at $BUILD_OUTPUT_DIR/${APP_NAME}_1.0.0_amd64.deb"

# Clean up temp
rm -rf "$TEMP_BUILD_DIR"

echo -e "\n[3/3] Done! Package generated inside $BUILD_OUTPUT_DIR"
ls -lh "$BUILD_OUTPUT_DIR"
