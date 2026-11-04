// SPDX-License-Identifier: GPL-3.0-or-later

function list(text) {
    try {
        const value = JSON.parse(text || "[]");
        return Array.isArray(value) ? value : [];
    } catch (_) {
        return [];
    }
}

function exceptions(text) {
    const result = Object.create(null);
    for (const key of list(text)) {
        if (typeof key === "string" && key.length) {
            result[key] = true;
        }
    }
    return result;
}

function encodeExceptions(values) {
    return JSON.stringify(Object.keys(values).sort());
}

function updateVisibility(current, edits, tabs) {
    const editedKeys = Object.keys(edits);
    if (!editedKeys.length) {
        return current;
    }
    const values = exceptions(current);
    const liveKeys = new Set();
    for (const tab of tabs) {
        if (tab && typeof tab.key === "string") {
            liveKeys.add(tab.key);
        }
    }
    for (const key of editedKeys) {
        if (liveKeys.has(key)) {
            if (edits[key]) {
                values[key] = true;
            } else {
                delete values[key];
            }
        }
    }
    return encodeExceptions(values);
}

function launcher(url, makeKey) {
    return { launcherKey: makeKey(), launcherUrl: String(url), customName: "", customIcon: "" };
}

function reconcile(urls, saved, makeKey, seen = new Set()) {
    // Match occurrences in order when a legacy URL list changes externally.
    const byUrl = new Map();
    for (const record of saved) {
        if (!record || typeof record.launcherUrl !== "string") {
            continue;
        }
        if (!byUrl.has(record.launcherUrl)) {
            byUrl.set(record.launcherUrl, []);
        }
        byUrl.get(record.launcherUrl).push(record);
    }
    const offsets = new Map();
    const result = [];
    for (const raw of urls) {
        if (raw === null || raw === undefined || String(raw) === "") {
            continue;
        }
        const url = String(raw);
        const offset = offsets.get(url) || 0;
        const bucket = byUrl.get(url);
        const savedRecord = bucket && bucket[offset];
        offsets.set(url, offset + 1);
        let record;
        if (savedRecord) {
            const key = savedRecord.launcherKey;
            record = {
                launcherKey: typeof key === "string" && key && !seen.has(key) ? key : makeKey(),
                launcherUrl: url,
                customName: typeof savedRecord.customName === "string" ? savedRecord.customName : "",
                customIcon: typeof savedRecord.customIcon === "string" ? savedRecord.customIcon : ""
            };
        } else {
            record = launcher(url, makeKey);
        }
        seen.add(record.launcherKey);
        result.push(record);
    }
    return result;
}

function copyLaunchers(records, makeKey) {
    return records.map(record => Object.assign({}, record, { launcherKey: makeKey() }));
}

function wheelStep(remainder, delta, unit, fresh) {
    // Respond on the first event, then charge the rest of that detent against it.
    const distance = fresh ? delta : remainder + delta;
    const steps = Math.max(0, Math.ceil(distance / unit));
    return { steps: steps, remainder: distance - steps * unit };
}
