#include "DeviceManager.h"
#include <QRegularExpression>
#include <QDebug>
#include <QThread>

DeviceManager::DeviceManager(QObject *parent)
    : QObject(parent)
{
    m_pollTimer = new QTimer(this);
    m_pollTimer->setInterval(3000);
    connect(m_pollTimer, &QTimer::timeout, this, &DeviceManager::refresh);
    m_pollTimer->start();

    refresh();
}

QVariantList DeviceManager::devices() const
{
    QVariantList list;
    for (const auto &dev : m_deviceList) {
        list.append(dev.toMap());
    }
    return list;
}

QVariantMap DeviceManager::selectedDevice() const
{
    for (const auto &dev : m_deviceList) {
        if (dev.serial == m_selectedSerial) {
            return dev.toMap();
        }
    }
    if (!m_deviceList.isEmpty()) {
        return m_deviceList.first().toMap();
    }
    return {};
}

bool DeviceManager::hasDevice() const
{
    return !m_deviceList.isEmpty();
}

void DeviceManager::selectDevice(const QString &serial)
{
    if (m_selectedSerial != serial) {
        m_selectedSerial = serial;
        Q_EMIT selectedDeviceChanged();
    }
}

QList<DeviceInfo> DeviceManager::parseAdbDevicesOutput(const QString &output)
{
    QList<DeviceInfo> list;
    const QStringList lines = output.split('\n', Qt::SkipEmptyParts);

    for (const QString &line : lines) {
        const QString trimmed = line.trimmed();
        if (trimmed.isEmpty() || trimmed.startsWith('*') || trimmed.startsWith("List of devices")) {
            continue;
        }

        const QStringList parts = trimmed.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
        if (parts.size() < 2) {
            continue;
        }

        DeviceInfo dev;
        dev.serial = parts.at(0);
        dev.state = parts.at(1);
        dev.isWireless = dev.serial.contains(':');
        dev.transport = dev.isWireless ? "wifi" : "usb";

        for (int i = 2; i < parts.size(); ++i) {
            const QString &part = parts.at(i);
            if (part.startsWith("model:")) {
                dev.model = part.mid(6);
            } else if (part.startsWith("product:")) {
                if (dev.name.isEmpty()) dev.name = part.mid(8);
            }
        }

        if (dev.name.isEmpty()) {
            dev.name = dev.model.isEmpty() ? dev.serial : dev.model;
        }

        list.append(dev);
    }

    return list;
}

void DeviceManager::refresh()
{
    if (m_isScanning) return;
    m_isScanning = true;
    Q_EMIT isScanningChanged();

    QProcess proc;
    proc.start("adb", QStringList() << "devices" << "-l");
    if (!proc.waitForFinished(2000)) {
        proc.kill();
        m_isScanning = false;
        Q_EMIT isScanningChanged();
        return;
    }

    const QString output = QString::fromUtf8(proc.readAllStandardOutput());
    QList<DeviceInfo> parsed = parseAdbDevicesOutput(output);

    // Update details for each authorized device
    for (DeviceInfo &dev : parsed) {
        if (dev.state == "device") {
            updateDeviceInfo(dev);
        }
    }

    m_deviceList = parsed;

    // Ensure selected serial is valid or prefer USB/First
    bool found = false;
    for (const auto &dev : m_deviceList) {
        if (dev.serial == m_selectedSerial) {
            found = true;
            break;
        }
    }
    if (!found && !m_deviceList.isEmpty()) {
        m_selectedSerial = m_deviceList.first().serial;
    }

    m_isScanning = false;
    Q_EMIT isScanningChanged();
    Q_EMIT devicesChanged();
    Q_EMIT selectedDeviceChanged();
}

void DeviceManager::updateDeviceInfo(DeviceInfo &dev)
{
    // Market name (friendly name)
    QProcess proc;
    proc.start("adb", QStringList() << "-s" << dev.serial << "shell" << "getprop" << "ro.product.marketname");
    if (proc.waitForFinished(1000)) {
        QString market = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
        if (!market.isEmpty()) {
            dev.name = market;
        }
    }

    // Android release
    proc.start("adb", QStringList() << "-s" << dev.serial << "shell" << "getprop" << "ro.build.version.release");
    if (proc.waitForFinished(1000)) {
        dev.androidVersion = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
    }

    // OS check (HyperOS / MIUI / AOSP)
    proc.start("adb", QStringList() << "-s" << dev.serial << "shell" << "getprop" << "ro.miui.ui.version.name");
    if (proc.waitForFinished(1000)) {
        QString miui = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
        if (!miui.isEmpty()) {
            dev.osType = "HyperOS";
        } else {
            dev.osType = "Android";
        }
    }

    queryBattery(dev);
    queryNetwork(dev);
}

