#!/bin/bash
set -e

# Path to Flutter binary
FLUTTER_BIN="$HOME/flutter-sdk/bin/flutter"

if [ ! -f "$FLUTTER_BIN" ]; then
    if which flutter >/dev/null; then
        FLUTTER_BIN="flutter"
    else
        echo "Error: Flutter SDK not found at $FLUTTER_BIN or in PATH."
        exit 1
    fi
fi

echo "Starting PDF Editor..."
$FLUTTER_BIN run -d linux
