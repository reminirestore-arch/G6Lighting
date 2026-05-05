import SwiftUI
import AppKit

@main
struct G6LightingApp: App {
    @StateObject private var settings = Settings()
    @StateObject private var engine: LightingEngine
    @StateObject private var autoLaunch = AutoLaunch()

    init() {
        let s = Settings()
        _settings = StateObject(wrappedValue: s)
        _engine = StateObject(wrappedValue: LightingEngine(settings: s))
    }

    var body: some Scene {
        MenuBarExtra("G6 Lighting", systemImage: "lightbulb.circle") {
            ContentView()
                .environmentObject(settings)
                .environmentObject(engine)
                .environmentObject(autoLaunch)
        }
        .menuBarExtraStyle(.window)
    }
}
