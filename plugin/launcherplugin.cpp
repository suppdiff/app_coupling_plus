// SPDX-FileCopyrightText: 2026 suppdiff
// SPDX-License-Identifier: GPL-3.0-or-later

#include "launcherbridge.h"

#include <QQmlExtensionPlugin>
#include <qqml.h>

class AppCouplingLauncherPlugin final : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid)

public:
    void registerTypes(const char *uri) override
    {
        qmlRegisterType<LauncherBridge>(uri, 1, 0, "LauncherBridge");
    }
};

#include "launcherplugin.moc"
