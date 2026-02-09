import AppKit
import Foundation

enum DragModifier: String, CaseIterable {
    case option
    case command
    case shift

    var flags: NSEvent.ModifierFlags {
        switch self {
        case .option:
            return .option
        case .command:
            return .command
        case .shift:
            return .shift
        }
    }

    var menuTitle: String {
        switch self {
        case .option:
            return L10n.tr("menu.drag_modifier.option", comment: "Drag modifier option title: Option key.")
        case .command:
            return L10n.tr("menu.drag_modifier.command", comment: "Drag modifier option title: Command key.")
        case .shift:
            return L10n.tr("menu.drag_modifier.shift", comment: "Drag modifier option title: Shift key.")
        }
    }
}

enum SignboardTextColor: String, CaseIterable {
    case white
    case black

    var menuTitle: String {
        switch self {
        case .white:
            return L10n.tr("menu.text_color.white", comment: "Text color menu title: white.")
        case .black:
            return L10n.tr("menu.text_color.black", comment: "Text color menu title: black.")
        }
    }

    var color: NSColor {
        switch self {
        case .white:
            return .white
        case .black:
            return .black
        }
    }
}

enum SignboardOpacityPreset: Double, CaseIterable {
    case percent100 = 1.0
    case percent80 = 0.8
    case percent60 = 0.6
    case percent40 = 0.4

    var menuTitle: String {
        switch self {
        case .percent100:
            return "100%"
        case .percent80:
            return "80%"
        case .percent60:
            return "60%"
        case .percent40:
            return "40%"
        }
    }
}

final class AppPreferences {
    static let shared = AppPreferences()

    private let defaults = UserDefaults.standard
    private let initializedKey = "signboard.initialized"
    private let fontNameKey = "signboard.fontName"
    private let fontSizeKey = "signboard.fontSize"
    private let dragModifierKey = "signboard.dragModifier"
    private let textColorKey = "signboard.textColor"
    private let underlineKey = "signboard.underline"

    func applyInitialDefaultsIfNeeded() {
        if defaults.bool(forKey: initializedKey) {
            return
        }
        defaults.set("AvenirNext-Bold", forKey: fontNameKey)
        defaults.set(48.0, forKey: fontSizeKey)
        defaults.set(true, forKey: underlineKey)
        defaults.set(true, forKey: initializedKey)
    }

    var fontName: String? {
        get {
            return defaults.string(forKey: fontNameKey)
        }
        set {
            defaults.set(newValue, forKey: fontNameKey)
        }
    }

    var fontSize: CGFloat {
        get {
            let size = defaults.double(forKey: fontSizeKey)
            return size > 0 ? size : 26
        }
        set {
            defaults.set(Double(newValue), forKey: fontSizeKey)
        }
    }

    var dragModifier: DragModifier {
        get {
            guard let raw = defaults.string(forKey: dragModifierKey),
                  let modifier = DragModifier(rawValue: raw)
            else {
                return .option
            }
            return modifier
        }
        set {
            defaults.set(newValue.rawValue, forKey: dragModifierKey)
        }
    }

    var underline: Bool {
        get { defaults.bool(forKey: underlineKey) }
        set { defaults.set(newValue, forKey: underlineKey) }
    }

    var textColor: SignboardTextColor {
        get {
            guard let raw = defaults.string(forKey: textColorKey),
                  let color = SignboardTextColor(rawValue: raw)
            else {
                return .white
            }
            return color
        }
        set {
            defaults.set(newValue.rawValue, forKey: textColorKey)
        }
    }
}
