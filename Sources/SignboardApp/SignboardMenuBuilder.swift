import AppKit

@objc protocol SignboardMenuActions: AnyObject {
    func createSignboard(_ sender: Any?)
    func deleteAllSignboards(_ sender: Any?)
    func toggleVisibility(_ sender: Any?)
    func showFontPanel(_ sender: Any?)
    func selectDragModifier(_ sender: Any?)
    func showSpaceGuide(_ sender: Any?)
    func quitApp(_ sender: Any?)
    func editSignboard(_ sender: Any?)
    func deleteSignboard(_ sender: Any?)
    func selectTextColor(_ sender: Any?)
    func selectOpacity(_ sender: Any?)
}

final class SignboardMenuBuilder {
    private weak var target: (SignboardMenuActions & NSObjectProtocol)?

    private enum MenuTitle {
        static let newSignboard = L10n.tr("menu.app.new_signboard", comment: "App menu item title.")
        static let deleteAllSignboards = L10n.tr("menu.app.delete_all_signboards", comment: "App menu item title.")
        static let hideAllSignboards = L10n.tr("menu.app.hide_all_signboards", comment: "App menu item title.")
        static let showAllSignboards = L10n.tr("menu.app.show_all_signboards", comment: "App menu item title.")
        static let font = L10n.tr("menu.shared.font", comment: "Shared menu item title.")
        static let spaceGuide = L10n.tr("menu.shared.space_guide", comment: "Shared menu item title.")
        static let quitSignboard = L10n.tr("menu.app.quit_signboard", comment: "App menu item title.")
        static let editSignboard = L10n.tr("menu.context.edit_signboard", comment: "Context menu item title.")
        static let deleteSignboard = L10n.tr("menu.context.delete_signboard", comment: "Context menu item title.")
        static let dragModifier = L10n.tr("menu.app.drag_modifier", comment: "App menu item title.")
        static let defaultTextColor = L10n.tr("menu.app.default_text_color", comment: "App menu item title.")
        static let versionFormat = L10n.tr("menu.app.version_format", comment: "App menu item title format with version.")
        static let textColor = L10n.tr("menu.context.text_color", comment: "Context menu item title.")
        static let opacity = L10n.tr("menu.context.opacity", comment: "Context menu item title.")
    }

    var signboardController: ((String) -> SignboardController?)?
    var currentTargetSignboardController: (() -> SignboardController?)?
    var preferencesTextColor: (() -> SignboardTextColor)?
    var preferencesDragModifier: (() -> DragModifier)?

    private var toggleVisibilityMenuItems: [NSMenuItem] = []
    private var modifierMenuItems: [DragModifier: [NSMenuItem]] = [:]
    private var textColorMenus: [NSMenu] = []
    private var opacityMenus: [NSMenu] = []

    init(target: SignboardMenuActions & NSObjectProtocol) {
        self.target = target
    }

