// SPDX-License-Identifier: GPL-3.0-only
// Copyright © 2026 33to9
#if KEENQUAD_TEST
// Compiled only into the test build (KEENQUAD_TEST=1 ./build.sh), never into the product.
// Drives the real NSMenu items and panel keys through a distributed notification and writes results to $TMPDIR/keenquad-test.txt.
import AppKit
import ServiceManagement

final class TestHook: NSObject {
    static let shared = TestHook()
    weak var delegate: AppDelegate?
    private let out = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("keenquad-test.txt")

    func install(_ d: AppDelegate) {
        delegate = d
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(handle(_:)),
                                                            name: .init("com.keenquad.test"), object: nil,
                                                            suspensionBehavior: .deliverImmediately)
        write("ready")
    }

    private func write(_ s: String) {
        let line = "[\(Date().timeIntervalSince1970)] " + s + "\n"
        if let h = try? FileHandle(forWritingTo: out) { h.seekToEndOfFile(); h.write(line.data(using: .utf8)!); try? h.close() }
        else { try? line.write(to: out, atomically: true, encoding: .utf8) }
    }

    private func titleOf(_ i: NSMenuItem) -> String { i.attributedTitle?.string ?? i.title }

    private func dump(_ m: NSMenu, indent: String = "") -> [String] {
        m.items.flatMap { i -> [String] in
            if i.isSeparatorItem { return [indent + "────"] }
            var l = indent + (i.state == .on ? "✓ " : "  ") + titleOf(i)
            if !i.isEnabled { l += "  [disabled]" }
            if !i.keyEquivalent.isEmpty { l += "  [⌘\(i.keyEquivalent)]" }
            if i.attributedTitle != nil { l += "  [attributed]" }
            if let tip = i.toolTip { l += "  [tip: \(tip)]" }
            var r = [l]
            if let s = i.submenu { r[0] += " ▸"; r += dump(s, indent: indent + "      ") }
            return r
        }
    }

    private func find(_ title: String, in m: NSMenu) -> (NSMenu, Int)? {
        for (idx, i) in m.items.enumerated() {
            if titleOf(i) == title || titleOf(i).hasPrefix(title + "\u{3000}") { return (m, idx) }
            if let s = i.submenu, let r = find(title, in: s) { return r }
        }
        return nil
    }

    private func snap(_ v: NSView, _ name: String) {
        for (suffix, appearance) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
            v.appearance = NSAppearance(named: appearance)
            guard let rep = v.bitmapImageRepForCachingDisplay(in: v.bounds) else { continue }
            v.cacheDisplay(in: v.bounds, to: rep)
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("kq-\(name)-\(suffix).png")
            try? rep.representation(using: .png, properties: [:])?.write(to: url)
            write("snap \(url.path) \(rep.pixelsWide)x\(rep.pixelsHigh)")
        }
        v.appearance = nil
    }

    private var panel: NSPanel? { NSApp.windows.compactMap { $0 as? NSPanel }.first { $0.isVisible } }

    private func key(_ chars: String, code: UInt16) {
        guard let p = panel else { write("key: no panel"); return }
        for type in [NSEvent.EventType.keyDown, .keyUp] {
            if let e = NSEvent.keyEvent(with: type, location: .zero, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
                                        windowNumber: p.windowNumber, context: nil, characters: chars,
                                        charactersIgnoringModifiers: chars, isARepeat: false, keyCode: code) {
                NSApp.sendEvent(e)
            }
        }
        write("key sent \(code)")
    }

    @objc private func handle(_ n: Notification) {
        guard let d = delegate, let cmd = n.object as? String else { return }
        switch cmd {
        case "menu":
            d.menu.delegate?.menuNeedsUpdate?(d.menu)
            write("menu:\n" + dump(d.menu).joined(separator: "\n"))
        case let c where c.hasPrefix("click:"):
            let t = String(c.dropFirst(6))
            d.menu.delegate?.menuNeedsUpdate?(d.menu)
            if let (m, idx) = find(t, in: d.menu) {
                write("click \(t) enabled=\(m.items[idx].isEnabled)")
                if m.items[idx].isEnabled { m.performActionForItem(at: idx) }
            } else { write("click \(t): not found") }
        case "return": key("\r", code: 36)
        case "esc": key("\u{1b}", code: 53)
        case "state":
            if let p = panel {
                let body = (p.contentView?.subviews.compactMap { ($0 as? NSTextField)?.stringValue } ?? []).joined(separator: " | ")
                let b = CGDisplayBounds(CGMainDisplayID())
                write("panel visible key=\(p.isKeyWindow) appActive=\(NSApp.isActive) level=\(p.level.rawValue) frame=\(NSStringFromRect(p.frame)) display=\(b) text=\(body)")
            } else { write("panel none appActive=\(NSApp.isActive)") }
        case "icon":
            guard let b = d.statusItem.button, let img = b.image else { write("icon: none"); return }
            let reps = img.representations.map { "\($0.pixelsWide)x\($0.pixelsHigh)" }.joined(separator: ",")
            let f = b.window?.frame ?? .zero
            write("icon size=\(img.size) template=\(img.isTemplate) reps=\(reps) visible=\(d.statusItem.isVisible) windowFrame=\(NSStringFromRect(f)) screenTop=\(NSScreen.main?.frame.maxY ?? 0)")
            snap(b, "icon")
        case "snap": if let p = panel, let v = p.contentView { snap(v, "panel") } else { write("snap: no panel") }
        case "remove":   // simulate the display being removed through the real C callback
            reconfigurationCallback(CGMainDisplayID(), .removeFlag, Unmanaged.passUnretained(d).toOpaque())
            write("remove callback sent")
        case "setmode":  // our own switches trigger the callback too and must be ignored
            reconfigurationCallback(CGMainDisplayID(), .setModeFlag, Unmanaged.passUnretained(d).toOpaque())
            write("setmode callback sent")
        case "loginstatus":
            write("login status raw=\(SMAppService.mainApp.status.rawValue) (0 notRegistered,1 enabled,2 requiresApproval,3 notFound)")
        case "loginregister":
            do { try SMAppService.mainApp.register(); write("register ok status=\(SMAppService.mainApp.status.rawValue)") }
            catch { write("register error: \(error) status=\(SMAppService.mainApp.status.rawValue)") }
        case let c where c.hasPrefix("update"):
            // update[:<pretend installed version>[:<repo>]]: real network request; dumps the menu while checking, then writes the alert text and a snapshot without showing it modally
            let parts = c.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
            let current = parts.count > 1 && !parts[1].isEmpty ? parts[1] : UpdateChecker.bundleVersion
            let repo = parts.count > 2 ? parts[2] : UpdateChecker.bundleRepository
            d.updateChecker.check(repository: repo, current: current) { [weak self] outcome in
                guard let self else { return }
                let alert = d.makeUpdateAlert(outcome, current: current)
                alert.layout()
                self.write("update outcome=\(outcome) title=\(alert.messageText) | body=\(alert.informativeText) | buttons=\(alert.buttons.map(\.title))")
                if let v = alert.window.contentView { self.snap(v, "update") }
            }
            d.menu.delegate?.menuNeedsUpdate?(d.menu)
            write("during check:\n" + dump(d.menu).suffix(3).joined(separator: "\n"))
        default: write("unknown \(cmd)")
        }
    }
}
#endif
