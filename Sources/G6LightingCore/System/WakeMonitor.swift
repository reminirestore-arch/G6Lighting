import Foundation
import AppKit

/// Watches for system wake-from-sleep so dependents can resend device state.
public final class WakeMonitor: @unchecked Sendable {
    private let observer: NSObjectProtocol

    public init(onWake: @escaping @Sendable () -> Void) {
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
