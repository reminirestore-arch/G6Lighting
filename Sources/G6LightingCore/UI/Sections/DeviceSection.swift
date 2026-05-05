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
                            Text("Volume knob light")
                                .font(.system(size: 12))
                            Text("White/red status indicator")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                .help("Toggle the ring LED around the volume knob. Hardware is white/red only — this is the firmware status indicator, not an RGB zone.")

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
