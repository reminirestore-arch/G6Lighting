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
            switch settings.mode {
            case .staticColor:
                try await sendStatic()
            case .breathing:
                try await runBreathing()
            case .pulse:
                try await runPulse()
            case .cycle:
                try await runCycle()
            }
        } catch is CancellationError {
            // ignore — restart triggered
        } catch {
            isConnected = false
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func sendStatic() async throws {
        let r = UInt8(settings.red), g = UInt8(settings.green), b = UInt8(settings.blue)
        let bri = UInt8(min(255, settings.brightness * 255 / 100))
        try await controller.setColor(red: r, green: g, blue: b, brightness: bri)
        isConnected = true
        lastError = nil
    }

    private func runBreathing() async throws {
        let r = UInt8(settings.red), g = UInt8(settings.green), b = UInt8(settings.blue)
        let baseBri = Double(settings.brightness) / 100.0
        let speed = max(0.05, settings.breathingSpeed)
        var phase: Double = 0
        while !Task.isCancelled {
            let intensity = (sin(phase) + 1) / 2 * baseBri
            let bri = UInt8(max(0, min(255, intensity * 255)))
            try await controller.setColor(red: r, green: g, blue: b, brightness: bri)
            isConnected = true
            lastError = nil
            phase += 0.05 * speed * 2 * .pi
            try await Task.sleep(nanoseconds: frameInterval)
        }
    }

    private func runPulse() async throws {
        let r = UInt8(settings.red), g = UInt8(settings.green), b = UInt8(settings.blue)
        let bri = UInt8(min(255, settings.brightness * 255 / 100))
        while !Task.isCancelled {
            try await controller.setColor(red: r, green: g, blue: b, brightness: bri)
            isConnected = true
            lastError = nil
            try await Task.sleep(nanoseconds: 400_000_000)
            try await controller.setColor(red: 0, green: 0, blue: 0, brightness: 0)
            try await Task.sleep(nanoseconds: 250_000_000)
        }
    }

    private func runCycle() async throws {
        let bri = UInt8(min(255, settings.brightness * 255 / 100))
        let speed = max(0.05, settings.cycleSpeed)
        var hue: Double = 0
        while !Task.isCancelled {
            let (r, g, b) = hsvToRgb(hue: hue, saturation: 1, value: 1)
            try await controller.setColor(red: r, green: g, blue: b, brightness: bri)
            isConnected = true
            lastError = nil
            hue = (hue + 0.005 * speed * 5).truncatingRemainder(dividingBy: 1)
            try await Task.sleep(nanoseconds: frameInterval)
        }
    }

    private func hsvToRgb(hue: Double, saturation: Double, value: Double) -> (UInt8, UInt8, UInt8) {
        let h = hue * 6
        let i = floor(h)
        let f = h - i
        let p = value * (1 - saturation)
        let q = value * (1 - saturation * f)
        let t = value * (1 - saturation * (1 - f))
        let (r, g, b): (Double, Double, Double)
        switch Int(i) % 6 {
        case 0: (r, g, b) = (value, t, p)
        case 1: (r, g, b) = (q, value, p)
        case 2: (r, g, b) = (p, value, t)
        case 3: (r, g, b) = (p, q, value)
        case 4: (r, g, b) = (t, p, value)
        default: (r, g, b) = (value, p, q)
        }
        return (UInt8(r * 255), UInt8(g * 255), UInt8(b * 255))
    }
}
