import Foundation

/// Composition root: instantiates and wires every long-lived dependency.
/// Replacing this with a different factory (e.g. injecting a MockHIDTransport
/// for screenshots/UI tests) is the only thing needed to run the app off-device.
@MainActor
final class AppEnvironment: ObservableObject {
    let settings: SettingsStore
    let viewModel: LightingViewModel
    let autoLaunch: AutoLaunch

    init(
        settings: SettingsStore? = nil,
        device: G6Device = .makeReal()
    ) {
        let s = settings ?? SettingsStore()
        self.settings = s
        self.viewModel = LightingViewModel(settings: s, device: device)
        self.autoLaunch = AutoLaunch()
    }

    static let shared = AppEnvironment()
}
