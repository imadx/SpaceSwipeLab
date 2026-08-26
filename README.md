# Space Swipe Lab

Space Swipe Lab is a free, open-source macOS utility for switching Mission Control Spaces with much shorter motion. Choose **Normal**, **Fast**, or **Instant**, then use the same horizontal trackpad gesture you already know.

It runs locally, makes no network requests, and does not collect analytics.

## Features

- Normal, Fast, and near-instant Space transitions
- Four-finger horizontal gesture support through the macOS trackpad setting
- Native macOS edge feedback when swiping beyond the first or last Space
- Quick Previous and Next buttons for testing
- Optional menu-bar icon and launch at login
- Universal Apple silicon and Intel builds
- Developer ID signing and Apple notarization for published releases

## Download and install

1. Download the DMG from the [latest GitHub release](https://github.com/imadx/SpaceSwipeLab/releases/latest).
2. Open it and drag **Space Swipe Lab** onto **Applications**.
3. Launch the app from Applications.
4. Select **Allow Access**, then enable Space Swipe Lab in **System Settings → Privacy & Security → Accessibility**.
5. In **System Settings → Trackpad → More Gestures**, set **Swipe between full-screen applications** to four fingers.
6. Return to Space Swipe Lab, enable **Fast switching**, and choose a transition speed.

Closing the settings window leaves the utility running. Use the menu-bar icon to reopen settings, disable the override, or quit.

## Requirements and compatibility

- macOS 13 Ventura or later
- At least two Mission Control Spaces
- A built-in trackpad or Magic Trackpad
- Accessibility permission

Space Swipe Lab uses undocumented Dock event fields and SkyLight Space information because macOS does not provide a public API for this behavior. It does not require disabling System Integrity Protection, but a future macOS update may require a compatibility update. See the [release checklist](RELEASE_CHECKLIST.md) for the current manual test matrix.

## Build from source

Install Xcode Command Line Tools, then run:

```bash
git clone https://github.com/imadx/SpaceSwipeLab.git
cd SpaceSwipeLab
./scripts/run-local.sh
```

On first launch, grant the locally built app Accessibility permission. Run the automated tests with:

```bash
swift test
```

The tests cover gesture phase handling, Space ordering, boundary decisions, and a live SkyLight topology read when available. Physical gesture switching must still be tested interactively because Dock and WindowServer control the transition.

## Build a signed release

The Mac performing the release must contain a valid `Developer ID Application` identity:

```bash
./scripts/build-release.sh
```

The universal signed DMG and checksum are written to `dist/`. To submit the DMG to Apple and staple the notarization ticket, provide either a `notarytool` keychain profile or App Store Connect API-key environment variables:

```bash
NOTARY_KEYCHAIN_PROFILE=your-profile \
  ./scripts/notarize-release.sh "$PWD/dist/SpaceSwipeLab-0.5.0.dmg"
```

The tag-based GitHub release workflow expects these repository secrets:

- `DEVELOPER_ID_CERTIFICATE_BASE64`
- `DEVELOPER_ID_CERTIFICATE_PASSWORD`
- `RELEASE_KEYCHAIN_PASSWORD`
- `NOTARY_KEY_BASE64`
- `NOTARY_KEY_ID`
- `NOTARY_ISSUER_ID`

Never commit certificates, API keys, keychains, or `.env` files.

## Privacy, security, and contributing

- [Privacy statement](PRIVACY.md)
- [Security policy](SECURITY.md)
- [Contributing guide](CONTRIBUTING.md)
- [Third-party notices](ATTRIBUTIONS.md)

Space Swipe Lab is available under the [MIT License](LICENSE). Its synthetic Dock-swipe technique is derived from [InstantSpaceSwitcher](https://github.com/jurplel/InstantSpaceSwitcher); the required upstream notice is included in `ATTRIBUTIONS.md` and in packaged applications.
