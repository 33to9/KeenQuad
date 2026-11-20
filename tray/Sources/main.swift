import AppKit

// F9.2：已有相同 Bundle ID 的实例在运行时直接退出。
let bundleID = Bundle.main.bundleIdentifier ?? "com.keenquad.app"
let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
    .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
if !others.isEmpty { exit(0) }

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)   // F1.1：无 Dock 图标、无主菜单
app.run()
