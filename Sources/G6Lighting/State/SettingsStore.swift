import Foundation
import SwiftUI

/// Single observable bag of user-settable preferences. Backed by an injectable
/// KeyValueStore so tests can run with InMemoryKeyValueStore instead of UserDefaults.
@MainActor
final class SettingsStore: ObservableObject {
    private enum Key {
        static let isOn = "g6.isOn"
        static let ringLed = "g6.ringLed"
        static let red = "g6.color.red"
        static let green = "g6.color.green"
        static let blue = "g6.color.blue"
        static let brightness = "g6.brightness"
        static let mode = "g6.mode"
        static let cycleSpeed = "g6.cycleSpeed"
        static let breathingSpeed = "g6.breathingSpeed"
    }

    private let store: KeyValueStore

    @Published var isOn: Bool          { didSet { store.setBool(isOn, forKey: Key.isOn) } }
    @Published var ringLedOn: Bool     { didSet { store.setBool(ringLedOn, forKey: Key.ringLed) } }
    @Published var red: Int            { didSet { store.setInteger(red, forKey: Key.red) } }
    @Published var green: Int          { didSet { store.setInteger(green, forKey: Key.green) } }
    @Published var blue: Int           { didSet { store.setInteger(blue, forKey: Key.blue) } }
    @Published var brightness: Int     { didSet { store.setInteger(brightness, forKey: Key.brightness) } }
    @Published var mode: LightingMode  { didSet { store.setString(mode.rawValue, forKey: Key.mode) } }
    @Published var cycleSpeed: Double  { didSet { store.setDouble(cycleSpeed, forKey: Key.cycleSpeed) } }
    @Published var breathingSpeed: Double { didSet { store.setDouble(breathingSpeed, forKey: Key.breathingSpeed) } }

    init(store: KeyValueStore = UserDefaults.standard) {
        self.store = store
        self.isOn = store.bool(forKey: Key.isOn, default: true)
        self.ringLedOn = store.bool(forKey: Key.ringLed, default: true)
        self.red = store.integer(forKey: Key.red, default: 0)
        self.green = store.integer(forKey: Key.green, default: 128)
        self.blue = store.integer(forKey: Key.blue, default: 255)
        self.brightness = store.integer(forKey: Key.brightness, default: 100)
        let modeRaw = store.string(forKey: Key.mode) ?? LightingMode.staticColor.rawValue
        self.mode = LightingMode(rawValue: modeRaw) ?? .staticColor
        self.cycleSpeed = store.double(forKey: Key.cycleSpeed, default: 0.3)
        self.breathingSpeed = store.double(forKey: Key.breathingSpeed, default: 0.5)
    }

    var color: RGBColor {
        get { RGBColor(red: UInt8(clamp(red)), green: UInt8(clamp(green)), blue: UInt8(clamp(blue))) }
        set { red = Int(newValue.red); green = Int(newValue.green); blue = Int(newValue.blue) }
    }

    private func clamp(_ v: Int) -> Int { max(0, min(255, v)) }
}