void DeviceManager::queryBattery(DeviceInfo &dev)
{
    QProcess proc;
    proc.start("adb", QStringList() << "-s" << dev.serial << "shell" << "dumpsys" << "battery");
    if (proc.waitForFinished(1000)) {
        const QString out = QString::fromUtf8(proc.readAllStandardOutput());
        const QStringList lines = out.split('\n');
        for (const QString &line : lines) {
            const QString tr = line.trimmed();
            if (tr.startsWith("level:")) {
                dev.batteryLevel = tr.mid(6).trimmed().toInt();
            } else if (tr.startsWith("USB powered: true") || tr.startsWith("AC powered: true") || tr.startsWith("status: 2")) {
                dev.isCharging = true;
            }
        }
    }
}

void DeviceManager::queryNetwork(DeviceInfo &dev)
{
    if (dev.isWireless) {
        dev.ipAddress = dev.serial.section(':', 0, 0);
        return;
    }

    QProcess proc;
    proc.start("adb", QStringList() << "-s" << dev.serial << "shell" << "ip" << "route");
    if (proc.waitForFinished(1000)) {
        const QString out = QString::fromUtf8(proc.readAllStandardOutput());
        const QStringList lines = out.split('\n');
        for (const QString &line : lines) {
            const QStringList tokens = line.trimmed().split(' ');
            if (tokens.contains("src")) {
                int idx = tokens.indexOf("src");
                if (idx + 1 < tokens.size()) {
                    QString ip = tokens.at(idx + 1);
                    if (!ip.startsWith("127.") && !ip.startsWith("10.108.")) {
                        dev.ipAddress = ip;
                    } else if (dev.ipAddress.isEmpty()) {
                        dev.ipAddress = ip;
                    }
                }
            }
        }
    }
}

void DeviceManager::enableWirelessMode(const QString &usbSerial)
{
    QString target = usbSerial;
    if (target.isEmpty()) {
        for (const auto &dev : m_deviceList) {
            if (!dev.isWireless && dev.state == "device") {
                target = dev.serial;
                break;
            }
        }
    }

    if (target.isEmpty()) {
        m_statusMessage = tr("No hay dispositivo USB conectado para habilitar Wi-Fi.");
        Q_EMIT statusMessageChanged();
        Q_EMIT wirelessModeConfigured(QString(), false);
        return;
    }

    m_statusMessage = tr("Activando modo inalámbrico TCP/IP en puerto 5555...");
    Q_EMIT statusMessageChanged();

    // 1. adb -s <target> tcpip 5555
    QProcess proc;
    proc.start("adb", QStringList() << "-s" << target << "tcpip" << "5555");
    proc.waitForFinished(3000);

    // 2. Find IP
    QString ip;
    for (const auto &dev : m_deviceList) {
        if (dev.serial == target && !dev.ipAddress.isEmpty()) {
            ip = dev.ipAddress;
            break;
        }
    }

    if (ip.isEmpty()) {
        proc.start("adb", QStringList() << "-s" << target << "shell" << "ip" << "route");
        if (proc.waitForFinished(2000)) {
            QString out = QString::fromUtf8(proc.readAllStandardOutput());
            for (const QString &line : out.split('\n')) {
                QStringList tokens = line.trimmed().split(' ');
                int idx = tokens.indexOf("src");
                if (idx != -1 && idx + 1 < tokens.size()) {
                    QString candidate = tokens.at(idx + 1);
                    if (candidate.startsWith("192.168.") || candidate.startsWith("10.")) {
                        ip = candidate;
                        break;
                    }
                }
            }
        }
    }

    if (ip.isEmpty()) {
        m_statusMessage = tr("No se pudo obtener la IP local del teléfono.");
        Q_EMIT statusMessageChanged();
        Q_EMIT wirelessModeConfigured(QString(), false);
        return;
    }

    const QString targetEndpoint = QString("%1:5555").arg(ip);
    m_statusMessage = tr("Conectando a %1...").arg(targetEndpoint);
    Q_EMIT statusMessageChanged();

    proc.start("adb", QStringList() << "connect" << targetEndpoint);
    proc.waitForFinished(3000);

    refresh();
    m_statusMessage = tr("¡Conectado inalámbricamente a %1!").arg(targetEndpoint);
    Q_EMIT statusMessageChanged();
    Q_EMIT wirelessModeConfigured(targetEndpoint, true);
}

void DeviceManager::disconnectWireless(const QString &ipPort)
{
    QProcess proc;
    proc.start("adb", QStringList() << "disconnect" << ipPort);
    proc.waitForFinished(2000);
    refresh();
}
