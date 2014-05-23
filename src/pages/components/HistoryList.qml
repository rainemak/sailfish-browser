/****************************************************************************
**
** Copyright (C) 2014 Jolla Ltd.
** Contact: Vesa-Matti Hartikainen <vesa-matti.hartikainen@jolla.com>
**
****************************************************************************/

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

import QtQuick 2.1
import Sailfish.Silica 1.0

ListView {
    id: view
    property string search

    signal load(string url, string title)

    // To prevent model to steal focus
    currentIndex: -1
    cacheBuffer: Theme.itemSizeLarge * 8
    pixelAligned: true
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    delegate: BackgroundItem {
        id: historyDelegate
        width: view.width
        height: Theme.itemSizeSmall

        ListView.onAdd: AddAnimation { target: historyDelegate }

        Row {
            id: row
            width: view.width - Theme.paddingLarge * 2
            x: Theme.paddingLarge
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: titleText
                text: Theme.highlightText(title, search, Theme.highlightColor)
                color: highlighted ? Theme.highlightColor : Theme.primaryColor
                font.pixelSize: Theme.fontSizeMedium
            }

            Text {
                id: separator
                // Should this be localized e.g. for Chinese user?
                text: " • "
                color: highlighted ? Theme.highlightColor : Theme.primaryColor
                font.pixelSize: Theme.fontSizeMedium
            }

            Text {
                id: urlText
                text: Theme.highlightText(url, search, Theme.highlightColor)
                opacity: 0.6
                color: highlighted ? Theme.highlightColor : Theme.primaryColor
                font.pixelSize: Theme.fontSizeMedium
            }
        }

        // TODO: Remove this and change above labels to use truncationMode: TruncationMode.Fade
        // once bug #8173 is fixed.
        OpacityRampEffect {
            slope: 1 + 6 * row.width / Screen.width
            offset: 1 - 1 / slope
            sourceItem: row
            enabled: (titleText.implicitWidth + separator.implicitWidth + urlText.implicitWidth) > row.width
        }

        onClicked: {
            Qt.inputMethod.hide()
            view.load(model.url, model.title)
        }
    }

    VerticalScrollDecorator {
        parent: view
        flickable: view
    }
}
