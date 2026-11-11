#!/bin/bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_dir"
export CLANG_MODULE_CACHE_PATH="$project_dir/.build/module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$project_dir/.build/module-cache"
swift build -c release --disable-sandbox
app_path="$project_dir/dist/Quiet Line.app"
mkdir -p "$app_path/Contents/MacOS"
cp .build/release/QuietLine "$app_path/Contents/MacOS/QuietLine"
cat > "$app_path/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>CFBundleExecutable</key><string>QuietLine</string>
    <key>CFBundleIdentifier</key><string>dev.quietline.demo</string>
    <key>CFBundleName</key><string>Quiet Line</string>
    <key>CFBundleDisplayName</key><string>Quiet Line</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.3.0</string>
    <key>CFBundleVersion</key><string>3</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST
codesign --force --sign - "$app_path"
ditto -c -k --keepParent "$app_path" "$project_dir/dist/Quiet-Line-macOS.zip"
printf '\nBuilt: %s\n' "$app_path"
