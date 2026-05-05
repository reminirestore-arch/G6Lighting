import Foundation
import IOKit
import IOKit.hid

enum G6ControllerError: Error, LocalizedError {
    case deviceNotFound
    case openFailed(IOReturn)
    case sendFailed(IOReturn)

    var errorDescription: String? {
        switch self {
        case .deviceNotFound:
            return "Sound BlasterX G6 (vendor HID interface) not found. Is the device connected?"
        case .openFailed(let r):
            return "Failed to open G6 HID interface (IOReturn 0x\(String(r, radix: 16)))."
        case .sendFailed(let r):
            return "Failed to send HID report (IOReturn 0x\(String(r, radix: 16)))."
        }
    }
}

final class G6Controller: @unchecked Sendable {
    private let queue = DispatchQueue(label: "g6.controller", qos: .userInitiated)

    func setColor(red: UInt8, green: UInt8, blue: UInt8, brightness: UInt8) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            queue.async {
                do {
                    try self.sendFramesSync(G6Protocol.setRgbFrames(red: red, green: green, blue: blue, brightness: brightness))
                    cont.resume()
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    func disable() async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            queue.async {
                do {
                    try self.sendFramesSync([G6Protocol.disablePacket()])
                    cont.resume()
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    func setRingLed(enabled: Bool) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            queue.async {
                do {
                    try self.sendFramesSync(G6Protocol.ringLedFrames(enabled: enabled))
                    cont.resume()
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    private func sendFramesSync(_ frames: [[UInt8]]) throws {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let matching: [String: Any] = [
            kIOHIDVendorIDKey: Int(G6Protocol.vendorID),
            kIOHIDProductIDKey: Int(G6Protocol.productID),
        ]
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)

        let mgrOpen = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        guard mgrOpen == kIOReturnSuccess else {
            throw G6ControllerError.openFailed(mgrOpen)
        }
        defer { IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone)) }

        guard let devicesSet = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else {
            throw G6ControllerError.deviceNotFound
        }

        let candidate = devicesSet.first { device in
            guard let pageNum = IOHIDDeviceGetProperty(device, kIOHIDPrimaryUsagePageKey as CFString) as? Int else {
                return false
            }
            return UInt32(pageNum) == G6Protocol.targetUsagePage
        }

        guard let device = candidate else {
            throw G6ControllerError.deviceNotFound
        }

        let devOpen = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
        guard devOpen == kIOReturnSuccess else {
            throw G6ControllerError.openFailed(devOpen)
        }
        defer { IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone)) }

        for frame in frames {
            try frame.withUnsafeBufferPointer { buf in
                guard let baseAddr = buf.baseAddress else {
                    throw G6ControllerError.sendFailed(kIOReturnInternalError)
                }
                let result = IOHIDDeviceSetReport(
                    device,
                    kIOHIDReportTypeOutput,
                    0,
                    baseAddr,
                    buf.count
                )
                if result != kIOReturnSuccess {
                    throw G6ControllerError.sendFailed(result)
                }
            }
        }
    }
}
