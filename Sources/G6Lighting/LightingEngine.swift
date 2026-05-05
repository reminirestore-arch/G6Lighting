import Foundation
import Combine
import AppKit
import IOKit
import IOKit.hid

@MainActor
final class LightingEngine: ObservableObject {
    @Published private(set) var lastError: String?
    @Published private(set) var isConnected: Bool = false

    private let controller = G6Controller()
    private let settings: Settings
    private var animationTask: Task<Void, Never>?
    private var settingsCancellables: Set<AnyCancellable> = []
    private let frameInterval: UInt64 = 33_000_000  // ~30 fps
    private var hidManager: IOHIDManager?
    private var wakeObserver: NSObjectProtocol?

    init(settings: Settings) {
        self.settings = settings

        settings.objectWillChange
            .debounce(for: .milliseconds(80), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.restart()
            }
            .store(in: &settingsCancellables)

        startDeviceMonitor()
        startWakeMonitor()
        restart()
    }

    deinit {
        if let mgr = hidManager {
            IOHIDManagerUnscheduleFromRunLoop(mgr, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
            IOHIDManagerClose(mgr, IOOptionBits(kIOHIDOptionsTypeNone))
        }
        if let obs = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
        }
    }

    private func startDeviceMonitor() {
        let mgr = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let matching: [String: Any] = [
            kIOHIDVendorIDKey: Int(G6Protocol.vendorID),
            kIOHIDProductIDKey: Int(G6Protocol.productID),
        ]
        IOHIDManagerSetDeviceMatching(mgr, matching as CFDictionary)
        IOHIDManagerScheduleWithRunLoop(mgr, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerOpen(mgr, IOOptionBits(kIOHIDOptionsTypeNone))

        let context = Unmanaged.passUnretained(self).toOpaque()
        let callback: IOHIDDeviceCallback = { context, _, _, _ in
            guard let context = context else { return }
            let engine = Unmanaged<LightingEngine>.fromOpaque(context).takeUnretainedValue()
            DispatchQueue.main.async {
                // Small delay so device fully enumerates before we send
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    engine.restart()
                }
            }
        }
        IOHIDManagerRegisterDeviceMatchingCallback(mgr, callback, context)
        hidManager = mgr
    }

    private func startWakeMonitor() {
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Resend after wake; the device may have lost color state during sleep
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.restart()
            }
        }
    }

    func restart() {
        animationTask?.cancel()
        animationTask = Task { [weak self] in
            await self?.run()
        }
    }

    private func run() async {
        do {
            // Apply volume-knob ring LED state first (single shot, persisted in firmware)
            try await controller.setRingLed(enabled: settings.ringLedOn)

            if !settings.isOn {
                try await controller.disable()
                isConnected = true
                lastError = nil
                return
            }

            let baseColor = RGBColor(
                red: UInt8(settings.red),
                green: UInt8(settings.green),
                blue: UInt8(settings.blue)
            )
            let effect = EffectFactory.make(
                mode: settings.mode,
                baseColor: baseColor,
                brightnessPercent: settings.brightness,
                breathingSpeed: settings.breathingSpeed,
                cycleSpeed: settings.cycleSpeed
            )
            try await runEffect(effect)
        } catch is CancellationError {
            // ignore — restart triggered
        } catch {
            isConnected = false
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func runEffect(_ effect: LightingEffect) async throws {
        let started = Date()
        while !Task.isCancelled {
            let now = Date().timeIntervalSince(started)
            let (frame, nextDelay) = effect.frame(at: now)
            try await controller.setColor(
                red: frame.color.red,
                green: frame.color.green,
                blue: frame.color.blue,
                brightness: frame.brightness
            )
            isConnected = true
            lastError = nil
            guard let delay = nextDelay else { return }
            let nanos = UInt64(max(0, delay) * 1_000_000_000)
            try await Task.sleep(nanoseconds: nanos)
        }
    }
}
