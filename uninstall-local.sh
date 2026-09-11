#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 suppdiff
# SPDX-License-Identifier: GPL-3.0-or-later

set -euo pipefail

root_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
manifest="$root_dir/build/install_manifest.txt"
env_file="$HOME/.config/environment.d/90-app-coupling-plus.conf"

if [[ ! -f "$manifest" ]]; then
    printf 'No install manifest found at %s\n' "$manifest" >&2
    printf 'Nothing was removed.\n' >&2
    exit 1
fi

while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    if [[ "$path" == "$HOME/.local/"* && -e "$path" ]]; then
        rm -f -- "$path"
        printf 'removed %s\n' "$path"
    fi
done < "$manifest"

if [[ -f "$env_file" ]] && grep -q '^# Managed by App Coupling+ local installer\.$' "$env_file"; then
    rm -f -- "$env_file"
    printf 'removed %s\n' "$env_file"
fi

printf 'Finished. Empty directories, if any, were left in place intentionally.\n'
printf 'The current session may retain the old QML import path until logout; that is harmless.\n'
