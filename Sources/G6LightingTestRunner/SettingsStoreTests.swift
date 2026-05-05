import Testing
import G6LightingCore

@MainActor
@Suite("SettingsStore")
struct SettingsStoreTests {

    @Test func defaultsWhenStoreEmpty() {
        let store = SettingsStore(store: InMemoryKeyValueStore())
        #expect(store.isOn == true)
        #expect(store.ringLedOn == true)
        #expect(store.red == 0)
        #expect(store.green == 128)
        #expect(store.blue == 255)
        #expect(store.brightness == 100)
        #expect(store.mode == .staticColor)
    }

    @Test func writesPersist() {
        let backing = InMemoryKeyValueStore()
        let store = SettingsStore(store: backing)
        store.red = 200
        store.mode = .breathing
        store.ringLedOn = false

        let reloaded = SettingsStore(store: backing)
        #expect(reloaded.red == 200)
        #expect(reloaded.mode == .breathing)
        #expect(reloaded.ringLedOn == false)
    }

    @Test func colorComputedAccessor() {
        let store = SettingsStore(store: InMemoryKeyValueStore())
        store.color = RGBColor(red: 10, green: 20, blue: 30)
        #expect(store.red == 10)
        #expect(store.green == 20)
        #expect(store.blue == 30)
        #expect(store.color == RGBColor(red: 10, green: 20, blue: 30))
    }

    @Test func colorClampsOutOfRangeIntegers() {
        let store = SettingsStore(store: InMemoryKeyValueStore())
        store.red = 999
        store.green = -50
        #expect(store.color.red == 255)
        #expect(store.color.green == 0)
    }

    @Test func invalidStoredModeFallsBackToStatic() {
        let backing = InMemoryKeyValueStore()
        backing.setString("nonsense_mode", forKey: "g6.mode")
        let store = SettingsStore(store: backing)
        #expect(store.mode == .staticColor)
    }
}
