# App Coupling+

Thanks for your interest.

## Issues

Before opening an issue:

- Search existing issues first.
- Use the bug or feature-request template when applicable.
- For bugs, include:
  - KDE Plasma version
  - distribution
  - Wayland or X11
  - App Coupling+ version
  - installation method: package or local source
  - steps to reproduce
  - expected and actual behavior

Do not report security vulnerabilities in a public issue. See `SECURITY.md`.

## Development

App Coupling+ targets KDE Plasma 6 and uses QML with a small native C++ QML plugin.

For a local development installation:

```bash
./install-local.sh
```

After changes, check for whitespace errors:
```bash
git diff --check
```

Please avoid committing generated build directories or packaged artifacts.

## Pull requests

Keep pull requests focused on one change where practical.

Please describe:
- what changed
- why it changed
- how it was tested
- whether UI behavior changed

Try to preserve existing functionality unless the change intentionally modifies it.
