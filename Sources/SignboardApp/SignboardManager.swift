import AppKit
import SignboardCore

final class SignboardManager {
    private let store: SignboardStore
    private let preferences: AppPreferences

    private(set) var controllers: [SignboardController] = []
    private(set) var lastActiveSignboardID: String?

    init(store: SignboardStore, preferences: AppPreferences) {
        self.store = store
        self.preferences = preferences
    }

    func loadInitialSignboards(makeController: (SignboardItem) -> SignboardController) {
        let storedSignboards = store.load()
        let hasSignboardItems = store.hasSignboardItems()
        let signboards = storedSignboards.isEmpty && !hasSignboardItems ? [makeDefaultSignboard(index: 0)] : storedSignboards
        if storedSignboards.isEmpty, !hasSignboardItems {
            store.save(signboards)
        }
        controllers = signboards.map(makeController)
        lastActiveSignboardID = controllers.first?.signboard.id
    }

    func setActiveSignboard(id: String) {
        lastActiveSignboardID = id
    }

    func signboardController(for id: String) -> SignboardController? {
        controllers.first(where: { $0.signboard.id == id })
    }

    func currentTargetSignboardController() -> SignboardController? {
        if let signboardID = lastActiveSignboardID,
           let controller = signboardController(for: signboardID)
        {
            return controller
        }
        return controllers.first
    }

    @discardableResult
    func createDefaultSignboard(makeController: (SignboardItem) -> SignboardController, isVisible: Bool) -> SignboardController {
        let signboard = makeDefaultSignboard(index: controllers.count)
        return createSignboard(signboard, makeController: makeController, isVisible: isVisible)
    }

    @discardableResult
    func createSignboard(id: String, text: String, makeController: (SignboardItem) -> SignboardController, isVisible: Bool) -> SignboardController {
        let signboard = makeSignboard(id: id, text: text, index: controllers.count)
        return createSignboard(signboard, makeController: makeController, isVisible: isVisible)
    }

    @discardableResult
    func removeSignboard(id: String) -> String? {
        guard let index = controllers.firstIndex(where: { $0.signboard.id == id }) else { return lastActiveSignboardID }
        let controller = controllers.remove(at: index)
        controller.close()
        store.delete(id: id)

        if controllers.isEmpty {
            lastActiveSignboardID = nil
            return nil
        }

        if lastActiveSignboardID == id {
            let nextIndex = min(index, controllers.count - 1)
            let nextID = controllers[nextIndex].signboard.id
            lastActiveSignboardID = nextID
        }

        return lastActiveSignboardID
    }

    func removeAllSignboards() {
        for controller in controllers {
            controller.close()
        }
        controllers.removeAll()
        store.deleteAll()
        lastActiveSignboardID = nil
    }

    func applyVisibility(_ visible: Bool) {
        if visible {
            controllers.forEach { $0.show() }
        } else {
            controllers.forEach { $0.hide() }
        }
    }

    func listLines() -> [String] {
        controllers.map { controller in
            "\(controller.signboard.id) \(SignboardText.listSafe(controller.signboard.text))"
        }
    }

    private func createSignboard(_ signboard: SignboardItem, makeController: (SignboardItem) -> SignboardController, isVisible: Bool) -> SignboardController {
        let controller = makeController(signboard)
        controllers.append(controller)
        store.upsert(signboard)
        if isVisible {
            controller.show()
        } else {
            controller.hide()
        }
        return controller
    }

    private func makeDefaultSignboard(index: Int) -> SignboardItem {
        makeSignboard(
            id: SignboardText.shortUUID(),
            text: String(
                format: L10n.tr("signboard.default_name", comment: "Default signboard name with index."),
                locale: Locale.current,
                index + 1
            ),
            index: index
        )
    }

    private func makeSignboard(id: String, text: String, index: Int) -> SignboardItem {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let offset = CGFloat(index) * SignboardLayout.cascadeOffset
        let initialFrame = NSRect(
            x: screenFrame.minX + SignboardLayout.baseOffsetX + offset,
            y: screenFrame.maxY - SignboardLayout.baseOffsetY - offset,
            width: SignboardLayout.defaultSize.width,
            height: SignboardLayout.defaultSize.height
        )
        return SignboardItem(
            id: id,
            text: text,
            frame: StoredRect(initialFrame),
            opacity: 1.0,
            textColor: preferences.textColor.rawValue
        )
    }
}
