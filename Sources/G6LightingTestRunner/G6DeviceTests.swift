import Testing
import G6LightingCore

@Suite("G6Device")
struct G6DeviceTests {

    @Test func setColorEmitsThreePackets() async throws {
        let mock = MockHIDTransport()
        let device = G6Device(transport: mock)
        let frame = LightingFrame(color: RGBColor(red: 1, green: 2, blue: 3), brightness: 200)
        try await device.setColor(frame)
        #expect(mock.sentReports.count == 3)
        #expect(mock.sentReports[2] == G6Protocol.colorPacket(red: 1, green: 2, blue: 3, brightness: 200))
    }

    @Test func disableLogoEmitsOnePacket() async throws {
        let mock = MockHIDTransport()
        let device = G6Device(transport: mock)
        try await device.disableLogo()
        #expect(mock.sentReports.count == 1)
        #expect(mock.sentReports[0] == G6Protocol.disablePacket())
    }

    @Test func ringLedToggleEmitsDataAndCommit() async throws {
        let mock = MockHIDTransport()
        let device = G6Device(transport: mock)

        try await device.setRingLed(enabled: false)
        #expect(mock.sentReports.count == 2)
        #expect(mock.sentReports[0][5] == 0x01)
        #expect(mock.sentReports[1][2] == 0x01)

        mock.reset()
        try await device.setRingLed(enabled: true)
        #expect(mock.sentReports[0][5] == 0x00)
    }

    @Test func transportFailurePropagates() async {
        let mock = MockHIDTransport()
        let device = G6Device(transport: mock)
        mock.setFailureMode(.always)
        await #expect(throws: HIDTransportError.self) {
            try await device.setColor(LightingFrame(color: .white, brightness: 255))
        }
    }
}
