# SPDX-FileCopyrightText: 2026 suppdiff
# SPDX-License-Identifier: GPL-3.0-or-later

cmake_minimum_required(VERSION 3.20)

project(AppCouplingPlus VERSION 1.0.2 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(ECM 6.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs6)
include(FeatureSummary)

find_package(Qt6 6.7 REQUIRED COMPONENTS Core Gui Qml Widgets)
find_package(KF6 6.0 REQUIRED COMPONENTS Config CoreAddons KIO Service)
find_package(Plasma 6.0 REQUIRED)

# find_package(Plasma) provides plasma_install_package() on Plasma 6.
plasma_install_package(package io.github.suppdiff.appcouplingplus)
add_subdirectory(plugin)

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
