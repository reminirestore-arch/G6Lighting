import Foundation
import IOKit
import IOKit.hid

/// Real macOS implementation: opens the matching device via IOHIDManager and writes
/// each report as an Output SET_REPORT control transfer. Stateless across calls
/// (manager + device opened/closed per send burst), matching the original behaviour
/// that already proved reliable on the user's hardware.
final class IOKitHIDTransport: HIDTransport, @unchecked Sendable {
    let vendorID: UInt16
    let productID: UInt16
    let usagePage: UInt32

    private let queue = DispatchQueue(label: "g6.transport", qos: .userInitiated)

    init(vendorID: UInt16, productID: UInt16, usagePage: UInt32) {
        self.vendorID = vendorID
        self.productID = productID
        self.usagePage = usagePage
    }

    func send(reports: [[UInt8]]) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            queue.async {
                do {
                    try self.sendSync(reports: reports)
                    cont.resume()
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    private func sendSync(reports: [[UInt8]]) throws {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let matching: [String: Any] = [
            kIOHIDVendorIDKey: Int(vendorID),
            kIOHIDProductIDKey: Int(productID),
        ]
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)

        let mgrOpen = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        guard mgrOpen == kIOReturnSuccess else {
            throw HIDTransportError.openFailed(mgrOpen)
        }
        defer { IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone)) }

        guard let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else {
            throw HIDTransportError.deviceNotFound
        }

        let device = devices.first { dev in
            guard let page = IOHIDDeviceGetProperty(dev, kIOHIDPrimaryUsagePageKey as CFString) as? Int else {
                return false
            }
            return UInt32(page) == usagePage
        }
        guard let device = device else {
            throw HIDTransportError.deviceNotFound
        }

        let devOpen = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
        guard devOpen == kIOReturnSuccess else {
            throw HIDTransportError.openFailed(devOpen)
        }
        defer { IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone)) }

        for report in reports {
            try report.withUnsafeBufferPointer { buf in
                guard let base = buf.baseAddress else {
                    throw HIDTransportError.sendFailed(kIOReturnInternalError)
                }
                let r = IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0, base, buf.count)
                guard r == kIOReturnSuccess else {
                    throw HIDTransportError.sendFailed(r)
                }
            }
        }
    }
}
