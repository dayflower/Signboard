import Foundation
import SignboardCore

private func printUsage() {
    let message = """
    Usage:
      signboard --version
      signboard create [-i id] <text>
      signboard update -i <id> <text>
      signboard delete -i <id>
      signboard delete-all
      signboard hide-all
      signboard show-all
      signboard list
    """
    fputs(message, stderr)
}

private func fail(_ message: String, code: Int = 1) -> Never {
    fputs(message + "\n", stderr)
    exit(Int32(code))
}

private func parseCreate(_ args: [String]) -> SignboardCommand? {
    var id: String?
    var textParts: [String] = []
    var index = 0
    while index < args.count {
        let arg = args[index]
        if arg == "-i" {
            guard index + 1 < args.count else {
                return nil
            }
            id = args[index + 1]
            index += 2
            continue
        }
        textParts.append(arg)
        index += 1
    }
    guard !textParts.isEmpty else {
        return nil
    }
    return SignboardCommand(action: .create, id: id, text: textParts.joined(separator: " "))
}

private func parseUpdate(_ args: [String]) -> SignboardCommand? {
    var id: String?
    var textParts: [String] = []
    var index = 0
    while index < args.count {
        let arg = args[index]
        if arg == "-i" {
            guard index + 1 < args.count else {
                return nil
            }
            id = args[index + 1]
            index += 2
            continue
        }
        textParts.append(arg)
        index += 1
    }
    guard let id, !id.isEmpty else {
        return nil
    }
    guard !textParts.isEmpty else {
        return nil
    }
    return SignboardCommand(action: .update, id: id, text: textParts.joined(separator: " "))
}

private func parseHideAll(_ args: [String]) -> SignboardCommand? {
    guard args.isEmpty else {
        return nil
    }
    return SignboardCommand(action: .hide)
}

private func parseDelete(_ args: [String]) -> SignboardCommand? {
    guard args.count == 2, args[0] == "-i" else {
        return nil
    }
    let id = args[1].trimmingCharacters(in: .whitespacesAndNewlines)
    guard !id.isEmpty else {
        return nil
    }
    return SignboardCommand(action: .delete, id: id, all: false)
}

private func parseDeleteAll(_ args: [String]) -> SignboardCommand? {
    guard args.isEmpty else {
        return nil
    }
    return SignboardCommand(action: .delete, all: true)
}

private func parseShowAll(_ args: [String]) -> SignboardCommand? {
    guard args.isEmpty else {
        return nil
    }
    return SignboardCommand(action: .show)
}

private func parseList(_ args: [String]) -> SignboardCommand? {
    guard args.isEmpty else {
        return nil
    }
    return SignboardCommand(action: .list)
}

private func sendCommand(_ command: SignboardCommand) -> SignboardResponse {
    let center = DistributedNotificationCenter.default()
    let requestID = UUID().uuidString
    let userInfo = SignboardNotification.makeCommandUserInfo(command, requestID: requestID)

    var response: SignboardResponse?
    let semaphore = DispatchSemaphore(value: 0)
    let observer = center.addObserver(forName: SignboardNotification.responseName, object: nil, queue: nil) { note in
        guard let userInfo = note.userInfo,
              let parsed = SignboardNotification.parseResponse(userInfo),
              parsed.requestID == requestID
        else {
            return
        }
        response = parsed.response
        semaphore.signal()
    }

    center.postNotificationName(SignboardNotification.requestName, object: nil, userInfo: userInfo, deliverImmediately: true)

    let timeoutDate = Date().addingTimeInterval(2.0)
    while Date() < timeoutDate {
        if semaphore.wait(timeout: .now()) == .success {
            break
        }
        RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.02))
    }

    center.removeObserver(observer)

    if let response {
        return response
    }
    return SignboardResponse.failure(code: 3, message: "SignboardApp is not running.")
}

let arguments = Array(CommandLine.arguments.dropFirst())
if arguments.isEmpty {
    printUsage()
    exit(Int32(1))
}

if arguments.count == 1, arguments[0] == "--version" || arguments[0] == "-v" {
    print(SignboardVersion.displayString())
    exit(Int32(0))
}

let commandName = arguments[0]
let commandArgs = Array(arguments.dropFirst())
let command: SignboardCommand?

switch commandName {
case "create":
    command = parseCreate(commandArgs)
case "update":
    command = parseUpdate(commandArgs)
case "delete":
    command = parseDelete(commandArgs)
case "delete-all":
    command = parseDeleteAll(commandArgs)
case "hide-all":
    command = parseHideAll(commandArgs)
case "show-all":
    command = parseShowAll(commandArgs)
case "list":
    command = parseList(commandArgs)
default:
    command = nil
}

guard let command else {
    printUsage()
    exit(Int32(1))
}

let response = sendCommand(command)
if let error = response.error {
    fail(error, code: response.code)
}

if let output = response.output, !output.isEmpty {
    print(output)
}

exit(Int32(response.code))
