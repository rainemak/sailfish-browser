/****************************************************************************
**
** Copyright (C) 2014 Jolla Ltd.
** Contact: Raine Makelainen <raine.makelainen@jolla.com>
**
****************************************************************************/

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Browser 1.0
import "." as Browser

PanelBackground {
    id: overlay

    property bool active
    property alias webView: overlayAnimator.webView
    property Item browserPage
    property alias historyModel: historyList.model
    property alias toolBar: toolBar
    property alias progressBar: progressBar
    property alias animator: overlayAnimator

    property var enteredPage

    function loadPage(url, title)  {
        // let gecko figure out how to handle malformed URLs

        var pageUrl = url
        var pageTitle = title || ""
        if (!isNaN(pageUrl) && pageUrl.trim()) {
            pageUrl = "\"" + pageUrl.trim() + "\""
        }

        if (!searchField.enteringNewTabUrl) {
            webView.load(pageUrl, pageTitle)
        } else {
            // Loading will start once overlay animator has animated chrome visible.
            enteredPage = {
                "url": pageUrl,
                "title": pageTitle
            }
        }

        webView.focus = true
        overlayAnimator.showChrome()
    }

    function enterNewTabUrl(action) {
        if (webView.contentItem) {
            webView.contentItem.opacity = 0.0
        }

        searchField.enteringNewTabUrl = true
        searchField.resetUrl("")
        overlayAnimator.showOverlay(action === PageStackAction.Immediate)
    }

    function cancelEnteringUrl() {
        if (webView.contentItem) {
            webView.contentItem.opacity = 1.0
        }
        overlay.animator.showChrome()
    }

    y: webView.fullscreenHeight - toolBar.toolsHeight

    width: parent.width
    height: historyContainer.height

    onActiveChanged: {
        if (active && !webView.contentItem && !searchField.enteringNewTabUrl && webView.tabId > 0) {
            webView.activatePage(webView.tabId, true)
        }
    }

    gradient: Gradient {
        GradientStop { position: 0.0; color: Theme.rgba(Theme.highlightBackgroundColor, 0.3) }
        GradientStop { position: 1.0; color: Theme.rgba(Theme.highlightBackgroundColor, 0.0) }
    }

    // Immediately active WebView height binding when dragging
    // starts. If this binding is removed, state change to
    // "draggingOverlay" at OverlayAnimator causes a visual glitch
    // right after transition to "draggingOverlay" has finnished.
    Binding {
        target: webView
        property: "height"
        value: overlay.y
        when: dragArea.drag.active
    }

    Browser.OverlayAnimator {
        id: overlayAnimator

        overlay: overlay
        portrait: browserPage.isPortrait
        active: Qt.application.active

        onAtBottomChanged: {
            if (atBottom) {
                if (searchField.enteringNewTabUrl && enteredPage) {
                    console.log("Load enter url at bottom:", enteredPage.url, enteredPage.title)
                    webView.tabModel.newTab(enteredPage.url, enteredPage.title)
                    searchField.enteringNewTabUrl = false
                    enteredPage = null
                } else {
                    searchField.resetUrl(webView.url)
                }
            }
        }
    }

    Connections {
        target: webView
        onUrlChanged: searchField.resetUrl(webView.url)
    }

    Image {
        anchors.fill: parent
        source: "image://theme/graphic-gradient-edge"
    }

    Browser.ProgressBar {
        id: progressBar
        width: parent.width
        height: toolBar.toolsHeight
        visible: !firstUseOverlay
        opacity: webView.loading ? 1.0 : 0.0
        progress: webView.loadProgress / 100.0
    }

    MouseArea {
        id: dragArea

        property int dragThreshold: state === "fullscreenOverlay" ? toolBar.toolsHeight * 1.5 :
                                                                    state === "doubleToolBar" ?
                                                                        (webView.fullscreenHeight - toolBar.toolsHeight * 4) :
                                                                        (webView.fullscreenHeight - toolBar.toolsHeight * 2)

        width: parent.width
        height: historyContainer.height
        enabled: !webView.fullscreenMode && webView.contentItem

        drag.target: overlay
        drag.filterChildren: true
        drag.axis: Drag.YAxis
        drag.minimumY: browserPage.isPortrait ? toolBar.toolsHeight : 0
        drag.maximumY: browserPage.isPortrait ? webView.fullscreenHeight - toolBar.toolsHeight : webView.fullscreenHeight

        drag.onActiveChanged: {
            if (!drag.active) {
                if (overlay.y < dragThreshold) {
                    overlayAnimator.showOverlay(false)
                } else {
                    cancelEnteringUrl()
                }
            } else {
                // Store previous end state
                if (!overlayAnimator.dragging) {
                    state = overlayAnimator.state
                }

                overlayAnimator.drag()
                console.log("Previous dragging state:", state)

            }
        }

        Item {
            id: historyContainer

            readonly property bool showFavorites: (!searchField.edited && searchField.text === webView.url || !searchField.text)

            width: parent.width
            height: toolBar.toolsHeight + historyList.height
            clip: true

            Browser.ToolBar {
                id: toolBar

                function saveBookmark(data) {
                    bookmarkModel.addBookmark(webView.url, webView.title || webView.url,
                                                      data, browserPage.favoriteImageLoader.acceptedTouchIcon)
                    browserPage.desktopBookmarkWriter.iconFetched.disconnect(toolBar.saveBookmark)
                }

                function fetchIcon() {
                    // Async operation when loading of touch icon is needed.
                    browserPage.desktopBookmarkWriter.iconFetched.connect(toolBar.saveBookmark)
                    // TODO: would be safer to pass here an object containing url, title, icon, and icon type (touch icon)
                    // as this is async call in case we're fetching favicon.
                    browserPage.desktopBookmarkWriter.fetchIcon(browserPage.favoriteImageLoader.icon)
                }

                url: overlay.webView.url
                bookmarked: bookmarkModel.count && bookmarkModel.contains(webView.url)
                opacity: (overlay.y - webView.fullscreenHeight/2)  / (webView.fullscreenHeight/2 - toolBar.height)
                visible: opacity > 0.0
                secondaryToolsActive: overlayAnimator.secondaryTools

                onShowOverlay: overlayAnimator.showOverlay()
                onShowTabs: {
                    overlayAnimator.showChrome()
                    // Push the tab index and active page that were current at this moment.
                    // Changing of active tab cannot cause blinking.
                    pageStack.push(tabView, {
                                       "activeTabIndex": webView.tabModel.activeTabIndex,
                                       "activeWebPage": webView.contentItem
                                   })
                }
                onShowSecondaryTools: overlayAnimator.showSecondaryTools()
                onHideSecondaryTools: overlayAnimator.showChrome()

                onCloseActiveTab: {
                    console.log("Close active page")
                    // Activates (loads) the tab next to the currect active.
                    webView.tabModel.closeActiveTab()
                    if (webView.tabModel.count == 0) {
                        overlay.enterNewTabUrl()
                    }
                }

                onEnterNewTabUrl: {
                    console.log("Enter url for new tab")
                    overlay.enterNewTabUrl()
                }
                onSearchFromActivePage: console.log("Search from active page")
                onShareActivePage: {
                    console.log("Share active page")

                    pageStack.push(Qt.resolvedUrl("../ShareLinkPage.qml"), {"link" : webView.url, "linkTitle": webView.title})
                }
                onShowDownloads: console.log("Show downloads")

                onBookmarkActivePage: {
                    var webPage = webView && webView.contentItem
                    if (webPage) {
                        toolBar.fetchIcon()
                    }
                }

                onRemoveActivePageFromBookmarks: bookmarkModel.removeBookmark(webView.url)
            }

            SearchField {
                id: searchField

                readonly property bool overlayAtTop: overlayAnimator.atTop
                property bool edited
                property bool enteringNewTabUrl

                function resetUrl(url) {
                    // Reset first text and then mark as unedited.
                    text = url
                    edited = false
                }

                // Follow grid / list position.
                y: -((historyContainer.showFavorites ? favoriteGrid.contentY : historyList.contentY) + height)
                // On top of HistoryList and FavoriteGrid
                z: 1
                width: parent.width
                textLeftMargin: Theme.paddingLarge
                textRightMargin: Theme.paddingLarge

                //: Placeholder text for url typing and searching
                //% "Type URL or search"
                placeholderText: qsTrId("sailfish_browser-ph-type_url_or_search")
                EnterKey.onClicked: overlay.loadPage(text)

                background: null
                opacity: toolBar.opacity * -1.0
                visible: opacity > 0.0
                onOverlayAtTopChanged: {
                    if (overlayAtTop) {
                        forceActiveFocus()
                    } else {
                        focus = false
                    }
                }

                onFocusChanged: {
                    if (focus) {
                        searchField.selectAll()
                    }
                }

                onTextChanged: {
                    if (!edited && text !== webView.url) {
                        edited = true
                    }
                }
            }

            Browser.HistoryList {
                id: historyList

                width: parent.width
                height: browserPage.height - dragArea.drag.minimumY

                header: Item {
                    width: parent.width
                    height: searchField.height
                }

                search: searchField.text
                opacity: historyContainer.showFavorites ? 0.0 : 1.0
                visible: !overlayAnimator.atBottom && opacity > 0.0

                onMovingChanged: if (moving) historyList.focus = true
                onSearchChanged: if (search !== webView.url) historyModel.search(search)
                onLoad: overlay.loadPage(url, title)

                Behavior on opacity { FadeAnimation {} }
            }

            Browser.FavoriteGrid {
                id: favoriteGrid

                height: historyList.height
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: historyContainer.showFavorites ? 1.0 : 0.0
                visible: !overlayAnimator.atBottom && opacity > 0.0
                columns: browserPage.isPortrait ? 4 : 7

                header: Item {
                    width: parent.width
                    height: searchField.height
                }

                model: BookmarkModel {
                    id: bookmarkModel
                }

                onMovingChanged: if (moving) favoriteGrid.focus = true
                onLoad: overlay.loadPage(url, title)

                // Do we need this one???
                onNewTab: {
                    toolBar.reset("", true)
                    overlay.loadPage(url, title)
                }

                onRemoveBookmark: bookmarkModel.removeBookmark(url)
                onEditBookmark: {
                    // index, url, title
                    pageStack.push(editDialog,
                                   {
                                       "url": url,
                                       "title": title,
                                       "index": index,
                                   })
                }

                onAddToLauncher: {
                    // url, title, favicon
                    pageStack.push(addToLauncher,
                                   {
                                       "url": url,
                                       "title": title
                                   })
                }

                onShare: pageStack.push(Qt.resolvedUrl("../ShareLinkPage.qml"), {"link" : url, "linkTitle": title})

                Behavior on opacity { FadeAnimation {} }
            }
        }
    }

    Component {
        id: tabView
        Page {
            id: tabPage
            property int activeTabIndex
            property Item activeWebPage

            onStatusChanged: {
                if (status == PageStatus.Active) {
                    activeWebPage.grabToFile()
                }
            }

            Browser.TabView {
                model: webView.tabModel
                portrait: tabPage.isPortrait

                onHide: pageStack.pop()
                onEnterNewTabUrl: {
                    overlay.enterNewTabUrl(PageStackAction.Immediate)
                    pageStack.pop()
                }
                onActivateTab: {
                    pageStack.pop()
                    webView.tabModel.activateTab(index)
                }
                onCloseTab: {
                    webView.tabModel.remove(index)
                    if (webView.tabModel.count === 0) {
                        console.log("All tabs closed open new tab view!!")
                        // Call own slot.
                        enterNewTabUrl()
                    }
                }

                Component.onCompleted: positionViewAtIndex(webView.tabModel.activeTabIndex, ListView.Center)
            }
        }
    }

    Component {
        id: editDialog
        Browser.BookmarkEditDialog {
            onAccepted: bookmarkModel.editBookmark(index, editedUrl, editedTitle)
        }
    }

    Component {
        id: addToLauncher
        Browser.BookmarkEditDialog {
            //: Title of the "Add to launcher" dialog.
            //% "Add to launcher"
            title: qsTrId("sailfish_browser-he-add_bookmark_to_launcher")
            canAccept: editedUrl !== "" && editedTitle !== ""
            onAccepted: {
                // TODO: This should use directly the icon the the bookmark.
                var icon = browserPage.favoriteImageLoader.icon
                browserPage.desktopBookmarkWriter.link = editedUrl
                browserPage.desktopBookmarkWriter.title = editedTitle
                browserPage.desktopBookmarkWriter.icon = icon
                browserPage.desktopBookmarkWriter.save()
            }
        }
    }
}
