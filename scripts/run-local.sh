#!/bin/bash

set -euo pipefail

script_directory="$(cd "$(dirname "$0")" && pwd)"
app_path="$($script_directory/build-app.sh debug)"

open "$app_path"
