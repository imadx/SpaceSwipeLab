# Space Swipe Lab

A local macOS prototype for replacing the native horizontal Space-switching gesture with an artificially high-velocity Dock swipe. This makes the transition much shorter and can make it effectively instantaneous.

Space Swipe Lab is free and open source under the MIT license. It runs as a background menu-bar utility, makes no network requests, and does not collect analytics.

The app icon source is stored at `Resources/AppIconSource.png`. Run `scripts/build-icon.sh` to regenerate the complete `AppIcon.icns` file used by local and release builds. The release DMG uses a minimal, interactive Finder layout with a direct drag-to-install instruction. Run `xcrun swift scripts/build-dmg-background.swift` to regenerate its background from `Resources/DMGBackgroundSource.png`.

## Requirements

- macOS 13 or later
- Xcode Command Line Tools
- At least two Mission Control Spaces
- Accessibility permission for the locally built app

This prototype uses undocumented `CGEvent` types and SkyLight Space information. It is intended for local testing and direct distribution, not the Mac App Store. System Integrity Protection does not need to be disabled.

## Build and run

```bash
cd /Users/ishan/projects/ishan/SpaceSwipeLab
./scripts/run-local.sh
```

On first launch:

1. Click **Allow Access**.
2. Enable **Space Swipe Lab** in System Settings → Privacy & Security → Accessibility.
3. Return to the app. The status card should turn green within a second.
4. Use **Previous Space** and **Next Space** to verify that synthetic switching works.
5. In System Settings → Trackpad → More Gestures, configure **Swipe between full-screen applications** to use four fingers.
6. Turn on **Fast switching**.
7. Swipe left or right with four fingers.

Choose **Normal**, **Fast**, or **Instant** in the main window. Closing the window leaves the utility running. Use the menu-bar icon to enable or disable the override, reopen settings, or quit. Menu-bar visibility, launch at login, and Accessibility settings are in the ellipsis menu.

At the first or last Space, an outward swipe is returned to macOS instead of being replaced. This keeps the familiar native edge feedback when there is no desktop in that direction.

## Restore normal behavior

Turn off the Fast switching control or quit the app. The event tap exists only while the process is running; the app does not permanently change trackpad settings.

## Tests

```bash
swift test
```

The automated tests cover the gesture phase/direction state machine, Space ordering, boundary decisions, and a live SkyLight topology read. Actual gesture switching must still be verified interactively because it is controlled by Dock and WindowServer.

## Build a signed release locally

This Mac must contain a valid `Developer ID Application` identity:

```bash
./scripts/build-release.sh
```

The universal signed DMG and checksum are written to `dist/`. To notarize it, provide either a notarytool keychain profile or App Store Connect API-key environment variables:

```bash
NOTARY_KEYCHAIN_PROFILE=your-profile \
  ./scripts/notarize-release.sh "$PWD/dist/SpaceSwipeLab-0.5.0.dmg"
```

The release workflow expects these GitHub Actions secrets:

- `DEVELOPER_ID_CERTIFICATE_BASE64`
- `DEVELOPER_ID_CERTIFICATE_PASSWORD`
- `RELEASE_KEYCHAIN_PASSWORD`
- `NOTARY_KEY_BASE64`
- `NOTARY_KEY_ID`
- `NOTARY_ISSUER_ID`

See [PRIVACY.md](PRIVACY.md) for the privacy statement and [ATTRIBUTIONS.md](ATTRIBUTIONS.md) for third-party notices.

Before publishing a release, complete the manual macOS and hardware matrix in [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md). Contributions are covered by [CONTRIBUTING.md](CONTRIBUTING.md).
