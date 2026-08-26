# Release checklist

## Automated verification

- [x] Swift unit tests pass.
- [x] Universal `arm64` and `x86_64` release binary builds.
- [x] App and DMG use hardened-runtime Developer ID signatures.
- [x] DMG is notarized, stapled, and accepted by Gatekeeper.
- [x] DMG checksum is published alongside the release.
- [x] App icon includes the full macOS `.icns` size set.

## Manual compatibility matrix

Run the direct Previous/Next test and physical swipe override for each supported configuration:

- [ ] macOS 13 Ventura
- [ ] macOS 14 Sonoma
- [ ] macOS 15 Sequoia
- [ ] macOS 26 Tahoe
- [ ] Built-in Force Touch trackpad
- [ ] Magic Trackpad
- [ ] One display
- [ ] Multiple displays with “Displays have separate Spaces” enabled
- [ ] Multiple displays with “Displays have separate Spaces” disabled
- [ ] A regular Desktop Space on each side
- [ ] A full-screen application Space on each side
- [ ] First and last Space boundary behavior
- [ ] Mission Control and App Exposé remain usable
- [ ] Sleep/wake while the override is enabled
- [ ] Login-item launch after installing in `/Applications`
- [ ] Accessibility permission survives app relaunch and version upgrade

## Before publishing the repository

- [ ] Confirm the final product and repository name.
- [ ] Create the public GitHub repository and push `main`.
- [ ] Add the six signing/notarization GitHub Actions secrets documented in the README.
- [ ] Protect the `main` branch and require the Tests workflow.
- [ ] Publish the first signed DMG and `SHA256SUMS` through GitHub Releases.
- [ ] Enable GitHub Pages after the website is added.
- [ ] Add final screenshots and a short gesture demonstration video.
- [ ] Decide whether to add Sparkle after the permanent GitHub Releases URL exists.

## Compatibility policy

Space Swipe Lab depends on undocumented Dock event fields. Every major macOS update must be treated as potentially breaking. A release should not claim support for a macOS version until the physical gesture has been tested on that version.
