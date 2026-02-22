import Foundation
import SignboardCore

final class SignboardCommandHandler {
    private let manager: SignboardManager
    private let makeController: (SignboardItem) -> SignboardController
    private let setVisibility: (Bool) -> Void
    private let isVisible: () -> Bool

    init(
        manager: SignboardManager,
        makeController: @escaping (SignboardItem) -> SignboardController,
        setVisibility: @escaping (Bool) -> Void,
        isVisible: @escaping () -> Bool
    ) {
        self.manager = manager
        self.makeController = makeController
        self.setVisibility = setVisibility
        self.isVisible = isVisible
    }

    func handle(_ command: SignboardCommand) -> SignboardResponse {
        guard let action = command.action else {
            return SignboardResponse.failure(code: 1, message: "Unknown command.")
        }
        switch action {
        case .create:
            return handleCreate(command)
        case .update:
            return handleUpdate(command)
        case .delete:
            return handleDelete(command)
        case .hide:
            return handleHide(command)
        case .show:
            return handleShow(command)
        case .list:
            return handleList(command)
        }
    }

    private func handleCreate(_ command: SignboardCommand) -> SignboardResponse {
        guard let text = command.text, !text.isEmpty else {
            return SignboardResponse.failure(code: 1, message: "Text is required.")
        }
        let trimmedID = command.id?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let id = trimmedID, !id.isEmpty, let controller = manager.signboardController(for: id) {
            controller.updateTextFromCommand(text)
            return SignboardResponse.ok("updated \(id)")
        }

        let resolvedID = (trimmedID?.isEmpty == false) ? trimmedID! : SignboardText.shortUUID()
        let controller = manager.createSignboard(id: resolvedID, text: text, makeController: makeController, isVisible: isVisible())
        return SignboardResponse.ok("created \(controller.signboard.id)")
    }

    private func handleUpdate(_ command: SignboardCommand) -> SignboardResponse {
        guard let id = command.id, !id.isEmpty else {
            return SignboardResponse.failure(code: 1, message: "ID is required.")
        }
        guard let text = command.text, !text.isEmpty else {
            return SignboardResponse.failure(code: 1, message: "Text is required.")
        }
        guard let controller = manager.signboardController(for: id) else {
            return SignboardResponse.failure(code: 2, message: "Unknown id: \(id)")
        }
        controller.updateTextFromCommand(text)
        return SignboardResponse.ok("updated \(id)")
    }

    private func handleHide(_ command: SignboardCommand) -> SignboardResponse {
        _ = command
        setVisibility(false)
        return SignboardResponse.ok("hidden")
    }

    private func handleDelete(_ command: SignboardCommand) -> SignboardResponse {
        if command.all {
            let count = manager.controllers.count
            manager.removeAllSignboards()
            return SignboardResponse.ok("deleted-all \(count)")
        }

        guard let id = command.id?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty else {
            return SignboardResponse.failure(code: 1, message: "ID is required.")
        }
        guard manager.signboardController(for: id) != nil else {
            return SignboardResponse.failure(code: 2, message: "Unknown id: \(id)")
        }
        manager.removeSignboard(id: id)
        return SignboardResponse.ok("deleted \(id)")
    }

    private func handleShow(_ command: SignboardCommand) -> SignboardResponse {
        _ = command
        setVisibility(true)
        return SignboardResponse.ok("shown")
    }

    private func handleList(_: SignboardCommand) -> SignboardResponse {
        let lines = manager.listLines()
        return SignboardResponse.ok(lines.joined(separator: "\n"))
    }
}
