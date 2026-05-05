import Testing
import G6LightingCore

@Suite("MockHIDTransport")
struct MockHIDTransportTests {

    @Test func recordsSentReports() async throws {
        let mock = MockHIDTransport()
        try await mock.send(reports: [[1, 2, 3], [4, 5]])
        try await mock.send(reports: [[6]])
        #expect(mock.sentReports.count == 3)
        #expect(mock.sentReports[0] == [1, 2, 3])
        #expect(mock.sentReports[2] == [6])
    }

    @Test func reset() async throws {
        let mock = MockHIDTransport()
        try await mock.send(reports: [[1]])
        mock.reset()
        #expect(mock.sentReports.isEmpty)
    }

    @Test func failureModeAlways() async {
        let mock = MockHIDTransport()
        mock.setFailureMode(.always, error: .deviceNotFound)
        await #expect(throws: HIDTransportError.self) {
            try await mock.send(reports: [[1]])
        }
        #expect(mock.sentReports.isEmpty, "no reports recorded on failure")
    }

    @Test func failureModeOnceRecoversAfterFirstThrow() async throws {
        let mock = MockHIDTransport()
        mock.setFailureMode(.once)
        await #expect(throws: HIDTransportError.self) {
            try await mock.send(reports: [[1]])
        }
        try await mock.send(reports: [[2]])
        #expect(mock.sentReports == [[2]])
    }
}
