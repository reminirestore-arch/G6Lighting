// swift-tools-version:6.0
import PackageDescription
import Foundation

// swift-testing's Testing.framework lives in different places depending on
// whether the toolchain is Command Line Tools (no Xcode) or full Xcode.
// Detect the right -F search path and the right rpath to lib_TestingInterop.dylib
// at evaluation time so this Package.swift works in both environments
// (local CLT, GitHub Actions macOS runner with Xcode, etc.).
let frameworkPathCandidates = [
    "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
    "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks",
]
let interopPathCandidates = [
    "/Library/Developer/CommandLineTools/Library/Developer/usr/lib",
    "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib",
]
let fm = FileManager.default
let testFrameworkPath = frameworkPathCandidates.first(where: {
    fm.fileExists(atPath: $0 + "/Testing.framework")
}) ?? frameworkPathCandidates[0]
let testInteropPath = interopPathCandidates.first(where: {
    fm.fileExists(atPath: $0 + "/lib_TestingInterop.dylib")
}) ?? interopPathCandidates[0]

let testSwiftSettings: [SwiftSetting] = [
    .unsafeFlags(["-F", testFrameworkPath])
]
let testLinkerSettings: [LinkerSetting] = [
    .unsafeFlags([
        "-F", testFrameworkPath,
        "-framework", "Testing",
        "-Xlinker", "-rpath", "-Xlinker", testFrameworkPath,
        "-Xlinker", "-rpath", "-Xlinker", testInteropPath,
    ])
]

let package = Package(
    name: "G6Lighting",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "G6Lighting", targets: ["G6Lighting"]),
        .library(name: "G6LightingCore", targets: ["G6LightingCore"]),
    ],
    targets: [
        .target(
            name: "G6LightingCore",
            path: "Sources/G6LightingCore"
        ),
        .executableTarget(
            name: "G6Lighting",
            dependencies: ["G6LightingCore"],
            path: "Sources/G6Lighting"
        ),
        // Executable test runner — works on Command Line Tools-only setups
        // where SwiftPM's standard test bundle can't be exec()'d. Run with:
        //   swift run G6LightingTestRunner --testing-library swift-testing
        .executableTarget(
            name: "G6LightingTestRunner",
            dependencies: ["G6LightingCore"],
            path: "Sources/G6LightingTestRunner",
            swiftSettings: testSwiftSettings,
            linkerSettings: testLinkerSettings
        ),
    ]
)
