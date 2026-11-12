/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later

    Golden Gate layout audit.

    The window is rendered offscreen at several sizes and in every UI state,
    and the resulting QQuickItem tree is audited for the classic design
    defects: protruding items, items sticking out of the window, texts cut
    without elision and the window title overlapping the header clusters.
*/

#include <QDir>
#include <QGuiApplication>
#include <QLoggingCategory>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QTest>
#include <QUrl>

#include "DeviceManager.h"
#include "LayoutAuditor.h"
#include "MirrorSession.h"

namespace {

struct UiState {
    QString name;
    bool sidebar = true;
    QString tab = QStringLiteral("today");
    bool preferences = false;
    bool controlCenter = false;
};

void addImportPaths(QQmlApplicationEngine &engine)
{
    const QStringList candidates = {
        qEnvironmentVariable("CACHYOS_UI_IMPORT_PATH"),
        qEnvironmentVariable("QML2_IMPORT_PATH"),
        QDir::homePath() + QStringLiteral("/.local/lib/qt6/qml"),
        QStringLiteral("/usr/lib/qt6/qml"),
    };

    for (const QString &entry : candidates) {
        const QStringList parts = entry.split(QLatin1Char(':'), Qt::SkipEmptyParts);
        for (const QString &part : parts) {
            if (!engine.importPathList().contains(part)) {
                engine.addImportPath(part);
            }
        }
    }
}

} // namespace

class TestLayoutAudit : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void initTestCase();
    void cleanupTestCase();
    void auditWindowStates_data();
    void auditWindowStates();
    void auditHeaderTitleSweep();

private:
    void applyState(const UiState &state);
    QList<LayoutAuditor::Violation> auditNow();

    DeviceManager m_deviceManager;
    MirrorSession m_mirrorSession;
    QQmlApplicationEngine m_engine;
    QQuickWindow *m_window = nullptr;
    QObject *m_root = nullptr;
};

void TestLayoutAudit::initTestCase()
{
    addImportPaths(m_engine);

    m_engine.rootContext()->setContextProperty(QStringLiteral("deviceManager"), &m_deviceManager);
    m_engine.rootContext()->setContextProperty(QStringLiteral("mirrorSession"), &m_mirrorSession);
    m_engine.load(QUrl(QStringLiteral("qrc:/qml/Main.qml")));

    if (m_engine.rootObjects().isEmpty()) {
        QFAIL("The QML scene could not be loaded");
    }

    m_root = m_engine.rootObjects().constFirst();
    m_window = qobject_cast<QQuickWindow *>(m_root);
    if (!m_window) {
        QFAIL("The root object is not a window");
    }
    m_window->show();
    QTest::qWait(100);
}

void TestLayoutAudit::cleanupTestCase()
{
    m_window->hide();
}

void TestLayoutAudit::applyState(const UiState &state)
{
    m_root->setProperty("showSidebar", state.sidebar);
    m_root->setProperty("activeTab", state.tab);
    m_root->setProperty("preferencesVisible", state.preferences);
    m_mirrorSession.setControlCenterVisible(state.controlCenter);
    QTest::qWait(30);
}

QList<LayoutAuditor::Violation> TestLayoutAudit::auditNow()
{
    return LayoutAuditor::audit(m_window->contentItem());
}

void TestLayoutAudit::auditWindowStates_data()
{
    QTest::addColumn<int>("width");
    QTest::addColumn<int>("height");

    QTest::newRow("minimum") << 620 << 520;
    QTest::newRow("compact") << 700 << 640;
    QTest::newRow("compact-portrait") << 680 << 820;
    QTest::newRow("default") << 980 << 680;
    QTest::newRow("wide") << 1440 << 900;
    QTest::newRow("tall-narrow") << 640 << 1000;
}

void TestLayoutAudit::auditWindowStates()
{
    QFETCH(int, width);
    QFETCH(int, height);

    const QVector<UiState> states = {
        {QStringLiteral("today"), true, QStringLiteral("today"), false, false},
        {QStringLiteral("apps"), true, QStringLiteral("apps"), false, false},
        {QStringLiteral("mirroring"), true, QStringLiteral("device"), false, false},
        {QStringLiteral("today-nosidebar"), false, QStringLiteral("today"), false, false},
        {QStringLiteral("preferences"), true, QStringLiteral("today"), true, false},
        {QStringLiteral("control-center"), true, QStringLiteral("device"), false, true},
    };

    m_window->resize(width, height);
    QTest::qWait(50);

    for (const UiState &state : states) {
        applyState(state);

        const QList<LayoutAuditor::Violation> violations = auditNow();
        for (const LayoutAuditor::Violation &violation : violations) {
            QFAIL(qPrintable(QStringLiteral("state '%1' (%2x%3): %4")
                                 .arg(state.name)
                                 .arg(width)
                                 .arg(height)
                                 .arg(violation.toString())));
        }
    }
}

void TestLayoutAudit::auditHeaderTitleSweep()
{
    // The title must never collide with the header clusters, whatever the
    // window width is. This is the regression guard for the overlap that the
    // former symmetric approximation of the title band produced: the long
    // title is the worst case that used to overlap the trailing cluster.
    const int minimum = 620;
    const int maximum = 1440;

    const QStringList titles = {
        QStringLiteral("Android Mirroring"),
        QStringLiteral("Android & iPhone Phone Mirroring"),
        QStringLiteral("Android Phone Mirroring — Continuity Control Center Extended"),
    };

    for (const QString &title : titles) {
        m_root->setProperty("title", title);

        for (const bool sidebar : {true, false}) {
            m_root->setProperty("showSidebar", sidebar);

            for (int width = minimum; width <= maximum; width += 3) {
                m_window->resize(width, 680);
                QTest::qWait(1);

                const QList<LayoutAuditor::Violation> violations = auditNow();
                for (const LayoutAuditor::Violation &violation : violations) {
                    if (violation.rule != LayoutAuditor::Rule::HeaderOverlap) {
                        continue;
                    }
                    QFAIL(qPrintable(QStringLiteral("title '%1' sidebar=%2 width=%3: %4")
                                         .arg(title)
                                         .arg(sidebar)
                                         .arg(width)
                                         .arg(violation.toString())));
                }
            }
        }
    }
}

int main(int argc, char *argv[])
{
    qputenv("QT_QPA_PLATFORM", "offscreen");
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");

    // The KWin blur cannot be applied on the offscreen platform.
    QLoggingCategory::setFilterRules(QStringLiteral("kf.windowsystem.warning=false\n"));

    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("kphonemirroring"));

    TestLayoutAudit testCase;
    return QTest::qExec(&testCase, argc, argv);
}

#include "test_layout_audit.moc"
