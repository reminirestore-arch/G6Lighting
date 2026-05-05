import SwiftUI

struct HeaderSection: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var engine: LightingViewModel

    public var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Sound BlasterX G6")
                    .font(.headline)
                StatusPill(status: status)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 6) {
                Toggle("", isOn: $settings.isOn)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .help(settings.isOn ? "Turn lighting off" : "Turn lighting on")
                    .accessibilityLabel("Lighting power")
                Text("Lighting")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .kerning(0.4)
            }
        }
        .padding(.bottom, 4)
    }

    private var status: StatusPill.Status {
        if let err = engine.lastError { return .error(err) }
        return engine.isConnected ? .connected : .disconnected
    }
}
