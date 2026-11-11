#!/bin/bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
version="$(cat "$project_dir/VERSION")"
release_dir="$project_dir/dist/releases/$version"
mkdir -p "$release_dir"
QUIETLINE_BUILD_MODE=universal QUIETLINE_OUTPUT_DIR="$release_dir/bundle" bash "$project_dir/scripts/build.sh"

asset_base="Quiet-Line-$version-macOS-universal"
cp "$release_dir/bundle/Quiet-Line-macOS.zip" "$release_dir/$asset_base.zip"
cp "$project_dir/docs/INSTALL.txt" "$release_dir/INSTALL.txt"
dmg_stage="$(mktemp -d "$release_dir/.dmg-stage.XXXXXX")"
trap 'rm -rf "$dmg_stage"' EXIT
ditto "$release_dir/bundle/Quiet Line.app" "$dmg_stage/Quiet Line.app"
ln -s /Applications "$dmg_stage/Applications"
cp "$project_dir/docs/INSTALL.txt" "$dmg_stage/INSTALL.txt"
hdiutil create -volname "Quiet Line $version" -srcfolder "$dmg_stage" -fs HFS+ -format UDZO -ov "$release_dir/$asset_base.dmg"
hdiutil verify "$release_dir/$asset_base.dmg"
(
    cd "$release_dir"
    shasum -a 256 "$asset_base.dmg" "$asset_base.zip" INSTALL.txt > SHA256SUMS.txt
)
printf '\nRelease assets: %s\n' "$release_dir"
