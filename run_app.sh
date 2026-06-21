#!/bin/bash
set -e

# Path to Flutter binary
FLUTTER_BIN="$HOME/flutter-sdk/bin/flutter"

if [ ! -f "$FLUTTER_BIN" ]; then
    if which flutter >/dev/null; then
        FLUTTER_BIN="flutter"
    else
        echo "Flutter SDK not found. Setting it up automatically..."
        ./setup_flutter.sh
        FLUTTER_BIN="$HOME/flutter-sdk/bin/flutter"
    fi
fi

echo "Starting PDF Editor..."
$FLUTTER_BIN run -d linux
