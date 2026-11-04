// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Item {
    id: face
    required property string name
    required property string iconName
    required property int iconSize
    property bool showName: false
    property bool highlighted: false
    readonly property alias dragIcon: picture
    readonly property var iconSource: iconName.startsWith("file:") ? Qt.resolvedUrl(iconName) : iconName
    readonly property int captionHeight: showName ? 17 : 0

    Kirigami.Icon {
        id: picture
        x: Math.round((parent.width - width) / 2)
        y: Math.round((Math.max(1, parent.height - face.captionHeight) - height) / 2)
        width: Math.min(face.iconSize, parent.width, Math.max(1, parent.height - face.captionHeight))
        height: width
        source: face.iconSource
        active: face.highlighted
    }

    Controls.Label {
        visible: face.showName
        anchors.bottom: parent.bottom
        width: parent.width
        height: face.captionHeight
        text: face.name
        textFormat: Text.PlainText
        elide: Text.ElideRight
        maximumLineCount: 1
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 11
    }
}
