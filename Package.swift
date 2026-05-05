// swift-tools-version:6.0
import PackageDescription

// swift-testing on a Command Line Tools-only setup (no Xcode) needs:
//   1. The Testing.framework search path (-F) at compile + link time.
//   2. Two rpaths so the framework + lib_TestingInterop.dylib resolve at runtime.
//   3. An executable target for actually running the tests, because SwiftPM's
//      generated test bundle is a Mach-O bundle that cannot be exec()'d directly.
let testFrameworkPath = "/Library/Developer/CommandLineTools/Library/Developer/Frameworks"
let testInteropPath = "/Library/Developer/CommandLineTools/Library/Developer/usr/lib"

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
        .executableTarget(
            name: "G6LightingTestRunner",
            dependencies: ["G6LightingCore"],
            path: "Sources/G6LightingTestRunner",
            swiftSettings: testSwiftSettings,
            linkerSettings: testLinkerSettings
        ),
    ]
)
