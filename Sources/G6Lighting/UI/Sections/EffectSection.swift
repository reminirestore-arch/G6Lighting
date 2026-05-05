import SwiftUI

struct EffectSection: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        SectionCard("Effect", systemImage: "sparkles") {
            VStack(alignment: .leading, spacing: 12) {
                // Mode chips
                HStack(spacing: 6) {
                    ForEach(LightingMode.allCases) { mode in
                        ModeChip(
                            mode: mode,
                            isSelected: settings.mode == mode
                        ) {
                            settings.mode = mode
                        }
                    }
                }

                // Brightness
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "sun.max.fill")
                            .imageScale(.small)
                            .foregroundStyle(.secondary)
                        Text("Brightness")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(settings.brightness)%")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: Binding(
                        get: { Double(settings.brightness) },
                        set: { settings.brightness = Int($0) }
                    ), in: 0...100, step: 1)
                }

                // Effect-specific speed
                if settings.mode == .breathing {
                    speedSlider("Breathing speed", value: $settings.breathingSpeed)
                }
                if settings.mode == .cycle {
                    speedSlider("Cycle speed", value: $settings.cycleSpeed)
                }
            }
        }
    }

    @ViewBuilder
    private func speedSlider(_ label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "speedometer")
                    .imageScale(.small)
                    .foregroundStyle(.secondary)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: 0.1...2.0)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

private struct ModeChip: View {
    let mode: LightingMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: mode.systemImage)
                    .font(.system(size: 14, weight: .medium))
                    .frame(height: 18)
                Text(mode.label)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.20) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.accentColor.opacity(0.6) : Color.white.opacity(0.10),
                        lineWidth: isSelected ? 1.0 : 0.5
                    )
            )
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
