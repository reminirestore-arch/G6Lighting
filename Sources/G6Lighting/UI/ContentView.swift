import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        VStack(spacing: 12) {
            HeaderSection()

            GlowingPreview()
                .padding(.vertical, 4)

            if settings.isOn {
                ColorSection()
                    .transition(.opacity.combined(with: .move(edge: .top)))
                EffectSection()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            DeviceSection()

            FooterSection()
        }
        .padding(14)
        .frame(width: 360)
        .background(.ultraThinMaterial)
        .animation(.easeInOut(duration: 0.2), value: settings.isOn)
        .animation(.easeInOut(duration: 0.15), value: settings.mode)
    }
}
