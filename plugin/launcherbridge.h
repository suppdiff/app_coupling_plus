// App Coupling+ local enhancement v1
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
    // Open a native image chooser; the selected file URL is emitted to QML.
    Q_INVOKABLE void selectIconFile();

Q_SIGNALS:
    void launcherAdded(const QString &url);
    void iconFileSelected(const QString &url);
    void launchError(const QString &message);
};
