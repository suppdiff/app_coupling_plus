#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 suppdiff
# SPDX-License-Identifier: GPL-3.0-or-later

set -euo pipefail

root_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
build_dir="$root_dir/build"
prefix="$HOME/.local"

cmake -S "$root_dir" -B "$build_dir" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$prefix"

cmake --build "$build_dir" --parallel
cmake --install "$build_dir"

manifest="$build_dir/install_manifest.txt"
module_qmldir="$(grep '/appcoupling/launcher/qmldir$' "$manifest" | tail -n 1 || true)"
if [[ -z "$module_qmldir" ]]; then
    printf 'Error: could not determine the installed QML module path from %s\n' "$manifest" >&2
    exit 1
fi
qml_root="${module_qmldir%/appcoupling/launcher/qmldir}"

# Persist the user-local QML module root for future logins. environment.d
# supports variable expansion, so preserve any path configured before ours.
env_dir="$HOME/.config/environment.d"
env_file="$env_dir/90-app-coupling-plus.conf"
mkdir -p "$env_dir"
printf '# Managed by App Coupling+ local installer.\nQML_IMPORT_PATH=%s${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}\n' \
    "$qml_root" > "$env_file"

# Also update the current systemd user-manager environment so a plasmashell
# restart is enough; no logout is needed just to test this build.
if command -v systemctl >/dev/null 2>&1; then
    current_qml_path="$(systemctl --user show-environment 2>/dev/null | sed -n 's/^QML_IMPORT_PATH=//p' | head -n 1 || true)"
    case ":$current_qml_path:" in
        *":$qml_root:"*) new_qml_path="$current_qml_path" ;;
        *)
            if [[ -n "$current_qml_path" ]]; then
                new_qml_path="$qml_root:$current_qml_path"
            else
                new_qml_path="$qml_root"
            fi
            ;;
    esac
    systemctl --user set-environment "QML_IMPORT_PATH=$new_qml_path" || true
fi

printf '\nInstalled App Coupling+ into %s\n' "$prefix"
printf 'QML module root: %s\n' "$qml_root"
printf 'Restart Plasma before testing:\n'
printf '  systemctl --user restart plasma-plasmashell.service\n'
