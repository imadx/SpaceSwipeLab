#!/bin/bash

set -euo pipefail

script_directory="$(cd "$(dirname "$0")" && pwd)"
project_directory="$(cd "$script_directory/.." && pwd)"
configuration="${1:-debug}"
app_directory="$project_directory/build/SpaceSwipeLab.app"
contents_directory="$app_directory/Contents"

"$script_directory/build-icon.sh" >/dev/null
swift build --package-path "$project_directory" --configuration "$configuration"

binary_path="$(swift build --package-path "$project_directory" --configuration "$configuration" --show-bin-path)/SpaceSwipeLab"

rm -rf "$app_directory"
mkdir -p "$contents_directory/MacOS" "$contents_directory/Resources"
cp "$binary_path" "$contents_directory/MacOS/SpaceSwipeLab"
cp "$project_directory/Resources/Info.plist" "$contents_directory/Info.plist"
cp "$project_directory/Resources/AppIcon.icns" "$contents_directory/Resources/AppIcon.icns"

codesign \
    --force \
    --sign - \
    --identifier com.imadx.SpaceSwipeLab \
    "$app_directory"

echo "$app_directory"
