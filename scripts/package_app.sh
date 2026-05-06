#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/.build/arm64-apple-macosx/release"
APP_DIR="$ROOT/dist/LifeTracker.app"
ICON_SRC="$ROOT/Sources/LifeTrackerMac/Resources/iconLife.png"
ICONSET="$ROOT/.build/iconLife.iconset"
ICNS="$ROOT/.build/iconLife.icns"

cd "$ROOT"
swift scripts/render_icon.swift "$ICON_SRC"

if [[ -r "$HOME/Downloads/search icon.png" ]]; then
  swift scripts/crop_search_icon.swift "$HOME/Downloads/search icon.png" "$ROOT/Sources/LifeTrackerMac/Resources/searchIcon.png"
else
  echo "Keeping existing menu bar icon: search icon source not found"
fi
swift build -c release

rm -rf "$ICONSET" "$ICNS" "$APP_DIR"
mkdir -p "$ICONSET" "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

sips -z 16 16 "$ICON_SRC" --out "$ICONSET/icon_16x16.png" >/dev/null
sips -z 32 32 "$ICON_SRC" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$ICON_SRC" --out "$ICONSET/icon_32x32.png" >/dev/null
sips -z 64 64 "$ICON_SRC" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$ICON_SRC" --out "$ICONSET/icon_128x128.png" >/dev/null
sips -z 256 256 "$ICON_SRC" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$ICON_SRC" --out "$ICONSET/icon_256x256.png" >/dev/null
sips -z 512 512 "$ICON_SRC" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$ICON_SRC" --out "$ICONSET/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$ICON_SRC" --out "$ICONSET/icon_512x512@2x.png" >/dev/null
iconutil -c icns "$ICONSET" -o "$ICNS"

cp "$BUILD_DIR/LifeTrackerMac" "$APP_DIR/Contents/MacOS/LifeTrackerMac"
cp "$ICNS" "$APP_DIR/Contents/Resources/iconLife.icns"
cp "$ICON_SRC" "$APP_DIR/Contents/Resources/iconLife.png"
cp "$ROOT/Sources/LifeTrackerMac/Resources/searchIcon.png" "$APP_DIR/Contents/Resources/searchIcon.png"
cp -R "$BUILD_DIR/LifeTrackerMac_LifeTrackerMac.bundle" "$APP_DIR/LifeTrackerMac_LifeTrackerMac.bundle"

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>LifeTrackerMac</string>
  <key>CFBundleIconFile</key>
  <string>iconLife</string>
  <key>CFBundleIdentifier</key>
  <string>com.vidvuds.lifetracker</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>LifeTracker</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSMultipleInstancesProhibited</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

cat > "$APP_DIR/Contents/PkgInfo" <<'PKG'
APPL????
PKG

echo "$APP_DIR"
