import Foundation

struct RGBColor: Hashable, Sendable, Codable {
    var red: UInt8
    var green: UInt8
    var blue: UInt8

    static let off = RGBColor(red: 0, green: 0, blue: 0)
    static let white = RGBColor(red: 255, green: 255, blue: 255)

    init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    init?(hex: String) {
        let cleaned = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6,
              let r = UInt8(cleaned.prefix(2), radix: 16),
              let g = UInt8(cleaned.dropFirst(2).prefix(2), radix: 16),
              let b = UInt8(cleaned.suffix(2), radix: 16)
        else { return nil }
        self.init(red: r, green: g, blue: b)
    }

    var hex: String {
        String(format: "%02X%02X%02X", red, green, blue)
    }

    static func fromHSV(hue: Double, saturation: Double, value: Double) -> RGBColor {
        let h = (hue.truncatingRemainder(dividingBy: 1.0) + 1.0).truncatingRemainder(dividingBy: 1.0) * 6
        let i = floor(h)
        let f = h - i
        let p = value * (1 - saturation)
        let q = value * (1 - saturation * f)
        let t = value * (1 - saturation * (1 - f))
        let (r, g, b): (Double, Double, Double)
        switch Int(i) % 6 {
        case 0: (r, g, b) = (value, t, p)
        case 1: (r, g, b) = (q, value, p)
        case 2: (r, g, b) = (p, value, t)
        case 3: (r, g, b) = (p, q, value)
        case 4: (r, g, b) = (t, p, value)
        default: (r, g, b) = (value, p, q)
        }
        return RGBColor(
            red: UInt8(max(0, min(255, r * 255))),
            green: UInt8(max(0, min(255, g * 255))),
            blue: UInt8(max(0, min(255, b * 255)))
        )
    }
}
