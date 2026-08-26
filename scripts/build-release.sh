#!/bin/bash

set -euo pipefail

script_directory="$(cd "$(dirname "$0")" && pwd)"
project_directory="$(cd "$script_directory/.." && pwd)"
version="${RELEASE_VERSION:-0.5.0}"
signing_identity="${SIGNING_IDENTITY:-Developer ID Application: Ishan Madhusanka (P7FS8ZJ583)}"
dist_directory="$project_directory/dist"
app_directory="$dist_directory/SpaceSwipeLab.app"
dmg_staging_directory="$project_directory/build/dmg-root"
volume_name="Space Swipe Lab $version"
dmg_work_directory="$(mktemp -d)"
writable_dmg_path="$dmg_work_directory/SpaceSwipeLab-writable.dmg"
mount_directory="/Volumes/$volume_name"
mounted_by_script=false
dmg_path="$dist_directory/SpaceSwipeLab-$version.dmg"

cleanup() {
    if [[ "$mounted_by_script" == true ]]; then
        hdiutil detach "$mount_directory" >/dev/null 2>&1 || true
    fi
    rm -rf "$dmg_work_directory"
}
trap cleanup EXIT

"$script_directory/build-icon.sh" >/dev/null
xcrun swift "$script_directory/build-dmg-background.swift" >/dev/null
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
mkdir -p \
    "$app_directory/Contents/MacOS" \
    "$app_directory/Contents/Resources" \
    "$dmg_staging_directory/.background"

cp "$binary_directory/SpaceSwipeLab" "$app_directory/Contents/MacOS/SpaceSwipeLab"
cp "$project_directory/Resources/Info.plist" "$app_directory/Contents/Info.plist"
cp "$project_directory/Resources/AppIcon.icns" "$app_directory/Contents/Resources/AppIcon.icns"

codesign \
    --force \
    --options runtime \
    --timestamp=http://timestamp.apple.com/ts01 \
    --sign "$signing_identity" \
    --identifier com.imadx.SpaceSwipeLab \
    "$app_directory"

codesign --verify --deep --strict --verbose=2 "$app_directory"

cp -R "$app_directory" "$dmg_staging_directory/SpaceSwipeLab.app"
ln -s /Applications "$dmg_staging_directory/Applications"
cp "$project_directory/Resources/DMGBackground.png" \
    "$dmg_staging_directory/.background/DMGBackground.png"

hdiutil create \
    -volname "$volume_name" \
    -srcfolder "$dmg_staging_directory" \
    -ov \
    -format UDRW \
    "$writable_dmg_path"

if [[ -e "$mount_directory" ]]; then
    echo "A volume named '$volume_name' is already mounted. Eject it and retry." >&2
    exit 73
fi

hdiutil attach \
    "$writable_dmg_path" \
    -readwrite \
    -noverify \
    -noautoopen >/dev/null
mounted_by_script=true

SetFile -a V "$mount_directory/.background"
osascript "$script_directory/layout-dmg.applescript" "$volume_name"
sync
hdiutil detach "$mount_directory" >/dev/null
mounted_by_script=false

hdiutil convert \
    "$writable_dmg_path" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -ov \
    -o "$dmg_path" >/dev/null

codesign \
    --force \
    --timestamp=http://timestamp.apple.com/ts01 \
    --sign "$signing_identity" \
    "$dmg_path"

shasum -a 256 "$dmg_path" > "$dist_directory/SHA256SUMS"

echo "$dmg_path"
