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

    // Keep the left side stable while letting the right-side pair drift a little
    // as the dialog grows. Wider dialogs also give helper text more room, which
    // reduces wrapping and vertical scrolling without recentring the form.
    readonly property int contentLeftMargin: 10
    readonly property int contentRightMargin: 18
    readonly property int contentTopMargin: 12
    readonly property int minimumFormWidth: 550
    readonly property int formWidth: Math.max(minimumFormWidth, page.availableWidth - contentLeftMargin - contentRightMargin)
    readonly property int rowHeight: 34
    readonly property int labelGap: 6
    readonly property int firstControlX: 126
    readonly property int secondLabelX: Math.max(292, Math.min(344, Math.round(formWidth * 0.52)))
    readonly property int secondControlX: secondLabelX + 112
    readonly property int compactControlWidth: 88
    readonly property int comboControlWidth: 135

    property alias cfg_sections: sections.value
    property alias cfg_iconSize: iconSize.value
    property alias cfg_horizontalSpacing: horizontalSpacing.value
    property alias cfg_verticalSpacing: verticalSpacing.value
    property alias cfg_launcherAlignment: launcherAlignment.currentIndex
    property alias cfg_crossAlignment: crossAlignment.currentIndex
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
    property alias cfg_desktopAppearance: desktopAppearance.currentIndex
    property alias cfg_desktopRevealAnimation: desktopRevealAnimation.currentIndex
    property alias cfg_desktopRevealDuration: desktopRevealDuration.value

    implicitWidth: Kirigami.Units.gridUnit * 34
    implicitHeight: Kirigami.Units.gridUnit * 28
    clip: true
    contentWidth: Math.max(availableWidth, settingsContent.implicitWidth)
    contentHeight: settingsContent.implicitHeight

    QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AsNeeded
    QQC2.ScrollBar.vertical.policy: QQC2.ScrollBar.AsNeeded

    Item {
        id: settingsContent
        implicitWidth: page.contentLeftMargin + page.formWidth + page.contentRightMargin
        implicitHeight: page.contentTopMargin + formColumn.height + 12
        width: page.contentWidth
        height: implicitHeight

        Column {
            id: formColumn
            x: page.contentLeftMargin
            y: page.contentTopMargin
            width: page.formWidth
            spacing: 3

            Item {
                width: parent.width
                height: 24

                QQC2.Label {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n("Layout")
                    font.bold: true
                    opacity: 0.86
                }

                Kirigami.Separator {
                    anchors.left: parent.left
                    anchors.leftMargin: 54
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: 0.65
                }
            }

            Item {
                width: parent.width
                height: page.rowHeight

                QQC2.Label {
                    x: page.firstControlX - implicitWidth - page.labelGap
                    anchors.verticalCenter: parent.verticalCenter
                    text: page.verticalPanel ? i18n("Columns:") : i18n("Rows:")
                }
                QQC2.SpinBox {
                    id: sections
                    x: page.firstControlX
                    width: page.compactControlWidth
                    anchors.verticalCenter: parent.verticalCenter
                    from: 1
                    to: 99
                    editable: true
                    textFromValue: function(value) { return value.toString(); }
                }

                QQC2.Label {
                    x: page.secondControlX - implicitWidth - page.labelGap
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n("Icon size:")
                }
                QQC2.SpinBox {
                    id: iconSize
                    x: page.secondControlX
                    width: page.compactControlWidth
                    anchors.verticalCenter: parent.verticalCenter
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
            }

            Item {
                width: parent.width
                height: page.rowHeight

                QQC2.Label {
                    x: page.firstControlX - implicitWidth - page.labelGap
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n("Horizontal spacing:")
                }
                QQC2.SpinBox {
                    id: horizontalSpacing
                    x: page.firstControlX
                    width: page.compactControlWidth
                    anchors.verticalCenter: parent.verticalCenter
                    from: 0
                    to: 64
                    editable: true
                    textFromValue: function(value) { return value + " px"; }
                    valueFromText: function(text) {
                        const n = parseInt(text);
                        return isNaN(n) ? value : n;
                    }
                }

                QQC2.Label {
                    x: page.secondControlX - implicitWidth - page.labelGap
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n("Vertical spacing:")
                }
                QQC2.SpinBox {
                    id: verticalSpacing
                    x: page.secondControlX
                    width: page.compactControlWidth
                    anchors.verticalCenter: parent.verticalCenter
                    from: 0
                    to: 64
                    editable: true
                    textFromValue: function(value) { return value + " px"; }
                    valueFromText: function(text) {
                        const n = parseInt(text);
                        return isNaN(n) ? value : n;
                    }
                }
            }

            Item {
                width: parent.width
                height: page.rowHeight

                QQC2.Label {
                    x: page.firstControlX - implicitWidth - page.labelGap
                    anchors.verticalCenter: parent.verticalCenter
                    text: page.verticalPanel ? i18n("Vertical alignment:") : i18n("Horizontal alignment:")
                    enabled: launcherAlignment.enabled
                }
                QQC2.ComboBox {
                    id: launcherAlignment
                    x: page.firstControlX
                    width: page.comboControlWidth
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: !page.inPanel || lengthMode.currentIndex !== 0
                    model: page.verticalPanel
                        ? [i18n("Top"), i18n("Center"), i18n("Bottom")]
                        : [i18n("Left"), i18n("Center"), i18n("Right")]
                }

                QQC2.Label {
                    x: page.secondControlX - implicitWidth - page.labelGap
                    anchors.verticalCenter: parent.verticalCenter
                    text: page.verticalPanel ? i18n("Horizontal alignment:") : i18n("Vertical alignment:")
                }
                QQC2.ComboBox {
                    id: crossAlignment
                    x: page.secondControlX
                    width: page.comboControlWidth
                    anchors.verticalCenter: parent.verticalCenter
                    model: page.verticalPanel
                        ? [i18n("Left"), i18n("Center"), i18n("Right")]
                        : [i18n("Top"), i18n("Center"), i18n("Bottom")]
                }
            }

            Item {
                width: parent.width
                height: 24

                QQC2.Label {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n("Tabs")
                    font.bold: true
                    opacity: 0.86
                }

                Kirigami.Separator {
                    anchors.left: parent.left
                    anchors.leftMargin: 42
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: 0.65
                }
            }

            Item {
                width: parent.width
                height: page.rowHeight

                QQC2.Label {
                    x: page.firstControlX - implicitWidth - page.labelGap
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n("Tabs:")
                }
                QQC2.CheckBox {
                    id: enableTabs
                    x: page.firstControlX
                    width: 150
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n("Enable launcher tabs")
                }

                QQC2.Label {
                    x: page.secondControlX - implicitWidth - page.labelGap
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n("Position:")
                    enabled: page.inPanel ? panelTabPosition.enabled : desktopTabPosition.enabled
                }
                QQC2.ComboBox {
                    id: panelTabPosition
                    x: page.secondControlX
                    width: page.comboControlWidth
                    anchors.verticalCenter: parent.verticalCenter
                    visible: page.inPanel
                    enabled: enableTabs.checked
                    model: [
                        i18n("Automatic"),
                        i18n("Opposite side")
                    ]
                }
                QQC2.ComboBox {
                    id: desktopTabPosition
                    x: page.secondControlX
                    width: page.comboControlWidth
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !page.inPanel
                    enabled: enableTabs.checked
                    model: [
                        i18n("Top"),
                        i18n("Bottom"),
                        i18n("Left"),
                        i18n("Right")
                    ]
                }
            }

            Item {
                width: parent.width
                height: visible ? Math.max(18, tabsInfo.implicitHeight + 2) : 0
                visible: enableTabs.checked

                QQC2.Label {
                    id: tabsInfo
                    x: page.firstControlX
                    width: parent.width - x
                    text: i18n("Needs ~%1 px; hides if space is tight.", page.configTabStripThickness + 2)
                    wrapMode: Text.WordWrap
                    opacity: 0.72
                }
            }

            Item {
                width: parent.width
                height: 24

                QQC2.Label {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n("Sizing & overflow")
                    font.bold: true
                    opacity: 0.86
                }

                Kirigami.Separator {
                    anchors.left: parent.left
                    anchors.leftMargin: 126
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: 0.65
                }
            }

            Item {
                width: parent.width
                height: page.rowHeight

                QQC2.Label {
                    x: page.firstControlX - implicitWidth - page.labelGap
                    anchors.verticalCenter: parent.verticalCenter
                    text: page.verticalPanel ? i18n("Widget height:") : i18n("Widget width:")
                }
                QQC2.ComboBox {
                    id: lengthMode
                    x: page.firstControlX
                    width: 150
                    anchors.verticalCenter: parent.verticalCenter
                    model: [
                        i18n("Automatic"),
                        i18n("Fixed"),
                        i18n("Fill remaining space")
                    ]
                }

                QQC2.Label {
                    x: page.secondControlX - implicitWidth - page.labelGap
                    anchors.verticalCenter: parent.verticalCenter
                    visible: lengthMode.currentIndex === 0
                    text: i18n("Max length:")
                }
                QQC2.SpinBox {
                    id: automaticMaxLength
                    x: page.secondControlX
                    width: page.compactControlWidth
                    anchors.verticalCenter: parent.verticalCenter
                    visible: lengthMode.currentIndex === 0
                    from: page.minimumUsableLength
                    to: 4096
                    stepSize: 8
                    editable: true
                    textFromValue: function(value) { return value + " px"; }
                    valueFromText: function(text) {
                        const n = parseInt(text);
                        return isNaN(n) ? value : n;
                    }
                }

                QQC2.Label {
                    x: page.secondControlX - implicitWidth - page.labelGap
                    anchors.verticalCenter: parent.verticalCenter
                    visible: lengthMode.currentIndex === 1
                    text: i18n("Length:")
                }
                QQC2.SpinBox {
                    id: fixedLength
                    x: page.secondControlX
                    width: page.compactControlWidth
                    anchors.verticalCenter: parent.verticalCenter
                    visible: lengthMode.currentIndex === 1
                    from: page.minimumUsableLength
                    to: 4096
                    stepSize: 8
                    editable: true
                    textFromValue: function(value) { return value + " px"; }
                    valueFromText: function(text) {
                        const n = parseInt(text);
                        return isNaN(n) ? value : n;
                    }
                }
            }

            Item {
                width: parent.width
                height: page.rowHeight

                QQC2.Label {
                    x: page.firstControlX - implicitWidth - page.labelGap
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n("Overflow:")
                }
                QQC2.ComboBox {
                    id: overflowMode
                    x: page.firstControlX
                    width: page.comboControlWidth
                    anchors.verticalCenter: parent.verticalCenter
                    model: [
                        i18n("Paged arrows"),
                        i18n("Popup overflow"),
                        i18n("Scroll")
                    ]
                }

                QQC2.Label {
                    x: page.secondLabelX
                    width: parent.width - x
                    anchors.verticalCenter: parent.verticalCenter
                    text: lengthMode.currentIndex === 2
                        ? i18n("Uses available panel space.")
                        : i18n("Minimum: %1 px", page.minimumUsableLength)
                    wrapMode: Text.WordWrap
                    opacity: 0.72
                }
            }

            Item {
                width: parent.width
                height: 24

                QQC2.Label {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n("Style")
                    font.bold: true
                    opacity: 0.86
                }

                Kirigami.Separator {
                    anchors.left: parent.left
                    anchors.leftMargin: 42
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: 0.65
                }
            }

            Item {
                width: parent.width
                height: page.rowHeight

                QQC2.Label {
                    x: page.firstControlX - implicitWidth - page.labelGap
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n("Desktop:")
                    enabled: desktopAppearance.enabled
                }
                QQC2.ComboBox {
                    id: desktopAppearance
                    x: page.firstControlX
                    width: 160
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: !page.inPanel
                    model: [
                        i18n("Normal"),
                        i18n("Transparent"),
                        i18n("Reveal on hover")
                    ]
                }

                QQC2.Label {
                    x: page.secondControlX - implicitWidth - page.labelGap
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n("Outline:")
                }
                QQC2.CheckBox {
                    id: showBorder
                    x: page.secondControlX
                    width: 130
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n("Show border")
                }
            }

            Item {
                width: parent.width
                height: page.rowHeight

                QQC2.Label {
                    x: page.firstControlX - implicitWidth - page.labelGap
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n("Animation:")
                    enabled: desktopRevealAnimation.enabled
                }
                QQC2.ComboBox {
                    id: desktopRevealAnimation
                    x: page.firstControlX
                    width: page.comboControlWidth
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: !page.inPanel && desktopAppearance.currentIndex === 2
                    model: [
                        i18n("None"),
                        i18n("Fade")
                    ]
                }

                QQC2.Label {
                    x: page.secondControlX - implicitWidth - page.labelGap
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n("Transition:")
                    enabled: desktopRevealDuration.enabled
                }
                QQC2.SpinBox {
                    id: desktopRevealDuration
                    x: page.secondControlX
                    width: page.compactControlWidth
                    anchors.verticalCenter: parent.verticalCenter
                    from: 0
                    to: 500
                    stepSize: 10
                    editable: true
                    enabled: !page.inPanel && desktopAppearance.currentIndex === 2 && desktopRevealAnimation.currentIndex !== 0
                    textFromValue: function(value) { return value + " ms"; }
                    valueFromText: function(text) {
                        const n = parseInt(text);
                        return isNaN(n) ? value : n;
                    }
                }
            }

            Item {
                width: parent.width
                height: page.rowHeight

                QQC2.Label {
                    x: page.firstControlX - implicitWidth - page.labelGap
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n("Thickness:")
                    enabled: borderWidth.enabled
                }
                QQC2.SpinBox {
                    id: borderWidth
                    x: page.firstControlX
                    width: page.compactControlWidth
                    anchors.verticalCenter: parent.verticalCenter
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

                QQC2.Label {
                    x: page.secondControlX - implicitWidth - page.labelGap
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n("Opacity:")
                    enabled: borderOpacity.enabled
                }
                QQC2.SpinBox {
                    id: borderOpacity
                    x: page.secondControlX
                    width: page.compactControlWidth
                    anchors.verticalCenter: parent.verticalCenter
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
            }

            Item {
                width: parent.width
                height: page.rowHeight

                QQC2.Label {
                    x: page.firstControlX - implicitWidth - page.labelGap
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n("Corner radius:")
                    enabled: borderRadius.enabled
                }
                QQC2.SpinBox {
                    id: borderRadius
                    x: page.firstControlX
                    width: page.compactControlWidth
                    anchors.verticalCenter: parent.verticalCenter
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
                    id: iconInfo
                    x: page.secondLabelX
                    width: parent.width - x
                    anchors.verticalCenter: parent.verticalCenter
                    text: i18n("Icons keep size; overflow handles extras.")
                    wrapMode: Text.WordWrap
                    opacity: 0.72
                }
            }
        }
    }
}
