import Foundation

public struct LightingFrame: Hashable, Sendable {
    public var color: RGBColor
    public var brightness: UInt8

    public init(color: RGBColor, brightness: UInt8) {
        self.color = color
        self.brightness = brightness
    }

    public static let off = LightingFrame(color: .off, brightness: 0)
}
