#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantMap>
#include <QProcess>

class MirrorSession : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isRunning READ isRunning NOTIFY runningChanged)
    Q_PROPERTY(QString activeSerial READ activeSerial NOTIFY activeSerialChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)
    Q_PROPERTY(QString currentAppId READ currentAppId NOTIFY currentAppChanged)
    Q_PROPERTY(QString currentAppTitle READ currentAppTitle NOTIFY currentAppChanged)
    Q_PROPERTY(bool controlCenterVisible READ controlCenterVisible WRITE setControlCenterVisible NOTIFY controlCenterVisibleChanged)

    // Golden Gate mirroring options (persisted in ~/.config/cesar.org/kphonemirroring.conf)
    Q_PROPERTY(bool turnScreenOff READ turnScreenOff WRITE setTurnScreenOff NOTIFY optionsChanged)
    Q_PROPERTY(bool stayAwake READ stayAwake WRITE setStayAwake NOTIFY optionsChanged)
    Q_PROPERTY(bool audioEnabled READ audioEnabled WRITE setAudioEnabled NOTIFY optionsChanged)
    Q_PROPERTY(int maxFps READ maxFps WRITE setMaxFps NOTIFY optionsChanged)
    Q_PROPERTY(int bitrateMbps READ bitrateMbps WRITE setBitrateMbps NOTIFY optionsChanged)

public:
    explicit MirrorSession(QObject *parent = nullptr);
    ~MirrorSession() override;

    bool isRunning() const;
    QString activeSerial() const { return m_activeSerial; }
    QString errorMessage() const { return m_errorMessage; }
    QString currentAppId() const { return m_currentAppId; }
    QString currentAppTitle() const { return m_currentAppTitle; }
    bool controlCenterVisible() const { return m_controlCenterVisible; }
    void setControlCenterVisible(bool visible);

    bool turnScreenOff() const { return m_turnScreenOff; }
    bool stayAwake() const { return m_stayAwake; }
    bool audioEnabled() const { return m_audioEnabled; }
    int maxFps() const { return m_maxFps; }
    int bitrateMbps() const { return m_bitrateMbps; }

    void setTurnScreenOff(bool enabled);
    void setStayAwake(bool enabled);
    void setAudioEnabled(bool enabled);
    void setMaxFps(int fps);
    void setBitrateMbps(int mbps);

    static int clampMaxFps(int fps);
    static int clampBitrateMbps(int mbps);

    static QStringList buildScrcpyArgs(const QString &serial,
                                      bool turnScreenOff = true,
                                      bool stayAwake = true,
                                      bool audio = true,
                                      int maxFps = 60,
                                      int bitrateMbps = 16,
                                      const QString &windowTitle = QString());

public Q_SLOTS:
    bool startMirroring(const QString &serial, const QString &windowTitle = QString());
    void stopMirroring();

    // Golden Gate & Sequoia Quick Actions
    void sendHome();
    void sendAppSwitcher();
    void sendBack();
    void sendLock();
    void sendVolumeUp();
    void sendVolumeDown();
    void sendExpandNotifications();
    void sendExpandSettings();
    void openControlCenter();
    void openSpotlight();
    void takeScreenshot();

    // Golden Gate Per-App Dynamic Window Size Memory
    void openApp(const QString &appId, const QString &appTitle, const QString &androidPackage = QString());
    void returnToHomeScreen();
    void saveAppWindowSize(const QString &appId, int width, int height);
    QVariantMap rememberedSizeForApp(const QString &appId) const;

Q_SIGNALS:
    void runningChanged(bool running);
    void activeSerialChanged(const QString &serial);
    void errorMessageChanged(const QString &error);
    void screenshotTaken(const QString &filePath);
    void sessionFinished(int exitCode);
    void currentAppChanged();
    void controlCenterVisibleChanged();
    void requestWindowResize(int width, int height);
    void optionsChanged();

private:
    void runAdbShellCommand(const QStringList &args);
    void loadOptions();
    void saveOptions();

    QProcess *m_scrcpyProcess = nullptr;
    QString m_activeSerial;
    QString m_errorMessage;
    QString m_currentAppId = QStringLiteral("today");
    QString m_currentAppTitle = QStringLiteral("Today");
    bool m_controlCenterVisible = false;

    bool m_turnScreenOff = true;
    bool m_stayAwake = true;
    bool m_audioEnabled = true;
    int m_maxFps = 60;
    int m_bitrateMbps = 16;
};
