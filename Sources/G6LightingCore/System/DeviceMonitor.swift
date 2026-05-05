import Foundation
import IOKit
import IOKit.hid

/// Watches USB enumeration for the G6 and reports connect/disconnect events.
/// Lives for the lifetime of the app; clients subscribe via the closure.
public final class DeviceMonitor: @unchecked Sendable {
    public enum Event: Sendable {
        case connected
        case disconnected
    }

    private let manager: IOHIDManager
    private let onEvent: @Sendable (Event) -> Void

    public init(vendorID: UInt16, productID: UInt16, onEvent: @escaping @Sendable (Event) -> Void) {
        self.onEvent = onEvent

        let mgr = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let matching: [String: Any] = [
            kIOHIDVendorIDKey: Int(vendorID),
            kIOHIDProductIDKey: Int(productID),
        ]
        IOHIDManagerSetDeviceMatching(mgr, matching as CFDictionary)
        IOHIDManagerScheduleWithRunLoop(mgr, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerOpen(mgr, IOOptionBits(kIOHIDOptionsTypeNone))
        self.manager = mgr

        let context = Unmanaged.passUnretained(self).toOpaque()

        let matchedCallback: IOHIDDeviceCallback = { ctx, _, _, _ in
            guard let ctx = ctx else { return }
            let monitor = Unmanaged<DeviceMonitor>.fromOpaque(ctx).takeUnretainedValue()
            monitor.onEvent(.connected)
        }
        let removedCallback: IOHIDDeviceCallback = { ctx, _, _, _ in
            guard let ctx = ctx else { return }
            let monitor = Unmanaged<DeviceMonitor>.fromOpaque(ctx).takeUnretainedValue()
            monitor.onEvent(.disconnected)
        }
        IOHIDManagerRegisterDeviceMatchingCallback(mgr, matchedCallback, context)
        IOHIDManagerRegisterDeviceRemovalCallback(mgr, removedCallback, context)
    }

    deinit {
        IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }
}
