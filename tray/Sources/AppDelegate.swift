// SPDX-License-Identifier: GPL-3.0-only
// Copyright © 2026 33to9
import AppKit
import ServiceManagement
import os

/// 菜单项携带的选择信息。只保存签名，不保存模式号（6.6）。
private final class ModeChoice: NSObject {
    let display: CGDirectDisplayID
    let signature: String
    /// F12 清晰版修复项：同尺寸从 1 倍切到 HiDPI，不弹确认。
    let isSharpFix: Bool
    init(display: CGDirectDisplayID, signature: String, isSharpFix: Bool = false) {
        self.display = display
        self.signature = signature
        self.isSharpFix = isSharpFix
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private struct Pending {
        let display: CGDirectDisplayID
        let uuid: String
        let target: Mode
        let previous: Mode?
        let panel: ConfirmPanel
    }

    private(set) var statusItem: NSStatusItem!   // 内部可读：仅供测试构建
    let menu = NSMenu()   // 内部可见：仅供测试构建的 TestHook 读取
    private var pending: Pending?
    /// 以 forAppOnly 试用、但既没保留也没还原就结束等待的模式（例如 F6.8 显示器被移除）。显示器 UUID → 模式签名。
    /// 只在内存中，用来避免 F7.3 把一个从未确认过的试用档位误记为已确认。
    private var unkeptTrial: [String: String] = [:]
    private var signalSources: [DispatchSourceSignal] = []
    let updateChecker = UpdateChecker()   // 内部可见：仅供测试构建
    private let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.keenquad.app", category: "switch")

    // MARK: - 生命周期

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            if let image = Bundle.main.image(forResource: "MenuIconTemplate") {
                image.size = NSSize(width: 18, height: 18)
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "KQ"
            }
            button.toolTip = "KeenQuad"
        }
        menu.autoenablesItems = false
        menu.delegate = self
        statusItem.menu = menu

        // F10.2：只用于 F6.8
        CGDisplayRegisterReconfigurationCallback(reconfigurationCallback, Unmanaged.passUnretained(self).toOpaque())

