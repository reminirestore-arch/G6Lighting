import Testing
import G6LightingCore

@Suite("RGBColor")
struct RGBColorTests {

    @Test func hexParseValid() {
        #expect(RGBColor(hex: "FF0000") == RGBColor(red: 0xFF, green: 0, blue: 0))
        #expect(RGBColor(hex: "#00FF00") == RGBColor(red: 0, green: 0xFF, blue: 0))
        #expect(RGBColor(hex: "  abcdef ") == RGBColor(red: 0xAB, green: 0xCD, blue: 0xEF))
    }

    @Test func hexParseInvalid() {
        #expect(RGBColor(hex: "ZZZZZZ") == nil)
        #expect(RGBColor(hex: "12345") == nil)
        #expect(RGBColor(hex: "1234567") == nil)
        #expect(RGBColor(hex: "") == nil)
    }

    @Test func hexEmit() {
        #expect(RGBColor(red: 0, green: 128, blue: 255).hex == "0080FF")
        #expect(RGBColor(red: 0xAB, green: 0xCD, blue: 0xEF).hex == "ABCDEF")
        #expect(RGBColor.off.hex == "000000")
        #expect(RGBColor.white.hex == "FFFFFF")
    }

    @Test func hexRoundtrip() {
        for color: RGBColor in [.off, .white, RGBColor(red: 1, green: 2, blue: 3)] {
            #expect(RGBColor(hex: color.hex) == color)
        }
    }

    @Test func hsvPrimaries() {
        #expect(RGBColor.fromHSV(hue: 0, saturation: 1, value: 1) == RGBColor(red: 255, green: 0, blue: 0))

        let green = RGBColor.fromHSV(hue: 1.0/3.0, saturation: 1, value: 1)
        #expect(green.red == 0)
        #expect(green.green > 250)
        #expect(green.blue == 0)

        let blue = RGBColor.fromHSV(hue: 2.0/3.0, saturation: 1, value: 1)
        #expect(blue.red == 0)
        #expect(blue.green == 0)
        #expect(blue.blue > 250)
    }

    @Test func hsvHueWraps() {
        let a = RGBColor.fromHSV(hue: 0.25, saturation: 1, value: 1)
        let b = RGBColor.fromHSV(hue: 1.25, saturation: 1, value: 1)
        #expect(a == b)
    }

    @Test func hsvZeroSaturationGivesWhiteAtFullValue() {
        #expect(RGBColor.fromHSV(hue: 0.5, saturation: 0, value: 1) == RGBColor.white)
    }
}
