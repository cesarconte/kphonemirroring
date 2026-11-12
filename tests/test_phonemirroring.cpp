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
    void testGoldenGatePerAppWindowSizeMemory();
    void testMirroringOptionsSettersAndClamping();
    void testMirroringOptionsPersistAcrossInstances();
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

void TestPhoneMirroring::testGoldenGatePerAppWindowSizeMemory()
{
    MirrorSession session;
    QSignalSpy resizeSpy(&session, &MirrorSession::requestWindowResize);

    // Save custom multi-column dimensions for "chatgpt"
    session.saveAppWindowSize(QStringLiteral("chatgpt"), 860, 650);
    const QVariantMap remembered = session.rememberedSizeForApp(QStringLiteral("chatgpt"));
    QCOMPARE(remembered.value(QStringLiteral("width")).toInt(), 860);
    QCOMPARE(remembered.value(QStringLiteral("height")).toInt(), 650);

    // Opening the app emits requestWindowResize with the remembered size
    session.openApp(QStringLiteral("chatgpt"), QStringLiteral("ChatGPT"));
    QCOMPARE(session.currentAppId(), QStringLiteral("chatgpt"));
    QCOMPARE(resizeSpy.count(), 1);
    QCOMPARE(resizeSpy.at(0).at(0).toInt(), 860);
    QCOMPARE(resizeSpy.at(0).at(1).toInt(), 650);

    // Returning to Home Screen resets window to normal portrait size (440x700)
    session.returnToHomeScreen();
    QCOMPARE(session.currentAppId(), QStringLiteral("home"));
    QCOMPARE(resizeSpy.count(), 2);
    QCOMPARE(resizeSpy.at(1).at(0).toInt(), 440);
    QCOMPARE(resizeSpy.at(1).at(1).toInt(), 700);

    // Control Center toggle (Cmd+4)
    QVERIFY(!session.controlCenterVisible());
    session.openControlCenter();
    QVERIFY(session.controlCenterVisible());
}

void TestPhoneMirroring::testMirroringOptionsSettersAndClamping()
{
    MirrorSession session;
    QSignalSpy optionsSpy(&session, &MirrorSession::optionsChanged);

    // Golden Gate defaults
    QCOMPARE(session.turnScreenOff(), true);
    QCOMPARE(session.stayAwake(), true);
    QCOMPARE(session.audioEnabled(), true);
    QCOMPARE(session.maxFps(), 60);
    QCOMPARE(session.bitrateMbps(), 16);

    // Toggling an option notifies exactly once
    session.setAudioEnabled(false);
    QCOMPARE(optionsSpy.count(), 1);
    QCOMPARE(session.audioEnabled(), false);

    // Setting the same value again is a no-op (no spurious notification)
    session.setAudioEnabled(false);
    QCOMPARE(optionsSpy.count(), 1);

    // Out-of-range values are clamped to the canonical scrcpy boundaries
    session.setMaxFps(5);
    QCOMPARE(session.maxFps(), MirrorSession::clampMaxFps(5));
    QCOMPARE(session.maxFps(), 15);

    session.setMaxFps(1000);
    QCOMPARE(session.maxFps(), 120);

    session.setBitrateMbps(0);
    QCOMPARE(session.bitrateMbps(), 4);

    session.setBitrateMbps(999);
    QCOMPARE(session.bitrateMbps(), 64);

    // The options feed the scrcpy command line
    const QStringList args = MirrorSession::buildScrcpyArgs("serial",
                                                            session.turnScreenOff(),
                                                            session.stayAwake(),
                                                            session.audioEnabled(),
                                                            session.maxFps(),
                                                            session.bitrateMbps(),
                                                            QStringLiteral("Device"));
    QVERIFY(!args.contains("--audio-source=playback"));
    QVERIFY(args.contains("--no-audio"));
    QVERIFY(args.contains("--max-fps=120"));
    QVERIFY(args.contains("--video-bit-rate=64M"));
}

void TestPhoneMirroring::testMirroringOptionsPersistAcrossInstances()
{
    {
        MirrorSession session;
        session.setMaxFps(30);
        session.setBitrateMbps(8);
        session.setTurnScreenOff(false);
    }

    // A brand new session restores the persisted Golden Gate options
    MirrorSession restored;
    QCOMPARE(restored.maxFps(), 30);
    QCOMPARE(restored.bitrateMbps(), 8);
    QCOMPARE(restored.turnScreenOff(), false);

    // Restore the defaults so the persisted state stays neutral for the
    // remaining test runs of the suite.
    restored.setMaxFps(60);
    restored.setBitrateMbps(16);
    restored.setTurnScreenOff(true);
}

QTEST_MAIN(TestPhoneMirroring)
#include "test_phonemirroring.moc"