import SwiftUI

struct HeaderSection: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var engine: LightingViewModel

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Sound BlasterX G6")
                    .font(.headline)
                StatusPill(status: status)
            }
            Spacer()
            Toggle("", isOn: $settings.isOn)
                .toggleStyle(.switch)
                .labelsHidden()
                .scaleEffect(1.05)
                .help(settings.isOn ? "Turn lighting off" : "Turn lighting on")
        }
    }

    private var status: StatusPill.Status {
        if let err = engine.lastError { return .error(err) }
        return engine.isConnected ? .connected : .disconnected
    }
}
