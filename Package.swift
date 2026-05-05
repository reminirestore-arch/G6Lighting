// swift-tools-version:6.0
import PackageDescription
import Foundation

// swift-testing is bundled with full Xcode toolchains and the swift driver
// can find it without any extra flags. Command Line Tools-only setups have
// a Testing.framework but it's not on the default search path, so we have
// to point -F + rpath at it manually. Only do that when CLT is in use.
let cltFrameworkPath = "/Library/Developer/CommandLineTools/Library/Developer/Frameworks"
let cltInteropPath = "/Library/Developer/CommandLineTools/Library/Developer/usr/lib"
let xcodeFrameworkPath = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks"

let fm = FileManager.default
let hasXcodeTesting = fm.fileExists(atPath: xcodeFrameworkPath + "/Testing.framework")
let hasCLTTesting = fm.fileExists(atPath: cltFrameworkPath + "/Testing.framework")
let needsCLTFlags = !hasXcodeTesting && hasCLTTesting

let testSwiftSettings: [SwiftSetting]
let testLinkerSettings: [LinkerSetting]
if needsCLTFlags {
    testSwiftSettings = [.unsafeFlags(["-F", cltFrameworkPath])]
    testLinkerSettings = [.unsafeFlags([
        "-F", cltFrameworkPath,
        "-framework", "Testing",
        "-Xlinker", "-rpath", "-Xlinker", cltFrameworkPath,
        "-Xlinker", "-rpath", "-Xlinker", cltInteropPath,
    ])]
} else {
    testSwiftSettings = []
    testLinkerSettings = []
}

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
