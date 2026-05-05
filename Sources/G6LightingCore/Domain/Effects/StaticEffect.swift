import Foundation

public struct StaticEffect: LightingEffect {
    public let color: RGBColor
    public let brightness: UInt8

    public init(color: RGBColor, brightness: UInt8) {
        self.color = color
        self.brightness = brightness
    }

    public func frame(at time: TimeInterval) -> (frame: LightingFrame, nextDelay: TimeInterval?) {
        (LightingFrame(color: color, brightness: brightness), nil)
    }
}
