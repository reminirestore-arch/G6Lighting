import Testing
import G6LightingCore

/// Effects are pure functions of (time, parameters): deterministic and need no
/// device, so we can assert exact frames at chosen times.
@Suite("Effects")
struct EffectTests {

    @Test func staticReturnsSingleFrameThenStops() {
        let e = StaticEffect(color: RGBColor(red: 10, green: 20, blue: 30), brightness: 200)
        let (frame, next) = e.frame(at: 0)
        #expect(frame.color == RGBColor(red: 10, green: 20, blue: 30))
        #expect(frame.brightness == 200)
        #expect(next == nil, "static is one-shot — runner should stop after one frame")
    }

    @Test func staticIsTimeIndependent() {
        let e = StaticEffect(color: .white, brightness: 100)
        #expect(e.frame(at: 0).frame == e.frame(at: 99).frame)
    }

    @Test func breathingStartsAtZeroBrightness() {
        // sin(0) = 0 → intensity = 0 → brightness = 0
        let e = BreathingEffect(color: .white, peakBrightness: 200, speed: 1.0)
        let (frame, next) = e.frame(at: 0)
        #expect(frame.brightness == 0)
        #expect(next != nil)
    }

    @Test func breathingPeaksAtQuarterPeriod() {
        // For speed=1, period = 1.0; quarter period = 0.25 → sin(π/2) = 1 → max
        let peak: UInt8 = 200
        let e = BreathingEffect(color: .white, peakBrightness: peak, speed: 1.0)
        #expect(e.frame(at: 0.25).frame.brightness == peak)
    }

    @Test func breathingHalfPeriodIsZeroAgain() {
        let e = BreathingEffect(color: .white, peakBrightness: 200, speed: 1.0)
        #expect(e.frame(at: 0.5).frame.brightness == 0)
    }

    @Test func breathingFrameDelayMatchesFrameRate() {
        let e = BreathingEffect(color: .white, peakBrightness: 200, speed: 1, frameRate: 30)
        let (_, next) = e.frame(at: 0)
        #expect(abs((next ?? 0) - 1.0/30.0) < 0.0001)
    }

    @Test func pulseOnPhaseEmitsColor() {
        let e = PulseEffect(color: RGBColor(red: 100, green: 0, blue: 0),
                            brightness: 200,
                            onDuration: 0.4,
                            offDuration: 0.25)
        let (frame, next) = e.frame(at: 0.1)
        #expect(frame.color == RGBColor(red: 100, green: 0, blue: 0))
        #expect(frame.brightness == 200)
        #expect(abs((next ?? 0) - 0.3) < 0.001)  // 0.4 - 0.1
    }

    @Test func pulseOffPhaseEmitsBlack() {
        let e = PulseEffect(color: RGBColor(red: 100, green: 0, blue: 0),
                            brightness: 200,
                            onDuration: 0.4,
                            offDuration: 0.25)
        #expect(e.frame(at: 0.5).frame == .off)
    }

    @Test func pulseCyclesAfterPeriod() {
        let e = PulseEffect(color: RGBColor(red: 50, green: 50, blue: 50),
                            brightness: 100,
                            onDuration: 0.4,
                            offDuration: 0.25)
        // t=0.66 ≈ start of next on-phase (cycle is 0.65)
        #expect(e.frame(at: 0.66).frame.color == RGBColor(red: 50, green: 50, blue: 50))
    }

    @Test func cycleStartsAtRed() {
        let e = CycleEffect(brightness: 255, speed: 1)
        #expect(e.frame(at: 0).frame.color == RGBColor(red: 255, green: 0, blue: 0))
    }

    @Test func cycleAdvancesHue() {
        let e = CycleEffect(brightness: 255, speed: 1)
        #expect(e.frame(at: 0).frame.color != e.frame(at: 1).frame.color)
    }

    @Test func effectFactoryDispatch() {
        let color = RGBColor(red: 1, green: 2, blue: 3)
        #expect(EffectFactory.make(mode: .staticColor, baseColor: color, brightnessPercent: 50, breathingSpeed: 0.5, cycleSpeed: 0.3) is StaticEffect)
        #expect(EffectFactory.make(mode: .breathing, baseColor: color, brightnessPercent: 50, breathingSpeed: 0.5, cycleSpeed: 0.3) is BreathingEffect)
        #expect(EffectFactory.make(mode: .pulse, baseColor: color, brightnessPercent: 50, breathingSpeed: 0.5, cycleSpeed: 0.3) is PulseEffect)
        #expect(EffectFactory.make(mode: .cycle, baseColor: color, brightnessPercent: 50, breathingSpeed: 0.5, cycleSpeed: 0.3) is CycleEffect)
    }

    @Test func effectFactoryConvertsBrightnessPercentage() {
        let e = EffectFactory.make(mode: .staticColor, baseColor: .white, brightnessPercent: 50,
                                   breathingSpeed: 0.5, cycleSpeed: 0.3)
        // 50% of 255 = 127 (integer div)
        #expect(e.frame(at: 0).frame.brightness == 127)
    }
}
