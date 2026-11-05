#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <QTimer>
#include <QProcess>

struct DeviceInfo {
    QString serial;
    QString name;
    QString model;
    QString androidVersion;
    QString osType; // "HyperOS", "Android", etc.
    QString transport; // "usb" or "wifi"
    QString state; // "device", "unauthorized", "offline"
    int batteryLevel = -1;
    bool isCharging = false;
    QString ipAddress;
    bool isWireless = false;

    QVariantMap toMap() const {
        return {
            {"serial", serial},
            {"name", name},
            {"model", model},
            {"androidVersion", androidVersion},
            {"osType", osType},
            {"transport", transport},
            {"state", state},
            {"batteryLevel", batteryLevel},
            {"isCharging", isCharging},
            {"ipAddress", ipAddress},
            {"isWireless", isWireless}
        };
    }
};

class DeviceManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList devices READ devices NOTIFY devicesChanged)
    Q_PROPERTY(QVariantMap selectedDevice READ selectedDevice NOTIFY selectedDeviceChanged)
    Q_PROPERTY(bool hasDevice READ hasDevice NOTIFY devicesChanged)
    Q_PROPERTY(bool isScanning READ isScanning NOTIFY isScanningChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)

public:
    explicit DeviceManager(QObject *parent = nullptr);
    ~DeviceManager() override = default;

    QVariantList devices() const;
    QVariantMap selectedDevice() const;
    bool hasDevice() const;
    bool isScanning() const { return m_isScanning; }
    QString statusMessage() const { return m_statusMessage; }

    static QList<DeviceInfo> parseAdbDevicesOutput(const QString &output);

public Q_SLOTS:
    void refresh();
    void selectDevice(const QString &serial);
    void enableWirelessMode(const QString &usbSerial = QString());
    void disconnectWireless(const QString &ipPort);

Q_SIGNALS:
    void devicesChanged();
    void selectedDeviceChanged();
    void isScanningChanged();
    void statusMessageChanged();
    void wirelessModeConfigured(const QString &ipPort, bool success);

private:
    void updateDeviceInfo(DeviceInfo &dev);
    void queryBattery(DeviceInfo &dev);
    void queryNetwork(DeviceInfo &dev);

    QList<DeviceInfo> m_deviceList;
    QString m_selectedSerial;
    bool m_isScanning = false;
    QString m_statusMessage;
    QTimer *m_pollTimer = nullptr;
};
