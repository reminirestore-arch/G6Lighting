// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "G6Lighting",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "G6Lighting",
            path: "Sources/G6Lighting"
        ),
    ]
)
