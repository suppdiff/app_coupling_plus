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

cmake -S "$root_dir" -B "$build_dir" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$prefix"

cmake --build "$build_dir" --parallel

# A user-local development install takes precedence over a system package.
# Make that explicit so it is not surprising while testing packages.
if command -v pacman >/dev/null 2>&1 && \
   pacman -Q plasma6-applets-app-coupling-plus >/dev/null 2>&1; then
    printf 'Note: the system App Coupling+ package is installed.\n'
    printf 'This user-local development install will take precedence until ./uninstall-local.sh is run.\n\n'
fi

# Collect QML roots used by earlier App Coupling+ development installs before
# overwriting the managed environment file. This lets upgrades clean stale
# modules even if Qt/KDE used a different user-local library layout previously.
previous_qml_roots=()

add_previous_qml_root() {
    local candidate="${1:-}"
    [[ -n "$candidate" ]] || return 0
    [[ "$candidate" == "$prefix/"* ]] || return 0

    local existing
    for existing in "${previous_qml_roots[@]:-}"; do
        [[ "$existing" == "$candidate" ]] && return 0
    done
    previous_qml_roots+=("$candidate")
}

previous_manifest="$build_dir/install_manifest.txt"
if [[ -f "$previous_manifest" ]]; then
    previous_module_qmldir="$(grep '/appcoupling/launcher/qmldir$' "$previous_manifest" | tail -n 1 || true)"
    if [[ -n "$previous_module_qmldir" ]]; then
        add_previous_qml_root "${previous_module_qmldir%/appcoupling/launcher/qmldir}"
    fi
fi

if [[ -f "$env_file" ]] && grep -q '^# Managed by App Coupling+ local installer\.$' "$env_file"; then
    previous_env_qml_root="$(sed -n 's/^QML_IMPORT_PATH=\([^$]*\).*$/\1/p' "$env_file" | head -n 1 || true)"
    add_previous_qml_root "$previous_env_qml_root"
fi

# Also cover the user-local layouts used by current Qt/KDE installations.
add_previous_qml_root "$prefix/lib/qml"
add_previous_qml_root "$prefix/lib/qt6/qml"

# Remove only App Coupling+'s previous user-local payload before installing.
# This prevents files removed or renamed between development versions from
# surviving as stale files.
rm -rf -- "$applet_dir"
for previous_qml_root in "${previous_qml_roots[@]}"; do
    rm -rf -- "$previous_qml_root/appcoupling/launcher"
    rmdir --ignore-fail-on-non-empty "$previous_qml_root/appcoupling" 2>/dev/null || true
done

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
mkdir -p "$env_dir"
printf '# Managed by App Coupling+ local installer.\nQML_IMPORT_PATH=%s${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}\n' \
    "$qml_root" > "$env_file"

# Also update the current systemd user-manager environment so a plasmashell
# restart is enough; no logout is needed just to test this build.
if command -v systemctl >/dev/null 2>&1; then
    current_qml_path="$(systemctl --user show-environment 2>/dev/null | sed -n 's/^QML_IMPORT_PATH=//p' | head -n 1 || true)"
    preserved_qml_path=""

    if [[ -n "$current_qml_path" ]]; then
        IFS=':' read -ra current_paths <<< "$current_qml_path"
        for path in "${current_paths[@]}"; do
            [[ -n "$path" ]] || continue

            # Drop QML roots previously managed by App Coupling+, plus any
            # existing copy of the newly installed root, while preserving all
            # unrelated QML_IMPORT_PATH entries.
            remove_path=false
            [[ "$path" == "$qml_root" ]] && remove_path=true
            if ! $remove_path; then
                for previous_qml_root in "${previous_qml_roots[@]}"; do
                    if [[ "$path" == "$previous_qml_root" ]]; then
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
