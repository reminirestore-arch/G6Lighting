import SwiftUI

/// Live color preview rendered as a glowing dot — mirrors the actual frame
/// currently being sent to the device (subscribes to EffectPlayer.currentFrame).
struct GlowingPreview: View {
    @EnvironmentObject var player: EffectPlayer
    @EnvironmentObject var settings: SettingsStore

    public var body: some View {
        let frame = player.currentFrame
        let color = settings.isOn ? frame.color : .off
        let brightness = settings.isOn ? Double(frame.brightness) / 255.0 : 0

        ZStack {
            // outer halo
            Circle()
                .fill(color.swiftUIColor)
                .frame(width: 130, height: 130)
                .blur(radius: 30)
                .opacity(brightness * 0.65)

            // inner orb with radial gradient — its luminance follows the live brightness
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            color.swiftUIColor.opacity(min(1.0, brightness + 0.10)),
                            color.swiftUIColor.opacity(brightness * 0.85)
                        ],
                        center: .center,
                        startRadius: 1,
                        endRadius: 30
                    )
                )
                .frame(width: 60, height: 60)
                .overlay(
                    Circle().strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
                )

            // dim ring when off, so the orb doesn't disappear visually
            if !settings.isOn {
                Circle()
                    .strokeBorder(.secondary.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .frame(width: 60, height: 60)
            }
        }
        .frame(height: 110)
        .frame(maxWidth: .infinity)
        // Only animate the major on/off transition; per-frame color/brightness
        // changes render immediately so the orb stays in lockstep with the LED.
        // Sub-frame USB latency (5-15 ms) is below human perception.
        .animation(.easeInOut(duration: 0.25), value: settings.isOn)
    }
}
