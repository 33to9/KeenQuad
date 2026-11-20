// SPDX-License-Identifier: GPL-3.0-only
// Copyright © 2026 33to9
import AppKit

/// "Keep this resolution?" panel. A small non-modal panel plus a timer in the `.common` run-loop mode, so it reverts even if nobody is there.
final class ConfirmPanel: NSObject, NSWindowDelegate {
    enum Outcome { case keep, revert }

    static let countdownSeconds = 15
    static let width: CGFloat = 420

    private let panel: NSPanel
    private let bodyLabel: NSTextField
    private let previousSize: (Int, Int)
    private let display: CGDirectDisplayID
    private var remaining = ConfirmPanel.countdownSeconds
    private var timer: Timer?
    private var onFinish: ((Outcome) -> Void)?

    init(display: CGDirectDisplayID, previousSize: (Int, Int), renderSize: (Int, Int), onFinish: @escaping (Outcome) -> Void) {
        self.display = display
        self.previousSize = previousSize
        self.onFinish = onFinish

        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: ConfirmPanel.width, height: 168),
                        styleMask: [.titled, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false
        panel.level = .modalPanel
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let icon = NSImageView(image: NSApp.applicationIconImage ?? NSImage())
        icon.imageScaling = .scaleProportionallyUpOrDown

        let titleLabel = NSTextField(wrappingLabelWithString: L10n.confirmTitle)
        titleLabel.isSelectable = false
        titleLabel.font = .boldSystemFont(ofSize: NSFont.systemFontSize + 1)

        // Says how many pixels this mode renders
        // Translations vary in length: body text wraps at a fixed width and the panel grows to fit
        let textWidth = ConfirmPanel.width - 82 - 20
        let renderLabel = NSTextField(wrappingLabelWithString: L10n.confirmRender(w: renderSize.0, h: renderSize.1))
        renderLabel.preferredMaxLayoutWidth = textWidth
        renderLabel.isSelectable = false
        renderLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize + 1)

        bodyLabel = NSTextField(wrappingLabelWithString: "")
        bodyLabel.preferredMaxLayoutWidth = textWidth
        bodyLabel.isSelectable = false
        bodyLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize + 1)
        bodyLabel.textColor = .secondaryLabelColor

        let keepButton = NSButton(title: L10n.keep, target: nil, action: nil)
        keepButton.keyEquivalent = "\r"          // default button
        keepButton.bezelStyle = .rounded
        let revertButton = NSButton(title: L10n.revert, target: nil, action: nil)
        revertButton.keyEquivalent = "\u{1b}"     // Esc
        revertButton.bezelStyle = .rounded

        super.init()

        keepButton.target = self
        keepButton.action = #selector(keepClicked)
        revertButton.target = self
        revertButton.action = #selector(revertClicked)
        panel.delegate = self

        let content = NSView()
        for v in [icon, titleLabel, renderLabel, bodyLabel, keepButton, revertButton] as [NSView] {
            v.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(v)
        }
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            icon.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            icon.widthAnchor.constraint(equalToConstant: 48),
            icon.heightAnchor.constraint(equalToConstant: 48),

            titleLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 14),
            titleLabel.topAnchor.constraint(equalTo: content.topAnchor, constant: 22),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -20),

            renderLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            renderLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            renderLabel.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -20),

            bodyLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bodyLabel.topAnchor.constraint(equalTo: renderLabel.bottomAnchor, constant: 4),
            bodyLabel.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -20),

            keepButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            keepButton.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -18),
            keepButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            revertButton.trailingAnchor.constraint(equalTo: keepButton.leadingAnchor, constant: -10),
            revertButton.centerYAnchor.constraint(equalTo: keepButton.centerYAnchor),
            revertButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            keepButton.topAnchor.constraint(greaterThanOrEqualTo: bodyLabel.bottomAnchor, constant: 18),
            keepButton.topAnchor.constraint(greaterThanOrEqualTo: icon.bottomAnchor, constant: 12),
        ])
        content.widthAnchor.constraint(equalToConstant: ConfirmPanel.width).isActive = true
        titleLabel.preferredMaxLayoutWidth = ConfirmPanel.width - 82 - 20
        panel.contentView = content
        panel.defaultButtonCell = keepButton.cell as? NSButtonCell
        updateBody()
        // Size the panel for the longest countdown text so it doesn't jump every second
        content.layoutSubtreeIfNeeded()
        panel.setContentSize(NSSize(width: ConfirmPanel.width, height: max(150, content.fittingSize.height)))
    }

    func show() {
        center()
        NSApp.activate(ignoringOtherApps: true)   // an app without a Dock icon has to take keyboard focus itself
        // Since macOS 14 activation is cooperative and may be ignored; a non-activating panel can become key
        // without the app being frontmost, so Return and Esc always reach it.
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        panel.makeKey()

        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)   // keep firing during menu tracking and modal sessions
        timer = t
    }

    /// The screen size changes after switching, so center on the display's new bounds.
    func center() {
        let b = CGDisplayBounds(display)
        guard b.width > 0 else { panel.center(); return }
        let primaryHeight = CGDisplayBounds(CGMainDisplayID()).height
        let screenRect = NSRect(x: b.minX, y: primaryHeight - b.maxY, width: b.width, height: b.height)
        let size = panel.frame.size
        panel.setFrameOrigin(NSPoint(x: screenRect.midX - size.width / 2, y: screenRect.midY - size.height / 2))
    }

    /// Ends without calling back (the display was removed).
    func dismissSilently() {
        onFinish = nil
        close()
    }

    func finish(_ outcome: Outcome) {
        let cb = onFinish
        onFinish = nil
        close()
        cb?(outcome)
    }

    private func close() {
        timer?.invalidate()
        timer = nil
        panel.orderOut(nil)
        panel.close()
    }

    private func tick() {
        remaining -= 1
        if remaining <= 0 {
            finish(.revert)   // revert when nobody responds
        } else {
            updateBody()
        }
    }

    private func updateBody() {
        bodyLabel.stringValue = L10n.confirmBody(seconds: remaining, w: previousSize.0, h: previousSize.1)
    }

    @objc private func keepClicked() { finish(.keep) }
    @objc private func revertClicked() { finish(.revert) }

    func windowShouldClose(_ sender: NSWindow) -> Bool { finish(.revert); return false }
}
