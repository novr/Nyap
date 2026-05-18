#!/usr/bin/env zsh
set -euo pipefail

# Submits dist/Nyap-macOS.zip to Apple Notary Service, staples the ticket to dist/Nyap.app,
# then rebuilds the zip so distributed builds pass Gatekeeper without "unidentified developer".

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/Nyap.app"
ZIP_PATH="$DIST_DIR/Nyap-macOS.zip"
PROFILE="${NOTARY_PROFILE:-}"

if [[ -z "$PROFILE" ]]; then
  echo "Set NOTARY_PROFILE to a notarytool keychain profile name." >&2
  echo "Example: xcrun notarytool store-credentials --apple-id ... --password ... --team-id ... nyap-notary" >&2
  echo "Or API key: store-credentials --key ... --key-id ... --issuer ... nyap-notary  (last arg is profile name)" >&2
  exit 1
fi

if [[ ! -d "$APP_DIR" ]]; then
  echo "Missing $APP_DIR — run scripts/build-distribution.sh with SIGN_IDENTITY first." >&2
  exit 1
fi

if [[ ! -f "$ZIP_PATH" ]]; then
  echo "Missing $ZIP_PATH — run scripts/build-distribution.sh first." >&2
  exit 1
fi

echo "Submitting for notarization: $ZIP_PATH"
xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$PROFILE" --wait

echo "Stapling notarization ticket to: $APP_DIR"
xcrun stapler staple "$APP_DIR"

echo "Recreating zip with stapled app..."
ditto -c -k --keepParent "$APP_DIR" "$ZIP_PATH"

echo ""
echo "Done. Distribute: $ZIP_PATH"
