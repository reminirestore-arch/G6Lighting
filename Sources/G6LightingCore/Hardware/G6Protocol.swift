import Foundation

public enum G6Protocol {
    public static let vendorID: UInt16 = 0x041E
    public static let productID: UInt16 = 0x3256
    public static let targetInterface: Int32 = 4
    public static let targetUsagePage: UInt32 = 0xFF00
    public static let payloadLength = 64

    public static func initPacket() -> [UInt8] {
        var buf = [UInt8](repeating: 0, count: payloadLength)
        buf[0] = 0x5A
        buf[1] = 0x3A
        buf[2] = 0x02
        buf[3] = 0x06
        buf[4] = 0x01
        return buf
    }

    public static func modePacket() -> [UInt8] {
        var buf = [UInt8](repeating: 0, count: payloadLength)
        buf[0] = 0x5A
        buf[1] = 0x3A
        buf[2] = 0x06
        buf[3] = 0x04
        buf[5] = 0x03
        buf[6] = 0x01
        buf[8] = 0x01
        return buf
    }

    public static func colorPacket(red: UInt8, green: UInt8, blue: UInt8, brightness: UInt8) -> [UInt8] {
        var buf = [UInt8](repeating: 0, count: payloadLength)
        buf[0] = 0x5A
        buf[1] = 0x3A
        buf[2] = 0x09
        buf[3] = 0x0A
        buf[5] = 0x03
        buf[6] = 0x01
        buf[7] = 0x01
        buf[8] = brightness
        buf[9] = blue
        buf[10] = green
        buf[11] = red
        return buf
    }

    public static func disablePacket() -> [UInt8] {
        var buf = [UInt8](repeating: 0, count: payloadLength)
        buf[0] = 0x5A
        buf[1] = 0x3A
        buf[2] = 0x02
        buf[3] = 0x06
        return buf
    }

    public static func setRgbFrames(red: UInt8, green: UInt8, blue: UInt8, brightness: UInt8) -> [[UInt8]] {
        return [
            initPacket(),
            modePacket(),
            colorPacket(red: red, green: green, blue: blue, brightness: brightness),
        ]
    }

    // Volume-knob ring LED toggle (the "LED indicator" in Sound Blaster Command).
    // Reverse-engineered by Kaan88 (nils-skowasch/soundblaster-x-g6-cli#4, 2026-04).
    // Each toggle is a DATA + COMMIT pair.
    public static func ringLedFrames(enabled: Bool) -> [[UInt8]] {
        var data = [UInt8](repeating: 0, count: payloadLength)
        data[0] = 0x5A
        data[1] = 0x39
        data[2] = 0x03
        data[3] = 0x00
        data[4] = 0x0E
        data[5] = enabled ? 0x00 : 0x01

        var commit = [UInt8](repeating: 0, count: payloadLength)
        commit[0] = 0x5A
        commit[1] = 0x39
        commit[2] = 0x01
        commit[3] = 0x01

        return [data, commit]
    }
}
