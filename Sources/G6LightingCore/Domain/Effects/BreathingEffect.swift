import Foundation

public struct BreathingEffect: LightingEffect {
    public let color: RGBColor
    public let peakBrightness: UInt8
    public let speed: Double
    public let frameRate: Double

    public init(color: RGBColor, peakBrightness: UInt8, speed: Double, frameRate: Double = 30) {
        self.color = color
        self.peakBrightness = peakBrightness
        self.speed = max(0.05, speed)
        self.frameRate = frameRate
    }

    public func frame(at time: TimeInterval) -> (frame: LightingFrame, nextDelay: TimeInterval?) {
        // |sin| so a breath cycle goes 0 → peak → 0; starts dark on mode switch.
        let phase = time * speed * 2 * .pi
        let intensity = abs(sin(phase))
        let bri = UInt8(max(0, min(255, intensity * Double(peakBrightness))))
        return (
            LightingFrame(color: color, brightness: bri),
            1.0 / frameRate
        )
    }
}
