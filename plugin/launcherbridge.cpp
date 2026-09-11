// SPDX-FileCopyrightText: 2026 suppdiff
// SPDX-License-Identifier: GPL-3.0-or-later

#include "launcherbridge.h"

#include <QFileInfo>
#include <QMimeDatabase>
#include <QMimeType>

#include <KDesktopFile>
#include <KJob>
#include <KJobUiDelegate>
#include <KOpenWithDialog>
#include <KService>
#include <KIO/JobUiDelegateFactory>
#include <KIO/OpenUrlJob>

LauncherBridge::LauncherBridge(QObject *parent)
    : QObject(parent)
{
}

QVariantMap LauncherBridge::launcherData(const QUrl &url) const
{
    QString name;
    QString genericName;
    QString iconName;

    if (url.isLocalFile()) {
        const QString path = url.toLocalFile();
        const QFileInfo fileInfo(path);

        if (path.endsWith(QLatin1String(".desktop"), Qt::CaseInsensitive)) {
            const KDesktopFile desktopFile(path);
            name = desktopFile.readName();
            genericName = desktopFile.readGenericName();
            iconName = desktopFile.readIcon();

            if (name.isEmpty()) {
                const auto service = KService::serviceByStorageId(path);
                if (service) {
                    name = service->name();
                    genericName = service->genericName();
                    iconName = service->icon();
                }
            }
        } else {
            const QMimeType mimeType = QMimeDatabase().mimeTypeForFile(fileInfo);
            name = fileInfo.completeBaseName();
            genericName = mimeType.comment();
            iconName = mimeType.iconName();
        }

        if (name.isEmpty()) {
            name = fileInfo.fileName();
        }
    } else {
        if (url.scheme() == QLatin1String("http") || url.scheme() == QLatin1String("https")) {
            name = url.host();
            iconName = QStringLiteral("internet-web-browser");
        } else {
            name = url.toDisplayString();
            iconName = QStringLiteral("system-run");
        }
    }

    if (iconName.isEmpty()) {
        iconName = QStringLiteral("system-run");
    }

    return {
        {QStringLiteral("applicationName"), name},
        {QStringLiteral("genericName"), genericName},
        {QStringLiteral("iconName"), iconName},
    };
}

void LauncherBridge::openUrl(const QUrl &url)
{
    if (!url.isValid() || url.isEmpty()) {
        Q_EMIT launchError(QStringLiteral("Invalid launcher URL"));
        return;
    }

    auto *job = new KIO::OpenUrlJob(url, this);

    // This widget is explicitly an application launcher. KIO still performs its
    // normal trust checks for desktop files outside standard application locations.
    job->setRunExecutables(true);

    if (auto *delegate = KIO::createDefaultJobUiDelegate(KJobUiDelegate::AutoHandlingEnabled, nullptr)) {
        job->setUiDelegate(delegate);
    }

    connect(job, &KJob::result, this, [this, job]() {
        if (job->error()) {
            Q_EMIT launchError(job->errorString());
        }
    });

    job->start();
}

void LauncherBridge::addLauncher()
{
    auto *dialog = new KOpenWithDialog();
    dialog->setModal(false);
    dialog->setAttribute(Qt::WA_DeleteOnClose);
    dialog->hideRunInTerminal();
    dialog->setSaveNewApplications(true);

    connect(dialog, &KOpenWithDialog::accepted, this, [this, dialog]() {
        const auto service = dialog->service();
        if (!service) {
            return;
        }

        const QUrl launcherUrl = QUrl::fromLocalFile(service->entryPath());
        if (launcherUrl.isValid()) {
            Q_EMIT launcherAdded(launcherUrl.toString());
        }
    });

    dialog->show();
}
