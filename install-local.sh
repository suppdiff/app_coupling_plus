#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 suppdiff
# SPDX-License-Identifier: GPL-3.0-or-later

set -euo pipefail

root_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
build_dir="$root_dir/build"
prefix="$HOME/.local"
applet_dir="$prefix/share/plasma/plasmoids/io.github.suppdiff.appcouplingplus"
env_dir="$HOME/.config/environment.d"
env_file="$env_dir/90-app-coupling-plus.conf"

# Remember QML roots previously managed by App Coupling+ before reconfiguring.
# These are the only roots we may remove from the current QML_IMPORT_PATH later;
# generic user-local QML roots may also be used by other projects.
previous_managed_qml_roots=()
cleanup_qml_roots=()

add_previous_managed_root() {
    local candidate="${1:-}"
    [[ -n "$candidate" ]] || return 0
    [[ "$candidate" == "$prefix/"* ]] || return 0

    local existing
    for existing in "${previous_managed_qml_roots[@]:-}"; do
        [[ "$existing" == "$candidate" ]] && return 0
    done
    previous_managed_qml_roots+=("$candidate")
}

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

previous_manifest="$build_dir/install_manifest.txt"
if [[ -f "$previous_manifest" ]]; then
    previous_module_qmldir="$(grep '/appcoupling/launcher/qmldir$' "$previous_manifest" | tail -n 1 || true)"
    if [[ -n "$previous_module_qmldir" ]]; then
        previous_root="${previous_module_qmldir%/appcoupling/launcher/qmldir}"
        add_previous_managed_root "$previous_root"
        add_cleanup_root "$previous_root"
    fi
fi

if [[ -f "$env_file" ]] && grep -q '^# Managed by App Coupling+ local installer\.$' "$env_file"; then
    previous_env_qml_root="$(sed -n 's/^QML_IMPORT_PATH=\([^$]*\).*$/\1/p' "$env_file" | head -n 1 || true)"
    add_previous_managed_root "$previous_env_qml_root"
    add_cleanup_root "$previous_env_qml_root"
fi

# Search all user-local layouts App Coupling+ may have used for stale module
# files, but do not treat these generic roots as App Coupling+-owned environment
# entries. Other local Plasma/QML projects may rely on them.
add_cleanup_root "$prefix/lib/qml"
add_cleanup_root "$prefix/lib/qt6/qml"
add_cleanup_root "$prefix/lib64/qml"
add_cleanup_root "$prefix/lib64/qt6/qml"

cmake -S "$root_dir" -B "$build_dir" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$prefix" \
    -DKDE_INSTALL_QMLDIR=lib/qt6/qml

cmake --build "$build_dir" --parallel

# A user-local development install takes precedence over a system package.
if command -v pacman >/dev/null 2>&1 && \
   pacman -Q plasma6-applets-app-coupling-plus >/dev/null 2>&1; then
    printf 'Note: the system App Coupling+ package is installed.\n'
    printf 'This user-local development install will take precedence until ./uninstall-local.sh is run.\n\n'
fi

# Remove only App Coupling+'s previous user-local payload before installing.
rm -rf -- "$applet_dir"
for cleanup_qml_root in "${cleanup_qml_roots[@]}"; do
    rm -rf -- "$cleanup_qml_root/appcoupling/launcher"
    rmdir --ignore-fail-on-non-empty "$cleanup_qml_root/appcoupling" 2>/dev/null || true
done

cmake --install "$build_dir"

manifest="$build_dir/install_manifest.txt"
module_qmldir="$(grep '/appcoupling/launcher/qmldir$' "$manifest" | tail -n 1 || true)"
if [[ -z "$module_qmldir" ]]; then
    printf 'Error: could not determine the installed QML module path from %s\n' "$manifest" >&2
    exit 1
fi
qml_root="${module_qmldir%/appcoupling/launcher/qmldir}"

# The local installer deliberately uses the normal Qt 6 user QML root. Persist
# it for future logins while preserving any QML_IMPORT_PATH already configured.
mkdir -p "$env_dir"
printf '# Managed by App Coupling+ local installer.\nQML_IMPORT_PATH=%s${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}\n' \
    "$qml_root" > "$env_file"

# Update the current systemd user-manager environment without clobbering paths
# belonging to other local QML projects. Remove only roots that App Coupling+
# itself previously managed, deduplicate the new root, then prepend it.
if command -v systemctl >/dev/null 2>&1; then
    current_qml_path="$(systemctl --user show-environment 2>/dev/null | sed -n 's/^QML_IMPORT_PATH=//p' | head -n 1 || true)"
    preserved_qml_path=""

    if [[ -n "$current_qml_path" ]]; then
        IFS=':' read -ra current_paths <<< "$current_qml_path"
        for path in "${current_paths[@]}"; do
            [[ -n "$path" ]] || continue

            remove_path=false
            [[ "$path" == "$qml_root" ]] && remove_path=true
            if ! $remove_path; then
                for previous_root in "${previous_managed_qml_roots[@]}"; do
                    if [[ "$path" == "$previous_root" ]]; then
                        remove_path=true
                        break
                    fi
                done
            fi
            $remove_path && continue

            if [[ -n "$preserved_qml_path" ]]; then
                preserved_qml_path="$preserved_qml_path:$path"
            else
                preserved_qml_path="$path"
            fi
        done
    fi

    if [[ -n "$preserved_qml_path" ]]; then
        new_qml_path="$qml_root:$preserved_qml_path"
    else
        new_qml_path="$qml_root"
    fi
    systemctl --user set-environment "QML_IMPORT_PATH=$new_qml_path" || true
fi

printf '\nInstalled App Coupling+ into %s\n' "$prefix"
printf 'QML module root: %s\n' "$qml_root"
printf 'Restart Plasma before testing:\n'
printf '  systemctl --user restart plasma-plasmashell.service\n'
