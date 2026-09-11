// SPDX-FileCopyrightText: 2026 suppdiff
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QUrl>
#include <QVariantMap>

class LauncherBridge : public QObject
{
    Q_OBJECT

public:
    explicit LauncherBridge(QObject *parent = nullptr);

    Q_INVOKABLE QVariantMap launcherData(const QUrl &url) const;
    Q_INVOKABLE void openUrl(const QUrl &url);
    Q_INVOKABLE void addLauncher();

Q_SIGNALS:
    void launcherAdded(const QString &url);
    void launchError(const QString &message);
};
