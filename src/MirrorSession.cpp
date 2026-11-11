#include "MirrorSession.h"
#include <QStandardPaths>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QSettings>
#include <QDebug>

MirrorSession::MirrorSession(QObject *parent)
    : QObject(parent)
{
    m_scrcpyProcess = new QProcess(this);

    connect(m_scrcpyProcess, &QProcess::started, this, [this]() {
        m_errorMessage.clear();
        Q_EMIT errorMessageChanged(m_errorMessage);
        Q_EMIT runningChanged(true);
    });

    connect(m_scrcpyProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, [this](int exitCode, QProcess::ExitStatus exitStatus) {
        Q_UNUSED(exitStatus);
        Q_EMIT runningChanged(false);
        Q_EMIT sessionFinished(exitCode);
    });

    connect(m_scrcpyProcess, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart) {
            m_errorMessage = tr("No se pudo iniciar scrcpy. ¿Está instalado en el sistema?");
            Q_EMIT errorMessageChanged(m_errorMessage);
            Q_EMIT runningChanged(false);
        }
    });
}

MirrorSession::~MirrorSession()
{
    stopMirroring();
}

bool MirrorSession::isRunning() const
{
    return m_scrcpyProcess && m_scrcpyProcess->state() != QProcess::NotRunning;
}

QStringList MirrorSession::buildScrcpyArgs(const QString &serial,
                                          bool turnScreenOff,
                                          bool stayAwake,
                                          bool audio,
                                          int maxFps,
                                          int bitrateMbps,
                                          const QString &windowTitle)
{
    QStringList args;

    if (!serial.isEmpty()) {
        args << "-s" << serial;
    }

    if (turnScreenOff) {
        args << "--turn-screen-off";
    }

    if (stayAwake) {
        args << "--stay-awake";
    }

    if (audio) {
        args << "--audio-source=playback";
    } else {
        args << "--no-audio";
    }

    if (maxFps > 0) {
        args << QString("--max-fps=%1").arg(maxFps);
    }

    if (bitrateMbps > 0) {
        args << QString("--video-bit-rate=%1M").arg(bitrateMbps);
    }

    // Modern macOS Sequoia style window title and hotkeys
    const QString title = windowTitle.isEmpty() ? QStringLiteral("Phone Mirroring") : windowTitle;
    args << QString("--window-title=%1").arg(title);
    args << "--shortcut-mod=lalt";

    return args;
}

bool MirrorSession::startMirroring(const QString &serial,
                                   bool turnScreenOff,
                                   bool stayAwake,
                                   bool audio,
                                   int maxFps,
                                   int bitrateMbps,
                                   const QString &windowTitle)
{
    if (isRunning()) {
        stopMirroring();
    }

    m_activeSerial = serial;
    Q_EMIT activeSerialChanged(m_activeSerial);

    const QStringList args = buildScrcpyArgs(serial, turnScreenOff, stayAwake, audio, maxFps, bitrateMbps, windowTitle);

    m_scrcpyProcess->start("scrcpy", args);
    return true;
}

void MirrorSession::stopMirroring()
{
    if (isRunning()) {
        m_scrcpyProcess->terminate();
        if (!m_scrcpyProcess->waitForFinished(1500)) {
            m_scrcpyProcess->kill();
        }
    }
}

void MirrorSession::runAdbShellCommand(const QStringList &args)
{
    if (m_activeSerial.isEmpty()) return;

    QStringList cmdArgs;
    cmdArgs << "-s" << m_activeSerial << "shell" << args;

    QProcess *proc = new QProcess(this);
    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), proc, &QObject::deleteLater);
    proc->start("adb", cmdArgs);
}

void MirrorSession::sendHome()
{
    runAdbShellCommand({"input", "keyevent", "3"});
}

void MirrorSession::sendAppSwitcher()
{
    runAdbShellCommand({"input", "keyevent", "187"});
}

void MirrorSession::sendBack()
{
    runAdbShellCommand({"input", "keyevent", "4"});
}

void MirrorSession::sendLock()
{
    runAdbShellCommand({"input", "keyevent", "26"});
}

void MirrorSession::sendVolumeUp()
{
    runAdbShellCommand({"input", "keyevent", "24"});
}

void MirrorSession::sendVolumeDown()
{
    runAdbShellCommand({"input", "keyevent", "25"});
}

void MirrorSession::sendExpandNotifications()
{
    runAdbShellCommand({"cmd", "statusbar", "expand-notifications"});
}

