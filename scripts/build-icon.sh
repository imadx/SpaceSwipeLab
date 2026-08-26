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
xcrun swift "$script_directory/render-icon.swift" "$source_path" "$iconset_directory"

iconutil --convert icns --output "$output_path" "$iconset_directory"
echo "$output_path"
