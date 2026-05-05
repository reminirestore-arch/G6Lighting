import Foundation

public struct CycleEffect: LightingEffect {
    public let brightness: UInt8
    public let speed: Double
    public let frameRate: Double

    public init(brightness: UInt8, speed: Double, frameRate: Double = 30) {
        self.brightness = brightness
        self.speed = max(0.05, speed)
        self.frameRate = frameRate
    }

    public func frame(at time: TimeInterval) -> (frame: LightingFrame, nextDelay: TimeInterval?) {
        let hue = (time * speed * 0.15).truncatingRemainder(dividingBy: 1.0)
        let color = RGBColor.fromHSV(hue: hue, saturation: 1, value: 1)
        return (
            LightingFrame(color: color, brightness: brightness),
            1.0 / frameRate
        )
    }
}
