// SPDX-License-Identifier: GPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Column {
    id: selector
    readonly property int rowCount: rows.count
    readonly property int rowHeight: 26
    readonly property int selectorHeight: 120
    readonly property int scrollBarWidth: 8
    required property string explanation
    property int lastRow: -1
    property bool followDuringDrag: true
    signal rowsChangedByUser(var keys, bool follow)

    function replaceRows(tabs, exceptions) {
        lastRow = -1;
        rows.clear();
        for (const tab of tabs) {
            if (tab && tab.key) {
                rows.append({ tabKey: tab.key, title: tab.name || "", follows: !exceptions[tab.key] });
            }
        }
    }

    function paintRange(first, last, follow) {
        const keys = [];
        for (let i = Math.min(first, last); i <= Math.max(first, last); ++i) {
            const row = rows.get(i);
            if (row.follows !== follow) {
                keys.push(row.tabKey);
                rows.setProperty(i, "follows", follow);
            }
        }
        if (keys.length) {
            rowsChangedByUser(keys, follow);
        }
    }

    spacing: 4

    Controls.Label {
        text: selector.explanation
        wrapMode: Text.Wrap
        width: parent.width
    }

    Rectangle {
        id: box
        readonly property int contentHeight: selector.rowCount * selector.rowHeight
        readonly property bool hasOverflow: contentHeight > view.height
        width: parent.width
        height: selector.selectorHeight
        radius: 4
        color: Kirigami.Theme.alternateBackgroundColor
        border.color: Qt.alpha(Kirigami.Theme.textColor, 0.25)
        border.width: 1

        ListView {
            id: view
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.topMargin: 4
            anchors.bottomMargin: 4
            anchors.rightMargin: box.hasOverflow ? selector.scrollBarWidth + 4 : 4
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: ListModel { id: rows }

            delegate: Controls.ItemDelegate {
                id: row
                required property int index
                required property string title
                required property bool follows
                width: view.width
                height: selector.rowHeight
                padding: 5
                text: title
                highlighted: follows
                Accessible.checkable: true
                Accessible.checked: follows
                onClicked: selector.paintRange(index, index, !follows)

                MouseArea {
                    anchors.fill: parent
                    preventStealing: true
                    onPressed: {
                        row.forceActiveFocus(Qt.MouseFocusReason);
                        selector.lastRow = row.index;
                        selector.followDuringDrag = !row.follows;
                        selector.paintRange(row.index, row.index, selector.followDuringDrag);
                    }
                    onPositionChanged: mouse => {
                        if (pressed && selector.lastRow >= 0 && rows.count) {
                            const point = mapToItem(view.contentItem, mouse.x, mouse.y);
                            const next = Math.max(0, Math.min(rows.count - 1,
                                Math.floor(point.y / selector.rowHeight)));
                            if (next !== selector.lastRow) {
                                selector.paintRange(selector.lastRow, next, selector.followDuringDrag);
                                selector.lastRow = next;
                            }
                        }
                    }
                    onReleased: selector.lastRow = -1
                    onCanceled: selector.lastRow = -1
                }
            }
        }

        Rectangle {
            id: scrollTrack
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.topMargin: 4
            anchors.bottomMargin: 4
            anchors.rightMargin: 2
            width: selector.scrollBarWidth
            radius: width / 2
            color: "transparent"
            visible: box.hasOverflow
            z: 20

            readonly property real maxThumbY: Math.max(0, height - scrollThumb.height)
            readonly property real maxContentY: Math.max(0, view.contentHeight - view.height)
            property real dragOffset: 0

            Rectangle {
                id: scrollThumb
                width: parent.width
                height: Math.max(20, parent.height * Math.min(1, view.height / Math.max(1, view.contentHeight)))
                y: scrollTrack.maxContentY > 0
                    ? (Math.max(0, Math.min(scrollTrack.maxContentY, view.contentY)) / scrollTrack.maxContentY) * scrollTrack.maxThumbY
                    : 0
                radius: width / 2
                color: Qt.alpha(Kirigami.Theme.textColor, scrollMouse.containsMouse || scrollMouse.pressed ? 0.7 : 0.48)
            }

            MouseArea {
                id: scrollMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                function moveThumb(pointerY) {
                    if (scrollTrack.maxThumbY <= 0 || scrollTrack.maxContentY <= 0) {
                        return;
                    }
                    const nextY = Math.max(0, Math.min(scrollTrack.maxThumbY, pointerY - scrollTrack.dragOffset));
                    view.contentY = (nextY / scrollTrack.maxThumbY) * scrollTrack.maxContentY;
                }

                onPressed: mouse => {
                    if (mouse.y >= scrollThumb.y && mouse.y <= scrollThumb.y + scrollThumb.height) {
                        scrollTrack.dragOffset = mouse.y - scrollThumb.y;
                    } else {
                        scrollTrack.dragOffset = scrollThumb.height / 2;
                        moveThumb(mouse.y);
                    }
                }
                onPositionChanged: mouse => {
                    if (pressed) {
                        moveThumb(mouse.y);
                    }
                }
            }
        }

    }
}
