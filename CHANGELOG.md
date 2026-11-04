# Changelog

## 1.2.0 - 2026-11-04

- Custom names and KDE/system/local-image icons for individual launchers, including independent duplicate launchers.
- Optional launcher labels below icons with per-tab name visibility controls.
- Shift + scroll tab navigation and improved tab, overflow, and launcher interaction behavior.
- Improved launcher and tab persistence, including safer Settings Apply behavior when tabs change while Settings is open.
- Improved native icon picker handling, numeric settings editing, grid capacity calculations, and package dependencies.
- Packaging support for Arch, Fedora, and Debian/Ubuntu.

## 1.0.4 - 2026-09-15

- Improved the settings layout with tighter alignment, grouped sections, and more responsive spacing.
- Added desktop appearance options for transparent and reveal-on-hover modes.
- Added configurable reveal animation and transition duration, including an instant mode.
- Improved reveal-on-hover behavior so the entire widget can hide without shifting or flickering at its edges.
- Hardened local QML installation handling to preserve unrelated QML import paths and improve compatibility with other local Plasma projects.

## 1.0.3 - 2026-09-14

- Improved local installer cleanup of stale QML module paths from previous development installations.
- Removed unused internal QML properties, functions, and IDs.

## 1.0.2 - 2026-09-13

- Improved local development install and uninstall cleanup.
- Prevented stale user-local files and QML paths from interfering with system package installations.

## 1.0.1 - 2026-09-13

- Plus independent horizontal and vertical launcher alignment.
- Horizontal alignment supports Left, Center, and Right.
- Vertical alignment supports Top, Center, and Bottom.
- Alignment controls are disabled when Automatic sizing leaves no free space on that axis.

## 1.0.0 - 2026-09-11

- Initial public release.
