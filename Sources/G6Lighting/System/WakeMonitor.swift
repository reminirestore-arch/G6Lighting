import Foundation
import AppKit

/// Watches for system wake-from-sleep so dependents can resend device state.
final class WakeMonitor {
    private let observer: NSObjectProtocol

    init(onWake: @escaping () -> Void) {
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main,
            using: { _ in onWake() }
        )
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(observer)
    }
}
