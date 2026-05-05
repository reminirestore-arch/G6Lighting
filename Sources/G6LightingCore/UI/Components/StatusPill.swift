import SwiftUI

struct StatusPill: View {
    enum Status: Equatable {
        case connected, disconnected, error(String)

        var label: String {
            switch self {
            case .connected: return "Connected"
            case .disconnected: return "Disconnected"
            case .error: return "Error"
            }
        }

        var color: Color {
            switch self {
            case .connected: return .green
            case .disconnected: return .secondary
            case .error: return .red
            }
        }

        var systemImage: String {
            switch self {
            case .connected: return "checkmark.circle.fill"
            case .disconnected: return "moon.zzz.fill"
            case .error: return "exclamationmark.triangle.fill"
            }
        }
    }

    public let status: Status

    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: status.systemImage)
                .imageScale(.small)
            Text(status.label)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(status.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(status.color.opacity(0.12))
        )
        .overlay(
            Capsule()
                .strokeBorder(status.color.opacity(0.3), lineWidth: 0.5)
        )
    }
}
