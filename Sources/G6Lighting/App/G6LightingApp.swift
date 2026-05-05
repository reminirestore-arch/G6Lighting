import SwiftUI
import AppKit

@main
struct G6LightingApp: App {
    @StateObject private var env = AppEnvironment.shared

    var body: some Scene {
        MenuBarExtra("G6 Lighting", systemImage: "lightbulb.circle") {
            ContentView()
                .environmentObject(env.settings)
                .environmentObject(env.viewModel)
                .environmentObject(env.viewModel.player)
                .environmentObject(env.autoLaunch)
        }
        .menuBarExtraStyle(.window)
    }
}
