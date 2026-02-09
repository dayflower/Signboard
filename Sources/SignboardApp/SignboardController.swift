import AppKit

final class SignboardController: NSObject, NSWindowDelegate {
    private let store: SignboardStore
    private(set) var signboard: SignboardItem
    private let panel: SignboardPanel
    private let view: SignboardView
    private var editorPopover: EditorPopover?

    private var font: NSFont
    private var underline: Bool

    var menuProvider: (() -> NSMenu?)?
    var onAnyMouseDown: (() -> Void)?
    var onMenuDismissed: (() -> Void)?

    init(store: SignboardStore, signboard: SignboardItem, font: NSFont, underline: Bool, dragModifier: NSEvent.ModifierFlags) {
        self.store = store
        self.signboard = signboard
        self.font = font
        self.underline = underline

        view = SignboardView(frame: .zero)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        view.dragModifier = dragModifier
        view.text = signboard.text
        view.font = font
        view.underline = underline
        view.textColor = (SignboardTextColor(rawValue: signboard.textColor) ?? .white).color

        panel = SignboardPanel(contentRect: signboard.frame.nsRect)
        panel.contentView = view

        super.init()

        panel.delegate = self
        view.menuProvider = { [weak self] in
            guard let self else { return nil }
            return self.menuProvider?()
        }
        view.onAnyMouseDown = { [weak self] in
            self?.onAnyMouseDown?()
        }
        view.onMenuDismissed = { [weak self] in
            self?.onMenuDismissed?()
        }
        view.optionDragEnded = { [weak self] in
            self?.persistFrame()
        }

        applyText(signboard.text, keepTopLeft: false)
        panel.alphaValue = CGFloat(signboard.opacity)

        NotificationCenter.default.addObserver(self, selector: #selector(windowDidMoveNotification(_:)), name: NSWindow.didMoveNotification, object: panel)
    }

    func show() {
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    func close() {
        NotificationCenter.default.removeObserver(self, name: NSWindow.didMoveNotification, object: panel)
        editorPopover?.close()
        panel.orderOut(nil)
        panel.close()
    }

    func showEditor() {
        NSApp.activate(ignoringOtherApps: true)
        let popover = EditorPopover(currentText: signboard.text)
        popover.onCommit = { [weak self] newText in
            self?.commitText(newText)
        }
        popover.onCancel = { [weak self] in
            self?.editorPopover = nil
        }
        editorPopover = popover
        popover.show(relativeTo: view.bounds, of: view, preferredEdge: .maxY)
    }

    func updateTextFromCommand(_ text: String) {
        commitText(text)
    }

    private func commitText(_ text: String) {
        signboard.text = text
        applyText(text, keepTopLeft: true)
        persist()
        editorPopover = nil
    }

    func updateFont(_ font: NSFont) {
        self.font = font
        view.font = font
        applyText(signboard.text, keepTopLeft: true)
    }

    func updateUnderline(_ underline: Bool) {
        self.underline = underline
        view.underline = underline
        applyText(signboard.text, keepTopLeft: true)
    }

    func updateTextColor(_ choice: SignboardTextColor) {
        signboard.textColor = choice.rawValue
        view.textColor = choice.color
        persist()
    }

    func updateOpacity(_ opacity: Double) {
        signboard.opacity = opacity
        panel.alphaValue = CGFloat(opacity)
        persist()
    }

    func updateDragModifier(_ modifier: NSEvent.ModifierFlags) {
        view.dragModifier = modifier
    }

    func setInteractionEnabled(_ enabled: Bool) {
        panel.ignoresMouseEvents = !enabled
    }

    private func persistFrame() {
        signboard.frame = StoredRect(panel.frame)
        persist()
    }

    private func persist() {
        store.upsert(signboard)
    }

    private func layoutSize(for text: String) -> CGSize {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineBreakMode = .byClipping
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
        ]
        if underline {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let bounds = attributed.boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesFontLeading, .usesLineFragmentOrigin]
        )
        let height = ceil(bounds.height) + 2
        let width = ceil(bounds.width) + 2
        return CGSize(width: width + SignboardLayout.padding.width * 2, height: height + SignboardLayout.padding.height * 2)
    }

    private func applyText(_ text: String, keepTopLeft: Bool) {
        view.text = text
        let newSize = layoutSize(for: text)
        var frame = panel.frame
        if keepTopLeft {
            let delta = newSize.height - frame.size.height
            frame.origin.y -= delta
        }
        frame.size = newSize
        panel.setFrame(frame, display: true)
        view.frame = NSRect(origin: .zero, size: newSize)
    }

    @objc private func windowDidMoveNotification(_: Notification) {
        persistFrame()
    }
}
