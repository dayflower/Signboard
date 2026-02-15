import Foundation

public enum SignboardVersion {
    public static let current = "0.1.1"

    public static func displayString(bundle: Bundle = .main) -> String {
        if let fromBundle = displayStringIfPresent(in: bundle) {
            return fromBundle
        }

        if let appBundle = enclosingAppBundle(),
            appBundle.bundleURL != bundle.bundleURL,
            let fromAppBundle = displayStringIfPresent(in: appBundle)
        {
            return fromAppBundle
        }

        return current
    }

    private static func displayStringIfPresent(in bundle: Bundle) -> String? {
        let shortVersion =
            bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let buildVersion = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        if let shortVersion, !shortVersion.isEmpty {
            if let buildVersion, !buildVersion.isEmpty, buildVersion != shortVersion {
                return "\(shortVersion) (\(buildVersion))"
            }
            return shortVersion
        }

        if let buildVersion, !buildVersion.isEmpty {
            return buildVersion
        }

        return nil
    }

    private static func enclosingAppBundle() -> Bundle? {
        guard let executableURL = Bundle.main.executableURL?.resolvingSymlinksInPath() else {
            return nil
        }

        var candidateURL = executableURL.deletingLastPathComponent()
        while candidateURL.path != "/" {
            if candidateURL.pathExtension == "app" {
                return Bundle(url: candidateURL)
            }
            let parentURL = candidateURL.deletingLastPathComponent()
            if parentURL.path == candidateURL.path {
                break
            }
            candidateURL = parentURL
        }
        return nil
    }
}

public enum SignboardAction: String {
    case create
    case update
    case hide
    case show
    case list
}

public final class SignboardCommand: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool {
        true
    }

    public let actionRaw: String
    public let id: String?
    public let text: String?
    public let all: Bool

    public var action: SignboardAction? {
        SignboardAction(rawValue: actionRaw)
    }

    public init(action: SignboardAction, id: String? = nil, text: String? = nil, all: Bool = false)
    {
        actionRaw = action.rawValue
        self.id = id
        self.text = text
        self.all = all
        super.init()
    }

    public init(actionRaw: String, id: String? = nil, text: String? = nil, all: Bool = false) {
        self.actionRaw = actionRaw
        self.id = id
        self.text = text
        self.all = all
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard let actionRaw = coder.decodeObject(of: NSString.self, forKey: "actionRaw") as String?
        else {
            return nil
        }
        self.actionRaw = actionRaw
        id = coder.decodeObject(of: NSString.self, forKey: "id") as String?
        text = coder.decodeObject(of: NSString.self, forKey: "text") as String?
        all = coder.decodeBool(forKey: "all")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(actionRaw, forKey: "actionRaw")
        coder.encode(id, forKey: "id")
        coder.encode(text, forKey: "text")
        coder.encode(all, forKey: "all")
    }
}

public final class SignboardResponse: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool {
        true
    }

    public let code: Int
    public let output: String?
    public let error: String?

    public init(code: Int, output: String? = nil, error: String? = nil) {
        self.code = code
        self.output = output
        self.error = error
        super.init()
    }

    public required init?(coder: NSCoder) {
        code = coder.decodeInteger(forKey: "code")
        output = coder.decodeObject(of: NSString.self, forKey: "output") as String?
        error = coder.decodeObject(of: NSString.self, forKey: "error") as String?
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(code, forKey: "code")
        coder.encode(output, forKey: "output")
        coder.encode(error, forKey: "error")
    }

    public static func ok(_ output: String? = nil) -> SignboardResponse {
        SignboardResponse(code: 0, output: output)
    }

    public static func failure(code: Int, message: String) -> SignboardResponse {
        SignboardResponse(code: code, error: message)
    }
}

public enum SignboardText {
    public static func shortUUID() -> String {
        String(UUID().uuidString.prefix(8)).lowercased()
    }

    public static func listSafe(_ text: String) -> String {
        text.replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
    }
}
