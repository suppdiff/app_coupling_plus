#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
mode=${1:-}
case "$mode" in
    arch|fedora|debian) ;;
    *) printf 'Usage: %s {arch|fedora|debian} [output-directory]\n' "$0" >&2; exit 2 ;;
esac

destination=$(realpath -m -- "${2:-$(dirname -- "$root")/app_coupling_plus_PKG}")
case "$destination/" in
    "$root/"*) printf 'Package output must be outside the source tree.\n' >&2; exit 2 ;;
esac

version=$(sed -nE 's/^project\(AppCouplingPlus VERSION ([0-9]+\.[0-9]+\.[0-9]+) .*/\1/p' "$root/CMakeLists.txt")
[[ -n "$version" ]] || { printf 'Unable to read project version.\n' >&2; exit 1; }
temp=$(mktemp -d)
trap 'rm -rf -- "$temp"' EXIT
source_name="app-coupling-plus-$version"
mkdir -p -- "$temp/$source_name" "$destination"
cp -a -- "$root"/{CMakeLists.txt,LICENSE,README.md,CHANGELOG.md,package,plugin} "$temp/$source_name/"
tar -czf "$temp/$source_name.tar.gz" -C "$temp" "$source_name"

case "$mode" in
    arch)
        hash=$(sha256sum "$temp/$source_name.tar.gz")
        sed -e "s/@VERSION@/$version/g" -e "s/@SHA256@/${hash%% *}/g" \
            "$root/packaging/arch/PKGBUILD.in" > "$temp/PKGBUILD"
        (cd "$temp" && PKGDEST="$temp" SRCDEST="$temp" BUILDDIR="$temp" makepkg --cleanbuild)
        cp -- "$temp"/*.pkg.tar.* "$destination/"
        ;;
    fedora)
        top="$temp/rpm"
        mkdir -p "$top"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
        cp -- "$temp/$source_name.tar.gz" "$top/SOURCES/"
        sed "s/@VERSION@/$version/g" "$root/packaging/fedora/app-coupling-plus.spec.in" > "$top/SPECS/app-coupling-plus.spec"
        rpmbuild -bb --define "_topdir $top" --define "_tmppath $temp" "$top/SPECS/app-coupling-plus.spec"
        find "$top/RPMS" -type f -name '*.rpm' -exec cp -- {} "$destination/" \;
        ;;
    debian)
        cp -a -- "$root/packaging/debian" "$temp/$source_name/debian"
        cp -- "$temp/$source_name.tar.gz" "$temp/app-coupling-plus_${version}.orig.tar.gz"
        cat > "$temp/$source_name/debian/changelog" <<CHANGELOG
app-coupling-plus ($version-1) unstable; urgency=medium

  * Package App Coupling+ for Plasma 6.

 -- suppdiff <suppdiff@users.noreply.github.com>  $(date -R)
CHANGELOG
        (cd "$temp/$source_name" && dpkg-buildpackage -us -uc -b)
        cp -- "$temp"/*.deb "$destination/"
        ;;
esac
printf 'Package output: %s\n' "$destination"
