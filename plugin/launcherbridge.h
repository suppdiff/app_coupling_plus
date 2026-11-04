// SPDX-FileCopyrightText: 2026 suppdiff
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QPointer>
#include <QUrl>
#include <QVariantMap>

class QDialog;

class LauncherBridge : public QObject
{
    Q_OBJECT

public:
    explicit LauncherBridge(QObject *parent = nullptr);

    ~LauncherBridge() override;

    Q_INVOKABLE QString makeKey() const;
    Q_INVOKABLE QVariantMap launcherData(const QUrl &url) const;
    Q_INVOKABLE void openUrl(const QUrl &url);
    Q_INVOKABLE void addLauncher();
    Q_INVOKABLE void chooseIcon(bool localFile);
    Q_INVOKABLE void closeIconPicker();

Q_SIGNALS:
    void launcherAdded(const QString &url);
    void iconChosen(const QString &icon);
    void launchError(const QString &message);
private:
    QPointer<QDialog> m_applicationChooser;
    QPointer<QDialog> m_iconPicker;
};
