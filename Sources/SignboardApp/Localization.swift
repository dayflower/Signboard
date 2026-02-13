import Foundation

enum L10n {
    private static let tableName = "Localizable"
    private static let resourceBundleName = "Signboard_SignboardApp"
    private static let bundle: Bundle = {
        for candidate in candidateBundles() {
            if hasLocalizations(in: candidate) {
                return candidate
            }
        }
        return .module
    }()

    static func tr(_ key: String, comment: String) -> String {
        NSLocalizedString(key, tableName: tableName, bundle: bundle, value: key, comment: comment)
    }

    private static func candidateBundles() -> [Bundle] {
        var bundles: [Bundle] = [.module, .main]

        if let mainResourceURL = Bundle.main.resourceURL {
            let nestedResourceBundleURL = mainResourceURL.appendingPathComponent("\(resourceBundleName).bundle")
            if let nestedResourceBundle = Bundle(url: nestedResourceBundleURL) {
                bundles.append(nestedResourceBundle)
            }
        }

        if let executableURL = Bundle.main.executableURL {
            let resourcesURL = executableURL
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Resources")
            let nestedResourceBundleURL = resourcesURL.appendingPathComponent("\(resourceBundleName).bundle")
            if let nestedResourceBundle = Bundle(url: nestedResourceBundleURL) {
                bundles.append(nestedResourceBundle)
            }
        }

        var uniqueBundles: [Bundle] = []
        var seenURLs = Set<URL>()

        for bundle in bundles {
            let resolvedURL = bundle.bundleURL.resolvingSymlinksInPath()
            if seenURLs.insert(resolvedURL).inserted {
                uniqueBundles.append(bundle)
            }
        }

        return uniqueBundles
    }

    private static func hasLocalizations(in bundle: Bundle) -> Bool {
        bundle.path(forResource: tableName, ofType: "strings", inDirectory: nil, forLocalization: "en") != nil ||
            bundle.path(forResource: "en", ofType: "lproj") != nil
    }
}
