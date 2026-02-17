#!/bin/bash

# PimPid Release Build Script (double-click version)
# Build และสร้าง .app bundle สำหรับ macOS

# เปลี่ยนไปที่ directory ที่ script อยู่
cd "$(dirname "$0")"

set -e

RELEASE_DIR="../releases/macos"

echo "🔨 Building PimPid release..."
echo "📂 Working directory: $(pwd)"
echo ""

# 1. Build release binary
echo "📦 Building release binary..."
swift build -c release

# 2. สร้างโครงสร้าง .app bundle
echo "🗂️  Creating .app bundle structure..."
rm -rf "$RELEASE_DIR/PimPid.app"
mkdir -p "$RELEASE_DIR/PimPid.app/Contents/MacOS"
mkdir -p "$RELEASE_DIR/PimPid.app/Contents/Resources"

# 3. Copy executable
echo "📋 Copying executable..."
cp .build/release/PimPid "$RELEASE_DIR/PimPid.app/Contents/MacOS/"

# 4. Copy Info.plist
echo "📋 Creating Info.plist..."
if [[ -f PimPid/Info.plist ]]; then
  cp PimPid/Info.plist "$RELEASE_DIR/PimPid.app/Contents/Info.plist"
else
  cat > "$RELEASE_DIR/PimPid.app/Contents/Info.plist" << 'EOF'
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
	<string>1.5.10</string>
	<key>CFBundleVersion</key>
	<string>16</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>LSUIElement</key>
	<true/>
</dict>
</plist>
EOF
fi

# 5. Copy icon
echo "🎨 Copying icon..."
cp PimPid/Icon/PimPid.icns "$RELEASE_DIR/PimPid.app/Contents/Resources/"

# 5b. Copy Thai words list (optional)
[ -f PimPid/Resources/ThaiWords.txt ] && cp PimPid/Resources/ThaiWords.txt "$RELEASE_DIR/PimPid.app/Contents/Resources/"

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
echo ""
echo "Press any key to close..."
read -n 1 -s
