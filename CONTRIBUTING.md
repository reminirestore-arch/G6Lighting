# Contributing

Thanks for your interest in G6 Lighting. This is a small focused tool, but contributions of any size are welcome — bug reports, fixes, new effects, support for related Creative devices, documentation, you name it.

## Quick start for contributors

```bash
git clone https://github.com/reminirestore-arch/G6Lighting.git
cd G6Lighting
./build.sh                # builds G6Lighting.app locally
swift run G6LightingTestRunner --testing-library swift-testing  # runs tests
```

You only need:
- macOS 14 or later
- Xcode Command Line Tools (`xcode-select --install`) — full Xcode is not required

## Before opening a PR

- **Run the tests.** All 46 must pass: `swift run G6LightingTestRunner --testing-library swift-testing`.
- **Build cleanly.** `swift build -c release --arch arm64` should produce zero warnings.
- **Test on real hardware** if you change anything in `Hardware/` (G6Protocol, G6Device, IOKitHIDTransport). The byte-exact protocol tests catch regressions in the wire format, but only the device confirms the change actually works.
- **Match the existing style.** Read a few neighbouring files. The codebase favours small, single-purpose types and thin views.

## Architecture at a glance

Five layers, each only depending on layers below it:

```
App      → @main, AppEnvironment (DI)
State    → SettingsStore, LightingViewModel, EffectPlayer
Domain   → RGBColor, LightingFrame, LightingMode, LightingEffect (4 impl)
Hardware → G6Protocol, HIDTransport (Mock + IOKit), G6Device
System   → DeviceMonitor, WakeMonitor, AutoLaunch
UI       → ContentView + 4 Sections + 4 Components
```

When adding a new effect, you usually only touch `Domain/Effects/` and `EffectFactory`. When adding a new HID command, you touch `Hardware/G6Protocol.swift` (bytes), `Hardware/G6Device.swift` (high-level method), and add a corresponding test.

## Reporting bugs

Use the issue templates. Helpful info:
- macOS version
- G6 firmware version (`bcdDevice` from `ioreg -r -n "Sound BlasterX G6"`)
- What you expected vs. what happened
- Whether the issue is reproducible after a USB reconnect

## Adding support for other Creative devices

The architecture supports it out of the box — `G6Protocol` and `G6Device` would become a family. If you want to extend, file an issue first to discuss the abstraction so we don't end up with parallel hierarchies.

## Licence

By contributing you agree your work is released under the project's MIT licence.
