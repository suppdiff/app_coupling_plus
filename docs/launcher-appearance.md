# Launcher-specific labels and icons

App Coupling+ can display optional text labels and let users override the display
name and icon of a launcher without changing the underlying launcher URL.

## User-facing features

- Right-click a launcher and select **Edit name and icon…** to change its
  display name, choose a named icon from the active icon theme, or browse to a
  local image file (PNG, SVG, JPG, WebP, or ICO).
- Set **Launcher labels** to **Icons only** (default), **Right of icons**, or
  **Below icons** in the widget settings. Label width is configurable.
- Icons and labels work in both the main launcher grid and overflow popup.
- Existing launchers, drag-and-drop ordering, and tab configuration are kept.
- Overrides are persistent and stored **per widget instance** in Plasma config.
- Clearing both text fields restores the automatically detected name/icon.

## Implementation notes

- `launcherOverridesJson` stores a JSON object keyed by launcher URL. Values
  are `{ "name": "...", "icon": "..." }`. The existing launcher list format is
  deliberately unchanged, allowing upgrades without launcher migration.
- QML calculates cell dimensions from optional label extents for normal and
  overflow layouts; icons-only layout remains the default.
- `LauncherBridge::selectIconFile()` opens a native non-modal `QFileDialog` and
  returns the chosen file as a file URL for `Kirigami.Icon`.
- The logic uses the widget's existing persistent Plasma configuration; no
  network access or additional data collection is introduced.

## Known limitations

- The override key is the **launcher URL**, not the occurrence index. Two
  identical URLs within the same widget therefore share appearance settings.
- Labels are single-line and elided if they exceed the configured width.
- This change does not control Plasma's panel thickness or panel placement.
- Localization strings are currently provided through the existing `i18n()`
  calls and need localization updates through the normal translation process.

## Suggested manual tests

1. Start with an existing widget configuration and check original icons.
2. Add a folder from Dolphin, change its icon and display name.
3. Switch between icons-only, right, and below label modes.
4. Rearrange launchers and move one to another tab; check its override.
5. Verify labels and icons in the overflow popup.
6. Restart `plasma-plasmashell.service` and confirm all settings persist.
7. Clear both fields on a launcher and confirm the default appearance returns.

## Build

From the source checkout (with the required Qt 6, KF6 and Plasma 6 headers):

```sh
./install-local.sh
systemctl --user restart plasma-plasmashell.service
```

GPL-3.0-or-later, as with the upstream project.
