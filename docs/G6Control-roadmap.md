# G6 Control — future project plan

Standalone macOS menu-bar app for audio-DSP control of the Sound BlasterX G6 — sibling to **G6 Lighting** (which stays focused on RGB / ring LED).

Status: **not started**. Recorded so we don't forget.

---

## Why a separate repo (not merging into G6Lighting)

- Single-responsibility: G6 Lighting is "lighting only", trivially explainable
- Different mental model: lighting is set-and-forget; audio DSP is something users actively tweak per game/music
- Independent release cadences
- Smaller download for users who only want one
- If audio DSP work blocks on something hard, lighting work isn't held hostage

## Naming

- Repo: `G6Control` or `G6Audio` — pick when starting, lean towards `G6Control` if we eventually want to fold lighting + audio into one bundle download (it remains capable of running solo)
- Bundle ID: `local.g6control` (similar to `local.g6lighting`)
- Display name: "G6 Control"

## Features to ship in v0.1

Source: [`jackbrumley/rusty-g6`](https://github.com/jackbrumley/rusty-g6) — MIT-licensed Rust app for Linux/Windows. Wire format identical to ours (5A-prefixed 64-byte HID on interface 4, DATA + COMMIT framing).

- **Output toggle**: Headphones ↔ Speakers
- **SBX effects** (each: on/off + 0–100 slider):
  - Surround
  - Crystalizer
  - Bass
  - Smart Volume
  - Dialog Plus
- **Master SBX on/off**
- **Scout Mode**
- **Mic boost**: discrete 0 / 10 / 20 / 30 dB

## Stretch features

- Digital filter (DAC roll-off) — `rusty-g6` has it but marks the write as **unverified**. Test on real hardware first.
- Event listener for physical button presses (G6 sends notification packets when user touches device)
- Firmware version readout (display in About panel)
- Software volume — neither rusty-g6 nor nils-skowasch implement this; would need fresh reverse engineering
- Sidetone — same, would need fresh capture
- EQ writes — same, fresh capture needed

## Sources to copy from

All MIT-licensed. Attribute clearly in commit messages and README.

- [`jackbrumley/rusty-g6`](https://github.com/jackbrumley/rusty-g6) — packet builders in `src-tauri/src/g6_protocol_v2.rs`. Pure builder functions returning `Vec<u8>`. Mechanical port to Swift.
  - SBX builders: `:990, :1007` (Bass), `:1023, :1037` (Surround), `:1051, :1065` (Crystalizer), `:1079, :1093` (Smart Volume), `:1107, :1121` (Dialog Plus)
  - Output: `:937, :950`
  - Master SBX: `:1139`
  - Scout: `:1156`
  - Mic boost: `:1209`
- [`nils-skowasch/soundblaster-x-g6-cli`](https://github.com/nils-skowasch/soundblaster-x-g6-cli) — original protocol documentation in `doc/usb-protocol.md`. Already fully covered by rusty-g6 EXCEPT for Smart Volume Special and the slider-percent → IEEE 754 lookup table in `g6_core.py:198-300`.

## Architecture (reusable from G6 Lighting)

The 5-layer architecture from G6 Lighting carries over almost verbatim. Specifically:

- **Hardware/HIDTransport.swift + IOKitHIDTransport.swift** — copy as-is, add nothing
- **Hardware/MockHIDTransport.swift** — copy as-is for tests
- **Hardware/G6Protocol.swift** → split into `G6LightingProtocol.swift` (existing bytes) and new **`G6AudioProtocol.swift`** (port from rusty-g6)
- **Hardware/G6Device.swift** → expand high-level API: `setOutput / setSurround / setBass / setMicBoost / ...`
- **Domain/Models** — add `AudioOutputMode` enum, `SBXFeature` enum, `MicBoostLevel` enum
- **State/SettingsStore.swift** — new keys: `g6.audio.output`, `g6.audio.bass.enabled`, `g6.audio.bass.value` etc.
- **State/LightingViewModel.swift** → renamed `DeviceViewModel` (or split into `LightingViewModel` + `AudioViewModel` sharing one G6Device)
- **UI** — completely new sections: OutputSection, SBXSection (with 5 sub-controls), MicSection. Probably need tabs since popover would get tall.

## UI shape

Menu-bar popover with tabs (SwiftUI's TabView with `.tabViewStyle(.segmentedControl)` or custom). Two tabs at minimum:

- **Audio** (default): Output, SBX, Mic
- **About**: firmware version, device info, licence, link to G6 Lighting

If users complain about height, switch to a real window instead of popover.

## Cross-promotion with G6 Lighting

- G6 Lighting README footer: "For audio DSP control, see G6 Control"
- G6 Control README footer: "For RGB / volume-knob LED control, see G6 Lighting"
- Both apps can run simultaneously — they touch disjoint command families and use separate IOHIDDevice opens, no conflict expected (verify on first build)

## Effort estimate

- Scaffold project from G6 Lighting copy: 2 hours
- Port `g6_protocol_v2.rs` → Swift: 1 day
- Build UI for Output / SBX (5 features) / Mic: 1 day
- Tests for byte-exact output: 0.5 day
- First end-to-end test on real device: 0.5 day (user input needed)
- README + LICENSE + CI mirroring G6 Lighting: 0.5 day
- **Total: ~3-4 working days**

## Open questions for when we start

1. Single G6Device opened simultaneously by both apps — does macOS allow it? (We use non-exclusive IOHIDManager open; should be fine, but verify.)
2. Tabs vs separate windows for Audio / About? Tabs preferred for menu-bar app.
3. Should there be a "G6 Suite" parent bundle that ships both apps together as one DMG? Probably no — adds packaging complexity, users can install both individually.
4. Volume knob ring brightness — rusty-g6 doesn't touch it, neither does anyone else. Worth one-day capture session on Windows with USBPcap to see if Sound Blaster Command sends anything beyond on/off.

## When to start

Whenever you (the user) feel like it. This file is the breadcrumb. Reading this file + the G6 Lighting codebase + the two source repos = full context to begin.
