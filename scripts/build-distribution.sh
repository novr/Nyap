#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build/arm64-apple-macosx/release"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="PomodoroCat"
APP_DIR="$DIST_DIR/$APP_NAME.app"
ZIP_PATH="$DIST_DIR/$APP_NAME-macOS.zip"
EXECUTABLE_PATH="$BUILD_DIR/$APP_NAME"
RESOURCE_BUNDLE_PATH="$BUILD_DIR/${APP_NAME}_${APP_NAME}.bundle"

echo "Building release binary..."
swift build -c release --package-path "$ROOT_DIR"

if [[ ! -x "$EXECUTABLE_PATH" ]]; then
  echo "Executable not found: $EXECUTABLE_PATH" >&2
  exit 1
fi

if [[ ! -d "$RESOURCE_BUNDLE_PATH" ]]; then
  echo "Resource bundle not found: $RESOURCE_BUNDLE_PATH" >&2
  exit 1
fi

echo "Preparing app bundle..."
rm -rf "$APP_DIR" "$ZIP_PATH"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$EXECUTABLE_PATH" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp -R "$RESOURCE_BUNDLE_PATH" "$APP_DIR/${APP_NAME}_${APP_NAME}.bundle"

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>PomodoroCat</string>
    <key>CFBundleDisplayName</key>
    <string>PomodoroCat</string>
    <key>CFBundleExecutable</key>
    <string>PomodoroCat</string>
    <key>CFBundleIdentifier</key>
    <string>com.pomodorocat.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

if [[ -n "${SIGN_IDENTITY:-}" ]]; then
  echo "Signing app bundle with identity: $SIGN_IDENTITY"
  codesign --force --deep --sign "$SIGN_IDENTITY" "$APP_DIR"
else
  echo "Skipping codesign (set SIGN_IDENTITY to enable signing)."
fi

echo "Creating distributable zip..."
mkdir -p "$DIST_DIR"
ditto -c -k --keepParent "$APP_DIR" "$ZIP_PATH"

echo ""
echo "Done."
echo "App: $APP_DIR"
echo "ZIP: $ZIP_PATH"