void MirrorSession::sendExpandSettings()
{
    runAdbShellCommand({"cmd", "statusbar", "expand-settings"});
}

void MirrorSession::setControlCenterVisible(bool visible)
{
    if (m_controlCenterVisible == visible) {
        return;
    }
    m_controlCenterVisible = visible;
    Q_EMIT controlCenterVisibleChanged();
}

void MirrorSession::openControlCenter()
{
    setControlCenterVisible(!m_controlCenterVisible);
    if (m_controlCenterVisible) {
        runAdbShellCommand({"cmd", "statusbar", "expand-settings"});
    }
}

void MirrorSession::openSpotlight()
{
    runAdbShellCommand({"input", "keyevent", "84"});
}

void MirrorSession::openApp(const QString &appId, const QString &appTitle, const QString &androidPackage)
{
    const QString cleanId = appId.trimmed().isEmpty() ? QStringLiteral("today") : appId.trimmed();
    m_currentAppId = cleanId;
    m_currentAppTitle = appTitle.trimmed().isEmpty() ? cleanId : appTitle.trimmed();
    Q_EMIT currentAppChanged();

    if (!androidPackage.trimmed().isEmpty()) {
        runAdbShellCommand({"monkey", "-p", androidPackage.trimmed(), "-c", "android.intent.category.LAUNCHER", "1"});
    }

    const QVariantMap saved = rememberedSizeForApp(cleanId);
    const int w = saved.value(QStringLiteral("width"), 780).toInt();
    const int h = saved.value(QStringLiteral("height"), 620).toInt();
    Q_EMIT requestWindowResize(w, h);
}

void MirrorSession::returnToHomeScreen()
{
    m_currentAppId = QStringLiteral("home");
    m_currentAppTitle = QStringLiteral("Home Screen");
    m_controlCenterVisible = false;
    Q_EMIT currentAppChanged();
    Q_EMIT controlCenterVisibleChanged();

    sendHome();
    // Golden Gate resets window to normal portrait size when returning to Home Screen
    Q_EMIT requestWindowResize(440, 700);
}

void MirrorSession::saveAppWindowSize(const QString &appId, int width, int height)
{
    const QString cleanId = appId.trimmed();
    if (cleanId.isEmpty() || cleanId == QLatin1String("home")) {
        return;
    }
    QSettings settings(QStringLiteral("cesar.org"), QStringLiteral("kphonemirroring"));
    settings.beginGroup(QStringLiteral("AppWindowSizes"));
    settings.setValue(cleanId + QStringLiteral("_width"), qBound(400, width, 1600));
    settings.setValue(cleanId + QStringLiteral("_height"), qBound(520, height, 1200));
    settings.endGroup();
    settings.sync();
}

QVariantMap MirrorSession::rememberedSizeForApp(const QString &appId) const
{
    const QString cleanId = appId.trimmed();
    QSettings settings(QStringLiteral("cesar.org"), QStringLiteral("kphonemirroring"));
    settings.beginGroup(QStringLiteral("AppWindowSizes"));
    const int defaultW = (cleanId == QLatin1String("home")) ? 440 : 780;
    const int defaultH = (cleanId == QLatin1String("home")) ? 700 : 620;
    const int w = settings.value(cleanId + QStringLiteral("_width"), defaultW).toInt();
    const int h = settings.value(cleanId + QStringLiteral("_height"), defaultH).toInt();
    settings.endGroup();
    return {
        {QStringLiteral("width"), w},
        {QStringLiteral("height"), h}
    };
}

void MirrorSession::takeScreenshot()
{
    if (m_activeSerial.isEmpty()) return;

    QString picturesPath = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
    if (picturesPath.isEmpty()) {
        picturesPath = QDir::homePath();
    }

    const QString fileName = QString("Screenshot_Phone_%1.png")
                                 .arg(QDateTime::currentDateTime().toString("yyyyMMdd_hhmmss"));
    const QString fullPath = picturesPath + "/" + fileName;

    QProcess *proc = new QProcess(this);
    proc->start("adb", QStringList() << "-s" << m_activeSerial << "exec-out" << "screencap" << "-p");

    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, [this, proc, fullPath](int exitCode) {
        if (exitCode == 0) {
            QByteArray data = proc->readAllStandardOutput();
            QFile file(fullPath);
            if (file.open(QIODevice::WriteOnly)) {
                file.write(data);
                file.close();
                Q_EMIT screenshotTaken(fullPath);
            }
        }
        proc->deleteLater();
    });
}
