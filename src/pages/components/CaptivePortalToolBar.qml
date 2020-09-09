/*
 * Copyright (c) 2014 - 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Browser 1.0
import "." as Browser

Column {
    id: toolBarRow

    property string url
    property string findText
    property real certOverlayHeight
    property bool certOverlayActive
    property real certOverlayAnimPos
    property real certOverlayPreferedHeight: 4 * toolBarRow.height
    readonly property alias toolsHeight: toolsRow.height

    readonly property int horizontalOffset: largeScreen ? Theme.paddingLarge : Theme.paddingSmall
    readonly property int buttonPadding: largeScreen || orientation === Orientation.Landscape || orientation === Orientation.LandscapeInverted
                                         ? Theme.paddingMedium : Theme.paddingSmall
    readonly property int iconWidth: largeScreen ? (Theme.iconSizeLarge + 3 * buttonPadding) : (Theme.iconSizeMedium + 2 * buttonPadding)
    readonly property int smallIconWidth: largeScreen ? (Theme.iconSizeMedium + 3 * buttonPadding) : (Theme.iconSizeSmall + 2 * buttonPadding)
    // Height of toolbar should be such that viewport height is
    // even number both chrome and fullscreen modes. For instance
    // height of 110px for toolbar would result 1px rounding
    // error in chrome mode as viewport height would be 850px. This would
    // result in CSS pixels viewport height of 566.66..px -> rounded to 566px.
    // So, we make sure below that (device height - toolbar height) / pixel ratio is even number.
    // target values when Theme.pixelratio == 1 are:
    // portrait: 108px
    // landcape: 78px
    property int scaledPortraitHeight: Screen.height -
                                       Math.floor((Screen.height - Settings.toolbarLarge * Theme.pixelRatio) /
                                                  WebUtils.cssPixelRatio) * WebUtils.cssPixelRatio
    property int scaledLandscapeHeight: Screen.width -
                                        Math.floor((Screen.width - Settings.toolbarSmall * Theme.pixelRatio) /
                                                   WebUtils.cssPixelRatio) * WebUtils.cssPixelRatio


    signal showInfoOverlay
    signal showChrome
    signal showCertDetail

    width: parent.width

    Item {
        id: certOverlay
        visible: opacity > 0.0 || height > 0.0
        opacity: certOverlayActive ? 1.0 : 0.0
        height: certOverlayHeight
        width: parent.width

        Behavior on opacity { FadeAnimation {} }

        onVisibleChanged: {
            if (!visible && !certOverlayActive) {
                certOverlayLoader.active = false
            }
        }

        Loader {
            id: certOverlayLoader
            active: false
            sourceComponent: CertificateInfo {
                security: webView.security
                width: certOverlay.width
                height: certOverlayHeight
                portrait: browserPage.isPortrait
                opacity: Math.max((certOverlayAnimPos * 2.0) - 1.0, 0)

                onShowCertDetail: toolBarRow.showCertDetail()
                onCloseCertInfo: showChrome()

                onContentHeightChanged: {
                    if (contentHeight != 0) {
                        certOverlayPreferedHeight = contentHeight
                    }
                }
            }
            onLoaded: toolBarRow.showInfoOverlay()
        }
    }

    Row {
        id: toolsRow
        width: parent.width
        height: browserPage.isPortrait ? scaledPortraitHeight : scaledLandscapeHeight
        leftPadding: Theme.paddingLarge

        Browser.ExpandingButton {
            id: backIcon
            expandedWidth: toolBarRow.iconWidth
            icon.source: "image://theme/icon-m-back"
            active: webView.canGoBack
            onTapped: webView.goBack()
        }

        Browser.ExpandingButton {
            id: padlockIcon
            property bool danger: webView.security && webView.security.validState && !webView.security.allGood
            property real glow
            expandedWidth: toolBarRow.smallIconWidth
            icon.source: danger ? "image://theme/icon-s-filled-warning" : "image://theme/icon-s-outline-secure"
            icon.color: danger ? Qt.tint(Theme.primaryColor,
                                         Qt.rgba(Theme.errorColor.r, Theme.errorColor.g,
                                                 Theme.errorColor.b, glow))
                               : Theme.primaryColor
            enabled: webView.security

            SequentialAnimation {
                id: securityAnimation
                PauseAnimation { duration: 2000 }
                NumberAnimation {
                    target: padlockIcon; property: "glow";
                    to: 0.0; duration: 1000; easing.type: Easing.OutCubic
                }
            }

            function warn() {
                glow = 1.0
                securityAnimation.start()
            }

            onDangerChanged: warn()

            Connections {
                target: webView
                onLoadingChanged: {
                    if (!webView.loading && padlockIcon.danger) {
                        padlockIcon.warn()
                    }
                }
            }
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            width: toolBarRow.width - (reloadButton.width + padlockIcon.width + backIcon.width + toolsRow.leftPadding) + Theme.paddingMedium
            color: Theme.highlightColor

            text: {
                if (url) {
                    return WebUtils.displayableUrl(url)
                } else {
                    //: Loading text that is visible when url is not yet resolved.
                    //% "Loading"
                    return qsTrId("sailfish_browser-la-loading")
                }
            }

            truncationMode: TruncationMode.Fade
        }

        Browser.ExpandingButton {
            id: reloadButton
            expandedWidth: toolBarRow.iconWidth
            icon.source: webView.loading ? "image://theme/icon-m-reset" : "image://theme/icon-m-refresh"
            active: webView.contentItem
            onTapped: {
                if (webView.loading) {
                    webView.stop()
                } else {
                    webView.reload()
                }
                toolBarRow.showChrome()
            }
        }

    }
}
