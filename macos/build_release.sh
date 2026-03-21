#!/bin/bash

# PimPid Release Build Script
# Build, ad-hoc sign, สร้าง DMG + zip สำหรับ macOS
# รันจากโฟลเดอร์ macos/ หรือจาก root ของโปรเจกต์

set -e

VERSION="${PIMPID_VERSION:-1.7.0}"
BUILD="${PIMPID_BUILD:-23}"

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

# 7. Ad-hoc code signing
# เปลี่ยนจาก "damaged and can't be opened" เป็น "unidentified developer"
# ผู้ใช้สามารถกด Right-click > Open เพื่อเปิดได้
echo "🔏 Ad-hoc code signing..."
codesign --force --deep --sign - "$RELEASE_DIR/PimPid.app"
echo "   Verifying signature..."
codesign --verify --verbose "$RELEASE_DIR/PimPid.app" 2>&1 || true

# 8. Remove quarantine attribute
echo "🔓 Removing quarantine attribute..."
xattr -cr "$RELEASE_DIR/PimPid.app" 2>/dev/null || true

# 9. Create DMG for distribution
echo "💿 Creating DMG..."
DMG_NAME="PimPid-${VERSION}-macOS.dmg"
DMG_TEMP="$RELEASE_DIR/dmg_temp"
rm -rf "$DMG_TEMP" "$RELEASE_DIR/$DMG_NAME"
mkdir -p "$DMG_TEMP"
cp -R "$RELEASE_DIR/PimPid.app" "$DMG_TEMP/"
ln -s /Applications "$DMG_TEMP/Applications"

# สร้าง README สำหรับ first-time users
cat > "$DMG_TEMP/README — วิธีติดตั้ง.txt" << 'READMEEOF'
PimPid — วิธีติดตั้ง / Installation Guide
==========================================

1. ลาก PimPid.app ไปไว้ใน Applications
   Drag PimPid.app to Applications folder

2. เปิด PimPid จาก Applications
   Open PimPid from Applications

3. ถ้า macOS แสดง "unidentified developer":
   If macOS shows "unidentified developer":

   วิธี A: คลิกขวา (Right-click) ที่ PimPid.app > เลือก Open > กด Open
   Method A: Right-click PimPid.app > Open > Click Open

   วิธี B: ไปที่ System Settings > Privacy & Security > เลื่อนลงหา "PimPid" > กด Open Anyway
   Method B: Go to System Settings > Privacy & Security > Scroll down > Click "Open Anyway"

4. อนุญาต Accessibility permission เมื่อระบบถาม
   Grant Accessibility permission when prompted

เสร็จเรียบร้อย! PimPid จะอยู่ใน menu bar ด้านบน
Done! PimPid will appear in the menu bar at the top.
READMEEOF

hdiutil create -volname "PimPid $VERSION" \
  -srcfolder "$DMG_TEMP" \
  -ov -format UDZO \
  "$RELEASE_DIR/$DMG_NAME" \
  2>/dev/null

rm -rf "$DMG_TEMP"

# 10. Create zip as fallback
echo "📦 Creating zip archive..."
ZIP_NAME="PimPid-${VERSION}-macOS.zip"
cd "$RELEASE_DIR"
rm -f "$ZIP_NAME"
ditto -c -k --sequesterRsrc --keepParent "PimPid.app" "$ZIP_NAME"

# 11. แสดงข้อมูล
echo ""
echo "✅ Build complete!"
echo "📍 App: $RELEASE_DIR/PimPid.app"
echo "💿 DMG: $RELEASE_DIR/$DMG_NAME"
echo "📦 Zip: $RELEASE_DIR/$ZIP_NAME"
echo ""
ls -lh "$RELEASE_DIR/PimPid.app/Contents/MacOS/PimPid"
ls -lh "$RELEASE_DIR/$DMG_NAME"
ls -lh "$RELEASE_DIR/$ZIP_NAME"
echo ""
echo "🔏 Signed: ad-hoc (users Right-click > Open to bypass Gatekeeper)"
echo "🚀 To run: open $RELEASE_DIR/PimPid.app"
