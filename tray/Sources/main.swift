// SPDX-License-Identifier: GPL-3.0-only
// Copyright © 2026 Pivotfrag LLC
import AppKit

// Exit if another instance with the same bundle ID is already running.
// 0.4.0 shipped with the bundle ID com.keenquad.app; a copy of it still running counts as another instance.
let productID = "com.pivotfrag.keenquad"
let legacyID = "com.keenquad.app"
let bundleID = Bundle.main.bundleIdentifier ?? productID
let instanceIDs = bundleID == productID ? [productID, legacyID] : [bundleID]
let others = instanceIDs.flatMap { NSRunningApplication.runningApplications(withBundleIdentifier: $0) }
    .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
if !others.isEmpty { exit(0) }

// Copy the settings 0.4.0 stored under its old bundle ID, once. Existing values are never overwritten.
if bundleID == productID, !UserDefaults.standard.bool(forKey: "migratedLegacySettings") {
    if let old = UserDefaults.standard.persistentDomain(forName: legacyID) {
        for key in ["confirmedModes", "language"] where UserDefaults.standard.object(forKey: key) == nil {
            if let value = old[key] { UserDefaults.standard.set(value, forKey: key) }
        }
    }
    UserDefaults.standard.set(true, forKey: "migratedLegacySettings")
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)   // no Dock icon, no main menu
app.run()
