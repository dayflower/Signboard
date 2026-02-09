import AppKit

final class EditorPopover: NSObject, NSPopoverDelegate, NSTextFieldDelegate {
    private let popover: NSPopover
    private let textField: NSTextField
    private var didCommit = false

    var onCommit: ((String) -> Void)?
    var onCancel: (() -> Void)?

    init(currentText: String) {
        textField = NSTextField(string: currentText)
        textField.font = NSFont.systemFont(ofSize: 15)
        textField.isBordered = true
        textField.lineBreakMode = .byTruncatingTail

        let view = NSView(frame: NSRect(x: 0, y: 0, width: 240, height: 56))
        textField.frame = NSRect(x: 12, y: 14, width: 216, height: 28)
        view.addSubview(textField)

        let controller = NSViewController()
        controller.view = view

        popover = NSPopover()
        popover.contentViewController = controller
        popover.behavior = .transient

        super.init()

        textField.delegate = self
        popover.delegate = self
    }

    func show(relativeTo rect: NSRect, of view: NSView, preferredEdge: NSRectEdge) {
        popover.show(relativeTo: rect, of: view, preferredEdge: preferredEdge)
        view.window?.makeKey()
        view.window?.makeFirstResponder(textField)
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        guard let movementValue = obj.userInfo?[NSText.movementUserInfoKey] as? NSNumber else {
            return
        }
        let movement = movementValue.intValue
        if movement == NSReturnTextMovement {
            didCommit = true
            onCommit?(textField.stringValue)
            popover.close()
        } else if movement == NSCancelTextMovement {
            onCancel?()
            popover.close()
        }
    }

    func popoverDidClose(_: Notification) {
        if !didCommit {
            onCancel?()
        }
    }

    func close() {
        popover.close()
    }
}
