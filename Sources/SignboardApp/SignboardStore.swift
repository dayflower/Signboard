import AppKit
import Foundation

struct SignboardItem: Codable {
    let id: String
    var text: String
    var frame: StoredRect
    var opacity: Double
    var textColor: String

    init(id: String, text: String, frame: StoredRect, opacity: Double, textColor: String = SignboardTextColor.white.rawValue) {
        self.id = id
        self.text = text
        self.frame = frame
        self.opacity = opacity
        self.textColor = textColor
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        frame = try container.decode(StoredRect.self, forKey: .frame)
        opacity = try container.decode(Double.self, forKey: .opacity)
        textColor = try container.decodeIfPresent(String.self, forKey: .textColor) ?? SignboardTextColor.white.rawValue
    }
}

struct StoredRect: Codable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    init(_ rect: NSRect) {
        x = rect.origin.x
        y = rect.origin.y
        width = rect.size.width
        height = rect.size.height
    }

    var nsRect: NSRect {
        NSRect(x: x, y: y, width: width, height: height)
    }
}

final class SignboardStore {
    private let key = "signboard.signboards"
    private let defaults = UserDefaults.standard

    func hasSignboardItems() -> Bool {
        return defaults.object(forKey: key) != nil
    }

    func load() -> [SignboardItem] {
        guard let data = defaults.data(forKey: key) else {
            return []
        }
        do {
            return try JSONDecoder().decode([SignboardItem].self, from: data)
        } catch {
            return []
        }
    }

    func save(_ signboards: [SignboardItem]) {
        do {
            let data = try JSONEncoder().encode(signboards)
            defaults.set(data, forKey: key)
        } catch {
            return
        }
    }

    func upsert(_ signboard: SignboardItem) {
        var signboards = load()
        if let index = signboards.firstIndex(where: { $0.id == signboard.id }) {
            signboards[index] = signboard
        } else {
            signboards.append(signboard)
        }
        save(signboards)
    }

    func delete(id: String) {
        var signboards = load()
        signboards.removeAll { $0.id == id }
        save(signboards)
    }

    func deleteAll() {
        save([])
    }
}
