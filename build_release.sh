#!/bin/bash

# PimPid Release Build Script
# Build และสร้าง .app bundle สำหรับ macOS
# Task 86: อ่านเวอร์ชันจากด้านบน — แก้แค่ที่นี้แล้วใช้ใน plist

set -e  # หยุดทันทีถ้ามี error

VERSION="${PIMPID_VERSION:-1.5.9}"
BUILD="${PIMPID_BUILD:-15}"

echo "🔨 Building PimPid release ($VERSION / $BUILD)..."

# 1. Build release binary
echo "📦 Building release binary..."
swift build -c release

# 2. สร้างโครงสร้าง .app bundle
echo "🗂️  Creating .app bundle structure..."
rm -rf release/PimPid.app
mkdir -p release/PimPid.app/Contents/MacOS
mkdir -p release/PimPid.app/Contents/Resources

# 3. Copy executable
echo "📋 Copying executable..."
cp .build/release/PimPid release/PimPid.app/Contents/MacOS/

# 4. Copy Info.plist (task 102: ใช้ PimPid/Info.plist ถ้ามี แล้วตั้ง version/build)
echo "📋 Creating Info.plist..."
if [[ -f PimPid/Info.plist ]]; then
  cp PimPid/Info.plist release/PimPid.app/Contents/Info.plist
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" release/PimPid.app/Contents/Info.plist
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD" release/PimPid.app/Contents/Info.plist
else
  cat > release/PimPid.app/Contents/Info.plist << EOF
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
cp PimPid/Icon/PimPid.icns release/PimPid.app/Contents/Resources/

# 5b. Copy Thai words list (optional; แอปมีคำในตัวอยู่แล้ว)
[ -f PimPid/Resources/ThaiWords.txt ] && cp PimPid/Resources/ThaiWords.txt release/PimPid.app/Contents/Resources/

# 6. Refresh Services registration
echo "🔄 Refreshing Services registration..."
/System/Library/CoreServices/pbs -update

# 7. แสดงข้อมูล
echo ""
echo "✅ Build complete!"
echo "📍 Location: release/PimPid.app"
echo ""
ls -lh release/PimPid.app/Contents/MacOS/PimPid
echo ""
echo "🚀 To run: open release/PimPid.app"
