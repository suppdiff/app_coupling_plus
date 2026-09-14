# App Coupling+

A configurable application-launcher widget for KDE Plasma 6, built around independent launcher groups, drag-and-drop ordering, flexible sizing, and optional tabs.


![App Coupling+ panel](screenshots/1.jpeg)

![App Coupling+ tabs](screenshots/2.jpeg)

![App Coupling+ vertical panel](screenshots/3.jpeg)

![App Coupling+ desktop](screenshots/4.jpeg)


## Features

- Independent launcher lists — not tied to Plasma Favorites
- Drag applications or `.desktop` launchers onto the widget
- Drag launchers to reorder them
- Duplicate launchers are supported and reorder correctly
- Optional tabs, with a separate launcher list for each tab
- Move or copy launchers between tabs from the right-click menu
- Horizontal and vertical panel support, plus desktop-widget support
- Configurable rows/columns, icon size, and horizontal/vertical spacing
- Automatic, Fixed, and Fill panel sizing modes
- Three overflow modes:
  - **Paged arrows** — switch between fixed-size launcher pages
  - **Popup overflow** — open hidden launchers from a `+N` button
  - **Scroll** — wheel/flick through launchers
- Optional system-theme outline with configurable thickness, opacity, and corner radius
- Configurable tab placement, including mirrored panel placement and desktop Top/Bottom/Left/Right positioning
- User-local installation under `~/.local`; the installer itself does not require `sudo`

## Requirements

App Coupling+ targets KDE Plasma 6 and includes a small native Qt/KDE helper, so it must be compiled for the system on which it is installed.

The build currently requires:

- C++20 compiler/toolchain
- CMake 3.20+
- Extra CMake Modules 6+
- Qt 6.7+ (`Core`, `Gui`, `Qml`, `Widgets`)
- KDE Frameworks 6 (`Config`, `CoreAddons`, `KIO`, `Service`)
- Plasma 6 development files

On Arch Linux / CachyOS, the usual build tools can be installed with:

```bash
sudo pacman -S --needed base-devel cmake extra-cmake-modules
```

The remaining Qt/KDE runtime and development dependencies are normally already present on a Plasma development system; CMake will report anything missing.

## Installation

### Arch Linux / CachyOS package

For a normal installation, download the latest `.pkg.tar.zst` package from the GitHub Releases page, then install it with pacman.

> **Important:** Rename the directories and the `*.pkg.tar.zst` filename below to match your actual download location and downloaded package filename.

```bash
cd ~/Downloads
sudo pacman -U ./plasma6-applets-app-coupling-plus-<version>-<pkgrel>-x86_64.pkg.tar.zst
```

This installs App Coupling+ system-wide under `/usr` and lets pacman manage the installation.

### Local source installation

For development or a user-local installation, clone or download the source, enter the project directory, then run:

```bash
./install-local.sh
```

The installer builds App Coupling+ and installs it under `~/.local`. It does not install files into `/usr` and does not require `sudo`.

Because App Coupling+ includes a native QML plugin, restart Plasma after installing or updating it:

```bash
systemctl --user restart plasma-plasmashell.service
```

A full logout is normally not required.

Then add **App Coupling+** from Plasma's **Add Widgets** interface.

## Updating

Pull/download the newer source and run `./install-local.sh` again, then restart `plasma-plasmashell.service` as shown above.

Existing widget instances and settings are preserved as long as the plugin ID remains:

```text
io.github.suppdiff.appcouplingplus
```

## Basic usage

Drag an application or `.desktop` launcher onto App Coupling+ to add it. Drag existing launchers to rearrange them, and right-click a launcher for additional actions.

When tabs are enabled, each tab owns an independent launcher list. Tabs can be renamed, duplicated, moved, or removed, and launchers can be moved or copied between tabs.

For panels, Plasma controls the panel thickness while App Coupling+ controls its length along the panel. If the configured launchers do not fit, use Paged arrows, Popup overflow, or Scroll mode instead of silently shrinking the icons.

## Uninstall

If App Coupling+ was installed with `install-local.sh`, run the matching uninstaller from the source tree:

```bash
./uninstall-local.sh
```

The uninstaller removes the user-local App Coupling+ plasmoid, its QML module, and its managed environment entry. It leaves Plasma widget configuration and any pacman-managed system package untouched. Restart Plasma afterward if the widget was loaded.

## Security and privacy

- App Coupling+ does not expose arbitrary shell-command execution to QML.
- It does not read browser cookies or credentials.
- It does not perform background telemetry or analytics.
- Launching is handled through KDE/Qt APIs rather than shelling out to arbitrary commands.
- The local installer writes only App Coupling+ files under `~/.local` plus its own user environment entry used to expose the QML module path.

## Official source and third-party builds

This repository, owned by **suppdiff**, is the canonical upstream source for App Coupling+.

Forks are allowed by the license, but forks, repackaged builds, and downloads distributed elsewhere are **unofficial unless explicitly linked or endorsed by this repository**. A third-party build should not be assumed to be an official App Coupling+ release merely because it uses the same source code or project name.

## License

App Coupling+ is free software licensed under the **GNU General Public License, version 3 or any later version** (`GPL-3.0-or-later`). See [`LICENSE`](LICENSE) for the full license text.

Copyright © 2026 suppdiff.

The GPL allows use, modification, redistribution, and commercial redistribution under its terms. Distributed GPL-covered modifications must preserve the recipients' GPL rights and corresponding-source obligations.

Third-party libraries and KDE/Qt components used by App Coupling+ remain under their respective licenses.

## Contributing

Issues and pull requests are welcome. Contributions submitted for inclusion in App Coupling+ must be compatible with the project's `GPL-3.0-or-later` license.
