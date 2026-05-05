import Foundation
import Combine

@MainActor
final class LightingEngine: ObservableObject {
    @Published private(set) var lastError: String?
    @Published private(set) var isConnected: Bool = false

    private let device: G6Device
    private let settings: Settings
    private var animationTask: Task<Void, Never>?
    private var settingsCancellables: Set<AnyCancellable> = []
    private var deviceMonitor: DeviceMonitor?
    private var wakeMonitor: WakeMonitor?

    init(settings: Settings, device: G6Device = .makeReal()) {
        self.settings = settings
        self.device = device

        settings.objectWillChange
            .debounce(for: .milliseconds(80), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.restart()
            }
            .store(in: &settingsCancellables)

        deviceMonitor = DeviceMonitor(
            vendorID: G6Protocol.vendorID,
            productID: G6Protocol.productID
        ) { [weak self] event in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard let self else { return }
                if case .connected = event { self.restart() }
                if case .disconnected = event { self.isConnected = false }
            }
        }

        wakeMonitor = WakeMonitor { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.restart()
            }
        }

        restart()
    }

    func restart() {
        animationTask?.cancel()
        animationTask = Task { [weak self] in
            await self?.run()
        }
    }

    private func run() async {
        do {
            try await device.setRingLed(enabled: settings.ringLedOn)

            if !settings.isOn {
                try await device.disableLogo()
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
            try await device.setColor(frame)
            isConnected = true
            lastError = nil
            guard let delay = nextDelay else { return }
            let nanos = UInt64(max(0, delay) * 1_000_000_000)
            try await Task.sleep(nanoseconds: nanos)
        }
    }
}
