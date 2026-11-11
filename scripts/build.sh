#!/bin/bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_dir"
export CLANG_MODULE_CACHE_PATH="$project_dir/.build/module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$project_dir/.build/module-cache"
version="$(cat VERSION)"
mode="${QUIETLINE_BUILD_MODE:-native}"
output_dir="${QUIETLINE_OUTPUT_DIR:-$project_dir/dist}"
mkdir -p "$output_dir"
slice_dir="$(mktemp -d "$output_dir/.quiet-line-slices.XXXXXX")"
trap 'rm -rf "$slice_dir"' EXIT

case "$mode" in
    native)
        swift build -c release --disable-sandbox
        binary_dir="$(swift build -c release --disable-sandbox --show-bin-path)"
        cp "$binary_dir/QuietLine" "$slice_dir/QuietLine"
        ;;
    universal)
        for architecture in arm64 x86_64; do
            triple="$architecture-apple-macosx14.0"
            swift build -c release --triple "$triple" --disable-sandbox
            binary_dir="$(swift build -c release --triple "$triple" --disable-sandbox --show-bin-path)"
            cp "$binary_dir/QuietLine" "$slice_dir/QuietLine-$architecture"
        done
        xcrun lipo -create "$slice_dir/QuietLine-arm64" "$slice_dir/QuietLine-x86_64" -output "$slice_dir/QuietLine"
        xcrun lipo "$slice_dir/QuietLine" -verify_arch arm64 x86_64
        ;;
    *)
        printf 'Unknown QUIETLINE_BUILD_MODE: %s\n' "$mode" >&2
        exit 1
        ;;
esac

# Release downloads do not need local debug object paths.
xcrun strip -S "$slice_dir/QuietLine"
app_path="$output_dir/Quiet Line.app"
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
cp "$slice_dir/QuietLine" "$app_path/Contents/MacOS/QuietLine"
cp Resources/AppIcon.icns "$app_path/Contents/Resources/AppIcon.icns"
python3 - "$app_path/Contents/Info.plist" "$version" <<'PY'
import plistlib, sys
metadata = {
    'CFBundleExecutable': 'QuietLine',
    'CFBundleIdentifier': 'dev.quietline.demo',
    'CFBundleName': 'Quiet Line',
    'CFBundleDisplayName': 'Quiet Line',
    'CFBundlePackageType': 'APPL',
    'CFBundleShortVersionString': sys.argv[2],
    'CFBundleVersion': '5',
    'CFBundleIconFile': 'AppIcon',
    'LSMinimumSystemVersion': '14.0',
    'LSUIElement': True,
    'NSHighResolutionCapable': True,
    'NSPrincipalClass': 'NSApplication',
}
with open(sys.argv[1], 'wb') as output:
    plistlib.dump(metadata, output)
PY
codesign --force --sign - "$app_path"
codesign --verify --deep --strict "$app_path"
ditto -c -k --keepParent "$app_path" "$output_dir/Quiet-Line-macOS.zip"
printf '\nBuilt Quiet Line %s (%s): %s\n' "$version" "$mode" "$app_path"
