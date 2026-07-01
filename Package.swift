// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Cork",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Cork", targets: ["Cork"]),
        .library(name: "CorkCore", targets: ["CorkCore"])
    ],
    targets: [
        .executableTarget(
            name: "Cork",
            dependencies: ["CorkCore"],
            path: "Sources/Cork"
        ),
        .target(
            name: "CorkCore",
            path: "Sources/CorkCore"
        ),
        .testTarget(
            name: "CorkCoreTests",
            dependencies: ["CorkCore"],
            path: "Tests/CorkCoreTests"
        )
    ],
    swiftLanguageModes: [.v5]
)
