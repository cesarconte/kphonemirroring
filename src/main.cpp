#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QCommandLineParser>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QTimer>
#include <QIcon>
#include "DeviceManager.h"
#include "MirrorSession.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("kphonemirroring");
    app.setApplicationDisplayName("Android Mirroring");
    app.setOrganizationName("cesarconte");
    app.setOrganizationDomain("cesar.org");
    app.setDesktopFileName("org.cesar.kphonemirroring");
    app.setWindowIcon(QIcon(":/resources/icons/kphonemirroring.svg"));

    // Golden Gate parity: the application inherits the Plasma desktop style so
    // menus, tooltips and scrollbars match the rest of the CachyOS.UI ecosystem.
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
    }

    QCommandLineParser parser;
    parser.addHelpOption();
    QCommandLineOption screenshotOpt(QStringLiteral("screenshot"),
                                     QStringLiteral("Capture window screenshot and exit"),
                                     QStringLiteral("path"));
    parser.addOption(screenshotOpt);
    parser.process(app);

    DeviceManager deviceManager;
    MirrorSession mirrorSession;

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral("/home/cesar/.local/lib/qt6/qml"));
    engine.rootContext()->setContextProperty("deviceManager", &deviceManager);
    engine.rootContext()->setContextProperty("mirrorSession", &mirrorSession);

    const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    if (parser.isSet(screenshotOpt) && !engine.rootObjects().isEmpty()) {
        if (auto *win = qobject_cast<QQuickWindow *>(engine.rootObjects().first())) {
            const QString outPath = parser.value(screenshotOpt);
            QTimer::singleShot(350, win, [win, outPath, &app]() {
                const QImage img = win->grabWindow();
                img.save(outPath);
                app.quit();
            });
        }
    }

    return app.exec();
}
