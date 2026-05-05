import Foundation

public enum LightingMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case staticColor
    case breathing
    case pulse
    case cycle

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .staticColor: return "Static"
        case .breathing: return "Breathing"
        case .pulse: return "Pulse"
        case .cycle: return "Color Cycle"
        }
    }

    public var systemImage: String {
        switch self {
        case .staticColor: return "circle.fill"
        case .breathing: return "wave.3.right"
        case .pulse: return "waveform.path.ecg"
        case .cycle: return "rainbow"
        }
    }
}
