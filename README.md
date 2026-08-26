# Space Swipe Lab

A local macOS prototype for replacing the native horizontal Space-switching gesture with an artificially high-velocity Dock swipe. This makes the transition much shorter and can make it effectively instantaneous.

Space Swipe Lab is free and open source under the MIT license. It runs as a background menu-bar utility, makes no network requests, and does not collect analytics.

The app icon source is stored at `Resources/AppIconSource.png`. Run `scripts/build-icon.sh` to regenerate the complete `AppIcon.icns` file used by local and release builds.

## Requirements

- macOS 13 or later
- Xcode Command Line Tools
- At least two Mission Control Spaces
- Accessibility permission for the locally built app

This prototype uses undocumented `CGEvent` types and fields. It is intended for local testing and direct distribution, not the Mac App Store. System Integrity Protection does not need to be disabled.

## Build and run

```bash
cd /Users/ishan/projects/ishan/SpaceSwipeLab
./scripts/run-local.sh
```

On first launch:

1. Click **Request Accessibility Access**.
2. Enable **Space Swipe Lab** in System Settings → Privacy & Security → Accessibility.
3. Return to the app. The permission indicator should turn green within a second.
4. Use **Previous Space** and **Next Space** to verify that synthetic switching works.
5. In System Settings → Trackpad → More Gestures, configure **Swipe between full-screen applications** to use four fingers.
6. Enable **Override the native horizontal Space swipe**.
7. Swipe left or right with four fingers.

Closing the settings window leaves the utility running. Use the menu-bar icon to enable or disable the override, reopen settings, or quit. Settings also include launch-at-login and menu-bar visibility controls.

Start with velocity 80 if you want to observe a very short transition. Use 2000 for an effectively instant switch.

## Restore normal behavior

Turn off the override checkbox or quit the app. The event tap exists only while the process is running; the app does not permanently change trackpad settings.

## Tests

```bash
swift test
```

The automated tests cover the gesture phase/direction state machine. Actual Space switching must be verified interactively because it is controlled by Dock and WindowServer.

## Build a signed release locally

This Mac must contain a valid `Developer ID Application` identity:

```bash
./scripts/build-release.sh
```

The universal signed DMG and checksum are written to `dist/`. To notarize it, provide either a notarytool keychain profile or App Store Connect API-key environment variables:

```bash
NOTARY_KEYCHAIN_PROFILE=your-profile \
  ./scripts/notarize-release.sh "$PWD/dist/SpaceSwipeLab-0.3.0.dmg"
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
