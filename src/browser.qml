/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Vesa-Matti Hartikainen <vesa-matti.hartikainen@jollamobile.com>
** Contact: Raine Makelainen <raine.makelainen@jolla.com>
**
****************************************************************************/

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Browser 1.0
import "pages"

BrowserPage {
    id: window

    signal newTab

    width: Screen.width
    height: Screen.height

//    function setBrowserCover(model) {
//        if (model && model.count === 0) {
//            cover = Qt.resolvedUrl("cover/NoTabsCover.qml")
//        } else {
//            cover = null
//        }
//    }

//    width: Screen.width
//    height: Screen.height

//    BrowserPage {

//    }

//    allowedOrientations: WebUtils.firstUseDone && Qt.application.active ? defaultAllowedOrientations : Orientation.Portrait
//    _defaultPageOrientations: Orientation.All
//    cover: null
//    initialPage: Component {
//        BrowserPage {
//            id: browserPage

//            Connections {
//                target: window
//                onNewTab: browserPage.activateNewTabView()
//            }
//        }
//    }
}
