import Foundation

struct BreathingEffect: LightingEffect {
    let color: RGBColor
    let peakBrightness: UInt8
    let speed: Double
    let frameRate: Double

    init(color: RGBColor, peakBrightness: UInt8, speed: Double, frameRate: Double = 30) {
        self.color = color
        self.peakBrightness = peakBrightness
        self.speed = max(0.05, speed)
        self.frameRate = frameRate
    }

    func frame(at time: TimeInterval) -> (frame: LightingFrame, nextDelay: TimeInterval?) {
        let phase = time * speed * 2 * .pi
        let intensity = (sin(phase) + 1) / 2
        let bri = UInt8(max(0, min(255, intensity * Double(peakBrightness))))
        return (
            LightingFrame(color: color, brightness: bri),
            1.0 / frameRate
        )
    }
}
