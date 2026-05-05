import Foundation

/// Wire-level HID transport. The smallest possible interface so the device layer
/// can be tested in-memory and the IOKit implementation can stay focused.
protocol HIDTransport: Sendable {
    /// Send a sequence of HID OUTPUT reports. Each report is the raw payload (without report-ID prefix).
    func send(reports: [[UInt8]]) async throws
}

enum HIDTransportError: Error, LocalizedError {
    case deviceNotFound
    case openFailed(Int32)
    case sendFailed(Int32)

    var errorDescription: String? {
        switch self {
        case .deviceNotFound:
            return "Sound BlasterX G6 (vendor HID interface) not found. Is the device connected?"
        case .openFailed(let r):
            return "Failed to open G6 HID interface (IOReturn 0x\(String(UInt32(bitPattern: r), radix: 16)))."
        case .sendFailed(let r):
            return "Failed to send HID report (IOReturn 0x\(String(UInt32(bitPattern: r), radix: 16)))."
        }
    }
}
