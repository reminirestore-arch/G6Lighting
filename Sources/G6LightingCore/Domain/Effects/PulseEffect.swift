import Foundation

public struct PulseEffect: LightingEffect {
    public let color: RGBColor
    public let brightness: UInt8
    public let onDuration: TimeInterval
    public let offDuration: TimeInterval

    public init(color: RGBColor, brightness: UInt8, onDuration: TimeInterval = 0.4, offDuration: TimeInterval = 0.25) {
        self.color = color
        self.brightness = brightness
        self.onDuration = onDuration
        self.offDuration = offDuration
    }

    public func frame(at time: TimeInterval) -> (frame: LightingFrame, nextDelay: TimeInterval?) {
        let cycle = onDuration + offDuration
        let position = time.truncatingRemainder(dividingBy: cycle)
        if position < onDuration {
            return (
                LightingFrame(color: color, brightness: brightness),
                onDuration - position
            )
        } else {
            return (
                LightingFrame.off,
                cycle - position
            )
        }
    }
}
