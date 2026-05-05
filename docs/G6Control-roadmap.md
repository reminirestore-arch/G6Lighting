# G6 Control — future companion app

Standalone macOS menu-bar app for **complete** Sound BlasterX G6 management — RGB lighting + volume-knob LED + audio DSP (output toggle, SBX effects, mic boost, etc.) all in one place.

Status: **not started**. Recorded so we don't forget.

## Relationship with G6 Lighting (this repo)

**G6 Control will be a separate repo, not a merge or rename of G6 Lighting.** Both apps will coexist and stay actively maintained:

- **G6 Lighting** = small, focused, lighting-only. For users who only care about RGB / ring LED and want a minimal app.
- **G6 Control** = full-featured. Bundles lighting AND audio DSP. For users who want a single app that manages everything the G6 can do.

The two apps will share the same wire protocol (`G6Protocol.swift` and friends) but diverge on UI scope and audio surface area. G6 Control will copy G6 Lighting's protocol/transport/effects code as foundation, add audio packet builders, and ship a larger UI.

Both can be installed at the same time — they touch disjoint command families on the G6's HID interface 4 (lighting on `0x3a`/`0x39`, audio on `0x12`/`0x26`/`0x2c`/`0x3c`) and use non-exclusive IOHIDManager opens. No conflict expected.

## Naming

- Repo: `G6Control` (new, separate from `G6Lighting`)
- Bundle ID: `local.g6control`
- Display name: "G6 Control"

## Features to ship in v0.1

Lighting features (copied from G6 Lighting):
- X-logo full RGB color, brightness, four effects
- Volume-knob LED toggle
- Master on/off

Audio features (port from [`jackbrumley/rusty-g6`](https://github.com/jackbrumley/rusty-g6) — MIT-licensed Rust app for Linux/Windows, identical wire format):
- Output toggle: Headphones ↔ Speakers
- SBX effects (each with on/off + 0–100 slider): Surround, Crystalizer, Bass, Smart Volume, Dialog Plus
- Master SBX on/off, Scout Mode
- Mic Boost: discrete 0 / 10 / 20 / 30 dB

Stretch (post-v0.1):
- Digital filter (DAC roll-off — rusty-g6 has it but write is unverified, test on real hardware first)
- Event listener for physical button presses (G6 emits packets when user touches device)
- Firmware version readout in About panel
- Software volume — neither rusty-g6 nor nils-skowasch implement this; would need fresh capture
- Sidetone — same, would need fresh capture
- EQ writes — same

## Sources to copy from

All MIT-licensed. Attribute clearly in commit messages and README.

- [`jackbrumley/rusty-g6`](https://github.com/jackbrumley/rusty-g6) — packet builders in `src-tauri/src/g6_protocol_v2.rs`. Pure builder functions returning `Vec<u8>`. Mechanical port to Swift.
  - SBX builders: `:990, :1007` (Bass), `:1023, :1037` (Surround), `:1051, :1065` (Crystalizer), `:1079, :1093` (Smart Volume), `:1107, :1121` (Dialog Plus)
  - Output: `:937, :950`
  - Master SBX: `:1139`
  - Scout: `:1156`
  - Mic boost: `:1209`
- [`nils-skowasch/soundblaster-x-g6-cli`](https://github.com/nils-skowasch/soundblaster-x-g6-cli) — original protocol documentation in `doc/usb-protocol.md` and slider-percent → IEEE 754 lookup table in `g6_core.py:198-300`.
- **G6 Lighting** (this repo) — copy `Hardware/`, `Domain/`, `State/SettingsStore.swift`, `State/EffectPlayer.swift` as starting point.

## Architecture (reused from G6 Lighting)

The 5-layer architecture from G6 Lighting carries over almost verbatim:

- **Hardware/HIDTransport.swift + IOKitHIDTransport.swift** — copy as-is
- **Hardware/MockHIDTransport.swift** — copy as-is for tests
- **Hardware/G6Protocol.swift** → split into `G6LightingProtocol.swift` (existing bytes) and new **`G6AudioProtocol.swift`** (port from rusty-g6)
- **Hardware/G6Device.swift** → expand high-level API: `setOutput / setSurround / setBass / setMicBoost / ...`
- **Domain/Models** — add `AudioOutputMode` enum, `SBXFeature` enum, `MicBoostLevel` enum
- **State/SettingsStore.swift** — new keys: `g6.audio.output`, `g6.audio.bass.enabled`, `g6.audio.bass.value`, etc.
- **State/LightingViewModel.swift** → renamed to `DeviceViewModel` (or split into `LightingViewModel` + `AudioViewModel` sharing one G6Device)
- **UI** — completely new sections on top of existing ones: OutputSection, SBXSection (with 5 sub-controls), MicSection. Switch popover layout to `TabView` (Lighting / Audio / Device tabs) since a flat list would get too tall.

## UI shape

Menu-bar popover with tabs (SwiftUI's `TabView`). Three tabs:
- **Lighting** — current G6 Lighting UI (Color / Effect sections)
- **Audio** — Output, SBX, Mic, Filters
- **Device** — ring LED, autolaunch, firmware version, about

If users complain about height, switch to a real window instead of popover.

## Cross-promotion (ongoing, both apps stay alive)

- **G6 Lighting README** mentions "for full G6 management including audio, see G6 Control"
- **G6 Control README** mentions "if you only need RGB/ring control, G6 Lighting is a smaller alternative"
- Both apps work independently; users pick what they want

## Effort estimate

- Scaffold project from G6 Lighting copy: 2 hours
- Port `g6_protocol_v2.rs` → Swift: 1 day
- Build UI for Output / SBX (5 features) / Mic with TabView: 1.5 days
- Tests for byte-exact output: 0.5 day
- First end-to-end test on real device: 0.5 day (user input needed)
- README + LICENSE + CI mirroring G6 Lighting: 0.5 day
- **Total: ~4 working days**

## Open questions for when we start

1. Single G6 device opened simultaneously by both apps (G6 Lighting AND G6 Control running) — does macOS allow it? IOHIDManager non-exclusive open should work; verify on first build.
2. Tabs vs separate windows for the larger UI? Tabs preferred for menu-bar app.
3. Should there be a "G6 Suite" parent bundle that ships both apps as one DMG? Probably not — adds packaging complexity, users can install both individually.
4. Volume-knob ring brightness — neither rusty-g6 nor nils-skowasch touch it. One day of capture session on Windows with USBPcap to see if Sound Blaster Command sends anything beyond on/off would be worthwhile.

## When to start

Whenever the user feels like it. This file + the G6 Lighting codebase + the two source repos = full context to begin.
