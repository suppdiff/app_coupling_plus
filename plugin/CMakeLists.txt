# SPDX-FileCopyrightText: 2026 suppdiff
# SPDX-License-Identifier: GPL-3.0-or-later

add_library(appcouplinglauncherplugin SHARED
    launcherbridge.cpp
    launcherbridge.h
    launcherplugin.cpp
)

target_link_libraries(appcouplinglauncherplugin PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Widgets
    KF6::ConfigCore
    KF6::CoreAddons
    KF6::KIOGui
    KF6::KIOWidgets
    KF6::Service
)

# Install as a proper QML module. For a system package this resolves under
# /usr; for our local developer install it resolves under ~/.local.
set(APP_COUPLING_QML_MODULE_DIR "${KDE_INSTALL_QMLDIR}/appcoupling/launcher")

install(TARGETS appcouplinglauncherplugin
    LIBRARY DESTINATION "${APP_COUPLING_QML_MODULE_DIR}"
)
install(FILES qmldir
    DESTINATION "${APP_COUPLING_QML_MODULE_DIR}"
)
