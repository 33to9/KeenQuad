// SPDX-License-Identifier: GPL-3.0-only
// Copyright © 2026 33to9
import AppKit

// Exit if another instance with the same bundle ID is already running.
let bundleID = Bundle.main.bundleIdentifier ?? "com.keenquad.app"
let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
    .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
if !others.isEmpty { exit(0) }

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)   // no Dock icon, no main menu
app.run()