    func makeAppMenu(appVersion: String) -> NSMenu {
        let appMenu = NSMenu()
        appMenu.autoenablesItems = false
        let newItem = NSMenuItem(title: MenuTitle.newSignboard, action: #selector(SignboardMenuActions.createSignboard(_:)), keyEquivalent: "n")
        newItem.target = target
        appMenu.addItem(newItem)

        let deleteAllItem = NSMenuItem(title: MenuTitle.deleteAllSignboards, action: #selector(SignboardMenuActions.deleteAllSignboards(_:)), keyEquivalent: "")
        deleteAllItem.target = target
        appMenu.addItem(deleteAllItem)

        appMenu.addItem(NSMenuItem.separator())

        let toggleItem = NSMenuItem(title: MenuTitle.hideAllSignboards, action: #selector(SignboardMenuActions.toggleVisibility(_:)), keyEquivalent: "h")
        toggleItem.target = target
        appMenu.addItem(toggleItem)
        toggleVisibilityMenuItems.append(toggleItem)

        appMenu.addItem(NSMenuItem.separator())
        let fontItem = NSMenuItem(title: MenuTitle.font, action: #selector(SignboardMenuActions.showFontPanel(_:)), keyEquivalent: "")
        fontItem.target = target
        appMenu.addItem(fontItem)
        appMenu.addItem(makeTextColorMenuItem(signboardID: nil))
        appMenu.addItem(makeModifierMenuItem())

        appMenu.addItem(NSMenuItem.separator())
        let helpItem = NSMenuItem(title: MenuTitle.spaceGuide, action: #selector(SignboardMenuActions.showSpaceGuide(_:)), keyEquivalent: "")
        helpItem.target = target
        appMenu.addItem(helpItem)

        appMenu.addItem(NSMenuItem.separator())
        let versionTitle = String(format: MenuTitle.versionFormat, locale: Locale.current, appVersion)
        let versionItem = NSMenuItem(title: versionTitle, action: nil, keyEquivalent: "")
        versionItem.isEnabled = false
        appMenu.addItem(versionItem)

        appMenu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: MenuTitle.quitSignboard, action: #selector(SignboardMenuActions.quitApp(_:)), keyEquivalent: "q")
        quitItem.target = target
        appMenu.addItem(quitItem)

        return appMenu
    }

    func makeContextMenu(for signboardID: String) -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        let editItem = NSMenuItem(title: MenuTitle.editSignboard, action: #selector(SignboardMenuActions.editSignboard(_:)), keyEquivalent: "")
        editItem.target = target
        editItem.representedObject = signboardID
        menu.addItem(editItem)

        let deleteItem = NSMenuItem(title: MenuTitle.deleteSignboard, action: #selector(SignboardMenuActions.deleteSignboard(_:)), keyEquivalent: "")
        deleteItem.target = target
        deleteItem.representedObject = signboardID
        menu.addItem(deleteItem)
        menu.addItem(NSMenuItem.separator())

        let fontItem = NSMenuItem(title: MenuTitle.font, action: #selector(SignboardMenuActions.showFontPanel(_:)), keyEquivalent: "")
        fontItem.target = target
        menu.addItem(fontItem)

        menu.addItem(makeTextColorMenuItem(signboardID: signboardID))
        menu.addItem(makeOpacityMenuItem(signboardID: signboardID))
        menu.addItem(NSMenuItem.separator())

        let helpItem = NSMenuItem(title: MenuTitle.spaceGuide, action: #selector(SignboardMenuActions.showSpaceGuide(_:)), keyEquivalent: "")
        helpItem.target = target
        menu.addItem(helpItem)

        return menu
    }

    func setToggleVisibility(isVisible: Bool) {
        let title = isVisible ? MenuTitle.hideAllSignboards : MenuTitle.showAllSignboards
        for item in toggleVisibilityMenuItems {
            item.title = title
        }
    }

    func updateModifierMenuSelection(_ modifier: DragModifier) {
        for (key, items) in modifierMenuItems {
            for item in items {
                item.state = key == modifier ? .on : .off
            }
        }
    }

    func updateForActiveSignboard(id: String) {
        let fallbackColor = preferencesTextColor?() ?? .white
        for menu in textColorMenus {
            updateTextColorMenuSelection(in: menu, signboardID: id, fallback: fallbackColor)
        }
        for menu in opacityMenus {
            updateOpacityMenuSelection(in: menu, signboardID: id, fallback: 1.0)
        }
    }

    func updateTextColorMenusAfterSelection(menu: NSMenu?, signboardID: String?) {
        let fallback = preferencesTextColor?() ?? .white
        if let menu {
            updateTextColorMenuSelection(in: menu, signboardID: signboardID, fallback: fallback)
        }
        for menu in textColorMenus {
            updateTextColorMenuSelection(in: menu, signboardID: signboardID, fallback: fallback)
        }
    }

    func updateOpacityMenusAfterSelection(menu: NSMenu?, signboardID: String?) {
        if let menu {
            updateOpacityMenuSelection(in: menu, signboardID: signboardID, fallback: 1.0)
        }
        for menu in opacityMenus {
            updateOpacityMenuSelection(in: menu, signboardID: signboardID, fallback: 1.0)
        }
    }

    func refreshRootMenuSelections() {
        let fallback = preferencesTextColor?() ?? .white
        for menu in textColorMenus {
            updateTextColorMenuSelection(in: menu, signboardID: nil, fallback: fallback)
        }
        for menu in opacityMenus {
            updateOpacityMenuSelection(in: menu, signboardID: nil, fallback: 1.0)
        }
    }

    private func makeModifierMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: MenuTitle.dragModifier, action: nil, keyEquivalent: "")
        let menu = NSMenu()

        for modifier in DragModifier.allCases {
            let option = NSMenuItem(title: modifier.menuTitle, action: #selector(SignboardMenuActions.selectDragModifier(_:)), keyEquivalent: "")
            option.target = target
            option.representedObject = modifier
            menu.addItem(option)
            modifierMenuItems[modifier, default: []].append(option)
        }
        item.submenu = menu
        if let modifier = preferencesDragModifier?() {
            updateModifierMenuSelection(modifier)
        }
        return item
    }

    private func makeTextColorMenuItem(signboardID: String?) -> NSMenuItem {
        let title = signboardID == nil ? MenuTitle.defaultTextColor : MenuTitle.textColor
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let menu = NSMenu()

        for color in SignboardTextColor.allCases {
            let option = NSMenuItem(title: color.menuTitle, action: #selector(SignboardMenuActions.selectTextColor(_:)), keyEquivalent: "")
            option.target = target
            option.representedObject = color
            menu.addItem(option)
        }
        item.submenu = menu
        let fallback = preferencesTextColor?() ?? .white
        updateTextColorMenuSelection(in: menu, signboardID: signboardID, fallback: fallback)
        registerRootTextColorMenu(menu, signboardID: signboardID)
        return item
    }

    private func makeOpacityMenuItem(signboardID: String?) -> NSMenuItem {
        let item = NSMenuItem(title: MenuTitle.opacity, action: nil, keyEquivalent: "")
        let menu = NSMenu()
        menu.autoenablesItems = false
        item.isEnabled = true

        for preset in SignboardOpacityPreset.allCases {
            let option = NSMenuItem(title: preset.menuTitle, action: #selector(SignboardMenuActions.selectOpacity(_:)), keyEquivalent: "")
            option.target = target
            option.representedObject = preset
            option.isEnabled = true
            menu.addItem(option)
        }
        updateOpacityMenuSelection(in: menu, signboardID: signboardID, fallback: 1.0)
        registerRootOpacityMenu(menu, signboardID: signboardID)
        item.submenu = menu
        return item
    }

    private func updateTextColorMenuSelection(in menu: NSMenu, signboardID: String?, fallback: SignboardTextColor) {
        let targetColor: SignboardTextColor
        if let signboardID,
           let controller = signboardController?(signboardID)
        {
            targetColor = SignboardTextColor(rawValue: controller.signboard.textColor) ?? .white
        } else if let controller = currentTargetSignboardController?() {
            targetColor = SignboardTextColor(rawValue: controller.signboard.textColor) ?? .white
        } else {
            targetColor = fallback
        }
        for item in menu.items {
            guard let color = item.representedObject as? SignboardTextColor else { continue }
            item.state = color == targetColor ? .on : .off
        }
    }

    private func updateOpacityMenuSelection(in menu: NSMenu, signboardID: String?, fallback: Double) {
        let targetOpacity: Double
        if let signboardID,
           let controller = signboardController?(signboardID)
        {
            targetOpacity = controller.signboard.opacity
        } else if let controller = currentTargetSignboardController?() {
            targetOpacity = controller.signboard.opacity
        } else {
            targetOpacity = fallback
        }
        for item in menu.items {
            guard let preset = item.representedObject as? SignboardOpacityPreset else { continue }
            item.state = preset.rawValue == targetOpacity ? .on : .off
        }
    }

    private func registerRootTextColorMenu(_ menu: NSMenu, signboardID: String?) {
        guard signboardID == nil else { return }
        textColorMenus.append(menu)
    }

    private func registerRootOpacityMenu(_ menu: NSMenu, signboardID: String?) {
        guard signboardID == nil else { return }
        opacityMenus.append(menu)
    }
}
