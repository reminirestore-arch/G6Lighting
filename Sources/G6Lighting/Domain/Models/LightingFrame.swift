import Foundation

struct LightingFrame: Hashable, Sendable {
    var color: RGBColor
    var brightness: UInt8

    static let off = LightingFrame(color: .off, brightness: 0)
}
