// SPDX-FileCopyrightText: 2026 suppdiff
// SPDX-License-Identifier: GPL-3.0-or-later

#include "launcherbridge.h"

#include <QFileDialog>
#include <QFileInfo>
#include <QImageReader>
#include <QMimeDatabase>
#include <QMimeType>
#include <QUuid>

#include <KDesktopFile>
#include <KIconDialog>
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

LauncherBridge::~LauncherBridge()
{
    delete m_iconPicker.data();
    delete m_applicationChooser.data();
}

QString LauncherBridge::makeKey() const
{
    return QUuid::createUuid().toString(QUuid::WithoutBraces);
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
    if (m_applicationChooser && m_applicationChooser->isVisible()) {
        m_applicationChooser->activateWindow();
        return;
    }
    auto *dialog = new KOpenWithDialog();
    m_applicationChooser = dialog;
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

void LauncherBridge::closeIconPicker()
{
    const auto picker = m_iconPicker;
    m_iconPicker.clear();
    if (picker) {
        picker->disconnect(this);
        picker->reject();
        if (picker) {
            picker->deleteLater();
        }
    }
}

void LauncherBridge::chooseIcon(bool localFile)
{
    closeIconPicker();
    if (localFile) {
        auto *picker = new QFileDialog;
        m_iconPicker = picker;
        picker->setAttribute(Qt::WA_DeleteOnClose);
        picker->setFileMode(QFileDialog::ExistingFile);
        QStringList imageTypes;
        for (const auto &mimeType : QImageReader::supportedMimeTypes()) {
            imageTypes.push_back(QString::fromLatin1(mimeType));
        }
        picker->setMimeTypeFilters(imageTypes);
        connect(picker, &QFileDialog::fileSelected, this, [this, picker](const QString &path) {
            if (m_iconPicker == picker && !path.isEmpty()) {
                Q_EMIT iconChosen(QUrl::fromLocalFile(path).toString());
            }
        });
        picker->show();
    } else {
        auto *picker = new KIconDialog;
        m_iconPicker = picker;
        picker->setAttribute(Qt::WA_DeleteOnClose);
        picker->setup(KIconLoader::Desktop, KIconLoader::Any, false, 0, false, true);
        connect(picker, &KIconDialog::newIconName, this, [this, picker](const QString &name) {
            if (m_iconPicker == picker && !name.isEmpty()) {
                Q_EMIT iconChosen(name);
            }
        });
        picker->showDialog();
    }
}
