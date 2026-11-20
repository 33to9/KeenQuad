// SPDX-License-Identifier: GPL-3.0-only
// Copyright © 2026 Pivotfrag LLC
import AppKit
import ServiceManagement
import os

/// What a menu item selects. Stores the signature, never the mode number (numbers aren't stable).
private final class ModeChoice: NSObject {
    let display: CGDirectDisplayID
    let signature: String
    /// The "Switch to Sharp" item: same size, 1x to HiDPI, no confirmation.
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

    private(set) var statusItem: NSStatusItem!   // internal read access for the test build only
    let menu = NSMenu()   // internal so the test build's TestHook can read it
    private var pending: Pending?
    /// Trials applied with .forAppOnly that ended without Keep or Revert (e.g. the display was removed). Display UUID → signature.
    /// Kept in memory only, so that leaving such a mode doesn't mark it as kept.
    private var unkeptTrial: [String: String] = [:]
    private var signalSources: [DispatchSourceSignal] = []
    let updateChecker = UpdateChecker()   // internal for the test build
    private let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.pivotfrag.keenquad", category: "switch")

    // MARK: - Lifecycle

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

        // Used only to notice a display being removed during confirmation
        CGDisplayRegisterReconfigurationCallback(reconfigurationCallback, Unmanaged.passUnretained(self).toOpaque())