        // F6.7：普通的 kill / Ctrl-C / 挂断也走正常退出流程，先还原再退出
        for sig in [SIGTERM, SIGINT, SIGHUP] {
            signal(sig, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: sig, queue: .main)
            source.setEventHandler { NSApp.terminate(nil) }
            source.resume()
            signalSources.append(source)
        }
        #if KEENQUAD_TEST
        TestHook.shared.install(self)
        #endif
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if let p = pending {
            pending = nil
            p.panel.dismissSilently()
            revert(p)
        }
        return .terminateNow
    }

    // MARK: - 菜单

    func menuNeedsUpdate(_ menu: NSMenu) { rebuildMenu() }   // F2.1

    private func rebuildMenu() {
        menu.removeAllItems()
        let displays = Displays.active()
        if displays.isEmpty {
            menu.addItem(disabledItem(L10n.noDisplays))
        }
        for (index, display) in displays.enumerated() {
            if index > 0 { menu.addItem(.separator()) }   // F4.7
            addSection(for: display, ordinal: index + 1)
        }

        menu.addItem(.separator())
        let login = NSMenuItem(title: L10n.launchAtLogin, action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        login.target = self
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off   // F8.1
        menu.addItem(login)
        menu.addItem(languageItem())   // F13.1

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.4.0"
        menu.addItem(disabledItem(L10n.version(version)))

        // F14.1 / F14.2：检查进行中显示“正在检查更新…”并置灰
        let checking = updateChecker.isChecking
        let update = NSMenuItem(title: checking ? L10n.checkingForUpdates : L10n.checkForUpdates,
                                action: #selector(checkForUpdates(_:)), keyEquivalent: "")
        update.target = self
        update.isEnabled = !checking
        menu.addItem(update)

        let quit = NSMenuItem(title: L10n.quit, action: #selector(quit(_:)), keyEquivalent: "q")
        quit.keyEquivalentModifierMask = .command
        quit.target = self
        menu.addItem(quit)
    }

    private func addSection(for display: CGDirectDisplayID, ordinal: Int) {
        let table = PrivateDisplay.modeTable(of: display)
        let currentNumber = PrivateDisplay.currentModeNumber(of: display)
        let candidates = CandidateRules.compute(table: table, currentNumber: currentNumber)
        let name = screenName(of: display) ?? L10n.displayFallbackName(ordinal)
        let bounds = CGDisplayBounds(display)
        menu.addItem(disabledItem(MenuText.header(name: name, current: candidates.current,
                                                  fallbackSize: (Int(bounds.width), Int(bounds.height)))))

        if candidates.main.isEmpty && candidates.others.isEmpty {
            menu.addItem(disabledItem(L10n.noHiDPIModes))   // F4.8
            return
        }
        if let sharp = candidates.sharpVersion, let cur = candidates.current {   // F12.2
            let item = NSMenuItem(title: L10n.sharpVersion(sharp.mode.width, sharp.mode.height),
                                  action: #selector(selectMode(_:)), keyEquivalent: "")
            item.target = self
            item.toolTip = L10n.sharpVersionTip(cur.width, cur.height)   // F12.3
            item.representedObject = ModeChoice(display: display, signature: sharp.mode.signature, isSharpFix: true)
            item.isEnabled = pending == nil   // F12.5
            menu.addItem(item)
        }
        for c in candidates.main { menu.addItem(modeItem(c, display: display)) }
        if !candidates.others.isEmpty {   // F4.6
            let sub = NSMenu()
            sub.autoenablesItems = false
            for c in candidates.others { sub.addItem(modeItem(c, display: display)) }
            let item = NSMenuItem(title: L10n.otherAspects, action: nil, keyEquivalent: "")
            item.submenu = sub
            menu.addItem(item)
        }
    }

    private func modeItem(_ c: Candidate, display: CGDirectDisplayID) -> NSMenuItem {
        let text = MenuText.itemTitle(c)
        let item = NSMenuItem(title: text.main, action: #selector(selectMode(_:)), keyEquivalent: "")
        if let tag = text.tag {   // F4.4：较弱的视觉
            let s = NSMutableAttributedString(string: text.main, attributes: [.font: NSFont.menuFont(ofSize: 0)])
            s.append(NSAttributedString(string: L10n.gap + tag, attributes: [
                .font: NSFont.menuFont(ofSize: NSFont.smallSystemFontSize),
                .foregroundColor: NSColor.secondaryLabelColor,
            ]))
            item.attributedTitle = s
        }
        item.target = self
        item.representedObject = ModeChoice(display: display, signature: c.mode.signature)
        item.state = c.isCurrent ? .on : .off   // F3.6
        item.isEnabled = pending == nil          // F6.6
        return item
    }

    /// F13.1：跟随系统、分隔线、各语言（用本语言文字），当前选择打勾（F13.2）。
    private func languageItem() -> NSMenuItem {
        let sub = NSMenu()
        sub.autoenablesItems = false
        let choice = LanguageSetting.choice
        let follow = NSMenuItem(title: L10n.followSystem, action: #selector(selectLanguage(_:)), keyEquivalent: "")
        follow.target = self
        follow.state = choice == nil ? .on : .off
        sub.addItem(follow)
        sub.addItem(.separator())
        for lang in AppLanguage.allCases {
            let item = NSMenuItem(title: lang.nativeName, action: #selector(selectLanguage(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = lang.rawValue
            item.state = choice == lang ? .on : .off
            sub.addItem(item)
        }
        let item = NSMenuItem(title: L10n.language, action: nil, keyEquivalent: "")
        item.submenu = sub
        return item
    }

    /// F13.3 / F13.4：立即保存，下次显示起生效；选“跟随系统”时删除键。
    @objc private func selectLanguage(_ sender: NSMenuItem) {
        LanguageSetting.choice = (sender.representedObject as? String).flatMap(AppLanguage.init(rawValue:))
        log.info("language \(LanguageSetting.choice?.rawValue ?? "system", privacy: .public) -> \(LanguageSetting.current.rawValue, privacy: .public)")
    }

    private func disabledItem(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func screenName(of display: CGDirectDisplayID) -> String? {
        NSScreen.screens.first {
            ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value == display
        }?.localizedName
    }

    // MARK: - 切换（F5 / F6 / F7）

    @objc private func selectMode(_ sender: NSMenuItem) {
        guard pending == nil, let choice = sender.representedObject as? ModeChoice else { return }
        let display = choice.display
        guard Displays.active().contains(display) else { return }

        // 重新枚举，只允许切到本次枚举得到的候选（F5.4）
        let table = PrivateDisplay.modeTable(of: display)
        let currentNumber = PrivateDisplay.currentModeNumber(of: display)
        let candidates = CandidateRules.compute(table: table, currentNumber: currentNumber)
        guard let target = CandidateRules.find(signature: choice.signature, in: candidates) else { return }
        // F12：修复项只在当前仍是它对应的 1 倍模式时有效
        if choice.isSharpFix && candidates.sharpVersion?.mode.signature != target.signature { return }
        guard target.number != currentNumber else { return }   // F5.1

        let previous = candidates.current
        let previousBounds = CGDisplayBounds(display)
        let previousSize = previous.map { ($0.width, $0.height) }
            ?? (Int(previousBounds.width), Int(previousBounds.height))
        let uuid = Displays.uuid(of: display)
        let confirmed = choice.isSharpFix || target.isNative
            || ConfirmedStore.contains(target.signature, uuid: uuid)   // F12.4 / F7.2 / F7.4

        // 已确认：直接持久生效；未确认：先以 forAppOnly 试用（6.3）
        let option: CGConfigureOption = confirmed ? .permanently : .forAppOnly
        let label = choice.isSharpFix ? "sharpen" : (confirmed ? "apply" : "trial")
        guard perform(target, on: display, uuid: uuid, from: previous, option: option, label: label) else {
            return
        }
        if choice.isSharpFix { ConfirmedStore.add(target.signature, uuid: uuid) }   // F12.4
        // F7.3：切走的模式刚刚在正常显示，记为已确认；但未保留的试用档位除外
        if let previous, unkeptTrial[uuid] != previous.signature {
            ConfirmedStore.add(previous.signature, uuid: uuid)
        }
        unkeptTrial[uuid] = nil
        guard !confirmed else { return }

        let panel = ConfirmPanel(display: display, previousSize: previousSize,
                                 renderSize: (target.width * 2, target.height * 2)) { [weak self] outcome in
            self?.finishConfirmation(outcome)
        }
        pending = Pending(display: display, uuid: uuid, target: target, previous: previous, panel: panel)
        panel.show()   // F6.1
    }

    private func finishConfirmation(_ outcome: ConfirmPanel.Outcome) {
        guard let p = pending else { return }
        pending = nil
        switch outcome {
        case .keep:   // F6.4
            if perform(p.target, on: p.display, uuid: p.uuid, from: p.previous, option: .permanently, label: "keep") {
                ConfirmedStore.add(p.target.signature, uuid: p.uuid)
            } else {
                revert(p)
            }
        case .revert:   // F6.5
            revert(p)
        }
        // 面板是为了拿键盘焦点才激活本应用的；结束后把焦点交还给之前的应用
        NSApp.hide(nil)
    }

    /// 以 `.permanently` 切回之前的模式；还原本身不再弹确认（F6.5）。
    private func revert(_ p: Pending) {
        guard Displays.active().contains(p.display) else {
            // 显示器此刻不在活动列表里（例如睡眠）：无法按模式号切换，直接恢复系统保存的永久配置。
            // 除了这次试用，本工具的所有切换都是 permanently 提交的，所以这只会撤销试用。
            CGRestorePermanentDisplayConfiguration()
            log.info("revert uuid=\(p.uuid, privacy: .public) display inactive, restorePermanent")
            return
        }
        let table = PrivateDisplay.modeTable(of: p.display)
        if let prev = p.previous,
           let mode = CandidateRules.locate(signature: prev.signature, preferredNumber: prev.number, in: table),
           perform(mode, on: p.display, uuid: p.uuid, from: p.target, option: .permanently, label: "revert", reportErrors: false) {
            return
        }
        // 兜底：恢复系统保存的永久配置（试用是以 forAppOnly 提交的，永久配置仍是之前的模式）
        CGRestorePermanentDisplayConfiguration()
        let now = PrivateDisplay.currentModeNumber(of: p.display)
        log.error("revert fallback uuid=\(p.uuid, privacy: .public) restorePermanent current=#\(now)")
    }

    /// 执行一次切换并读回校验（F5.2 / F5.3），记录日志（F11.2），失败时提示并保持切换前的状态（F11.1）。
    @discardableResult
    private func perform(_ target: Mode, on display: CGDirectDisplayID, uuid: String, from previous: Mode?,
                         option: CGConfigureOption, label: String, reportErrors: Bool = true) -> Bool {
        let fromSig = previous?.signature ?? "unknown"
        var err = PrivateDisplay.apply(target.number, on: display, option: option)
        if err == .success {
            let readback = PrivateDisplay.currentModeNumber(of: display)
            if readback != target.number {
                log.error("\(label, privacy: .public) readback mismatch uuid=\(uuid, privacy: .public) want=#\(target.number) got=#\(readback)")
                err = .failure
                // 尽量回到切换前的状态
                if let previous, readback != previous.number {
                    _ = PrivateDisplay.apply(previous.number, on: display, option: .permanently)
                }
            }
        }
        if err == .success {
            log.info("\(label, privacy: .public) uuid=\(uuid, privacy: .public) \(fromSig, privacy: .public) -> \(target.signature, privacy: .public) ok")
            return true
        }
        log.error("\(label, privacy: .public) uuid=\(uuid, privacy: .public) \(fromSig, privacy: .public) -> \(target.signature, privacy: .public) failed CGError=\(err.rawValue)")
        if reportErrors {
            showAlert(L10n.switchFailedTitle, L10n.switchFailedBody(err.rawValue))
        }
        return false
    }

    /// F6.8：等待确认期间目标显示器被拔掉，静默结束等待。
    fileprivate func displayRemoved(_ display: CGDirectDisplayID) {
        guard let p = pending, p.display == display else { return }
        pending = nil
        p.panel.dismissSilently()
        unkeptTrial[p.uuid] = p.target.signature
        log.info("pending cancelled: display removed uuid=\(p.uuid, privacy: .public)")
    }

    // MARK: - 其他菜单动作

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
                // 系统可能要求用户在“系统设置 › 通用 › 登录项”里批准，否则菜单不会打勾，再点也没反应
                if service.status == .requiresApproval {
                    showAlert(L10n.loginItemFailedTitle, L10n.loginItemNeedsApproval)
                    SMAppService.openSystemSettingsLoginItems()
                }
            }
        } catch {
            showAlert(L10n.loginItemFailedTitle, L10n.loginItemFailedBody(error.localizedDescription))
        }
    }

    @objc private func quit(_ sender: Any?) { NSApp.terminate(nil) }

    // MARK: - 检查更新（F14）

    @objc private func checkForUpdates(_ sender: Any?) {
        updateChecker.check { [weak self] outcome in self?.presentUpdate(outcome) }
    }

    /// F14.3：按结果构造提示框；第一个按钮为默认按钮。内部可见：测试构建用它截图。
    func makeUpdateAlert(_ outcome: UpdateLogic.Outcome, current: String = UpdateChecker.bundleVersion) -> NSAlert {
        let alert = NSAlert()
        switch outcome {
        case let .newer(version, _, notes):
            alert.messageText = L10n.updateAvailableTitle(version)
            alert.informativeText = L10n.currentVersion(current) + (notes.isEmpty ? "" : "\n\n" + notes)
            alert.addButton(withTitle: L10n.download)
            alert.addButton(withTitle: L10n.later)
        case .upToDate:
            alert.messageText = L10n.upToDateTitle
            alert.informativeText = L10n.currentVersion(current)
            alert.addButton(withTitle: L10n.ok)
        case let .failed(failure):
            alert.messageText = L10n.updateFailedTitle
            alert.informativeText = L10n.updateFailure(failure)
            alert.addButton(withTitle: L10n.ok)
        }
        return alert
    }

    private func presentUpdate(_ outcome: UpdateLogic.Outcome) {
        log.info("update check: \(String(describing: outcome), privacy: .public)")
        NSApp.activate(ignoringOtherApps: true)   // F14.4
        let response = makeUpdateAlert(outcome).runModal()
        if case let .newer(_, url, _) = outcome, response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(url)
        }
        NSApp.hide(nil)
    }

    private func showAlert(_ title: String, _ body: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = body
        alert.addButton(withTitle: L10n.ok)
        alert.runModal()
    }
}

/// C 回调，不能捕获上下文。只关心移除事件（F10.2）。
func reconfigurationCallback(_ display: CGDirectDisplayID, _ flags: CGDisplayChangeSummaryFlags,
                                     _ userInfo: UnsafeMutableRawPointer?) {
    guard flags.contains(.removeFlag), let userInfo else { return }
    let delegate = Unmanaged<AppDelegate>.fromOpaque(userInfo).takeUnretainedValue()
    DispatchQueue.main.async { delegate.displayRemoved(display) }
}
