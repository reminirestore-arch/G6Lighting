import Foundation

/// High-level G6 API. Knows nothing about IOKit — only about packets and a transport.
/// All work is composed from G6Protocol byte builders.
final class G6Device: Sendable {
    let transport: HIDTransport

    init(transport: HIDTransport) {
        self.transport = transport
    }

    /// Convenience factory that wires the real IOKit transport for production use.
    static func makeReal() -> G6Device {
        G6Device(transport: IOKitHIDTransport(
            vendorID: G6Protocol.vendorID,
            productID: G6Protocol.productID,
            usagePage: G6Protocol.targetUsagePage
        ))
    }

    func setColor(_ frame: LightingFrame) async throws {
        try await transport.send(reports: G6Protocol.setRgbFrames(
            red: frame.color.red,
            green: frame.color.green,
            blue: frame.color.blue,
            brightness: frame.brightness
        ))
    }

    func disableLogo() async throws {
        try await transport.send(reports: [G6Protocol.disablePacket()])
    }

    func setRingLed(enabled: Bool) async throws {
        try await transport.send(reports: G6Protocol.ringLedFrames(enabled: enabled))
    }
}
