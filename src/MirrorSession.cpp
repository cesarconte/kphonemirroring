#include "MirrorSession.h"
#include <QStandardPaths>
#include <QDateTime>
#include <QDir>
#include <QFile>
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
