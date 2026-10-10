// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "YouTubeCleaner",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "YouTubeCleaner", targets: ["YouTubeCleanerApp"]),
    ],
    targets: [
        .target(
            name: "YouTubeCleanerCore"
        ),
        .executableTarget(
            name: "YouTubeCleanerApp",
            dependencies: ["YouTubeCleanerCore"]
        ),
        .testTarget(
            name: "YouTubeCleanerCoreTests",
            dependencies: ["YouTubeCleanerCore"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
