import AppKit

/// 防黑屏确认面板（F6）。非模态小面板 + 加入 `.common` 模式的定时器，超时无人操作也能自动还原。
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

        // F6.2 修订：说明这一档按多大像素渲染
        // 译文长短不一（F13）：正文按固定宽度自动换行，面板高度随内容
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
        keepButton.keyEquivalent = "\r"          // 默认按钮
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
        // 按最长倒计时文案确定高度，之后每秒更新时面板不跳动
        content.layoutSubtreeIfNeeded()
        panel.setContentSize(NSSize(width: ConfirmPanel.width, height: max(150, content.fittingSize.height)))
    }

    func show() {
        center()
        NSApp.activate(ignoringOtherApps: true)   // 6.6：无 Dock 图标的应用需要主动取得键盘焦点
        // macOS 14 起激活是协作式的，可能被系统忽略；非激活面板不依赖应用处于前台也能成为键窗口，
        // 保证回车和 Esc 一定送到这里。
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        panel.makeKey()

        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)   // 6.6：菜单跟踪 / 模态期间也要触发
        timer = t
    }

    /// 切换后屏幕尺寸会变，按目标显示器的新位置居中（F6.3）。
    func center() {
        let b = CGDisplayBounds(display)
        guard b.width > 0 else { panel.center(); return }
        let primaryHeight = CGDisplayBounds(CGMainDisplayID()).height
        let screenRect = NSRect(x: b.minX, y: primaryHeight - b.maxY, width: b.width, height: b.height)
        let size = panel.frame.size
        panel.setFrameOrigin(NSPoint(x: screenRect.midX - size.width / 2, y: screenRect.midY - size.height / 2))
    }

    /// 静默结束（F6.8），不回调。
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
            finish(.revert)   // F6.9：无人操作时自动还原
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