        // kill, Ctrl-C and hangup go through normal termination, which reverts a pending trial first
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
        // After the status item is up, so the menu bar icon is already there when the alert appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in self?.remindAboutLoginItemIfNeeded() }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if let p = pending {
            pending = nil
            p.panel.dismissSilently()
            revert(p)
        }
        return .terminateNow
    }

    // MARK: - Menu

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

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? UpdateChecker.bundleVersion
        menu.addItem(disabledItem(L10n.version(version)))

        // While checking, show "Checking for Updates…" disabled
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
        if let tag = text.tag {   // shown in a weaker style
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

    /// Follow System, a separator, then each language in its own script; the current choice is checked.
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

    /// Saved right away and used from the next time anything is shown; Follow System removes the key.
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

    // MARK: - Switching

    @objc private func selectMode(_ sender: NSMenuItem) {
        guard pending == nil, let choice = sender.representedObject as? ModeChoice else { return }
        let display = choice.display
        guard Displays.active().contains(display) else { return }

        // Enumerate again and only switch to a candidate from this enumeration
        let table = PrivateDisplay.modeTable(of: display)
        let currentNumber = PrivateDisplay.currentModeNumber(of: display)
        let candidates = CandidateRules.compute(table: table, currentNumber: currentNumber)
        guard let target = CandidateRules.find(signature: choice.signature, in: candidates) else { return }
        // The sharp-version item only applies while the current mode is still its 1x counterpart
        if choice.isSharpFix && candidates.sharpVersion?.mode.signature != target.signature { return }
        guard target.number != currentNumber else { return }   // F5.1

        let previous = candidates.current
        let previousBounds = CGDisplayBounds(display)
        let previousSize = previous.map { ($0.width, $0.height) }
            ?? (Int(previousBounds.width), Int(previousBounds.height))
        let uuid = Displays.uuid(of: display)
        let confirmed = choice.isSharpFix || target.isNative
            || ConfirmedStore.contains(target.signature, uuid: uuid)   // F12.4 / F7.2 / F7.4

        // Kept before: apply permanently. Otherwise try it with .forAppOnly first
        let option: CGConfigureOption = confirmed ? .permanently : .forAppOnly
        let label = choice.isSharpFix ? "sharpen" : (confirmed ? "apply" : "trial")
        guard perform(target, on: display, uuid: uuid, from: previous, option: option, label: label) else {
            return
        }
        if choice.isSharpFix { ConfirmedStore.add(target.signature, uuid: uuid) }   // F12.4
        // The mode we're leaving was just on screen, so mark it as kept, unless it was an unkept trial
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
        // The panel activated us only to get keyboard focus; give focus back to the previous app
        NSApp.hide(nil)
    }

    /// Switches back to the previous mode with `.permanently`. Reverting never asks for confirmation.
    private func revert(_ p: Pending) {
        guard Displays.active().contains(p.display) else {
            // The display isn't active (e.g. asleep), so we can't switch by mode number; restore the saved permanent configuration.
            // Every switch except this trial was applied permanently, so this only undoes the trial.
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
        // Fallback: restore the permanent configuration (the trial was .forAppOnly, so it still holds the previous mode)
        CGRestorePermanentDisplayConfiguration()
        let now = PrivateDisplay.currentModeNumber(of: p.display)
        log.error("revert fallback uuid=\(p.uuid, privacy: .public) restorePermanent current=#\(now)")
    }

    /// Switches, reads the mode back to verify, logs the result, and on failure shows an alert and keeps the previous state.
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
                // Try to get back to the state before the switch
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

    /// The display was removed while waiting for confirmation: end the wait silently.
    fileprivate func displayRemoved(_ display: CGDirectDisplayID) {
        guard let p = pending, p.display == display else { return }
        pending = nil
        p.panel.dismissSilently()
        unkeptTrial[p.uuid] = p.target.signature
        log.info("pending cancelled: display removed uuid=\(p.uuid, privacy: .public)")
    }

    // MARK: - Other menu actions

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        if SMAppService.mainApp.status == .enabled {
            do { try SMAppService.mainApp.unregister() }
            catch { showAlert(L10n.loginItemFailedTitle, L10n.loginItemFailedBody(error.localizedDescription)) }
        } else {
            enableLaunchAtLogin()
        }
    }

    private func enableLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            try service.register()
            // macOS may require approval in System Settings › General › Login Items; without it the item stays unchecked and clicking again does nothing
            if service.status == .requiresApproval {
                showAlert(L10n.loginItemFailedTitle, L10n.loginItemNeedsApproval)
                SMAppService.openSystemSettingsLoginItems()
            }
        } catch {
            showAlert(L10n.loginItemFailedTitle, L10n.loginItemFailedBody(error.localizedDescription))
        }
    }

    // MARK: - Login item reminder after updating from 0.4.0

    private func remindAboutLoginItemIfNeeded() {
        let defaults = UserDefaults.standard
        let decision = LoginReminder.decide(
            isProduct: Bundle.main.bundleIdentifier == LoginReminder.productBundleID,
            legacySettingsExist: defaults.persistentDomain(forName: LoginReminder.legacyBundleID) != nil,
            loginEnabled: SMAppService.mainApp.status == .enabled,
            alreadyDone: defaults.bool(forKey: LoginReminder.doneKey))
        log.info("login reminder: \(String(describing: decision), privacy: .public)")
        guard decision != .nothing else { return }
        defaults.set(true, forKey: LoginReminder.doneKey)   // ask at most once, whatever the answer
        guard decision == .show else { return }
        NSApp.activate(ignoringOtherApps: true)
        if makeLoginReminderAlert().runModal() == .alertFirstButtonReturn { enableLaunchAtLogin() }
        NSApp.hide(nil)
    }

    /// Internal so the test build can snapshot it.
    func makeLoginReminderAlert() -> NSAlert {
        let alert = NSAlert()
        alert.messageText = L10n.loginReminderTitle
        alert.informativeText = L10n.loginReminderBody
        alert.addButton(withTitle: L10n.turnOn)
        alert.addButton(withTitle: L10n.noThanks)
        return alert
    }

    @objc private func quit(_ sender: Any?) { NSApp.terminate(nil) }

    // MARK: - Check for Updates

    @objc private func checkForUpdates(_ sender: Any?) {
        updateChecker.check { [weak self] outcome in self?.presentUpdate(outcome) }
    }

    /// Builds the alert for a result; the first button is the default. Internal so the test build can snapshot it.
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

/// C callback, so it can't capture context. Only display removal matters; our own switches also trigger it.
func reconfigurationCallback(_ display: CGDirectDisplayID, _ flags: CGDisplayChangeSummaryFlags,
                                     _ userInfo: UnsafeMutableRawPointer?) {
    guard flags.contains(.removeFlag), let userInfo else { return }
    let delegate = Unmanaged<AppDelegate>.fromOpaque(userInfo).takeUnretainedValue()
    DispatchQueue.main.async { delegate.displayRemoved(display) }
}
