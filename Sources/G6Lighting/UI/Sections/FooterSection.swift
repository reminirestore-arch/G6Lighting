import SwiftUI

struct FooterSection: View {
    @EnvironmentObject var engine: LightingViewModel

    var body: some View {
        HStack(spacing: 8) {
            Button {
                engine.restart()
            } label: {
                Label("Resend", systemImage: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Spacer()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power.circle")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .keyboardShortcut("q")
        }
    }
}
