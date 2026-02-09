import Foundation

public enum SignboardNotification {
    public static let requestName = Notification.Name("SignboardApp.Command")
    public static let responseName = Notification.Name("SignboardApp.Response")

    private static let requestIDKey = "request_id"
    private static let actionKey = "action"
    private static let idKey = "id"
    private static let textKey = "text"
    private static let allKey = "all"

    private static let codeKey = "code"
    private static let outputKey = "output"
    private static let errorKey = "error"

    public static func makeCommandUserInfo(_ command: SignboardCommand, requestID: String) -> [String: Any] {
        var userInfo: [String: Any] = [
            requestIDKey: requestID,
            actionKey: command.actionRaw,
            allKey: command.all,
        ]
        if let id = command.id {
            userInfo[idKey] = id
        }
        if let text = command.text {
            userInfo[textKey] = text
        }
        return userInfo
    }

    public static func parseCommand(_ userInfo: [AnyHashable: Any]) -> (requestID: String, command: SignboardCommand)? {
        guard let requestID = userInfo[requestIDKey] as? String,
              let actionRaw = userInfo[actionKey] as? String
        else {
            return nil
        }
        let id = userInfo[idKey] as? String
        let text = userInfo[textKey] as? String
        let all = (userInfo[allKey] as? Bool) ?? false
        let command = SignboardCommand(actionRaw: actionRaw, id: id, text: text, all: all)
        return (requestID, command)
    }

    public static func makeResponseUserInfo(_ response: SignboardResponse, requestID: String) -> [String: Any] {
        var userInfo: [String: Any] = [
            requestIDKey: requestID,
            codeKey: response.code,
        ]
        if let output = response.output {
            userInfo[outputKey] = output
        }
        if let error = response.error {
            userInfo[errorKey] = error
        }
        return userInfo
    }

    public static func parseResponse(_ userInfo: [AnyHashable: Any]) -> (requestID: String, response: SignboardResponse)? {
        guard let requestID = userInfo[requestIDKey] as? String,
              let code = userInfo[codeKey] as? Int
        else {
            return nil
        }
        let output = userInfo[outputKey] as? String
        let error = userInfo[errorKey] as? String
        let response = SignboardResponse(code: code, output: output, error: error)
        return (requestID, response)
    }
}
