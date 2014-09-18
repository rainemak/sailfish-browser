/****************************************************************************
**
** Copyright (C) 2014 Jolla Ltd.
** Contact: Raine Makelainen <raine.makelainen@jollamobile.com>
**
****************************************************************************/

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "declarativewebpage.h"
#include "declarativewebcontainer.h"

#include <QtConcurrent>
#include <QStandardPaths>

static const QString gFullScreenMessage("embed:fullscreenchanged");
static const QString gDomContentLoadedMessage("embed:domcontentloaded");

DeclarativeWebPage::DeclarativeWebPage(QQuickItem *parent)
    : QuickMozView(parent)
    , m_container(0)
    , m_tabId(0)
    , m_viewReady(false)
    , m_loaded(false)
    , m_userHasDraggedWhileLoading(false)
    , m_fullscreen(false)
    , m_domContentLoaded(false)
    , m_urlHasChanged(false)
    , m_backForwardNavigation(false)
{
    connect(this, SIGNAL(viewInitialized()), this, SLOT(onViewInitialized()));
    connect(this, SIGNAL(recvAsyncMessage(const QString, const QVariant)),
            this, SLOT(onRecvAsyncMessage(const QString&, const QVariant&)));
    connect(&m_grabWritter, SIGNAL(finished()), this, SLOT(grabWritten()));
}

DeclarativeWebPage::~DeclarativeWebPage()
{
    m_grabWritter.cancel();
    m_grabWritter.waitForFinished();
    m_grabResult.clear();
}

DeclarativeWebContainer *DeclarativeWebPage::container() const
{
    return m_container;
}

void DeclarativeWebPage::setContainer(DeclarativeWebContainer *container)
{
    if (m_container != container) {
        m_container = container;
        emit containerChanged();
    }
}

int DeclarativeWebPage::tabId() const
{
    return m_tabId;
}

void DeclarativeWebPage::setTabId(int tabId)
{
    m_tabId = tabId;
}

bool DeclarativeWebPage::domContentLoaded() const
{
    return m_domContentLoaded;
}

bool DeclarativeWebPage::urlHasChanged() const
{
    return m_urlHasChanged;
}

void DeclarativeWebPage::setUrlHasChanged(bool urlHasChanged)
{
    m_urlHasChanged = urlHasChanged;
}

bool DeclarativeWebPage::backForwardNavigation() const
{
    return m_backForwardNavigation;
}

void DeclarativeWebPage::setBackForwardNavigation(bool backForwardNavigation)
{
    m_backForwardNavigation = backForwardNavigation;
}

bool DeclarativeWebPage::viewReady() const
{
    return m_viewReady;
}

QVariant DeclarativeWebPage::resurrectedContentRect() const
{
    return m_resurrectedContentRect;
}

void DeclarativeWebPage::setResurrectedContentRect(QVariant resurrectedContentRect)
{
    if (m_resurrectedContentRect != resurrectedContentRect) {
        m_resurrectedContentRect = resurrectedContentRect;
        emit resurrectedContentRectChanged();
    }
}

void DeclarativeWebPage::loadTab(QString newUrl, bool force)
{
    // Always enable chrome when load is called.
    setChrome(true);
    QString oldUrl = url().toString();
    if ((!newUrl.isEmpty() && oldUrl != newUrl) || force) {
        m_domContentLoaded = false;
        emit domContentLoadedChanged();
        load(newUrl);
    }
}

void DeclarativeWebPage::grabToFile()
{
    emit clearGrabResult();
    m_grabResult = grabToImage();
    connect(m_grabResult.data(), SIGNAL(ready()), this, SLOT(grabResultReady()));
}

void DeclarativeWebPage::componentComplete()
{
    QuickMozView::componentComplete();
}

void DeclarativeWebPage::onViewInitialized()
{
    addMessageListener(gFullScreenMessage);
    addMessageListener(gDomContentLoadedMessage);
}

void DeclarativeWebPage::grabResultReady()
{
    QImage image = m_grabResult->image();
    m_grabResult.clear();
    int size = qMin(width(), height());
    QRect cropBounds(0, 0, size, size/2);

    m_grabWritter.setFuture(QtConcurrent::run(this, &DeclarativeWebPage::saveToFile, image, cropBounds));
}

void DeclarativeWebPage::grabWritten()
{
    QString path = m_grabWritter.result();
    emit grabResult(path);
}

QString DeclarativeWebPage::saveToFile(QImage image, QRect cropBounds)
{
    if (image.isNull()) {
        return "";
    }

    // 75% quality jpg produces small and good enough capture.
    QString path = QString("%1/tab-%2-thumb.jpg").arg(QStandardPaths::writableLocation(QStandardPaths::CacheLocation)).arg(m_tabId);
    image = image.copy(cropBounds);
    return image.save(path, "jpg", 75) ? path : "";
}

void DeclarativeWebPage::onRecvAsyncMessage(const QString& message, const QVariant& data)
{
    if (message == gFullScreenMessage) {
        setFullscreen(data.toMap().value(QString("fullscreen")).toBool());
    } else if (message == gDomContentLoadedMessage && data.toMap().value("rootFrame").toBool()) {
        m_domContentLoaded = true;
        emit domContentLoadedChanged();
    }
}

bool DeclarativeWebPage::fullscreen() const
{
    return m_fullscreen;
}

void DeclarativeWebPage::setFullscreen(const bool fullscreen)
{
    if (m_fullscreen != fullscreen) {
        m_fullscreen = fullscreen;
        m_container->resetHeight();
        emit fullscreenChanged();
    }
}
