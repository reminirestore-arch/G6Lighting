import SwiftUI

struct DeviceSection: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var autoLaunch: AutoLaunch

    public var body: some View {
        SectionCard("Device", systemImage: "dial.medium.fill") {
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: $settings.ringLedOn) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Image(systemName: "circle.dotted")
                            .imageScale(.small)
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Volume knob ring LED")
                                .font(.system(size: 12))
                            Text("Bicolor firmware indicator (not RGB)")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)

                Toggle(isOn: Binding(
                    get: { autoLaunch.isEnabled },
                    set: { autoLaunch.setEnabled($0) }
                )) {
                    HStack(spacing: 6) {
                        Image(systemName: "power")
                            .imageScale(.small)
                            .foregroundStyle(.secondary)
                        Text("Launch at login")
                            .font(.system(size: 12))
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)

                if let err = autoLaunch.lastError {
                    Text(err)
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .lineLimit(2)
                }
            }
        }
    }
}
