#!/bin/bash

set -euo pipefail

script_directory="$(cd "$(dirname "$0")" && pwd)"
project_directory="$(cd "$script_directory/.." && pwd)"
version="${RELEASE_VERSION:-0.2.0}"
signing_identity="${SIGNING_IDENTITY:-Developer ID Application: Ishan Madhusanka (P7FS8ZJ583)}"
dist_directory="$project_directory/dist"
app_directory="$dist_directory/SpaceSwipeLab.app"
dmg_staging_directory="$project_directory/build/dmg-root"
dmg_path="$dist_directory/SpaceSwipeLab-$version.dmg"

swift build \
    --package-path "$project_directory" \
    --configuration release \
    --arch arm64 \
    --arch x86_64

binary_directory="$(swift build \
    --package-path "$project_directory" \
    --configuration release \
    --arch arm64 \
    --arch x86_64 \
    --show-bin-path)"

rm -rf "$app_directory" "$dmg_staging_directory"
rm -f "$dmg_path" "$dist_directory/SHA256SUMS"
mkdir -p "$app_directory/Contents/MacOS" "$dmg_staging_directory"

cp "$binary_directory/SpaceSwipeLab" "$app_directory/Contents/MacOS/SpaceSwipeLab"
cp "$project_directory/Resources/Info.plist" "$app_directory/Contents/Info.plist"

codesign \
    --force \
    --options runtime \
    --timestamp=http://timestamp.apple.com/ts01 \
    --sign "$signing_identity" \
    --identifier dev.ishan.SpaceSwipeLab \
    "$app_directory"

codesign --verify --deep --strict --verbose=2 "$app_directory"

cp -R "$app_directory" "$dmg_staging_directory/SpaceSwipeLab.app"
ln -s /Applications "$dmg_staging_directory/Applications"

hdiutil create \
    -volname "Space Swipe Lab" \
    -srcfolder "$dmg_staging_directory" \
    -ov \
    -format UDZO \
    "$dmg_path"

codesign \
    --force \
    --timestamp=http://timestamp.apple.com/ts01 \
    --sign "$signing_identity" \
    "$dmg_path"

shasum -a 256 "$dmg_path" > "$dist_directory/SHA256SUMS"

echo "$dmg_path"
