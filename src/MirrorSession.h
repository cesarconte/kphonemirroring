#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QProcess>

class MirrorSession : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isRunning READ isRunning NOTIFY runningChanged)
    Q_PROPERTY(QString activeSerial READ activeSerial NOTIFY activeSerialChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)

public:
    explicit MirrorSession(QObject *parent = nullptr);
    ~MirrorSession() override;

    bool isRunning() const;
    QString activeSerial() const { return m_activeSerial; }
    QString errorMessage() const { return m_errorMessage; }

    static QStringList buildScrcpyArgs(const QString &serial,
                                      bool turnScreenOff = true,
                                      bool stayAwake = true,
                                      bool audio = true,
                                      int maxFps = 60,
                                      int bitrateMbps = 16,
                                      const QString &windowTitle = QString());

public Q_SLOTS:
    bool startMirroring(const QString &serial,
                        bool turnScreenOff = true,
                        bool stayAwake = true,
                        bool audio = true,
                        int maxFps = 60,
                        int bitrateMbps = 16,
                        const QString &windowTitle = QString());
    void stopMirroring();

    // Sequoia Quick Actions
    void sendHome();
    void sendAppSwitcher();
    void sendBack();
    void sendLock();
    void sendVolumeUp();
    void sendVolumeDown();
    void sendExpandNotifications();
    void sendExpandSettings();
    void takeScreenshot();

Q_SIGNALS:
    void runningChanged(bool running);
    void activeSerialChanged(const QString &serial);
    void errorMessageChanged(const QString &error);
    void screenshotTaken(const QString &filePath);
    void sessionFinished(int exitCode);

private:
    void runAdbShellCommand(const QStringList &args);

    QProcess *m_scrcpyProcess = nullptr;
    QString m_activeSerial;
    QString m_errorMessage;
};
