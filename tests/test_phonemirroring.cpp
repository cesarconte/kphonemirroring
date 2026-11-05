#include <QTest>
#include <QSignalSpy>
#include "../src/DeviceManager.h"
#include "../src/MirrorSession.h"

class TestPhoneMirroring : public QObject {
    Q_OBJECT

private Q_SLOTS:
    void testParseAdbDevicesEmpty();
    void testParseAdbDevicesUsbAndWifi();
    void testParseAdbDevicesUnauthorized();
    void testBuildScrcpyArgsDefaults();
    void testBuildScrcpyArgsCustom();
};

void TestPhoneMirroring::testParseAdbDevicesEmpty()
{
    const QString emptyOutput = "";
    auto list = DeviceManager::parseAdbDevicesOutput(emptyOutput);
    QCOMPARE(list.size(), 0);

    const QString daemonBanner = "* daemon not running; starting now at tcp:5037\n* daemon started successfully\nList of devices attached\n\n";
    list = DeviceManager::parseAdbDevicesOutput(daemonBanner);
    QCOMPARE(list.size(), 0);
}

void TestPhoneMirroring::testParseAdbDevicesUsbAndWifi()
{
    const QString adbOutput =
        "List of devices attached\n"
        "DQMBWSUKPFEUS8TS       device usb:1-8 product:malachite_eea model:24090RA29G device:malachite transport_id:1\n"
        "192.168.1.11:5555      device product:malachite_eea model:24090RA29G device:malachite transport_id:2\n";

    auto list = DeviceManager::parseAdbDevicesOutput(adbOutput);
    QCOMPARE(list.size(), 2);

    // USB Device
    const auto &usbDev = list.at(0);
    QCOMPARE(usbDev.serial, QStringLiteral("DQMBWSUKPFEUS8TS"));
    QCOMPARE(usbDev.state, QStringLiteral("device"));
    QCOMPARE(usbDev.model, QStringLiteral("24090RA29G"));
    QCOMPARE(usbDev.isWireless, false);
    QCOMPARE(usbDev.transport, QStringLiteral("usb"));

    // Wi-Fi Device
    const auto &wifiDev = list.at(1);
    QCOMPARE(wifiDev.serial, QStringLiteral("192.168.1.11:5555"));
    QCOMPARE(wifiDev.state, QStringLiteral("device"));
    QCOMPARE(wifiDev.isWireless, true);
    QCOMPARE(wifiDev.transport, QStringLiteral("wifi"));
}

void TestPhoneMirroring::testParseAdbDevicesUnauthorized()
{
    const QString adbOutput =
        "List of devices attached\n"
        "DQMBWSUKPFEUS8TS       unauthorized usb:1-8 transport_id:1\n";

    auto list = DeviceManager::parseAdbDevicesOutput(adbOutput);
    QCOMPARE(list.size(), 1);

    const auto &dev = list.at(0);
    QCOMPARE(dev.serial, QStringLiteral("DQMBWSUKPFEUS8TS"));
    QCOMPARE(dev.state, QStringLiteral("unauthorized"));
}

void TestPhoneMirroring::testBuildScrcpyArgsDefaults()
{
    const QString serial = "DQMBWSUKPFEUS8TS";
    const QStringList args = MirrorSession::buildScrcpyArgs(serial, true, true, true, 60, 16, "Redmi Note 14 Pro 5G");

    QVERIFY(args.contains("-s"));
    QCOMPARE(args.at(args.indexOf("-s") + 1), serial);
    QVERIFY(args.contains("--turn-screen-off"));
    QVERIFY(args.contains("--stay-awake"));
    QVERIFY(args.contains("--audio-source=playback"));
    QVERIFY(args.contains("--max-fps=60"));
    QVERIFY(args.contains("--video-bit-rate=16M"));
    QVERIFY(args.contains("--window-title=Redmi Note 14 Pro 5G"));
    QVERIFY(args.contains("--shortcut-mod=lalt"));
}

void TestPhoneMirroring::testBuildScrcpyArgsCustom()
{
    const QString serial = "192.168.1.11:5555";
    const QStringList args = MirrorSession::buildScrcpyArgs(serial, false, false, false, 30, 8, "My Phone");

    QVERIFY(args.contains("-s"));
    QCOMPARE(args.at(args.indexOf("-s") + 1), serial);
    QVERIFY(!args.contains("--turn-screen-off"));
    QVERIFY(!args.contains("--stay-awake"));
    QVERIFY(args.contains("--no-audio"));
    QVERIFY(args.contains("--max-fps=30"));
    QVERIFY(args.contains("--video-bit-rate=8M"));
    QCOMPARE(args.at(args.indexOf("--window-title=My Phone")), QStringLiteral("--window-title=My Phone"));
}

QTEST_MAIN(TestPhoneMirroring)
#include "test_phonemirroring.moc"
