// SPDX-FileCopyrightText: 2026 suppdiff
// SPDX-License-Identifier: GPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.draganddrop as DragAndDrop
import org.kde.plasma.extras as PlasmaExtras
import appcoupling.launcher 1.0

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    readonly property bool verticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool horizontalPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
    readonly property bool inPanel: verticalPanel || horizontalPanel
    // Desktop launcher layout stays left-to-right; only the tab strip can move to any side.
    readonly property bool horizontalLayout: !verticalPanel

    readonly property int sectionCount: Math.max(1, Plasmoid.configuration.sections)
    readonly property int requestedIconSize: Math.max(8, Plasmoid.configuration.iconSize)
    readonly property int effectiveIconSize: requestedIconSize
    readonly property int horizontalSpacing: Math.max(0, Plasmoid.configuration.horizontalSpacing)
    readonly property int verticalSpacing: Math.max(0, Plasmoid.configuration.verticalSpacing)
    readonly property int cellWidth: requestedIconSize + horizontalSpacing
    readonly property int cellHeight: requestedIconSize + verticalSpacing
    readonly property int primaryCellExtent: horizontalLayout ? cellWidth : cellHeight
    readonly property int crossCellExtent: horizontalLayout ? cellHeight : cellWidth
    readonly property int primarySpacing: horizontalLayout ? horizontalSpacing : verticalSpacing
    readonly property int crossSpacing: horizontalLayout ? verticalSpacing : horizontalSpacing
    // Alignment is independent on the launcher (primary) and cross axes.
    // 0 = start, 1 = center, 2 = end.
    readonly property int primaryLauncherAlignment: Math.max(0, Math.min(2, Plasmoid.configuration.launcherAlignment))
    readonly property int crossLauncherAlignment: Math.max(0, Math.min(2, Plasmoid.configuration.crossAlignment))

    // Along-panel sizing: automatic (capped), fixed pixels, or fill leftover panel space.
    readonly property int lengthMode: Math.max(0, Math.min(2, Plasmoid.configuration.lengthMode))
    readonly property int configuredFixedLength: Math.max(24, Plasmoid.configuration.fixedLength)
    readonly property int automaticMaxLength: Math.max(48, Plasmoid.configuration.automaticMaxLength)

    // 0 = paged arrows, 1 = popup overflow, 2 = scroll.
    readonly property int overflowMode: Math.max(0, Math.min(2, Plasmoid.configuration.overflowMode))

    // Optional theme-colored outline.
    readonly property bool showBorder: Plasmoid.configuration.showBorder
    readonly property int borderWidth: showBorder ? Math.max(1, Plasmoid.configuration.borderWidth) : 0
    readonly property real borderOpacity: Math.max(0.05, Math.min(1.0, Plasmoid.configuration.borderOpacity / 100.0))
    readonly property int borderRadius: Math.max(0, Plasmoid.configuration.borderRadius)
    readonly property int contentInset: borderWidth

    // Optional launcher groups/tabs.
    readonly property bool tabsEnabled: Plasmoid.configuration.enableTabs
    readonly property int panelTabPosition: Math.max(0, Math.min(1, Plasmoid.configuration.panelTabPosition))
    readonly property int desktopTabPosition: Math.max(0, Math.min(3, Plasmoid.configuration.desktopTabPosition))
    readonly property int tabItemThickness: Math.max(24, Math.min(36, requestedIconSize))
    // Vertical tabs keep their labels horizontal/readable, so the strip needs more width
    // than a horizontal tab bar needs height. It is still hidden when space is insufficient.
    readonly property int verticalTabStripWidth: Math.max(72, Math.min(144, requestedIconSize * 3))
    readonly property int tabGap: 2
    readonly property bool tabStripVertical: inPanel ? verticalPanel : desktopTabPosition >= 2
    readonly property int tabStripThickness: tabStripVertical ? verticalTabStripWidth : tabItemThickness
    readonly property int tabReserve: tabStripThickness + tabGap
    readonly property bool tabStripOnStartSide: {
        if (!inPanel) {
            return desktopTabPosition === 0 || desktopTabPosition === 2;
        }

        let automaticStart = true;
        if (verticalPanel) {
            // Inner edge: right side of a left panel, left side of a right panel.
            if (Plasmoid.location === PlasmaCore.Types.LeftEdge) {
                automaticStart = false;
            } else if (Plasmoid.location === PlasmaCore.Types.RightEdge) {
                automaticStart = true;
            }
        } else {
            // Inner edge: top of a bottom panel, bottom of a top panel.
            if (Plasmoid.location === PlasmaCore.Types.BottomEdge) {
                automaticStart = true;
            } else if (Plasmoid.location === PlasmaCore.Types.TopEdge) {
                automaticStart = false;
            }
        }
        return panelTabPosition === 0 ? automaticStart : !automaticStart;
    }
    readonly property bool tabsCanShow: tabsEnabled && tabsModel.count > 0 &&
        (tabStripVertical
            ? content.width >= requestedIconSize + tabReserve
            : content.height >= requestedIconSize + tabReserve)

    readonly property real launcherX: tabsCanShow && tabStripVertical && tabStripOnStartSide ? tabReserve : 0
    readonly property real launcherY: tabsCanShow && !tabStripVertical && tabStripOnStartSide ? tabReserve : 0
    readonly property real launcherWidth: Math.max(1, content.width - (tabsCanShow && tabStripVertical ? tabReserve : 0))
    readonly property real launcherHeight: Math.max(1, content.height - (tabsCanShow && !tabStripVertical ? tabReserve : 0))

    readonly property int configuredPrimarySlots: Math.max(1, Math.ceil(launcherModel.count / sectionCount))
    function extentForSlots(slots, spacing) {
        const count = Math.max(1, slots);
        return count * requestedIconSize + Math.max(0, count - 1) * spacing;
    }

    function slotsForExtent(extent, spacing) {
        return Math.max(1, Math.floor((Math.max(0, extent) + spacing) / Math.max(1, requestedIconSize + spacing)));
    }

    readonly property int fullPrimaryExtent: extentForSlots(configuredPrimarySlots, primarySpacing) + contentInset * 2
    readonly property int navigationExtent: Math.max(20, Math.min(30, requestedIconSize))
    // Keep at least one launcher cell usable, plus any overflow controls that must coexist with it.
    readonly property int minimumControlExtent: overflowMode === 0 ? navigationExtent * 2 : (overflowMode === 1 ? navigationExtent : 0)
    readonly property int minimumPrimaryExtent: requestedIconSize + minimumControlExtent + contentInset * 2
    readonly property int autoPrimaryExtent: Math.max(minimumPrimaryExtent, Math.min(fullPrimaryExtent, Math.max(minimumPrimaryExtent, automaticMaxLength)))
    readonly property int fixedPrimaryExtent: Math.max(minimumPrimaryExtent, configuredFixedLength)
    readonly property int preferredPrimaryExtent: lengthMode === 1 ? fixedPrimaryExtent : autoPrimaryExtent
    readonly property int configuredCrossExtent: extentForSlots(sectionCount, crossSpacing) + contentInset * 2
    readonly property int desktopWidthExtra: !inPanel && tabsEnabled && tabStripVertical ? tabReserve : 0
    readonly property int desktopHeightExtra: !inPanel && tabsEnabled && !tabStripVertical ? tabReserve : 0

    // Overflow is calculated from the actual launcher area. Icons never shrink to make the grid fit.
    readonly property real contentPrimaryAvailable: Math.max(1, horizontalLayout ? launcherWidth : launcherHeight)
    readonly property real contentCrossAvailable: Math.max(1, horizontalLayout ? launcherHeight : launcherWidth)
    readonly property int crossGridExtent: Math.max(1, Math.min(extentForSlots(sectionCount, crossSpacing), Math.floor(contentCrossAvailable)))
    readonly property int visibleCrossSlots: slotsForExtent(crossGridExtent, crossSpacing)
    readonly property int rawVisiblePrimarySlots: slotsForExtent(contentPrimaryAvailable, primarySpacing)
    readonly property bool rawOverflow: launcherModel.count > rawVisiblePrimarySlots * visibleCrossSlots
    readonly property int leadingReserve: overflowMode === 0 && rawOverflow ? navigationExtent : 0
    readonly property int trailingReserve: rawOverflow ? (overflowMode === 0 ? navigationExtent : (overflowMode === 1 ? navigationExtent : 0)) : 0
    readonly property int gridPrimaryExtent: Math.max(1, Math.floor(contentPrimaryAvailable - leadingReserve - trailingReserve))
    readonly property int visiblePrimarySlots: slotsForExtent(gridPrimaryExtent, primarySpacing)
    readonly property int pageCapacity: Math.max(1, visiblePrimarySlots * visibleCrossSlots)
    readonly property int pageCount: Math.max(1, Math.ceil(launcherModel.count / pageCapacity))
    readonly property bool hasOverflow: launcherModel.count > pageCapacity
    readonly property int hiddenCount: Math.max(0, launcherModel.count - pageCapacity)
    readonly property int pagePixelExtent: visiblePrimarySlots * primaryCellExtent
    readonly property int usedPrimarySlots: Math.max(1, Math.ceil(launcherModel.count / visibleCrossSlots))
    readonly property int usedPrimaryExtent: Math.min(gridPrimaryExtent, extentForSlots(usedPrimarySlots, primarySpacing))
    readonly property int alignedGridPrimaryExtent: hasOverflow ? gridPrimaryExtent : usedPrimaryExtent
    readonly property int primaryAlignmentSlack: Math.max(0, gridPrimaryExtent - alignedGridPrimaryExtent)
    readonly property int primaryAlignmentOffset: primaryLauncherAlignment === 1
        ? Math.round(primaryAlignmentSlack / 2)
        : (primaryLauncherAlignment === 2 ? primaryAlignmentSlack : 0)
    readonly property int crossAlignmentSlack: Math.max(0, Math.floor(contentCrossAvailable - crossGridExtent))
    readonly property int crossAlignmentOffset: crossLauncherAlignment === 1
        ? Math.round(crossAlignmentSlack / 2)
        : (crossLauncherAlignment === 2 ? crossAlignmentSlack : 0)

    property int pageIndex: 0
    property bool dragging: false
    property int internalDragIndex: -1
    property int internalDragOriginalIndex: -1
    property int activeTab: 0
    property int renameTabIndex: -1
    property int transferLauncherIndex: -1
    property bool transferCopyMode: false

    // Horizontal panels control width; vertical panels control height. Plasma controls panel thickness.
    Layout.preferredWidth: verticalPanel ? -1 : preferredPrimaryExtent + desktopWidthExtra
    Layout.minimumWidth: verticalPanel ? 0 : (lengthMode === 1 ? fixedPrimaryExtent : minimumPrimaryExtent) + desktopWidthExtra
    Layout.fillWidth: horizontalPanel && lengthMode === 2
    Layout.preferredHeight: verticalPanel ? preferredPrimaryExtent : (horizontalPanel ? -1 : configuredCrossExtent + desktopHeightExtra)
    Layout.minimumHeight: verticalPanel ? (lengthMode === 1 ? fixedPrimaryExtent : minimumPrimaryExtent) : (horizontalPanel ? 0 : requestedIconSize + contentInset * 2 + desktopHeightExtra)
    Layout.fillHeight: verticalPanel && lengthMode === 2

    implicitWidth: verticalPanel ? configuredCrossExtent : preferredPrimaryExtent + desktopWidthExtra
    implicitHeight: verticalPanel ? preferredPrimaryExtent : configuredCrossExtent + desktopHeightExtra

    function clampPage() {
        pageIndex = Math.max(0, Math.min(pageIndex, pageCount - 1));
    }

    function changePage(delta) {
        if (pageCount <= 1) {
            return;
        }
        pageIndex = Math.max(0, Math.min(pageCount - 1, pageIndex + delta));
    }

    function resetOverflowPosition() {
        pageIndex = 0;
        grid.contentX = 0;
        grid.contentY = 0;
        overflowDialog.visible = false;
    }

    function scrollBy(delta) {
        if (overflowMode !== 2 || !hasOverflow) {
            return;
        }

        const primarySlots = Math.max(1, Math.ceil(launcherModel.count / visibleCrossSlots));
        const modelPrimaryExtent = root.extentForSlots(primarySlots, root.primarySpacing);
        if (horizontalLayout) {
            const maxOffset = Math.max(0, modelPrimaryExtent - grid.width);
            grid.contentX = Math.max(0, Math.min(maxOffset, grid.contentX + delta));
        } else {
            const maxOffset = Math.max(0, modelPrimaryExtent - grid.height);
            grid.contentY = Math.max(0, Math.min(maxOffset, grid.contentY + delta));
        }
    }

    function rebuildOverflowModel() {
        overflowModel.clear();
        const start = Math.min(pageCapacity, launcherModel.count);
        for (let i = start; i < launcherModel.count; ++i) {
            overflowModel.append({
                launcherUrl: launcherModel.get(i).launcherUrl,
                sourceIndex: i
            });
        }
        if (overflowModel.count === 0) {
            overflowDialog.visible = false;
        }
    }

    function parsedUrls(jsonText) {
        try {
            const value = JSON.parse(jsonText || "[]");
            if (!Array.isArray(value)) {
                return [];
            }
            const result = [];
            for (let i = 0; i < value.length; ++i) {
                const url = value[i] === undefined || value[i] === null ? "" : value[i].toString();
                if (url.length > 0) {
                    result.push(url);
                }
            }
            return result;
        } catch (error) {
            return [];
        }
    }

    function loadTabs() {
        tabsModel.clear();
        let parsed = [];
        try {
            parsed = JSON.parse(Plasmoid.configuration.tabsJson || "[]");
        } catch (error) {
            parsed = [];
        }

        if (!Array.isArray(parsed) || parsed.length === 0) {
            const legacy = [];
            const configured = Plasmoid.configuration.launcherUrls;
            for (let i = 0; i < configured.length; ++i) {
                legacy.push(configured[i].toString());
            }
            parsed = [{ name: i18n("Apps"), launcherUrls: legacy }];
        }

        for (let i = 0; i < parsed.length; ++i) {
            const entry = parsed[i] || {};
            const urls = Array.isArray(entry.launcherUrls) ? entry.launcherUrls : [];
            tabsModel.append({
                name: entry.name && entry.name.toString().trim().length > 0 ? entry.name.toString() : i18n("Tab %1", i + 1),
                launcherUrlsJson: JSON.stringify(urls)
            });
        }

        activeTab = Math.max(0, Math.min(Plasmoid.configuration.selectedTab, tabsModel.count - 1));
        saveTabsConfiguration();
    }

    function saveTabsConfiguration() {
        const result = [];
        for (let i = 0; i < tabsModel.count; ++i) {
            const entry = tabsModel.get(i);
            result.push({
                name: entry.name,
                launcherUrls: parsedUrls(entry.launcherUrlsJson)
            });
        }
        Plasmoid.configuration.tabsJson = JSON.stringify(result);
        Plasmoid.configuration.selectedTab = activeTab;
    }

    function storeCurrentTabLaunchers() {
        if (tabsModel.count === 0 || activeTab < 0 || activeTab >= tabsModel.count) {
            return;
        }
        tabsModel.setProperty(activeTab, "launcherUrlsJson", JSON.stringify(launcherModel.urls()));
        saveTabsConfiguration();
    }

    function loadActiveTabLaunchers() {
        if (tabsModel.count === 0) {
            launcherModel.load([]);
            return;
        }
        activeTab = Math.max(0, Math.min(activeTab, tabsModel.count - 1));
        launcherModel.load(parsedUrls(tabsModel.get(activeTab).launcherUrlsJson));
        Plasmoid.configuration.selectedTab = activeTab;
        resetOverflowPosition();
    }

    function switchTab(index) {
        if (!tabsEnabled || index < 0 || index >= tabsModel.count || index === activeTab) {
            return;
        }
        storeCurrentTabLaunchers();
        activeTab = index;
        loadActiveTabLaunchers();
    }

    function addTab() {
        if (!tabsEnabled) {
            return;
        }
        storeCurrentTabLaunchers();
        tabsModel.append({ name: i18n("New Tab"), launcherUrlsJson: "[]" });
        activeTab = tabsModel.count - 1;
        saveTabsConfiguration();
        loadActiveTabLaunchers();
    }

    function duplicateTab(index) {
        if (index < 0 || index >= tabsModel.count) {
            return;
        }
        storeCurrentTabLaunchers();
        const entry = tabsModel.get(index);
        tabsModel.insert(index + 1, {
            name: i18n("%1 Copy", entry.name),
            launcherUrlsJson: entry.launcherUrlsJson
        });
        activeTab = index + 1;
        saveTabsConfiguration();
        loadActiveTabLaunchers();
    }

    function moveTab(index, delta) {
        const target = index + delta;
        if (index < 0 || index >= tabsModel.count || target < 0 || target >= tabsModel.count) {
            return;
        }
        storeCurrentTabLaunchers();
        tabsModel.move(index, target, 1);
        if (activeTab === index) {
            activeTab = target;
        } else if (activeTab === target) {
            activeTab = index;
        }
        saveTabsConfiguration();
    }

    function removeTab(index) {
        if (tabsModel.count <= 1 || index < 0 || index >= tabsModel.count) {
            return;
        }
        storeCurrentTabLaunchers();
        const wasActive = index === activeTab;
        tabsModel.remove(index, 1);
        if (activeTab > index) {
            activeTab -= 1;
        } else if (activeTab >= tabsModel.count) {
            activeTab = tabsModel.count - 1;
        }
        saveTabsConfiguration();
        if (wasActive) {
            loadActiveTabLaunchers();
        }
    }

    function beginRenameTab(index) {
        if (index < 0 || index >= tabsModel.count) {
            return;
        }
        renameTabIndex = index;
        renameField.text = tabsModel.get(index).name;
        renameDialog.visible = true;
        Qt.callLater(function() {
            renameField.forceActiveFocus();
            renameField.selectAll();
        });
    }

    function commitRenameTab() {
        if (renameTabIndex < 0 || renameTabIndex >= tabsModel.count) {
            renameDialog.visible = false;
            renameTabIndex = -1;
            return;
        }
        const cleaned = renameField.text.trim();
        if (cleaned.length > 0) {
            tabsModel.setProperty(renameTabIndex, "name", cleaned);
            saveTabsConfiguration();
        }
        renameDialog.visible = false;
        renameTabIndex = -1;
    }

    function beginLauncherTransfer(index, copyMode) {
        if (!tabsEnabled || tabsModel.count < 2 || index < 0 || index >= launcherModel.count) {
            return;
        }
        transferLauncherIndex = index;
        transferCopyMode = copyMode;
        transferDialog.visible = true;
    }

    function transferLauncherToTab(targetTabIndex) {
        if (!tabsEnabled || transferLauncherIndex < 0 || transferLauncherIndex >= launcherModel.count ||
                targetTabIndex < 0 || targetTabIndex >= tabsModel.count || targetTabIndex === activeTab) {
            transferDialog.visible = false;
            transferLauncherIndex = -1;
            return;
        }

        const url = launcherModel.get(transferLauncherIndex).launcherUrl;
        const destinationUrls = parsedUrls(tabsModel.get(targetTabIndex).launcherUrlsJson);
        destinationUrls.push(url);
        tabsModel.setProperty(targetTabIndex, "launcherUrlsJson", JSON.stringify(destinationUrls));

        if (!transferCopyMode) {
            launcherModel.remove(transferLauncherIndex, 1);
        }

        tabsModel.setProperty(activeTab, "launcherUrlsJson", JSON.stringify(launcherModel.urls()));
        saveTabsConfiguration();
        resetOverflowPosition();

        transferDialog.visible = false;
        transferLauncherIndex = -1;
    }

    function triggerInternalAction(name) {
        const action = Plasmoid.internalAction(name);
        if (action) {
            action.trigger();
        }
    }

    ListModel {
        id: tabsModel
    }

    ListModel {
        id: launcherModel

        function load(urls) {
            clear();
            for (let i = 0; i < urls.length; ++i) {
                append({ launcherUrl: urls[i].toString() });
            }
            Qt.callLater(root.rebuildOverflowModel);
        }

        function urls() {
            const result = [];
            for (let i = 0; i < count; ++i) {
                result.push(get(i).launcherUrl);
            }
            return result;
        }

        function insertUrls(index, urls) {
            let at = Math.max(0, Math.min(index, count));
            for (let i = 0; i < urls.length; ++i) {
                const value = urls[i].toString();
                if (value.length === 0) {
                    continue;
                }
                insert(at, { launcherUrl: value });
                ++at;
            }
            Qt.callLater(root.rebuildOverflowModel);
        }

        onCountChanged: {
            Qt.callLater(root.clampPage);
            Qt.callLater(root.rebuildOverflowModel);
        }
    }

    ListModel {
        id: overflowModel
    }

    function saveLaunchers() {
        if (tabsEnabled) {
            storeCurrentTabLaunchers();
        } else {
            Plasmoid.configuration.launcherUrls = launcherModel.urls();
        }
        Qt.callLater(rebuildOverflowModel);
    }

    function configuredLaunchersMatchModel() {
        const configured = Plasmoid.configuration.launcherUrls;
        if (configured.length !== launcherModel.count) {
            return false;
        }
        for (let i = 0; i < configured.length; ++i) {
            if (configured[i].toString() !== launcherModel.get(i).launcherUrl) {
                return false;
            }
        }
        return true;
    }

    function removeLauncher(index) {
        if (index < 0 || index >= launcherModel.count) {
            return;
        }
        launcherModel.remove(index, 1);
        saveLaunchers();
    }

    function calculatedIndex(eventX, eventY, allowEnd) {
        const p = grid.mapFromItem(dropArea, eventX, eventY);
        const xWithScroll = p.x + grid.contentX;
        const yWithScroll = p.y + grid.contentY;
        let column = Math.floor(xWithScroll / cellWidth);
        let row = Math.floor(yWithScroll / cellHeight);

        column = Math.max(0, column);
        row = Math.max(0, row);

        let index;
        if (horizontalLayout) {
            index = column * visibleCrossSlots + Math.min(row, visibleCrossSlots - 1);
        } else {
            index = row * visibleCrossSlots + Math.min(column, visibleCrossSlots - 1);
        }

        const maximum = allowEnd ? launcherModel.count : Math.max(0, launcherModel.count - 1);
        return Math.max(0, Math.min(index, maximum));
    }

    Rectangle {
        anchors.fill: parent
        visible: root.showBorder
        color: "transparent"
        border.width: root.borderWidth
        border.color: Kirigami.Theme.textColor
        radius: root.borderRadius
        opacity: root.borderOpacity
    }

    Item {
        id: content
        anchors.fill: parent
        anchors.margins: root.contentInset

        GridView {
            id: grid

            x: root.launcherX + (root.horizontalLayout
                ? root.leadingReserve + root.primaryAlignmentOffset
                : root.crossAlignmentOffset)
            y: root.launcherY + (root.horizontalLayout
                ? root.crossAlignmentOffset
                : root.leadingReserve + root.primaryAlignmentOffset)
            width: root.horizontalLayout ? root.alignedGridPrimaryExtent : root.crossGridExtent
            height: root.horizontalLayout ? root.crossGridExtent : root.alignedGridPrimaryExtent

            interactive: root.overflowMode === 2
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: root.horizontalLayout ? Flickable.HorizontalFlick : Flickable.VerticalFlick
            flow: root.horizontalLayout ? GridView.FlowTopToBottom : GridView.FlowLeftToRight

            QQC2.ScrollIndicator.horizontal: QQC2.ScrollIndicator {
                visible: root.overflowMode === 2 && root.hasOverflow && root.horizontalLayout
                active: visible
                opacity: grid.moving ? 1.0 : 0.55
            }

            QQC2.ScrollIndicator.vertical: QQC2.ScrollIndicator {
                visible: root.overflowMode === 2 && root.hasOverflow && !root.horizontalLayout
                active: visible
                opacity: grid.moving ? 1.0 : 0.55
            }
            cellWidth: root.cellWidth
            cellHeight: root.cellHeight
            model: launcherModel

            delegate: Item {
                id: launcherItem
                required property int index
                required property string launcherUrl

                readonly property bool appCouplingLauncher: true
                readonly property var appCouplingRoot: root

                width: root.requestedIconSize
                height: root.requestedIconSize

                readonly property var info: launcherBridge.launcherData(launcherUrl)
                readonly property string displayName: info.applicationName || launcherUrl
                readonly property string iconName: info.iconName || "system-run"

                DragAndDrop.DragArea {
                    id: dragSource
                    anchors.fill: parent
                    enabled: !Plasmoid.immutable
                    defaultAction: Qt.MoveAction
                    supportedActions: Qt.IgnoreAction | Qt.MoveAction | Qt.CopyAction
                    delegate: appIcon
                    source: launcherItem

                    mimeData {
                        url: launcherItem.launcherUrl
                        source: launcherItem
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        hoverEnabled: true

                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton) {
                                launcherBridge.openUrl(launcherItem.launcherUrl);
                            } else if (mouse.button === Qt.RightButton) {
                                itemMenu.open(mouse.x, mouse.y);
                            }
                        }

                        Kirigami.Icon {
                            id: appIcon
                            anchors.centerIn: parent
                            width: root.effectiveIconSize
                            height: width
                            source: launcherItem.iconName
                            active: mouseArea.containsMouse || launcherItem.index === root.internalDragIndex
                        }

                        PlasmaCore.ToolTipArea {
                            anchors.fill: parent
                            mainText: launcherItem.displayName
                            subText: launcherItem.info.genericName || ""
                            icon: launcherItem.iconName
                        }

                        PlasmaExtras.Menu {
                            id: itemMenu
                            visualParent: mouseArea

                            PlasmaExtras.MenuItem {
                                text: i18n("Remove Launcher")
                                icon: "list-remove"
                                onClicked: root.removeLauncher(launcherItem.index)
                            }

                            PlasmaExtras.MenuItem {
                                text: i18n("Add Launcher…")
                                icon: "list-add"
                                onClicked: launcherBridge.addLauncher()
                            }

                            PlasmaExtras.MenuItem {
                                text: i18n("Move to Tab…")
                                icon: "go-jump"
                                visible: root.tabsEnabled && tabsModel.count > 1
                                onClicked: root.beginLauncherTransfer(launcherItem.index, false)
                            }

                            PlasmaExtras.MenuItem {
                                text: i18n("Copy to Tab…")
                                icon: "edit-copy"
                                visible: root.tabsEnabled && tabsModel.count > 1
                                onClicked: root.beginLauncherTransfer(launcherItem.index, true)
                            }

                            PlasmaExtras.MenuItem {
                                separator: true
                            }

                            PlasmaExtras.MenuItem {
                                action: Plasmoid.internalAction("configure")
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: previousButton
            visible: root.overflowMode === 0 && root.hasOverflow
            enabled: root.pageIndex > 0
            x: root.launcherX
            y: root.launcherY
            width: root.horizontalLayout ? root.navigationExtent : root.launcherWidth
            height: root.horizontalLayout ? root.launcherHeight : root.navigationExtent
            radius: 4
            color: previousMouse.containsMouse && enabled
                ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                          Kirigami.Theme.highlightColor.g,
                          Kirigami.Theme.highlightColor.b, 0.10)
                : "transparent"

            Kirigami.Icon {
                anchors.centerIn: parent
                width: Math.min(18, parent.width)
                height: width
                source: root.horizontalLayout ? "go-previous" : "go-up"
                opacity: previousButton.enabled ? (previousMouse.containsMouse ? 1.0 : 0.72) : 0.28
            }

            MouseArea {
                id: previousMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: previousButton.enabled
                onClicked: root.changePage(-1)
            }

            PlasmaCore.ToolTipArea {
                anchors.fill: parent
                mainText: i18n("Previous page")
                subText: i18n("Page %1 of %2", root.pageIndex + 1, root.pageCount)
            }
        }

        Rectangle {
            id: nextButton
            visible: root.overflowMode === 0 && root.hasOverflow
            enabled: root.pageIndex < root.pageCount - 1
            x: root.horizontalLayout ? root.launcherX + root.launcherWidth - root.navigationExtent : root.launcherX
            y: root.horizontalLayout ? root.launcherY : root.launcherY + root.launcherHeight - root.navigationExtent
            width: root.horizontalLayout ? root.navigationExtent : root.launcherWidth
            height: root.horizontalLayout ? root.launcherHeight : root.navigationExtent
            radius: 4
            color: nextMouse.containsMouse && enabled
                ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                          Kirigami.Theme.highlightColor.g,
                          Kirigami.Theme.highlightColor.b, 0.10)
                : "transparent"

            Kirigami.Icon {
                anchors.centerIn: parent
                width: Math.min(18, parent.width)
                height: width
                source: root.horizontalLayout ? "go-next" : "go-down"
                opacity: nextButton.enabled ? (nextMouse.containsMouse ? 1.0 : 0.72) : 0.28
            }

            MouseArea {
                id: nextMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: nextButton.enabled
                onClicked: root.changePage(1)
            }

            PlasmaCore.ToolTipArea {
                anchors.fill: parent
                mainText: i18n("Next page")
                subText: i18n("Page %1 of %2", root.pageIndex + 1, root.pageCount)
            }
        }

        Rectangle {
            id: overflowButton
            visible: root.overflowMode === 1 && root.hasOverflow
            x: root.horizontalLayout ? root.launcherX + root.launcherWidth - root.navigationExtent : root.launcherX
            y: root.horizontalLayout ? root.launcherY : root.launcherY + root.launcherHeight - root.navigationExtent
            width: root.horizontalLayout ? root.navigationExtent : root.launcherWidth
            height: root.horizontalLayout ? root.launcherHeight : root.navigationExtent
            color: overflowMouse.containsMouse ? Kirigami.Theme.hoverColor : "transparent"

            QQC2.Label {
                anchors.centerIn: parent
                text: "+" + root.hiddenCount
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: Math.max(9, Math.min(13, root.navigationExtent * 0.42))
            }

            MouseArea {
                id: overflowMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    root.rebuildOverflowModel();
                    overflowDialog.visible = !overflowDialog.visible;
                }
            }

            PlasmaCore.ToolTipArea {
                anchors.fill: parent
                mainText: i18np("Show %1 more launcher", "Show %1 more launchers", root.hiddenCount)
            }
        }

        Item {
            id: emptyItem
            readonly property real emptyPrimarySlack: Math.max(0,
                (root.horizontalLayout ? root.launcherWidth : root.launcherHeight) -
                (root.horizontalLayout ? width : height))
            readonly property real emptyPrimaryOffset: root.primaryLauncherAlignment === 1
                ? Math.round(emptyPrimarySlack / 2)
                : (root.primaryLauncherAlignment === 2 ? emptyPrimarySlack : 0)
            readonly property real emptyCrossSlack: Math.max(0,
                (root.horizontalLayout ? root.launcherHeight : root.launcherWidth) -
                (root.horizontalLayout ? height : width))
            readonly property real emptyCrossOffset: root.crossLauncherAlignment === 1
                ? Math.round(emptyCrossSlack / 2)
                : (root.crossLauncherAlignment === 2 ? emptyCrossSlack : 0)

            x: root.horizontalLayout
                ? root.launcherX + emptyPrimaryOffset
                : root.launcherX + emptyCrossOffset
            y: root.horizontalLayout
                ? root.launcherY + emptyCrossOffset
                : root.launcherY + emptyPrimaryOffset
            width: Math.min(root.launcherWidth, root.requestedIconSize)
            height: Math.min(root.launcherHeight, root.requestedIconSize)
            visible: launcherModel.count === 0

            Kirigami.Icon {
                anchors.centerIn: parent
                width: Math.min(root.effectiveIconSize, parent.width)
                height: width
                source: "list-add"
                active: emptyMouse.containsMouse
            }

            MouseArea {
                id: emptyMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: launcherBridge.addLauncher()
            }

            PlasmaCore.ToolTipArea {
                anchors.fill: parent
                mainText: i18n("App Coupling+")
                subText: root.tabsEnabled
                    ? i18n("Drop applications into the current tab or click to add one")
                    : i18n("Drop applications here or click to add one")
            }
        }

        MouseArea {
            x: root.launcherX
            y: root.launcherY
            width: root.launcherWidth
            height: root.launcherHeight
            acceptedButtons: Qt.NoButton
            hoverEnabled: false
            onWheel: wheel => {
                if (!root.hasOverflow) {
                    wheel.accepted = false;
                    return;
                }
                const delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x;
                if (delta === 0) {
                    wheel.accepted = false;
                    return;
                }
                if (root.overflowMode === 0) {
                    root.changePage(delta < 0 ? 1 : -1);
                    wheel.accepted = true;
                } else if (root.overflowMode === 2) {
                    root.scrollBy(delta < 0 ? root.primaryCellExtent : -root.primaryCellExtent);
                    wheel.accepted = true;
                } else {
                    wheel.accepted = false;
                }
            }
        }

        // Tabs follow panel orientation. On desktop their side is explicit.
        Rectangle {
            id: tabStripBackground
            visible: root.tabsCanShow
            z: 20
            x: root.tabStripVertical ? (root.tabStripOnStartSide ? 0 : content.width - root.tabStripThickness) : 0
            y: root.tabStripVertical ? 0 : (root.tabStripOnStartSide ? 0 : content.height - root.tabStripThickness)
            width: root.tabStripVertical ? root.tabStripThickness : content.width
            height: root.tabStripVertical ? content.height : root.tabStripThickness
            color: Qt.rgba(Kirigami.Theme.textColor.r,
                           Kirigami.Theme.textColor.g,
                           Kirigami.Theme.textColor.b, 0.035)

            ListView {
                id: tabList
                anchors.fill: parent
                orientation: root.tabStripVertical ? ListView.Vertical : ListView.Horizontal
                spacing: 2
                clip: true
                interactive: root.tabStripVertical ? contentHeight > height : contentWidth > width
                boundsBehavior: Flickable.StopAtBounds
                model: tabsModel
                currentIndex: root.activeTab
                footerPositioning: ListView.InlineFooter

                footer: Item {
                    width: root.tabStripVertical ? root.tabStripThickness : root.tabItemThickness + 2
                    height: root.tabStripVertical ? root.tabItemThickness + 2 : root.tabItemThickness

                    QQC2.ToolButton {
                        anchors.centerIn: parent
                        width: root.tabStripVertical ? parent.width : root.tabItemThickness
                        height: root.tabItemThickness
                        enabled: !Plasmoid.immutable
                        text: "+"
                        font.pixelSize: Math.max(15, root.tabItemThickness * 0.52)
                        onClicked: root.addTab()
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: i18n("Add tab")
                    }
                }

                delegate: Item {
                    id: tabDelegate
                    required property int index
                    required property string name
                    required property string launcherUrlsJson

                    width: root.tabStripVertical
                        ? root.tabStripThickness
                        : Math.max(52, Math.min(160, tabLabel.implicitWidth + 28))
                    height: root.tabStripVertical
                        ? root.tabItemThickness
                        : root.tabItemThickness

                    Rectangle {
                        anchors.fill: parent
                        radius: Math.min(6, root.tabItemThickness / 4)
                        color: tabDelegate.index === root.activeTab
                            ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                                      Kirigami.Theme.highlightColor.g,
                                      Kirigami.Theme.highlightColor.b, 0.22)
                            : tabMouse.containsMouse
                                ? Qt.rgba(Kirigami.Theme.textColor.r,
                                          Kirigami.Theme.textColor.g,
                                          Kirigami.Theme.textColor.b, 0.07)
                                : "transparent"
                        border.width: tabDelegate.index === root.activeTab ? 1 : 0
                        border.color: Kirigami.Theme.highlightColor
                    }

                    QQC2.Label {
                        id: tabLabel
                        anchors.centerIn: parent
                        width: Math.max(1, tabDelegate.width - 14)
                        height: Math.max(1, tabDelegate.height - 4)
                        text: tabDelegate.name
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        rotation: 0
                    }

                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton) {
                                root.switchTab(tabDelegate.index);
                            } else {
                                tabMenu.open(mouse.x, mouse.y);
                            }
                        }
                    }

                    PlasmaCore.ToolTipArea {
                        anchors.fill: parent
                        mainText: tabDelegate.name
                        subText: tabDelegate.index === root.activeTab ? i18n("Current tab") : i18n("Switch tab")
                    }

                    PlasmaExtras.Menu {
                        id: tabMenu
                        visualParent: tabMouse

                        PlasmaExtras.MenuItem {
                            text: i18n("Rename Tab…")
                            icon: "edit-rename"
                            onClicked: root.beginRenameTab(tabDelegate.index)
                        }

                        PlasmaExtras.MenuItem {
                            text: i18n("Duplicate Tab")
                            icon: "edit-copy"
                            onClicked: root.duplicateTab(tabDelegate.index)
                        }

                        PlasmaExtras.MenuItem {
                            text: root.tabStripVertical ? i18n("Move Up") : i18n("Move Left")
                            icon: root.tabStripVertical ? "go-up" : "go-previous"
                            enabled: tabDelegate.index > 0
                            onClicked: root.moveTab(tabDelegate.index, -1)
                        }

                        PlasmaExtras.MenuItem {
                            text: root.tabStripVertical ? i18n("Move Down") : i18n("Move Right")
                            icon: root.tabStripVertical ? "go-down" : "go-next"
                            enabled: tabDelegate.index < tabsModel.count - 1
                            onClicked: root.moveTab(tabDelegate.index, 1)
                        }

                        PlasmaExtras.MenuItem {
                            text: i18n("Remove Tab")
                            icon: "list-remove"
                            enabled: tabsModel.count > 1
                            onClicked: root.removeTab(tabDelegate.index)
                        }

                        PlasmaExtras.MenuItem {
                            separator: true
                        }

                        PlasmaExtras.MenuItem {
                            text: i18n("Add Launcher…")
                            icon: "list-add"
                            onClicked: {
                                root.switchTab(tabDelegate.index);
                                launcherBridge.addLauncher();
                            }
                        }

                        PlasmaExtras.MenuItem {
                            action: Plasmoid.internalAction("configure")
                        }

                        PlasmaExtras.MenuItem {
                            action: Plasmoid.internalAction("remove")
                        }
                    }
                }
            }
        }
    }

    Binding {
        target: grid
        property: "contentX"
        when: root.overflowMode !== 2
        value: root.horizontalLayout && root.overflowMode === 0 ? root.pageIndex * root.pagePixelExtent : 0
    }

    Binding {
        target: grid
        property: "contentY"
        when: root.overflowMode !== 2
        value: !root.horizontalLayout && root.overflowMode === 0 ? root.pageIndex * root.pagePixelExtent : 0
    }

    PlasmaCore.Dialog {
        id: overflowDialog
        visualParent: overflowButton
        location: Plasmoid.location
        type: PlasmaCore.Dialog.PopupMenu
        hideOnWindowDeactivate: true
        backgroundHints: PlasmaCore.Dialog.StandardBackground
        visible: false

        mainItem: Item {
            readonly property int popupColumns: Math.max(1, Math.min(6, overflowModel.count))
            readonly property int popupRows: Math.max(1, Math.min(6, Math.ceil(overflowModel.count / popupColumns)))
            width: root.extentForSlots(popupColumns, root.horizontalSpacing)
            height: root.extentForSlots(popupRows, root.verticalSpacing)

            GridView {
                id: overflowGrid
                anchors.fill: parent
                clip: true
                interactive: contentHeight > height
                cellWidth: root.cellWidth
                cellHeight: root.cellHeight
                model: overflowModel

                delegate: Item {
                    required property int index
                    required property string launcherUrl
                    required property int sourceIndex
                    width: root.requestedIconSize
                    height: root.requestedIconSize

                    readonly property var info: launcherBridge.launcherData(launcherUrl)
                    readonly property string displayName: info.applicationName || launcherUrl
                    readonly property string iconName: info.iconName || "system-run"

                    MouseArea {
                        id: popupMouse
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        hoverEnabled: true
                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton) {
                                launcherBridge.openUrl(launcherUrl);
                                overflowDialog.visible = false;
                            } else if (mouse.button === Qt.RightButton) {
                                popupItemMenu.open(mouse.x, mouse.y);
                            }
                        }

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: root.requestedIconSize
                            height: width
                            source: iconName
                            active: popupMouse.containsMouse
                        }

                        PlasmaCore.ToolTipArea {
                            anchors.fill: parent
                            mainText: displayName
                            subText: info.genericName || ""
                            icon: iconName
                        }

                        PlasmaExtras.Menu {
                            id: popupItemMenu
                            visualParent: popupMouse

                            PlasmaExtras.MenuItem {
                                text: i18n("Remove Launcher")
                                icon: "list-remove"
                                onClicked: root.removeLauncher(sourceIndex)
                            }

                            PlasmaExtras.MenuItem {
                                text: i18n("Move to Tab…")
                                icon: "go-jump"
                                visible: root.tabsEnabled && tabsModel.count > 1
                                onClicked: {
                                    overflowDialog.visible = false;
                                    root.beginLauncherTransfer(sourceIndex, false);
                                }
                            }

                            PlasmaExtras.MenuItem {
                                text: i18n("Copy to Tab…")
                                icon: "edit-copy"
                                visible: root.tabsEnabled && tabsModel.count > 1
                                onClicked: {
                                    overflowDialog.visible = false;
                                    root.beginLauncherTransfer(sourceIndex, true);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    PlasmaCore.Dialog {
        id: transferDialog
        visualParent: root
        location: Plasmoid.location
        type: PlasmaCore.Dialog.PopupMenu
        hideOnWindowDeactivate: true
        backgroundHints: PlasmaCore.Dialog.StandardBackground
        visible: false

        onVisibleChanged: {
            if (!visible) {
                root.transferLauncherIndex = -1;
            }
        }

        mainItem: ColumnLayout {
            width: Math.max(220, transferTitle.implicitWidth + 32)
            spacing: 4

            QQC2.Label {
                id: transferTitle
                Layout.fillWidth: true
                Layout.margins: 8
                text: root.transferCopyMode ? i18n("Copy launcher to tab") : i18n("Move launcher to tab")
                font.bold: true
            }

            Repeater {
                model: tabsModel

                QQC2.ItemDelegate {
                    required property int index
                    required property string name

                    Layout.fillWidth: true
                    visible: index !== root.activeTab
                    enabled: visible
                    text: name
                    icon.name: index === root.activeTab ? "emblem-default" : "tab-new"
                    onClicked: root.transferLauncherToTab(index)
                }
            }

            QQC2.Button {
                Layout.alignment: Qt.AlignRight
                Layout.rightMargin: 8
                Layout.bottomMargin: 8
                text: i18n("Cancel")
                onClicked: transferDialog.visible = false
            }
        }
    }

    PlasmaCore.Dialog {
        id: renameDialog
        visualParent: root
        location: Plasmoid.location
        type: PlasmaCore.Dialog.PopupMenu
        hideOnWindowDeactivate: true
        backgroundHints: PlasmaCore.Dialog.StandardBackground
        visible: false

        onVisibleChanged: {
            if (!visible) {
                root.renameTabIndex = -1;
            }
        }

        mainItem: Item {
            width: 280
            height: renameLayout.implicitHeight + 20

            ColumnLayout {
                id: renameLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                spacing: 8

                QQC2.Label {
                    Layout.fillWidth: true
                    text: i18n("Rename tab")
                    font.bold: true
                }

                QQC2.TextField {
                    id: renameField
                    Layout.fillWidth: true
                    placeholderText: i18n("Tab name")
                    onAccepted: root.commitRenameTab()
                    Keys.onEscapePressed: renameDialog.visible = false
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight

                    QQC2.Button {
                        text: i18n("Cancel")
                        onClicked: renameDialog.visible = false
                    }

                    QQC2.Button {
                        text: i18n("Rename")
                        enabled: renameField.text.trim().length > 0
                        onClicked: root.commitRenameTab()
                    }
                }
            }
        }
    }

    DragAndDrop.DropArea {
        id: dropArea
        x: root.contentInset + root.launcherX
        y: root.contentInset + root.launcherY
        width: root.launcherWidth
        height: root.launcherHeight
        preventStealing: true
        enabled: !Plasmoid.immutable

        onDragEnter: event => {
            if (!event.mimeData.hasUrls) {
                event.ignore();
                return;
            }

            root.dragging = true;
            root.internalDragIndex = -1;
            root.internalDragOriginalIndex = -1;

            const sourceItem = event.mimeData.source;
            if (sourceItem && sourceItem.appCouplingLauncher === true && sourceItem.appCouplingRoot === root) {
                root.internalDragIndex = sourceItem.index;
                root.internalDragOriginalIndex = sourceItem.index;
            }
        }

        onDragMove: event => {
            if (root.internalDragIndex < 0 || launcherModel.count < 2) {
                return;
            }

            const target = root.calculatedIndex(event.x, event.y, false);
            if (target !== root.internalDragIndex) {
                launcherModel.move(root.internalDragIndex, target, 1);
                root.internalDragIndex = target;
            }
        }

        onDragLeave: {
            root.dragging = false;
            if (root.internalDragIndex >= 0 &&
                root.internalDragOriginalIndex >= 0 &&
                root.internalDragIndex !== root.internalDragOriginalIndex) {
                launcherModel.move(root.internalDragIndex, root.internalDragOriginalIndex, 1);
            }
            root.internalDragIndex = -1;
            root.internalDragOriginalIndex = -1;
            Qt.callLater(root.rebuildOverflowModel);
        }

        onDrop: event => {
            root.dragging = false;

            if (root.internalDragIndex >= 0) {
                root.internalDragIndex = -1;
                root.internalDragOriginalIndex = -1;
                root.saveLaunchers();
                event.accept(Qt.IgnoreAction);
                return;
            }

            const insertionIndex = root.calculatedIndex(event.x, event.y, true);
            launcherModel.insertUrls(insertionIndex, event.mimeData.urls);
            root.saveLaunchers();
            event.accept(event.proposedAction);
        }
    }

    LauncherBridge {
        id: launcherBridge

        onLauncherAdded: url => {
            launcherModel.insertUrls(launcherModel.count, [url]);
            root.saveLaunchers();
        }
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Add Launcher…")
            icon.name: "list-add"
            onTriggered: launcherBridge.addLauncher()
        },
        PlasmaCore.Action {
            text: i18n("Add Tab")
            icon.name: "tab-new"
            visible: root.tabsEnabled
            onTriggered: root.addTab()
        }
    ]

    Connections {
        target: Plasmoid.configuration

        function onLauncherUrlsChanged() {
            if (!root.tabsEnabled && !root.dragging && !root.configuredLaunchersMatchModel()) {
                launcherModel.load(Plasmoid.configuration.launcherUrls);
            }
        }

        function onOverflowModeChanged() {
            root.resetOverflowPosition();
            Qt.callLater(root.rebuildOverflowModel);
        }

        function onEnableTabsChanged() {
            if (root.tabsEnabled) {
                root.loadTabs();
                root.loadActiveTabLaunchers();
            } else {
                if (tabsModel.count > 0) {
                    root.storeCurrentTabLaunchers();
                    Plasmoid.configuration.launcherUrls = launcherModel.urls();
                }
                launcherModel.load(Plasmoid.configuration.launcherUrls);
                root.resetOverflowPosition();
            }
        }
    }

    onPageCapacityChanged: {
        clampPage();
        Qt.callLater(rebuildOverflowModel);
    }

    onPageCountChanged: clampPage()

    Component.onCompleted: {
        if (tabsEnabled) {
            loadTabs();
            loadActiveTabLaunchers();
        } else {
            // Do not seed tabsJson until tabs are actually enabled. This keeps
            // the first tab migration based on the latest single-list launchers.
            launcherModel.load(Plasmoid.configuration.launcherUrls);
        }
    }
}
