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
export UV_PYTHON_INSTALL_DIR="$BUILD_DIR/python-runtime"
rm -rf "$BUILD_DIR/python-runtime"
uv python install 3.14
PYTHON_RUNTIME=""
for candidate in "$BUILD_DIR"/python-runtime/cpython-3.14.*/bin/python3.14; do
  if [[ -x "$candidate" ]]; then
    PYTHON_RUNTIME="$candidate"
    break
  fi
done
if [[ -z "$PYTHON_RUNTIME" ]]; then
  echo "Could not locate the managed Python 3.14 runtime." >&2
  exit 1
fi
rm -rf "$BUILD_DIR/python-packages"
uv pip install --python "$PYTHON_RUNTIME" --target "$BUILD_DIR/python-packages" \
  'playwright>=1.55,<2' 'pydantic>=2.11,<3' 'rich>=14,<15' 'typer>=0.16,<1'
PYTHONPATH="$BUILD_DIR/python-packages" PLAYWRIGHT_BROWSERS_PATH="$BUILD_DIR/playwright-browsers" \
  "$PYTHON_RUNTIME" -m playwright install chromium
BIN_DIR="$(xcrun swift build --disable-sandbox --scratch-path "$BUILD_DIR" -c "$CONFIGURATION" --show-bin-path)"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources/PythonRuntime"
cp "$BIN_DIR/$PRODUCT" "$APP_DIR/Contents/MacOS/$PRODUCT"
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp -R "$PROJECT_DIR/Sources/YouTubeCleanerApp/youtube_cleaner" "$APP_DIR/Contents/Resources/youtube_cleaner"
cp -R "$BUILD_DIR/python-runtime"/cpython-3.14.* "$APP_DIR/Contents/Resources/PythonRuntime/"
cp -R "$BUILD_DIR/python-packages" "$APP_DIR/Contents/Resources/python-packages"
cp -R "$BUILD_DIR/playwright-browsers" "$APP_DIR/Contents/Resources/playwright-browsers"
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"

codesign --force --deep --sign - "$APP_DIR"
echo "$APP_DIR"
