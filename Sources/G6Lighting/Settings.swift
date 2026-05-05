import Foundation
import SwiftUI

@MainActor
final class Settings: ObservableObject {
    @AppStorage("g6.isOn") var isOn: Bool = true
    @AppStorage("g6.ringLed") var ringLedOn: Bool = true
    @AppStorage("g6.color.red") var red: Int = 0
    @AppStorage("g6.color.green") var green: Int = 128
    @AppStorage("g6.color.blue") var blue: Int = 255
    @AppStorage("g6.brightness") var brightness: Int = 100
    @AppStorage("g6.mode") var modeRaw: String = LightingMode.staticColor.rawValue
    @AppStorage("g6.cycleSpeed") var cycleSpeed: Double = 0.3
    @AppStorage("g6.breathingSpeed") var breathingSpeed: Double = 0.5

    var mode: LightingMode {
        get { LightingMode(rawValue: modeRaw) ?? .staticColor }
        set { modeRaw = newValue.rawValue; objectWillChange.send() }
    }

    var color: Color {
        get { Color(red: Double(red) / 255.0, green: Double(green) / 255.0, blue: Double(blue) / 255.0) }
        set {
            let comps = NSColor(newValue).usingColorSpace(.sRGB) ?? .red
            red = clamp(Int(comps.redComponent * 255))
            green = clamp(Int(comps.greenComponent * 255))
            blue = clamp(Int(comps.blueComponent * 255))
            objectWillChange.send()
        }
    }

    private func clamp(_ v: Int) -> Int { max(0, min(255, v)) }
}
