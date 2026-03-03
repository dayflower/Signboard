import Foundation

enum L10n {
    private static let tableName = "Localizable"
    private static let resourceBundleName = "Signboard_SignboardApp"
    private static let bundle: Bundle = {
        resolvedResourceBundle() ?? .main
    }()

    static func tr(_ key: String, comment: String) -> String {
        NSLocalizedString(key, tableName: tableName, bundle: bundle, value: key, comment: comment)
    }

    private static func resolvedResourceBundle() -> Bundle? {
        for candidateURL in candidateBundleURLs() {
            guard let candidateBundle = Bundle(url: candidateURL) else {
                continue
            }
            if hasLocalizations(in: candidateBundle) {
                return candidateBundle
            }
        }
        return nil
    }

    private static func candidateBundleURLs() -> [URL] {
        var bundleURLs: [URL] = []

        if let mainResourceURL = Bundle.main.resourceURL {
            bundleURLs.append(mainResourceURL.appendingPathComponent("\(resourceBundleName).bundle"))
        }

        bundleURLs.append(
            Bundle.main.bundleURL
                .appendingPathComponent("Contents")
                .appendingPathComponent("Resources")
                .appendingPathComponent("\(resourceBundleName).bundle")
        )

        bundleURLs.append(Bundle.main.bundleURL.appendingPathComponent("\(resourceBundleName).bundle"))

        if let executableURL = Bundle.main.executableURL {
            let executableDirectoryURL = executableURL.deletingLastPathComponent()
            bundleURLs.append(executableDirectoryURL.appendingPathComponent("\(resourceBundleName).bundle"))

            let contentsDirectoryURL = executableDirectoryURL.deletingLastPathComponent()
            bundleURLs.append(
                contentsDirectoryURL
                    .appendingPathComponent("Resources")
                    .appendingPathComponent("\(resourceBundleName).bundle")
            )
        }

        return uniqueExistingURLs(from: bundleURLs)
    }

    private static func uniqueExistingURLs(from urls: [URL]) -> [URL] {
        var uniqueURLs: [URL] = []
        var seenURLs = Set<URL>()

        for url in urls {
            let resolvedURL = url.resolvingSymlinksInPath()
            guard seenURLs.insert(resolvedURL).inserted else {
                continue
            }
            guard FileManager.default.fileExists(atPath: resolvedURL.path) else {
                continue
            }
            uniqueURLs.append(resolvedURL)
        }

        return uniqueURLs
    }

    private static func hasLocalizations(in bundle: Bundle) -> Bool {
        bundle.path(forResource: tableName, ofType: "strings", inDirectory: nil, forLocalization: "en") != nil ||
            bundle.path(forResource: "en", ofType: "lproj") != nil
    }
}
