/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later
*/

#include "LayoutAuditor.h"

#include <QQuickItem>
#include <QQuickWindow>
#include <QRectF>

namespace {

/**
 * A QML `Text` is inspected through property introspection instead of through
 * the private QQuickText header: the auditor must not depend on private Qt
 * APIs and must work with any text-like item.
 */
bool isTextItem(QQuickItem *item)
{
    return item->inherits("QQuickText");
}

/**
 * Explicit containment test. `QRectF::contains()` rejects empty rectangles,
 * which would produce false positives for the zero sized layout spacers.
 */
bool containsRect(const QRectF &outer, const QRectF &inner, qreal tolerance)
{
    return inner.left() >= outer.left() - tolerance
        && inner.top() >= outer.top() - tolerance
        && inner.right() <= outer.right() + tolerance
        && inner.bottom() <= outer.bottom() + tolerance;
}

/**
 * Scrollable containers are designed to hold more content than their
 * viewport, so their children are never reported as protruding.
 */
bool isScrollable(QQuickItem *item)
{
    return item->inherits("QQuickFlickable") || item->inherits("QQuickScrollView");
}

/**
 * True when the item lives inside a scrollable area. Its content is clipped
 * by the scroll view, so it can legitimately be bigger than the window.
 */
bool hasScrollableAncestor(QQuickItem *item)
{
    for (QQuickItem *current = item; current; current = current->parentItem()) {
        if (isScrollable(current)) {
            return true;
        }
    }
    return false;
}

/**
 * Components that intentionally bleed out of their container (for instance a
 * floating notification badge overlapping its avatar) opt out of the
 * containment rule by declaring the `auditBleed` dynamic property.
 */
bool declaresBleed(QQuickItem *item)
{
    return item->property("auditBleed").toBool();
}

} // namespace

QString ruleName(LayoutAuditor::Rule rule)
{
    switch (rule) {
    case LayoutAuditor::Rule::Protrusion:
        return QStringLiteral("protrusion");
    case LayoutAuditor::Rule::OutOfWindow:
        return QStringLiteral("out-of-window");
    case LayoutAuditor::Rule::TextClipping:
        return QStringLiteral("text-clipping");
    case LayoutAuditor::Rule::HeaderOverlap:
        return QStringLiteral("header-overlap");
    }
    return QStringLiteral("unknown");
}

QString LayoutAuditor::Violation::toString() const
{
    return QStringLiteral("[%1] %2 — %3").arg(ruleName(rule), itemPath, detail);
}

QString LayoutAuditor::describe(QQuickItem *item)
{
    const QString objectName = item->objectName();
    if (!objectName.isEmpty()) {
        return objectName;
    }
    return QString::fromLatin1(item->metaObject()->className());
}

QString LayoutAuditor::pathOf(QQuickItem *item)
{
    QStringList parts;
    for (QQuickItem *current = item; current; current = current->parentItem()) {
        parts.prepend(describe(current));
    }
    return parts.join(QStringLiteral(" > "));
}

QList<LayoutAuditor::Violation> LayoutAuditor::audit(QQuickItem *root)
{
    QList<Violation> violations;
    if (!root) {
        return violations;
    }
    auditItem(root, violations);
    auditHeader(root, violations);
    return violations;
}

