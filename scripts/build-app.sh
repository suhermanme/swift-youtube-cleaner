#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIGURATION="${1:-release}"
PRODUCT="YouTubeCleaner"
APP_DIR="$PROJECT_DIR/dist/YouTube Cleaner.app"
BUILD_DIR="$PROJECT_DIR/.build/app-bundle"

cd "$PROJECT_DIR"
export CLANG_MODULE_CACHE_PATH="$BUILD_DIR/clang-module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$BUILD_DIR/swiftpm-module-cache"
xcrun swift build --disable-sandbox --scratch-path "$BUILD_DIR" -c "$CONFIGURATION" --product "$PRODUCT"
BIN_DIR="$(xcrun swift build --disable-sandbox --scratch-path "$BUILD_DIR" -c "$CONFIGURATION" --show-bin-path)"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN_DIR/$PRODUCT" "$APP_DIR/Contents/MacOS/$PRODUCT"
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"

codesign --force --deep --sign - "$APP_DIR"
echo "$APP_DIR"
