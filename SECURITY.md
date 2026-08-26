# Security policy

## Supported versions

Security fixes are applied to the latest published release. Because Space Swipe Lab depends on undocumented macOS behavior, compatibility fixes are also released as new versions rather than backported.

## Reporting a vulnerability

Please do not disclose a suspected vulnerability or credential in a public issue.

Use GitHub's private vulnerability reporting option under the repository's **Security** tab. If that option is unavailable, open a public issue containing no sensitive details and ask the maintainer to establish a private contact channel.

Include the affected Space Swipe Lab and macOS versions, an impact summary, and minimal reproduction steps. Do not include unrelated application, window, account, or personal information.

## Security model

Space Swipe Lab requires Accessibility permission to observe, suppress, and synthesize horizontal gesture events. It does not disable System Integrity Protection, install a privileged helper, make network requests, or collect telemetry.
