// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls as Controls

Controls.SpinBox {
    id: number
    property string unit: ""

    editable: true
    live: false
    textFromValue: (value, locale) => value.toString() + number.unit
    valueFromText: (text, locale) => {
        const digits = number.unit && text.endsWith(number.unit)
            ? text.slice(0, -number.unit.length) : text;
        if (!/^\d+$/.test(digits.trim())) {
            return number.value;
        }
        return Math.max(number.from, Math.min(number.to, Number(digits)));
    }

    validator: RegularExpressionValidator {
        regularExpression: new RegExp("[0-9]*(?:" + number.unit + ")?")
    }

    contentItem: TextInput {
        id: input
        text: number.displayText
        font: number.font
        color: number.palette.text
        selectionColor: number.palette.highlight
        selectedTextColor: number.palette.highlightedText
        verticalAlignment: TextInput.AlignVCenter
        selectByMouse: true
        readOnly: !number.editable
        inputMethodHints: Qt.ImhDigitsOnly
        validator: number.validator
        clip: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                event.accepted = true;
                number.value = number.valueFromText(input.text, number.locale);
                input.text = Qt.binding(() => number.displayText);
            }
        }
    }
}
