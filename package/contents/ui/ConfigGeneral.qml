// SPDX-FileCopyrightText: 2026 suppdiff
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

QQC2.ScrollView {
    id: page

    readonly property bool verticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool horizontalPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
    readonly property bool inPanel: verticalPanel || horizontalPanel
    readonly property int configNavigationExtent: Math.max(20, Math.min(30, iconSize.value))
    readonly property int configControlExtent: overflowMode.currentIndex === 0
        ? configNavigationExtent * 2
        : (overflowMode.currentIndex === 1 ? configNavigationExtent : 0)
    readonly property int configBorderInset: showBorder.checked ? borderWidth.value : 0
    readonly property int minimumUsableLength: iconSize.value + configControlExtent + configBorderInset * 2
    readonly property int configTabItemThickness: Math.max(24, Math.min(36, iconSize.value))
    readonly property int configVerticalTabStripWidth: Math.max(72, Math.min(144, iconSize.value * 3))
    readonly property bool configTabStripVertical: inPanel ? verticalPanel : desktopTabPosition.currentIndex >= 2
    readonly property int configTabStripThickness: configTabStripVertical ? configVerticalTabStripWidth : configTabItemThickness

    property alias cfg_sections: sections.value
    property alias cfg_iconSize: iconSize.value
    property alias cfg_horizontalSpacing: horizontalSpacing.value
    property alias cfg_verticalSpacing: verticalSpacing.value
    property alias cfg_lengthMode: lengthMode.currentIndex
    property alias cfg_fixedLength: fixedLength.value
    property alias cfg_automaticMaxLength: automaticMaxLength.value
    property alias cfg_overflowMode: overflowMode.currentIndex
    property alias cfg_showBorder: showBorder.checked
    property alias cfg_borderWidth: borderWidth.value
    property alias cfg_borderOpacity: borderOpacity.value
    property alias cfg_borderRadius: borderRadius.value
    property alias cfg_enableTabs: enableTabs.checked
    property alias cfg_panelTabPosition: panelTabPosition.currentIndex
    property alias cfg_desktopTabPosition: desktopTabPosition.currentIndex

    implicitWidth: Kirigami.Units.gridUnit * 34
    implicitHeight: Kirigami.Units.gridUnit * 28
    clip: true
    contentWidth: availableWidth

    QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
    QQC2.ScrollBar.vertical.policy: QQC2.ScrollBar.AsNeeded

    Kirigami.FormLayout {
        id: form
        width: page.availableWidth
        height: implicitHeight

        QQC2.SpinBox {
            id: sections
            Kirigami.FormData.label: page.verticalPanel ? i18n("Columns:") : i18n("Rows:")
            from: 1
            to: 99
            editable: true
            textFromValue: function(value) { return value.toString(); }
        }

        QQC2.SpinBox {
            id: iconSize
            Kirigami.FormData.label: i18n("Icon size:")
            from: 12
            to: 128
            stepSize: 2
            editable: true
            textFromValue: function(value) { return value + " px"; }
            valueFromText: function(text) {
                const n = parseInt(text);
                return isNaN(n) ? value : n;
            }
        }

        QQC2.SpinBox {
            id: horizontalSpacing
            Kirigami.FormData.label: i18n("Horizontal spacing:")
            from: 0
            to: 64
            editable: true
            textFromValue: function(value) { return value + " px"; }
            valueFromText: function(text) {
                const n = parseInt(text);
                return isNaN(n) ? value : n;
            }
        }

        QQC2.SpinBox {
            id: verticalSpacing
            Kirigami.FormData.label: i18n("Vertical spacing:")
            from: 0
            to: 64
            editable: true
            textFromValue: function(value) { return value + " px"; }
            valueFromText: function(text) {
                const n = parseInt(text);
                return isNaN(n) ? value : n;
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: enableTabs
            Kirigami.FormData.label: i18n("Tabs:")
            text: i18n("Enable launcher tabs")
        }

        QQC2.ComboBox {
            id: panelTabPosition
            visible: page.inPanel
            enabled: enableTabs.checked
            Kirigami.FormData.label: i18n("Tab position:")
            model: [
                i18n("Automatic"),
                i18n("Opposite side")
            ]
        }

        QQC2.ComboBox {
            id: desktopTabPosition
            visible: !page.inPanel
            enabled: enableTabs.checked
            Kirigami.FormData.label: i18n("Tab position:")
            model: [
                i18n("Top"),
                i18n("Bottom"),
                i18n("Left"),
                i18n("Right")
            ]
        }

        QQC2.Label {
            visible: enableTabs.checked
            Kirigami.FormData.isSection: true
            text: i18n("Tabs use about %1 px of extra space across the widget. The tab strip is hidden automatically when the panel or desktop widget is too small to fit it plus at least one launcher icon.", page.configTabStripThickness + 2)
            wrapMode: Text.WordWrap
            opacity: 0.75
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
        }

        QQC2.ComboBox {
            id: lengthMode
            Kirigami.FormData.label: page.verticalPanel ? i18n("Widget height:") : i18n("Widget width:")
            model: [
                i18n("Automatic"),
                i18n("Fixed"),
                i18n("Fill remaining panel space")
            ]
        }

        QQC2.SpinBox {
            id: automaticMaxLength
            Kirigami.FormData.label: i18n("Automatic max length:")
            from: page.minimumUsableLength
            to: 4096
            stepSize: 8
            editable: true
            enabled: lengthMode.currentIndex === 0
            textFromValue: function(value) { return value + " px"; }
            valueFromText: function(text) {
                const n = parseInt(text);
                return isNaN(n) ? value : n;
            }
        }

        QQC2.SpinBox {
            id: fixedLength
            Kirigami.FormData.label: i18n("Fixed length:")
            from: page.minimumUsableLength
            to: 4096
            stepSize: 8
            editable: true
            enabled: lengthMode.currentIndex === 1
            textFromValue: function(value) { return value + " px"; }
            valueFromText: function(text) {
                const n = parseInt(text);
                return isNaN(n) ? value : n;
            }
        }

        QQC2.Label {
            visible: lengthMode.currentIndex !== 2
            Kirigami.FormData.isSection: true
            text: i18n("Minimum usable length for the current icon and overflow settings: %1 px", page.minimumUsableLength)
            wrapMode: Text.WordWrap
        }

        QQC2.ComboBox {
            id: overflowMode
            Kirigami.FormData.label: i18n("Overflow:")
            model: [
                i18n("Paged arrows"),
                i18n("Popup overflow"),
                i18n("Scroll")
            ]
        }

        QQC2.Label {
            visible: lengthMode.currentIndex === 2
            Kirigami.FormData.isSection: true
            text: i18n("Fill mode asks Plasma for unused space along the panel. Other expanding widgets or spacers can affect the final size.")
            wrapMode: Text.WordWrap
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: showBorder
            Kirigami.FormData.label: i18n("Outline:")
            text: i18n("Show theme-colored border")
        }

        QQC2.SpinBox {
            id: borderWidth
            Kirigami.FormData.label: i18n("Border thickness:")
            from: 1
            to: 12
            editable: true
            enabled: showBorder.checked
            textFromValue: function(value) { return value + " px"; }
            valueFromText: function(text) {
                const n = parseInt(text);
                return isNaN(n) ? value : n;
            }
        }

        QQC2.SpinBox {
            id: borderOpacity
            Kirigami.FormData.label: i18n("Border opacity:")
            from: 5
            to: 100
            stepSize: 5
            editable: true
            enabled: showBorder.checked
            textFromValue: function(value) { return value + "%"; }
            valueFromText: function(text) {
                const n = parseInt(text);
                return isNaN(n) ? value : n;
            }
        }

        QQC2.SpinBox {
            id: borderRadius
            Kirigami.FormData.label: i18n("Corner radius:")
            from: 0
            to: 32
            editable: true
            enabled: showBorder.checked
            textFromValue: function(value) { return value + " px"; }
            valueFromText: function(text) {
                const n = parseInt(text);
                return isNaN(n) ? value : n;
            }
        }

        QQC2.Label {
            Kirigami.FormData.isSection: true
            text: i18n("Icons keep the configured size. If the widget cannot show every launcher, the selected overflow mode handles the rest instead of silently shrinking icons.")
            wrapMode: Text.WordWrap
        }
    }
}
