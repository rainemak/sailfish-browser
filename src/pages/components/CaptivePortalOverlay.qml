/*
 * Copyright (c) 2014 - 2019 Jolla Ltd.
 * Copyright (c) 2012 Open Mobile Platform LLC.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 */

import QtQuick 2.2
import QtQuick.Window 2.2 as QuickWindow
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as Private
import Sailfish.Browser 1.0
import Sailfish.Policy 1.0
import Sailfish.WebView.Controls 1.0
import com.jolla.settings.system 1.0
import "." as Browser

Background {
    id: overlay

    property bool active
    property QtObject webView
    property Item containerPage
    property alias toolBar: toolBar
    property alias progressBar: progressBar
    property alias animator: overlayAnimator

    property real _overlayHeight: containerPage.isPortrait ? toolBar.toolsHeight : 0
    property bool _showFindInPage
    property bool _showUrlEntry
    property bool _showInfoOverlay
    readonly property bool _topGap: _showUrlEntry || _showFindInPage

    function loadPage(url)  {
        if (webView && webView.tabModel.count === 0) {
            webView.clearSurface();
        }
        // let gecko figure out how to handle malformed URLs
        var pageUrl = url
        if (!isNaN(pageUrl) && pageUrl.trim()) {
            pageUrl = "\"" + pageUrl.trim() + "\""
        }

        webView.load(pageUrl)
        overlayAnimator.showChrome()
    }

    function dismiss(immediate) {
        overlay.animator.showChrome(immediate)
    }

    y: webView.fullscreenHeight - toolBar.toolsHeight

    Private.VirtualKeyboardObserver {
        id: virtualKeyboardObserver
        active: overlay.active && !overlayAnimator.atBottom
        orientation: containerPage.orientation
    }

    width: parent.width
    height: toolBar.height + virtualKeyboardObserver.panelSize
    // `visible` is controlled by Browser.OverlayAnimator
    enabled: visible

    // This is an invisible object responsible to hide/show Overlay in an animated way
    Browser.OverlayAnimator {
        id: overlayAnimator

        overlay: overlay
        portrait: containerPage.isPortrait
        webView: overlay.webView

        readonly property real _fullHeight: isPortrait ? overlay.toolBar.toolsHeight : 0
        readonly property real _infoHeight: Math.max(webView.fullscreenHeight - overlay.toolBar.certOverlayPreferedHeight - overlay.toolBar.toolsHeight, 0)
    }

    Browser.ProgressBar {
        id: progressBar
        width: parent.width
        height: toolBar.toolsHeight
        opacity: webView.loading ? 1.0 : 0.0
        progress: webView.loadProgress / 100.0
    }

    Browser.CaptivePortalToolBar {
        id: toolBar

        x: Theme.horizontalPageMargin
        width: parent.width - 2 * x

        url: webView.contentItem && webView.contentItem.url || ""
        certOverlayActive: _showInfoOverlay
        certOverlayHeight: !_showInfoOverlay
                           ? 0
                           : Math.max((webView.fullscreenHeight - overlay.y - overlay.toolBar.toolsHeight), 0)

        certOverlayAnimPos: Math.min(Math.max((webView.fullscreenHeight - overlay.y - overlay.toolBar.toolsHeight)
                                              / (webView.fullscreenHeight - overlayAnimator._infoHeight
                                                 - overlay.toolBar.toolsHeight), 0.0), 1.0)

        onShowInfoOverlay: {
            _showInfoOverlay = true
            _overlayHeight = Qt.binding(function() { return overlayAnimator._infoHeight })
            overlayAnimator.showInfoOverlay(false)
        }
        onShowChrome: overlayAnimator.showChrome()
    }
}
