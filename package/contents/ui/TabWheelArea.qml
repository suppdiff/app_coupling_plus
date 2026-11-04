// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import "LauncherState.js" as State

MouseArea {
    id: surface
    acceptedButtons: Qt.NoButton
    scrollGestureEnabled: true

    property real lastEvent: 0
    property int lastDirection: 0
    property int lastUnit: 0
    property real remainder: 0
    signal stepRequested(int offset)

    onWheel: event => {
        if (!(event.modifiers & Qt.ShiftModifier)) {
            surface.lastDirection = 0;
            event.accepted = false;
            return;
        }
        event.accepted = true;
        const pixel = event.pixelDelta;
        const isPixel = pixel.x !== 0 || pixel.y !== 0;
        const pair = isPixel ? pixel : event.angleDelta;
        const delta = Math.abs(pair.x) > Math.abs(pair.y) ? pair.x : pair.y;
        if (!delta) {
            return;
        }
        const unit = isPixel ? 56 : 120;
        const direction = delta > 0 ? -1 : 1;
        const now = Date.now();
        const fresh = direction !== surface.lastDirection || unit !== surface.lastUnit
            || now - surface.lastEvent > 220;
        const step = State.wheelStep(surface.remainder, Math.abs(delta), unit, fresh);
        surface.lastDirection = direction;
        surface.lastUnit = unit;
        surface.lastEvent = now;
        surface.remainder = step.remainder;
        if (step.steps) {
            surface.stepRequested(direction * step.steps);
        }
    }
}
