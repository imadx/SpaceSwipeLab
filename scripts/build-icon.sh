#!/bin/bash

set -euo pipefail

script_directory="$(cd "$(dirname "$0")" && pwd)"
project_directory="$(cd "$script_directory/.." && pwd)"
source_path="$project_directory/Resources/AppIconSource.png"
output_path="$project_directory/Resources/AppIcon.icns"
work_directory="$(mktemp -d)"
iconset_directory="$work_directory/AppIcon.iconset"

cleanup() {
    rm -rf "$work_directory"
}
trap cleanup EXIT

if [[ ! -f "$source_path" ]]; then
    echo "Icon source not found: $source_path" >&2
    exit 66
fi

mkdir -p "$iconset_directory"

create_icon() {
    local pixels="$1"
    local filename="$2"
    sips -z "$pixels" "$pixels" "$source_path" --out "$iconset_directory/$filename" >/dev/null
}

create_icon 16 icon_16x16.png
create_icon 32 icon_16x16@2x.png
create_icon 32 icon_32x32.png
create_icon 64 icon_32x32@2x.png
create_icon 128 icon_128x128.png
create_icon 256 icon_128x128@2x.png
create_icon 256 icon_256x256.png
create_icon 512 icon_256x256@2x.png
create_icon 512 icon_512x512.png
create_icon 1024 icon_512x512@2x.png

iconutil --convert icns --output "$output_path" "$iconset_directory"
echo "$output_path"
