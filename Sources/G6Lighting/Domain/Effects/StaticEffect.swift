import Foundation

struct StaticEffect: LightingEffect {
    let color: RGBColor
    let brightness: UInt8

    func frame(at time: TimeInterval) -> (frame: LightingFrame, nextDelay: TimeInterval?) {
        (LightingFrame(color: color, brightness: brightness), nil)
    }
}
