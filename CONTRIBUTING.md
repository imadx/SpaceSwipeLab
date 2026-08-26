# Contributing

Contributions are welcome. Please open an issue before a large behavioral change so the approach can be discussed first.

## Development

```bash
swift test
./scripts/run-local.sh
```

The app requires Accessibility permission for interactive testing. Automated tests must not depend on changing Spaces or on a connected trackpad.

## Pull requests

- Keep the free, local-only privacy model intact.
- Add tests for pure gesture-state and preference logic.
- Do not add analytics, tracking, or network access without explicit project discussion.
- Document macOS versions and hardware used for manual gesture testing.
- Preserve the third-party notice in `ATTRIBUTIONS.md`.
