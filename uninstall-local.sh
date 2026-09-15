#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 suppdiff
# SPDX-License-Identifier: GPL-3.0-or-later

set -euo pipefail

root_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
manifest="$root_dir/build/install_manifest.txt"
prefix="$HOME/.local"
applet_dir="$prefix/share/plasma/plasmoids/io.github.suppdiff.appcouplingplus"
env_file="$HOME/.config/environment.d/90-app-coupling-plus.conf"

# Collect locations where an App Coupling+ development module may exist. These
# are used only to remove App Coupling+'s own module directory, never to claim
# ownership of the generic QML root itself.
cleanup_qml_roots=()

add_cleanup_root() {
    local candidate="${1:-}"
    [[ -n "$candidate" ]] || return 0
    [[ "$candidate" == "$prefix/"* ]] || return 0

    local existing
    for existing in "${cleanup_qml_roots[@]:-}"; do
        [[ "$existing" == "$candidate" ]] && return 0
    done
    cleanup_qml_roots+=("$candidate")
}

if [[ -f "$manifest" ]]; then
    module_qmldir="$(grep '/appcoupling/launcher/qmldir$' "$manifest" | tail -n 1 || true)"
    if [[ -n "$module_qmldir" ]]; then
        add_cleanup_root "${module_qmldir%/appcoupling/launcher/qmldir}"
    fi
fi

if [[ -f "$env_file" ]] && grep -q '^# Managed by App Coupling+ local installer\.$' "$env_file"; then
    env_qml_root="$(sed -n 's/^QML_IMPORT_PATH=\([^$]*\).*$/\1/p' "$env_file" | head -n 1 || true)"
    add_cleanup_root "$env_qml_root"
fi

add_cleanup_root "$prefix/lib/qml"
add_cleanup_root "$prefix/lib/qt6/qml"
add_cleanup_root "$prefix/lib64/qml"
add_cleanup_root "$prefix/lib64/qt6/qml"

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

if [[ -d "$applet_dir" ]]; then
    rm -rf -- "$applet_dir"
    printf 'removed %s\n' "$applet_dir"
fi

for qml_root in "${cleanup_qml_roots[@]}"; do
    module_dir="$qml_root/appcoupling/launcher"
    if [[ -d "$module_dir" ]]; then
        rm -rf -- "$module_dir"
        printf 'removed %s\n' "$module_dir"
    fi
    rmdir --ignore-fail-on-non-empty "$qml_root/appcoupling" 2>/dev/null || true
done

if [[ -f "$env_file" ]] && grep -q '^# Managed by App Coupling+ local installer\.$' "$env_file"; then
    rm -f -- "$env_file"
    printf 'removed %s\n' "$env_file"
fi

# Do not rewrite the current user-manager QML_IMPORT_PATH here. QML roots are
# shared search paths and may be used by other local Plasma/QML projects. The
# App Coupling+ module itself is already gone, and the managed environment.d
# entry is removed for future logins.

printf '\nFinished uninstalling the App Coupling+ user-local development install.\n'
printf 'Plasma configuration and the pacman-managed system package, if installed, were left untouched.\n'
printf 'Restart Plasma before testing another installation:\n'
printf '  systemctl --user restart plasma-plasmashell.service\n'
