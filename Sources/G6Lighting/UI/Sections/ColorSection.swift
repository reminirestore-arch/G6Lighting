import SwiftUI

struct ColorSection: View {
    @EnvironmentObject var settings: SettingsStore
    @State private var hexInput: String = ""

    private static let presets: [RGBColor] = [
        RGBColor(red: 255, green: 0, blue: 0),
        RGBColor(red: 255, green: 102, blue: 0),
        RGBColor(red: 255, green: 220, blue: 0),
        RGBColor(red: 0, green: 255, blue: 0),
        RGBColor(red: 0, green: 200, blue: 255),
        RGBColor(red: 0, green: 80, blue: 255),
        RGBColor(red: 160, green: 0, blue: 255),
        RGBColor(red: 255, green: 0, blue: 200),
        RGBColor(red: 255, green: 255, blue: 255),
    ]

    var body: some View {
        SectionCard("Color", systemImage: "paintpalette.fill") {
            VStack(alignment: .leading, spacing: 12) {
                // Hex input
                HStack(spacing: 8) {
                    Text("#")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                    TextField("RRGGBB", text: $hexInput)
                        .textFieldStyle(.plain)
                        .font(.system(.body, design: .monospaced))
                        .onSubmit { applyHex() }
                    Spacer()
                    Button("Apply", action: applyHex)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(.background.opacity(0.4))
                )

                // Preset row
                HStack(spacing: 6) {
                    ForEach(Array(Self.presets.enumerated()), id: \.offset) { _, preset in
                        ColorSwatchButton(
                            color: preset,
                            isSelected: settings.color == preset
                        ) {
                            settings.color = preset
                            updateHexFromSettings()
                        }
                    }
                }

                // RGB sliders
                VStack(spacing: 6) {
                    rgbSlider("R", value: Binding(
                        get: { Double(settings.red) },
                        set: { settings.red = Int($0); updateHexFromSettings() }
                    ), tint: .red)
                    rgbSlider("G", value: Binding(
                        get: { Double(settings.green) },
                        set: { settings.green = Int($0); updateHexFromSettings() }
                    ), tint: .green)
                    rgbSlider("B", value: Binding(
                        get: { Double(settings.blue) },
                        set: { settings.blue = Int($0); updateHexFromSettings() }
                    ), tint: .blue)
                }
            }
        }
        .onAppear { updateHexFromSettings() }
    }

    @ViewBuilder
    private func rgbSlider(_ label: String, value: Binding<Double>, tint: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(tint)
                .frame(width: 12, alignment: .leading)
            Slider(value: value, in: 0...255, step: 1)
                .tint(tint)
            Text("\(Int(value.wrappedValue))")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .trailing)
                .monospacedDigit()
        }
    }

    private func updateHexFromSettings() {
        hexInput = settings.color.hex
    }

    private func applyHex() {
        if let parsed = RGBColor(hex: hexInput) {
            settings.color = parsed
            hexInput = parsed.hex
        } else {
            updateHexFromSettings()
        }
    }
}
