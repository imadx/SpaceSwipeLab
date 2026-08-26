#!/bin/bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 /absolute/path/to/SpaceSwipeLab.dmg" >&2
    exit 64
fi

dmg_path="$1"
mount_directory="$(mktemp -d)"

cleanup() {
    hdiutil detach "$mount_directory" >/dev/null 2>&1 || true
    rmdir "$mount_directory" >/dev/null 2>&1 || true
}
trap cleanup EXIT

xcrun stapler validate "$dmg_path"
spctl --assess --type open --context context:primary-signature --verbose=2 "$dmg_path"
hdiutil attach "$dmg_path" -readonly -nobrowse -mountpoint "$mount_directory" >/dev/null

app_path="$mount_directory/SpaceSwipeLab.app"
codesign --verify --deep --strict --verbose=2 "$app_path"
spctl --assess --type execute --verbose=2 "$app_path"
lipo -archs "$app_path/Contents/MacOS/SpaceSwipeLab"

icon_name="$(plutil -extract CFBundleIconFile raw "$app_path/Contents/Info.plist")"
if [[ "$icon_name" != "AppIcon" || ! -f "$app_path/Contents/Resources/AppIcon.icns" ]]; then
    echo "The release bundle is missing its AppIcon.icns resource." >&2
    exit 65
fi

if [[ ! -f "$app_path/Contents/Resources/LICENSE.txt" ]] || \
    [[ ! -f "$app_path/Contents/Resources/THIRD-PARTY-NOTICES.txt" ]]; then
    echo "The release bundle is missing its license notices." >&2
    exit 65
fi

if [[ ! -L "$mount_directory/Applications" ]] || \
    [[ "$(readlink "$mount_directory/Applications")" != "/Applications" ]]; then
    echo "The DMG is missing its Applications drag target." >&2
    exit 65
fi

if [[ ! -f "$mount_directory/.background/DMGBackground.png" ]] || \
    [[ ! -f "$mount_directory/.DS_Store" ]]; then
    echo "The DMG is missing its custom drag-and-drop layout." >&2
    exit 65
fi

echo "Release verification passed: $dmg_path"
