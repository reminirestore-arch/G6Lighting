import Testing
import G6LightingCore

/// Byte-exact regression tests for the wire protocol. These guard against
/// accidental changes to packet structure (e.g. swapping BGR order or shifting
/// a brightness byte) that would silently break the device.
@Suite("G6Protocol")
struct G6ProtocolTests {

    @Test func initPacketLayout() {
        let p = G6Protocol.initPacket()
        #expect(p.count == 64)
        #expect(p[0] == 0x5A)
        #expect(p[1] == 0x3A)
        #expect(p[2] == 0x02)
        #expect(p[3] == 0x06)
        #expect(p[4] == 0x01)
        for i in 5..<64 {
            #expect(p[i] == 0, "byte \(i) should be zero")
        }
    }

    @Test func modePacketLayout() {
        let p = G6Protocol.modePacket()
        #expect(p.count == 64)
        #expect(p[0] == 0x5A)
        #expect(p[1] == 0x3A)
        #expect(p[2] == 0x06)
        #expect(p[3] == 0x04)
        #expect(p[5] == 0x03)
        #expect(p[6] == 0x01)
        #expect(p[8] == 0x01)
    }

    @Test func colorPacketByteOrderIsBlueGreenRed() {
        // Distinct values ensure we'd notice if any pair got swapped.
        let p = G6Protocol.colorPacket(red: 0xAA, green: 0xBB, blue: 0xCC, brightness: 0xDD)
        #expect(p.count == 64)
        #expect(p[0] == 0x5A)
        #expect(p[1] == 0x3A)
        #expect(p[2] == 0x09)
        #expect(p[3] == 0x0A)
        #expect(p[5] == 0x03)
        #expect(p[6] == 0x01)
        #expect(p[7] == 0x01)
        #expect(p[8] == 0xDD)
        #expect(p[9] == 0xCC)
        #expect(p[10] == 0xBB)
        #expect(p[11] == 0xAA)
    }

    @Test func setRgbFramesEmitsThreePackets() {
        let frames = G6Protocol.setRgbFrames(red: 1, green: 2, blue: 3, brightness: 4)
        #expect(frames.count == 3)
        #expect(frames[0] == G6Protocol.initPacket())
        #expect(frames[1] == G6Protocol.modePacket())
        #expect(frames[2] == G6Protocol.colorPacket(red: 1, green: 2, blue: 3, brightness: 4))
    }

    @Test func disablePacketLayout() {
        let p = G6Protocol.disablePacket()
        #expect(p.count == 64)
        #expect(p[0] == 0x5A)
        #expect(p[1] == 0x3A)
        #expect(p[2] == 0x02)
        #expect(p[3] == 0x06)
        #expect(p[4] == 0x00)  // distinguishes from init (which has 0x01)
    }

    @Test func ringLedFramesEnable() {
        let frames = G6Protocol.ringLedFrames(enabled: true)
        #expect(frames.count == 2)
        #expect(frames[0][0] == 0x5A)
        #expect(frames[0][1] == 0x39)
        #expect(frames[0][2] == 0x03)
        #expect(frames[0][3] == 0x00)
        #expect(frames[0][4] == 0x0E)
        #expect(frames[0][5] == 0x00)  // 0x00 = on
        #expect(frames[1][0] == 0x5A)
        #expect(frames[1][1] == 0x39)
        #expect(frames[1][2] == 0x01)
        #expect(frames[1][3] == 0x01)
    }

    @Test func ringLedFramesDisable() {
        let frames = G6Protocol.ringLedFrames(enabled: false)
        #expect(frames.count == 2)
        #expect(frames[0][5] == 0x01, "0x01 = off")
        #expect(frames[1] == G6Protocol.ringLedFrames(enabled: true)[1])
    }

    @Test func protocolConstants() {
        #expect(G6Protocol.vendorID == 0x041E)
        #expect(G6Protocol.productID == 0x3256)
        #expect(G6Protocol.targetUsagePage == 0xFF00)
        #expect(G6Protocol.payloadLength == 64)
    }

}
