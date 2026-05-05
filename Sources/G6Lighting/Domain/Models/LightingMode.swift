import Foundation

enum LightingMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case staticColor
    case breathing
    case pulse
    case cycle

    var id: String { rawValue }

    var label: String {
        switch self {
        case .staticColor: return "Static"
        case .breathing: return "Breathing"
        case .pulse: return "Pulse"
        case .cycle: return "Color Cycle"
        }
    }

    var systemImage: String {
        switch self {
        case .staticColor: return "circle.fill"
        case .breathing: return "wave.3.right"
        case .pulse: return "waveform.path.ecg"
        case .cycle: return "rainbow"
        }
    }
}
