import Testing
import Foundation
import G6LightingCore

@MainActor
@Suite("LightingViewModel", .serialized)
struct LightingViewModelTests {

    private func makeVM(
        settings: SettingsStore? = nil,
        mock: MockHIDTransport? = nil
    ) -> (vm: LightingViewModel, mock: MockHIDTransport, settings: SettingsStore) {
        let m = mock ?? MockHIDTransport()
        let s = settings ?? SettingsStore(store: InMemoryKeyValueStore())
        let vm = LightingViewModel(
            settings: s,
            device: G6Device(transport: m),
            installSystemMonitors: false
        )
        return (vm, m, s)
    }

    /// Wait until the mock has at least `count` reports recorded, with a timeout.
    private func waitForReports(_ mock: MockHIDTransport, count: Int, timeoutSeconds: Double = 1.0) async {
        let deadline = Date().addingTimeInterval(timeoutSeconds)
        while mock.sentReports.count < count && Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    @Test func startupSendsRingLedThenColor() async {
        let (vm, mock, _) = makeVM()
        await waitForReports(mock, count: 5, timeoutSeconds: 3.0)
        let reports = mock.sentReports
        #expect(reports.count >= 5)
        if reports.count >= 5 {
            #expect(reports[0][1] == 0x39, "first packet is ring DATA")
            #expect(reports[1][2] == 0x01, "second packet is ring COMMIT")
            #expect(reports[2] == G6Protocol.initPacket())
            #expect(reports[3] == G6Protocol.modePacket())
        }
        _ = vm
    }

    @Test func isOnFalseSendsDisablePacket() async {
        let backing = InMemoryKeyValueStore()
        backing.setBool(false, forKey: "g6.isOn")
        let (vm, mock, _) = makeVM(settings: SettingsStore(store: backing))
        await waitForReports(mock, count: 3, timeoutSeconds: 3.0)
        #expect(mock.sentReports.last == G6Protocol.disablePacket())
        _ = vm
    }

    @Test func ringLedDisabledSendsCorrectByte() async {
        let backing = InMemoryKeyValueStore()
        backing.setBool(false, forKey: "g6.ringLed")
        let (vm, mock, _) = makeVM(settings: SettingsStore(store: backing))
        await waitForReports(mock, count: 2, timeoutSeconds: 3.0)
        if !mock.sentReports.isEmpty {
            #expect(mock.sentReports[0][5] == 0x01, "0x01 = ring off")
        } else {
            Issue.record("no reports recorded")
        }
        _ = vm
    }

    @Test func transportFailureSurfacesAsLastError() async {
        let mock = MockHIDTransport()
        mock.setFailureMode(.always)
        let (vm, _, _) = makeVM(mock: mock)
        try? await Task.sleep(nanoseconds: 200_000_000)
        #expect(vm.lastError != nil)
        #expect(vm.isConnected == false)
    }

    @Test func colorChangeTriggersResend() async {
        let (vm, mock, settings) = makeVM()
        await waitForReports(mock, count: 5)
        let baseline = mock.sentReports.count

        settings.color = RGBColor(red: 200, green: 100, blue: 50)

        try? await Task.sleep(nanoseconds: 300_000_000)
        #expect(mock.sentReports.count > baseline)

        let lastColorPacket = mock.sentReports.last(where: { $0[2] == 0x09 })
        #expect(lastColorPacket != nil)
        #expect(lastColorPacket?[11] == 200, "red byte")
        #expect(lastColorPacket?[10] == 100, "green byte")
        #expect(lastColorPacket?[9] == 50, "blue byte")

        _ = vm
    }
}
