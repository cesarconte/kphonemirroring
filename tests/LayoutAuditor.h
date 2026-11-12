/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later

    Static analysis of a QQuickItem tree.

    The auditor detects the layout defects that must never reach the user:

      * Protrusion    — an item that sticks out of its parent container.
      * OutOfWindow   — an item that sticks out of the window.
      * TextClipping  — a text that gets cut without using the elide mechanism.
      * HeaderOverlap — the window title overlapping the header clusters.

    It is intentionally rule based and free of any application knowledge so it
    can be reused by every application of the ecosystem.
*/

#pragma once

#include <QList>
#include <QString>

class QQuickItem;

class LayoutAuditor
{
public:
    enum class Rule {
        Protrusion,
        OutOfWindow,
        TextClipping,
        HeaderOverlap,
    };

    struct Violation {
        Rule rule = Rule::Protrusion;
        QString itemPath;
        QString detail;

        QString toString() const;
    };

    /**
     * Tolerance in pixels that absorbs the elastic hover/press animations of
     * the Golden Gate controls (scale 1.03 … 1.18).
     */
    static constexpr qreal kTolerance = 2.0;

    static QList<Violation> audit(QQuickItem *root);

private:
    static void auditItem(QQuickItem *item, QList<Violation> &out);
    static void auditHeader(QQuickItem *root, QList<Violation> &out);
    static QString pathOf(QQuickItem *item);
    static QString describe(QQuickItem *item);
};
