import AppKit

final class SignboardView: NSView {
    var menuProvider: (() -> NSMenu?)?
    var optionDragEnded: (() -> Void)?
    var onAnyMouseDown: (() -> Void)?
    var onMenuDismissed: (() -> Void)?
    var dragModifier: NSEvent.ModifierFlags = .option
    var text: String = "" {
        didSet { needsDisplay = true }
    }

    var font: NSFont = .systemFont(ofSize: 26, weight: .semibold) {
        didSet { needsDisplay = true }
    }

    var textColor: NSColor = .white {
        didSet { needsDisplay = true }
    }

    var underline: Bool = false {
        didSet { needsDisplay = true }
    }

    private var isOptionDragging = false
    private var dragStartMouseLocation: NSPoint = .zero
    private var dragStartFrame: NSRect = .zero

    override func hitTest(_: NSPoint) -> NSView? {
        guard let event = NSApp.currentEvent else {
            return nil
        }
        switch event.type {
        case .rightMouseDown, .rightMouseUp, .rightMouseDragged,
             .leftMouseDown, .leftMouseUp, .leftMouseDragged:
            return event.modifierFlags.contains(dragModifier) ? self : nil
        default:
            return nil
        }
    }

    override func acceptsFirstMouse(for _: NSEvent?) -> Bool {
        return true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineBreakMode = .byClipping
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
        ]
        if underline {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let textRect = bounds.insetBy(dx: SignboardLayout.padding.width, dy: SignboardLayout.padding.height)
        attributed.draw(in: textRect)
    }

    override func rightMouseDown(with event: NSEvent) {
        guard event.modifierFlags.contains(dragModifier) else {
            return
        }
        onAnyMouseDown?()
        guard let menu = menuProvider?() else {
            return
        }
        NSMenu.popUpContextMenu(menu, with: event, for: self)
        onMenuDismissed?()
    }

    override func mouseDown(with event: NSEvent) {
        onAnyMouseDown?()
        if event.modifierFlags.contains(dragModifier) {
            isOptionDragging = true
            dragStartMouseLocation = NSEvent.mouseLocation
            dragStartFrame = window?.frame ?? .zero
        }
    }

    override func mouseDragged(with _: NSEvent) {
        guard isOptionDragging, let window else {
            return
        }
        let currentLocation = NSEvent.mouseLocation
        let dx = currentLocation.x - dragStartMouseLocation.x
        let dy = currentLocation.y - dragStartMouseLocation.y
        var newFrame = dragStartFrame
        newFrame.origin.x += dx
        newFrame.origin.y += dy
        window.setFrame(newFrame, display: true)
    }

    override func mouseUp(with _: NSEvent) {
        guard isOptionDragging else {
            return
        }
        isOptionDragging = false
        optionDragEnded?()
    }
}
