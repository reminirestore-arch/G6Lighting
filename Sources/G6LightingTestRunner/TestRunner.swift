// Executable test runner for environments without Xcode.
// `swift test` on a Command Line Tools-only setup builds a Mach-O bundle that
// cannot be executed directly, so swift-testing's __swiftPMEntryPoint() never
// gets a chance to print results. This target re-uses the same @Test functions
// and exposes them through a normal executable that prints to stdout.
//
// Run with: swift run G6LightingTestRunner

import Testing

@main
struct TestRunner {
    static func main() async {
        await Testing.__swiftPMEntryPoint() as Never
    }
}
