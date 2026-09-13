# Maintainer: suppdiff <327834173+suppdiff@users.noreply.github.com>
pkgname=plasma6-applets-app-coupling-plus
pkgver=1.0.2
pkgrel=1
pkgdesc="Configurable KDE Plasma 6 application launcher widget with tabs and independent launcher groups"
arch=('x86_64')
url="https://github.com/suppdiff/app_coupling_plus"
license=('GPL-3.0-or-later')

depends=(
    'kconfig'
    'kcoreaddons'
    'kdeclarative'
    'kio'
    'kirigami'
    'kservice'
    'libplasma'
    'qt6-base'
    'qt6-declarative'
)

makedepends=(
    'cmake'
    'extra-cmake-modules'
)

source=(
    "$pkgname-$pkgver.tar.gz::https://github.com/suppdiff/app_coupling_plus/archive/refs/tags/v$pkgver.tar.gz"
)

sha256sums=('afa4e39b19d02965c19594bf10cd01290a2ff07a8c2a095278713825bb4a3004')

build() {
    cmake -B build -S "app_coupling_plus-$pkgver" \
        -DCMAKE_BUILD_TYPE=None \
        -DCMAKE_INSTALL_PREFIX=/usr \


    cmake --build build
}

package() {
    DESTDIR="$pkgdir" cmake --install build
}
