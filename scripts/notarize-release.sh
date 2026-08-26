#!/bin/bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 /absolute/path/to/SpaceSwipeLab.dmg" >&2
    exit 64
fi

dmg_path="$1"

if [[ ! -f "$dmg_path" ]]; then
    echo "DMG not found: $dmg_path" >&2
    exit 66
fi

auth_arguments=()
if [[ -n "${NOTARY_KEYCHAIN_PROFILE:-}" ]]; then
    auth_arguments+=(--keychain-profile "$NOTARY_KEYCHAIN_PROFILE")
elif [[ -n "${NOTARY_API_KEY_PATH:-}" && -n "${NOTARY_KEY_ID:-}" && -n "${NOTARY_ISSUER_ID:-}" ]]; then
    auth_arguments+=(
        --key "$NOTARY_API_KEY_PATH"
        --key-id "$NOTARY_KEY_ID"
        --issuer "$NOTARY_ISSUER_ID"
    )
else
    echo "Set NOTARY_KEYCHAIN_PROFILE or the NOTARY_API_KEY_PATH, NOTARY_KEY_ID, and NOTARY_ISSUER_ID variables." >&2
    exit 78
fi

xcrun notarytool submit "$dmg_path" "${auth_arguments[@]}" --wait
xcrun stapler staple "$dmg_path"
xcrun stapler validate "$dmg_path"
spctl --assess --type open --context context:primary-signature --verbose=2 "$dmg_path"
dmg_directory="$(dirname "$dmg_path")"
dmg_filename="$(basename "$dmg_path")"
(
    cd "$dmg_directory"
    shasum -a 256 "$dmg_filename" > SHA256SUMS
)

echo "$dmg_path"