void LayoutAuditor::auditItem(QQuickItem *item, QList<Violation> &out)
{
    // Invisible subtrees are not rendered, therefore they cannot produce a
    // visual defect (and their geometry is not meaningful either).
    if (!item->isVisible()) {
        return;
    }

    QQuickItem *parent = item->parentItem();
    const bool rendered = item->width() > 0.0 && item->height() > 0.0;
    const bool measurable = rendered && parent && parent->width() > 0.0 && parent->height() > 0.0
        && !isScrollable(parent) && !declaresBleed(item);

    if (measurable) {
        const QRectF self(0.0, 0.0, item->width(), item->height());
        const QRectF inParent = item->mapRectToItem(parent, self);
        const QRectF bounds(0.0, 0.0, parent->width(), parent->height());

        if (!containsRect(bounds, inParent, kTolerance)) {
            out.append({Rule::Protrusion,
                        pathOf(item),
                        QStringLiteral("item occupies %1,%2 %3x%4 but the container is %5,%6 %7x%8")
                            .arg(inParent.x())
                            .arg(inParent.y())
                            .arg(inParent.width())
                            .arg(inParent.height())
                            .arg(bounds.x())
                            .arg(bounds.y())
                            .arg(bounds.width())
                            .arg(bounds.height())});
        }
    }

    // A text that does not fit must elide, never get silently cut.
    if (isTextItem(item)) {
        // Text.NoWrap == 0 and Text.ElideNone == 0
        const int wrapMode = item->property("wrapMode").toInt();
        const int elideMode = item->property("elide").toInt();
        const qreal implicitWidth = item->property("implicitWidth").toReal();

        if (wrapMode == 0 && elideMode == 0 && item->width() > 0.0
            && implicitWidth > item->width() + 0.5) {
            out.append({Rule::TextClipping,
                        pathOf(item),
                        QStringLiteral("text \"%1\" needs %2px but only %3px are available")
                            .arg(item->property("text").toString().left(48))
                            .arg(implicitWidth)
                            .arg(item->width())});
        }
    }

    // Nothing may stick out of the window either.
    if (rendered && !hasScrollableAncestor(item)) {
        if (auto *window = item->window()) {
            QQuickItem *content = window->contentItem();
            const QRectF self(0.0, 0.0, item->width(), item->height());
            const QRectF inWindow = item->mapRectToItem(content, self);
            const QRectF winRect(0.0, 0.0, window->width(), window->height());

            if (!containsRect(winRect, inWindow, kTolerance)) {
                out.append({Rule::OutOfWindow,
                            pathOf(item),
                            QStringLiteral("item occupies %1,%2 %3x%4 but the window is %5x%6")
                                .arg(inWindow.x())
                                .arg(inWindow.y())
                                .arg(inWindow.width())
                                .arg(inWindow.height())
                                .arg(window->width())
                                .arg(window->height())});
            }
        }
    }

    const QList<QQuickItem *> children = item->childItems();
    for (QQuickItem *child : children) {
        auditItem(child, out);
    }
}

void LayoutAuditor::auditHeader(QQuickItem *root, QList<Violation> &out)
{
    // The header items live inside the window object tree, which is not the
    // same as the visual (contentItem) tree, so the lookup starts at the window.
    QObject *searchRoot = root->window() ? static_cast<QObject *>(root->window()) : root;

    auto *leading = searchRoot->findChild<QQuickItem *>(QStringLiteral("cachyHeaderLeading"));
    auto *center = searchRoot->findChild<QQuickItem *>(QStringLiteral("cachyHeaderCenter"));
    auto *trailing = searchRoot->findChild<QQuickItem *>(QStringLiteral("cachyHeaderTrailing"));
    auto *title = searchRoot->findChild<QQuickItem *>(QStringLiteral("cachyHeaderTitle"));

    if (!leading || !center || !trailing || !title) {
        return;
    }
    if (!title->isVisible() || !leading->isVisible() || !trailing->isVisible()) {
        return;
    }

    const auto rectIn = [](QQuickItem *item, QQuickItem *reference) {
        return item->mapRectToItem(reference, QRectF(0.0, 0.0, item->width(), item->height()));
    };

    const QRectF titleRect = rectIn(title, center);
    const QRectF leadingRect = rectIn(leading, center);
    const QRectF trailingRect = rectIn(trailing, center);

    if (titleRect.intersects(leadingRect)) {
        out.append({Rule::HeaderOverlap,
                    pathOf(title),
                    QStringLiteral("title %1,%2 %3x%4 intersects the leading cluster %5,%6 %7x%8")
                        .arg(titleRect.x())
                        .arg(titleRect.y())
                        .arg(titleRect.width())
                        .arg(titleRect.height())
                        .arg(leadingRect.x())
                        .arg(leadingRect.y())
                        .arg(leadingRect.width())
                        .arg(leadingRect.height())});
    }

    if (titleRect.intersects(trailingRect)) {
        out.append({Rule::HeaderOverlap,
                    pathOf(title),
                    QStringLiteral("title %1,%2 %3x%4 intersects the trailing cluster %5,%6 %7x%8")
                        .arg(titleRect.x())
                        .arg(titleRect.y())
                        .arg(titleRect.width())
                        .arg(titleRect.height())
                        .arg(trailingRect.x())
                        .arg(trailingRect.y())
                        .arg(trailingRect.width())
                        .arg(trailingRect.height())});
    }
}
