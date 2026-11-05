#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include "DeviceManager.h"
#include "MirrorSession.h"

int main(int argc, char *argv[])
{
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");

    QGuiApplication app(argc, argv);
    app.setApplicationName("kphonemirroring");
    app.setApplicationDisplayName("Phone Mirroring");
    app.setOrganizationName("cesarconte");
    app.setOrganizationDomain("org.cesar");
    app.setDesktopFileName("org.cesar.kphonemirroring");
    app.setWindowIcon(QIcon(":/resources/icons/kphonemirroring.svg"));

    DeviceManager deviceManager;
    MirrorSession mirrorSession;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("deviceManager", &deviceManager);
    engine.rootContext()->setContextProperty("mirrorSession", &mirrorSession);

    const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
