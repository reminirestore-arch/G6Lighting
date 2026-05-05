import Foundation

/// A pure, deterministic frame source. Given a relative time-since-effect-started (in seconds),
/// returns the frame to display and how long to wait before the next frame.
/// `nextDelay == nil` indicates a one-shot effect — the runner should send the frame and stop.
protocol LightingEffect: Sendable {
    func frame(at time: TimeInterval) -> (frame: LightingFrame, nextDelay: TimeInterval?)
}

enum EffectFactory {
    /// Build the effect implementation that matches the given mode and parameters.
    static func make(
        mode: LightingMode,
        baseColor: RGBColor,
        brightnessPercent: Int,
        breathingSpeed: Double,
        cycleSpeed: Double
    ) -> LightingEffect {
        let baseBrightness = UInt8(min(255, max(0, brightnessPercent * 255 / 100)))
        switch mode {
        case .staticColor:
            return StaticEffect(color: baseColor, brightness: baseBrightness)
        case .breathing:
            return BreathingEffect(color: baseColor, peakBrightness: baseBrightness, speed: breathingSpeed)
        case .pulse:
            return PulseEffect(color: baseColor, brightness: baseBrightness)
        case .cycle:
            return CycleEffect(brightness: baseBrightness, speed: cycleSpeed)
        }
    }
}
