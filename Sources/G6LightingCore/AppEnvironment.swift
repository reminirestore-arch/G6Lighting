import Foundation

/// Composition root: instantiates and wires every long-lived dependency.
/// Replacing this with a different factory (e.g. injecting a MockHIDTransport
/// for screenshots/UI tests) is the only thing needed to run the app off-device.
@MainActor
public final class AppEnvironment: ObservableObject {
    public let settings: SettingsStore
    public let viewModel: LightingViewModel
    public let autoLaunch: AutoLaunch

    public init(
        settings: SettingsStore? = nil,
        device: G6Device = .makeReal()
    ) {
        let s = settings ?? SettingsStore()
        self.settings = s
        self.viewModel = LightingViewModel(settings: s, device: device)
        self.autoLaunch = AutoLaunch()
    }

    public static let shared = AppEnvironment()
}
