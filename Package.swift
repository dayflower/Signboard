// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Signboard",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SignboardApp", targets: ["SignboardApp"]),
        .executable(name: "signboard", targets: ["signboard"])
    ],
    targets: [
        .target(
            name: "SignboardCore",
            dependencies: []
        ),
        .executableTarget(
            name: "SignboardApp",
            dependencies: ["SignboardCore"],
            path: "Sources/SignboardApp",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "signboard",
            dependencies: ["SignboardCore"],
            path: "Sources/signboard"
        )
    ]
)
