#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 suppdiff
# SPDX-License-Identifier: GPL-3.0-or-later

set -euo pipefail

root_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
manifest="$root_dir/build/install_manifest.txt"
prefix="$HOME/.local"
applet_dir="$prefix/share/plasma/plasmoids/io.github.suppdiff.appcouplingplus"
env_file="$HOME/.config/environment.d/90-app-coupling-plus.conf"

# Collect every QML root App Coupling+ may have used. The manifest is preferred,
# but the environment file and known user-local Qt/KDE layouts let uninstall
# still work after the build directory has been deleted.
qml_roots=()

add_qml_root() {
    local candidate="${1:-}"
    [[ -n "$candidate" ]] || return 0
    [[ "$candidate" == "$prefix/"* ]] || return 0

    local existing
    for existing in "${qml_roots[@]:-}"; do
        [[ "$existing" == "$candidate" ]] && return 0
    done
    qml_roots+=("$candidate")
}

if [[ -f "$manifest" ]]; then
    module_qmldir="$(grep '/appcoupling/launcher/qmldir$' "$manifest" | tail -n 1 || true)"
    if [[ -n "$module_qmldir" ]]; then
        add_qml_root "${module_qmldir%/appcoupling/launcher/qmldir}"
    fi
fi

if [[ -f "$env_file" ]] && grep -q '^# Managed by App Coupling+ local installer\.$' "$env_file"; then
    env_qml_root="$(sed -n 's/^QML_IMPORT_PATH=\([^$]*\).*$/\1/p' "$env_file" | head -n 1 || true)"
    add_qml_root "$env_qml_root"
fi

add_qml_root "$prefix/lib/qml"
add_qml_root "$prefix/lib/qt6/qml"

# Remove files from the CMake manifest when available. Restrict removal to
# ~/.local so this script can never remove the pacman-managed /usr package.
if [[ -f "$manifest" ]]; then
    while IFS= read -r path; do
        [[ -n "$path" ]] || continue
        if [[ "$path" == "$prefix/"* && -f "$path" ]]; then
            rm -f -- "$path"
            printf 'removed %s\n' "$path"
        fi
    done < "$manifest"
fi

# Remove the complete App Coupling+ user-local payload. These paths belong only
# to this development install; no Plasma configuration is removed.
if [[ -d "$applet_dir" ]]; then
    rm -rf -- "$applet_dir"
    printf 'removed %s\n' "$applet_dir"
fi

for qml_root in "${qml_roots[@]}"; do
    module_dir="$qml_root/appcoupling/launcher"
    if [[ -d "$module_dir" ]]; then
        rm -rf -- "$module_dir"
        printf 'removed %s\n' "$module_dir"
    fi

    # Remove our namespace only when no other module uses it.
    rmdir --ignore-fail-on-non-empty "$qml_root/appcoupling" 2>/dev/null || true
done

if [[ -f "$env_file" ]] && grep -q '^# Managed by App Coupling+ local installer\.$' "$env_file"; then
    rm -f -- "$env_file"
    printf 'removed %s\n' "$env_file"
fi

# Remove only App Coupling+'s user-local QML roots from the current systemd
# user-manager environment, preserving any unrelated QML_IMPORT_PATH entries.
if command -v systemctl >/dev/null 2>&1; then
    current_qml_path="$(systemctl --user show-environment 2>/dev/null | sed -n 's/^QML_IMPORT_PATH=//p' | head -n 1 || true)"

    if [[ -n "$current_qml_path" ]]; then
        new_qml_path=""
        IFS=':' read -ra current_paths <<< "$current_qml_path"

        for path in "${current_paths[@]}"; do
            [[ -n "$path" ]] || continue

            remove_path=false
            for qml_root in "${qml_roots[@]}"; do
                if [[ "$path" == "$qml_root" ]]; then
                    remove_path=true
                    break
                fi
            done
            $remove_path && continue

            if [[ -n "$new_qml_path" ]]; then
                new_qml_path="$new_qml_path:$path"
            else
                new_qml_path="$path"
            fi
        done

        if [[ -n "$new_qml_path" ]]; then
            systemctl --user set-environment "QML_IMPORT_PATH=$new_qml_path" || true
        else
            systemctl --user unset-environment QML_IMPORT_PATH || true
        fi
    fi
fi

printf '\nFinished uninstalling the App Coupling+ user-local development install.\n'
printf 'Plasma configuration and the pacman-managed system package, if installed, were left untouched.\n'
printf 'Restart Plasma before testing another installation:\n'
printf '  systemctl --user restart plasma-plasmashell.service\n'
