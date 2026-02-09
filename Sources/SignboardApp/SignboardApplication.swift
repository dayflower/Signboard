import AppKit

private let changeAttributesSelector = NSSelectorFromString("changeAttributes:")

final class SignboardApplication: NSApplication {
    override func sendAction(_ action: Selector, to target: Any?, from sender: Any?) -> Bool {
        // changeAttributes: is sent through the responder chain (not via
        // NSFontManager.target like changeFont:).  In accessory-policy apps
        // the chain may never reach the delegate, so route it explicitly.
        if action == changeAttributesSelector {
            if let delegate = delegate, (delegate as AnyObject).responds(to: action) {
                return super.sendAction(action, to: delegate, from: sender)
            }
        }
        return super.sendAction(action, to: target, from: sender)
    }
}
