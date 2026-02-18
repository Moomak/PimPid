#!/bin/bash

# PimPid Release Build Script
# Build และสร้าง .app bundle สำหรับ macOS
# รันจากโฟลเดอร์ macos/ หรือจาก root ของโปรเจกต์

set -e

VERSION="${PIMPID_VERSION:-1.6.4}"
BUILD="${PIMPID_BUILD:-20}"

# หา root directory ของโปรเจกต์
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MACOS_DIR="$SCRIPT_DIR"
RELEASE_DIR="$PROJECT_ROOT/releases/macos"

echo "🔨 Building PimPid release ($VERSION / $BUILD)..."

# 1. Build release binary (ต้องอยู่ในโฟลเดอร์ที่มี Package.swift)
echo "📦 Building release binary..."
cd "$MACOS_DIR"
swift build -c release

# 2. สร้างโครงสร้าง .app bundle
echo "🗂️  Creating .app bundle structure..."
rm -rf "$RELEASE_DIR/PimPid.app"
mkdir -p "$RELEASE_DIR/PimPid.app/Contents/MacOS"
mkdir -p "$RELEASE_DIR/PimPid.app/Contents/Resources"

# 3. Copy executable
echo "📋 Copying executable..."
cp "$MACOS_DIR/.build/release/PimPid" "$RELEASE_DIR/PimPid.app/Contents/MacOS/"

# 4. Copy Info.plist
echo "📋 Creating Info.plist..."
if [[ -f "$MACOS_DIR/PimPid/Info.plist" ]]; then
  cp "$MACOS_DIR/PimPid/Info.plist" "$RELEASE_DIR/PimPid.app/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$RELEASE_DIR/PimPid.app/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD" "$RELEASE_DIR/PimPid.app/Contents/Info.plist"
else
  cat > "$RELEASE_DIR/PimPid.app/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>PimPid</string>
	<key>CFBundleIdentifier</key>
	<string>com.pimpid</string>
	<key>CFBundleName</key>
	<string>PimPid</string>
	<key>CFBundleIconFile</key>
	<string>PimPid</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>$VERSION</string>
	<key>CFBundleVersion</key>
	<string>$BUILD</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>LSUIElement</key>
	<true/>
	<key>NSServices</key>
	<array>
		<dict>
			<key>NSMenuItem</key>
			<dict><key>default</key><string>Convert Selected Text - PimPid</string></dict>
			<key>NSMessage</key>
			<string>convertSelectedText</string>
			<key>NSPortName</key>
			<string>PimPid</string>
			<key>NSSendTypes</key>
			<array><string>NSPasteboardTypeString</string></array>
			<key>NSReturnTypes</key>
			<array><string>NSPasteboardTypeString</string></array>
		</dict>
	</array>
</dict>
</plist>
EOF
fi

# 5. Copy icon
echo "🎨 Copying icon..."
cp "$MACOS_DIR/PimPid/Icon/PimPid.icns" "$RELEASE_DIR/PimPid.app/Contents/Resources/"

# 5b. Copy Thai words list (optional)
[ -f "$MACOS_DIR/PimPid/Resources/ThaiWords.txt" ] && cp "$MACOS_DIR/PimPid/Resources/ThaiWords.txt" "$RELEASE_DIR/PimPid.app/Contents/Resources/"

# 6. Refresh Services registration
echo "🔄 Refreshing Services registration..."
/System/Library/CoreServices/pbs -update

# 7. แสดงข้อมูล
echo ""
echo "✅ Build complete!"
echo "📍 Location: $RELEASE_DIR/PimPid.app"
echo ""
ls -lh "$RELEASE_DIR/PimPid.app/Contents/MacOS/PimPid"
echo ""
echo "🚀 To run: open $RELEASE_DIR/PimPid.app"
