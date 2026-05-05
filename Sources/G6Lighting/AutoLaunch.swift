import Foundation
import ServiceManagement

@MainActor
final class AutoLaunch: ObservableObject {
    @Published private(set) var isEnabled: Bool = false
    @Published private(set) var lastError: String?

    init() {
        refresh()
    }

    func refresh() {
        if #available(macOS 13.0, *) {
            isEnabled = (SMAppService.mainApp.status == .enabled)
        } else {
            isEnabled = false
        }
    }

    func setEnabled(_ enabled: Bool) {
        guard #available(macOS 13.0, *) else {
            lastError = "Auto-launch requires macOS 13 or later."
            return
        }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        refresh()
    }
}
