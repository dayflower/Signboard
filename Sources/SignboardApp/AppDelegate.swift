import AppKit
import SignboardCore

final class AppDelegate: NSObject, NSApplicationDelegate, NSFontChanging, NSUserInterfaceValidations, SignboardMenuActions {
    private let store = SignboardStore()
    private let preferences = AppPreferences.shared
    private lazy var manager = SignboardManager(store: store, preferences: preferences)
    private lazy var menuBuilder: SignboardMenuBuilder = {
        let builder = SignboardMenuBuilder(target: self)
        builder.signboardController = { [unowned self] id in
            self.manager.signboardController(for: id)
        }
        builder.currentTargetSignboardController = { [unowned self] in
            self.manager.currentTargetSignboardController()
        }
        builder.preferencesTextColor = { [unowned self] in
            self.preferences.textColor
        }
        builder.preferencesDragModifier = { [unowned self] in
            self.preferences.dragModifier
        }
        return builder
    }()

    private lazy var commandHandler = SignboardCommandHandler(
        manager: manager,
        makeController: { [unowned self] signboard in
            self.makeSignboardController(for: signboard)
        },
        setVisibility: { [unowned self] visible in
            self.setVisibility(visible)
        },
        isVisible: { [unowned self] in
            self.isVisible
        }
    )
    private var isVisible = true
    private var globalFlagsMonitor: Any?
    private var localFlagsMonitor: Any?
    private var isInteractionEnabled = false
    private var statusItem: NSStatusItem?
    private var notificationObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_: Notification) {
        preferences.applyInitialDefaultsIfNeeded()
        NSApp.setActivationPolicy(.accessory)
        buildMainMenu()
        buildStatusItem()

        manager.loadInitialSignboards(makeController: { [unowned self] signboard in
            self.makeSignboardController(for: signboard)
        })
        manager.applyVisibility(isVisible)
        if let signboardID = manager.controllers.first?.signboard.id {
            setActiveSignboard(id: signboardID)
        }
        startModifierMonitoring()
        startNotificationServer()
    }

    func applicationDidBecomeActive(_: Notification) {
        NSFontManager.shared.target = self
    }

    func applicationWillTerminate(_: Notification) {
        if let monitor = globalFlagsMonitor {
            NSEvent.removeMonitor(monitor)
            globalFlagsMonitor = nil
        }
        if let monitor = localFlagsMonitor {
            NSEvent.removeMonitor(monitor)
            localFlagsMonitor = nil
        }
        if let observer = notificationObserver {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
    }

    private func startNotificationServer() {
        let center = DistributedNotificationCenter.default()
        notificationObserver = center.addObserver(forName: SignboardNotification.requestName, object: nil, queue: nil) { [weak self] note in
            guard let self else { return }
            guard let userInfo = note.userInfo,
                  let parsed = SignboardNotification.parseCommand(userInfo)
            else {
                return
            }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let response = self.handleCommand(parsed.command)
                let payload = SignboardNotification.makeResponseUserInfo(response, requestID: parsed.requestID)
                center.postNotificationName(SignboardNotification.responseName, object: nil, userInfo: payload, deliverImmediately: true)
            }
        }
    }

    @objc func editSignboard(_ sender: Any?) {
        if let menuItem = sender as? NSMenuItem,
           let signboardID = menuItem.representedObject as? String,
           let controller = manager.signboardController(for: signboardID)
        {
            setActiveSignboard(id: signboardID)
            controller.showEditor()
            return
        }
        if let signboardID = manager.lastActiveSignboardID,
           let controller = manager.signboardController(for: signboardID)
        {
            controller.showEditor()
            return
        }
        manager.controllers.first?.showEditor()
    }

    @objc func toggleVisibility(_: Any?) {
        setVisibility(!isVisible)
    }

    private func setVisibility(_ visible: Bool) {
        guard isVisible != visible else { return }
        isVisible = visible
        manager.applyVisibility(isVisible)
        menuBuilder.setToggleVisibility(isVisible: isVisible)
    }

    @objc func createSignboard(_: Any?) {
        let controller = manager.createDefaultSignboard(makeController: { [unowned self] signboard in
            self.makeSignboardController(for: signboard)
        }, isVisible: isVisible)
        setActiveSignboard(id: controller.signboard.id)
    }

    @objc func deleteSignboard(_ sender: Any?) {
        if let menuItem = sender as? NSMenuItem,
           let signboardID = menuItem.representedObject as? String,
           let controller = manager.signboardController(for: signboardID)
        {
            guard confirmDeleteSignboard(text: controller.signboard.text) else { return }
            removeSignboard(id: signboardID)
            return
        }
        if let signboardID = manager.lastActiveSignboardID,
           let controller = manager.signboardController(for: signboardID)
        {
            guard confirmDeleteSignboard(text: controller.signboard.text) else { return }
            removeSignboard(id: signboardID)
            return
        }
        guard let controller = manager.controllers.first else { return }
        guard confirmDeleteSignboard(text: controller.signboard.text) else { return }
        removeSignboard(id: controller.signboard.id)
    }

    @objc func deleteAllSignboards(_: Any?) {
        guard !manager.controllers.isEmpty else { return }
        guard confirmDeleteAll() else { return }
        removeAllSignboards()
    }

    @objc func quitApp(_: Any?) {
        NSApp.terminate(nil)
    }

    @objc func showSpaceGuide(_: Any?) {
        let alert = NSAlert()
        alert.messageText = L10n.tr("alert.space_guide.title", comment: "Space guide alert title.")
        alert.informativeText = L10n.tr("alert.space_guide.message", comment: "Space guide alert message.")
        alert.addButton(withTitle: L10n.tr("alert.space_guide.button_ok", comment: "Space guide alert button title."))
        alert.runModal()
    }

    @objc func showFontPanel(_: Any?) {
        NSFontManager.shared.target = self
        NSApp.activate(ignoringOtherApps: true)
        let font = currentFont()
        NSFontManager.shared.setSelectedFont(font, isMultiple: false)
        var attrs: [String: Any] = [:]
        if preferences.underline {
            attrs[NSAttributedString.Key.underlineStyle.rawValue] = NSUnderlineStyle.single.rawValue
        }
        NSFontManager.shared.setSelectedAttributes(attrs, isMultiple: false)
        NSFontManager.shared.orderFrontFontPanel(self)
    }

    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        if item.action == #selector(selectOpacity(_:)) {
            return true
        }
        return true
    }

    @MainActor @objc func changeFont(_ sender: NSFontManager?) {
        guard let manager = sender else {
            return
        }
        let converted = manager.convert(currentFont())
        preferences.fontName = converted.fontName
        preferences.fontSize = converted.pointSize
        self.manager.controllers.forEach { $0.updateFont(converted) }
    }

    @objc func changeAttributes(_: Any?) {
        let fm = NSFontManager.shared
        var current: [String: Any] = [:]
        if preferences.underline {
            current[NSAttributedString.Key.underlineStyle.rawValue] = NSUnderlineStyle.single.rawValue
        }
        let converted = fm.convertAttributes(current)
        let underline: Bool
        if let style = converted[NSAttributedString.Key.underlineStyle.rawValue] as? Int {
            underline = style != 0
        } else {
            underline = false
        }
        preferences.underline = underline
        manager.controllers.forEach { $0.updateUnderline(underline) }
    }

    @objc func selectDragModifier(_ sender: Any?) {
        guard let menuItem = sender as? NSMenuItem,
              let modifier = menuItem.representedObject as? DragModifier
        else {
            return
        }
        preferences.dragModifier = modifier
        manager.controllers.forEach { $0.updateDragModifier(modifier.flags) }
        menuBuilder.updateModifierMenuSelection(modifier)
        updateInteraction(modifierFlags: currentModifierFlags())
    }

    @objc func selectTextColor(_ sender: Any?) {
        guard let menuItem = sender as? NSMenuItem,
              let color = menuItem.representedObject as? SignboardTextColor
        else {
            return
        }
        preferences.textColor = color
        if let controller = manager.currentTargetSignboardController() {
            controller.updateTextColor(color)
        } else {
            manager.controllers.first?.updateTextColor(color)
        }
        menuBuilder.updateTextColorMenusAfterSelection(menu: menuItem.menu, signboardID: manager.currentTargetSignboardController()?.signboard.id)
    }

    @objc func selectOpacity(_ sender: Any?) {
        guard let menuItem = sender as? NSMenuItem,
              let preset = menuItem.representedObject as? SignboardOpacityPreset
        else {
            return
        }
        let opacity = preset.rawValue
        if let controller = manager.currentTargetSignboardController() {
            controller.updateOpacity(opacity)
        } else {
            manager.controllers.first?.updateOpacity(opacity)
        }
        menuBuilder.updateOpacityMenusAfterSelection(menu: menuItem.menu, signboardID: manager.currentTargetSignboardController()?.signboard.id)
    }

    private func buildMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        appMenuItem.submenu = menuBuilder.makeAppMenu(appVersion: SignboardVersion.displayString())
        NSApp.mainMenu = mainMenu
    }

    private func buildStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "signpost.right", accessibilityDescription: L10n.tr("accessibility.status_item", comment: "Status item accessibility description."))
            button.imagePosition = .imageOnly
            button.title = ""
        }
        item.menu = menuBuilder.makeAppMenu(appVersion: SignboardVersion.displayString())
        statusItem = item
    }

    private func startModifierMonitoring() {
        updateInteraction(modifierFlags: currentModifierFlags())
        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            self?.updateInteraction(modifierFlags: event.modifierFlags)
        }
        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            self?.updateInteraction(modifierFlags: event.modifierFlags)
            return event
        }
    }

    private func currentModifierFlags() -> NSEvent.ModifierFlags {
        let flags = CGEventSource.flagsState(.combinedSessionState)
        return NSEvent.ModifierFlags(rawValue: UInt(flags.rawValue))
    }

    private func updateInteraction(modifierFlags: NSEvent.ModifierFlags) {
        let enabled = modifierFlags.contains(preferences.dragModifier.flags)
        guard enabled != isInteractionEnabled else {
            return
        }
        isInteractionEnabled = enabled
        manager.controllers.forEach { $0.setInteractionEnabled(enabled) }
    }

    private func refreshInteractionState() {
        updateInteraction(modifierFlags: currentModifierFlags())
    }

    func makeContextMenu(for signboardID: String) -> NSMenu {
        menuBuilder.makeContextMenu(for: signboardID)
    }

    private func makeSignboardController(for signboard: SignboardItem) -> SignboardController {
        let font = currentFont()
        let controller = SignboardController(
            store: store,
            signboard: signboard,
            font: font,
            underline: preferences.underline,
            dragModifier: preferences.dragModifier.flags
        )
        controller.menuProvider = { [weak self] in
            guard let self else { return nil }
            return self.makeContextMenu(for: signboard.id)
        }
        controller.onAnyMouseDown = { [weak self] in
            self?.setActiveSignboard(id: signboard.id)
        }
        controller.onMenuDismissed = { [weak self] in
            self?.refreshInteractionState()
        }
        return controller
    }

    private func confirmDeleteSignboard(text: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = L10n.tr("alert.delete_signboard.title", comment: "Delete signboard alert title.")
        alert.informativeText = String(
            format: L10n.tr("alert.delete_signboard.message", comment: "Delete signboard alert message with the signboard text."),
            locale: Locale.current,
            text
        )
        alert.addButton(withTitle: L10n.tr("alert.delete_signboard.button_delete", comment: "Delete signboard alert destructive button title."))
        alert.addButton(withTitle: L10n.tr("alert.delete_signboard.button_cancel", comment: "Delete signboard alert cancel button title."))
        return alert.runModal() == .alertFirstButtonReturn
    }

    private func confirmDeleteAll() -> Bool {
        let alert = NSAlert()
        alert.messageText = L10n.tr("alert.delete_all_signboards.title", comment: "Delete all signboards alert title.")
        alert.informativeText = L10n.tr("alert.delete_all_signboards.message", comment: "Delete all signboards alert message.")
        alert.addButton(withTitle: L10n.tr("alert.delete_all_signboards.button_delete_all", comment: "Delete all signboards alert destructive button title."))
        alert.addButton(withTitle: L10n.tr("alert.delete_all_signboards.button_cancel", comment: "Delete all signboards alert cancel button title."))
        return alert.runModal() == .alertFirstButtonReturn
    }

    private func removeSignboard(id: String) {
        let newActiveID = manager.removeSignboard(id: id)
        if manager.controllers.isEmpty {
            menuBuilder.refreshRootMenuSelections()
            return
        }
        if let newActiveID {
            menuBuilder.updateForActiveSignboard(id: newActiveID)
        }
    }

    private func removeAllSignboards() {
        manager.removeAllSignboards()
        menuBuilder.refreshRootMenuSelections()
    }

    private func currentFont() -> NSFont {
        let size = preferences.fontSize
        if let name = preferences.fontName, let font = NSFont(name: name, size: size) {
            return font
        }
        return NSFont.systemFont(ofSize: size, weight: .semibold)
    }

    private func setActiveSignboard(id: String) {
        manager.setActiveSignboard(id: id)
        menuBuilder.updateForActiveSignboard(id: id)
    }
}

extension AppDelegate {
    private func handleCommand(_ command: SignboardCommand) -> SignboardResponse {
        commandHandler.handle(command)
    }
}
