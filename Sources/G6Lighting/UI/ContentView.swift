import SwiftUI

private struct PresetSwatch: Identifiable {
    let id = UUID()
    let r: Int, g: Int, b: Int
    var color: Color { Color(red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255) }
}

private let presets: [PresetSwatch] = [
    .init(r: 255, g: 0,   b: 0),    // red
    .init(r: 255, g: 102, b: 0),    // orange
    .init(r: 255, g: 220, b: 0),    // yellow
    .init(r: 0,   g: 255, b: 0),    // green
    .init(r: 0,   g: 200, b: 255),  // cyan
    .init(r: 0,   g: 80,  b: 255),  // blue
    .init(r: 160, g: 0,   b: 255),  // purple
    .init(r: 255, g: 0,   b: 200),  // magenta
    .init(r: 255, g: 255, b: 255),  // white
]

struct ContentView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var engine: LightingViewModel
    @EnvironmentObject var autoLaunch: AutoLaunch

    @State private var hexInput: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: settings.isOn ? "lightbulb.fill" : "lightbulb.slash")
                    .foregroundColor(engine.isConnected && settings.isOn ? .accentColor : .gray)
                Text("Sound BlasterX G6")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { settings.isOn },
                    set: { settings.isOn = $0 }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
            }

            HStack {
                Text(engine.isConnected ? "Connected" : "Disconnected")
                    .font(.caption)
                    .foregroundColor(engine.isConnected ? .secondary : .red)
                Spacer()
                Text(settings.isOn ? "Lighting on" : "Lighting off")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            Picker("Mode", selection: Binding(
                get: { settings.mode },
                set: { settings.mode = $0 }
            )) {
                ForEach(LightingMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .disabled(!settings.isOn)

            if settings.isOn {
                // Live color preview
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(currentColor)
                        .frame(width: 36, height: 24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                        )
                    TextField("RRGGBB", text: $hexInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .onSubmit { applyHex() }
                    Button("Apply") { applyHex() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }

                // Preset swatches
                HStack(spacing: 6) {
                    ForEach(presets) { swatch in
                        Button {
                            settings.red = swatch.r
                            settings.green = swatch.g
                            settings.blue = swatch.b
                            updateHexFromSettings()
                        } label: {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(swatch.color)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                // RGB sliders
                rgbSlider("R", binding: Binding(
                    get: { Double(settings.red) },
                    set: { settings.red = Int($0); updateHexFromSettings() }
                ), tint: .red)
                rgbSlider("G", binding: Binding(
                    get: { Double(settings.green) },
                    set: { settings.green = Int($0); updateHexFromSettings() }
                ), tint: .green)
                rgbSlider("B", binding: Binding(
                    get: { Double(settings.blue) },
                    set: { settings.blue = Int($0); updateHexFromSettings() }
                ), tint: .blue)

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Brightness: \(settings.brightness)%")
                        .font(.caption)
                    Slider(value: Binding(
                        get: { Double(settings.brightness) },
                        set: { settings.brightness = Int($0) }
                    ), in: 0...100, step: 1)
                }

                if settings.mode == .breathing {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Breathing speed")
                            .font(.caption)
                        Slider(value: Binding(
                            get: { settings.breathingSpeed },
                            set: { settings.breathingSpeed = $0 }
                        ), in: 0.1...2.0)
                    }
                }

                if settings.mode == .cycle {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cycle speed")
                            .font(.caption)
                        Slider(value: Binding(
                            get: { settings.cycleSpeed },
                            set: { settings.cycleSpeed = $0 }
                        ), in: 0.1...2.0)
                    }
                }
            }

            if let error = engine.lastError {
                Divider()
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .lineLimit(3)
            }

            Divider()

            Toggle(isOn: Binding(
                get: { settings.ringLedOn },
                set: { settings.ringLedOn = $0 }
            )) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Volume knob ring LED")
                    Text("White/red firmware indicator (not RGB)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
            .controlSize(.small)

            Toggle("Launch at login", isOn: Binding(
                get: { autoLaunch.isEnabled },
                set: { autoLaunch.setEnabled($0) }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)

            if let err = autoLaunch.lastError {
                Text(err).font(.caption2).foregroundColor(.orange).lineLimit(2)
            }

            HStack {
                Button("Resend") {
                    engine.restart()
                }
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
        .padding(14)
        .frame(width: 340)
        .onAppear {
            updateHexFromSettings()
            autoLaunch.refresh()
        }
    }

    private var currentColor: Color {
        Color(red: Double(settings.red)/255, green: Double(settings.green)/255, blue: Double(settings.blue)/255)
    }

    @ViewBuilder
    private func rgbSlider(_ label: String, binding: Binding<Double>, tint: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(.caption, design: .monospaced))
                .frame(width: 14, alignment: .leading)
                .foregroundColor(tint)
            Slider(value: binding, in: 0...255, step: 1)
            Text("\(Int(binding.wrappedValue))")
                .font(.system(.caption, design: .monospaced))
                .frame(width: 30, alignment: .trailing)
                .foregroundColor(.secondary)
        }
    }

    private func updateHexFromSettings() {
        hexInput = String(format: "%02X%02X%02X", settings.red, settings.green, settings.blue)
    }

    private func applyHex() {
        let cleaned = hexInput.trimmingCharacters(in: .whitespaces).uppercased().replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6,
              let r = UInt8(cleaned.prefix(2), radix: 16),
              let g = UInt8(cleaned.dropFirst(2).prefix(2), radix: 16),
              let b = UInt8(cleaned.suffix(2), radix: 16)
        else {
            updateHexFromSettings()
            return
        }
        settings.red = Int(r)
        settings.green = Int(g)
        settings.blue = Int(b)
        hexInput = cleaned
    }
}
