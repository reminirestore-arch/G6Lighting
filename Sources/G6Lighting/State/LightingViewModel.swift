import Foundation
import Combine

@MainActor
final class LightingViewModel: ObservableObject {
    @Published private(set) var lastError: String?
    @Published private(set) var isConnected: Bool = false

    let settings: SettingsStore
    private let device: G6Device
    private var animationTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []
    private var deviceMonitor: DeviceMonitor?
    private var wakeMonitor: WakeMonitor?

    init(
        settings: SettingsStore,
        device: G6Device,
        installSystemMonitors: Bool = true
    ) {
        self.settings = settings
        self.device = device

        settings.objectWillChange
            .debounce(for: .milliseconds(80), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.restart() }
            .store(in: &cancellables)

        if installSystemMonitors {
            installMonitors()
        }
        restart()
    }

    private func installMonitors() {
        deviceMonitor = DeviceMonitor(
            vendorID: G6Protocol.vendorID,
            productID: G6Protocol.productID
        ) { [weak self] event in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard let self else { return }
                switch event {
                case .connected: self.restart()
                case .disconnected: self.isConnected = false
                }
            }
        }

        wakeMonitor = WakeMonitor { [weak self] in
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
            try await device.setRingLed(enabled: settings.ringLedOn)

            if !settings.isOn {
                try await device.disableLogo()
                isConnected = true
                lastError = nil
                return
            }

            let effect = EffectFactory.make(
                mode: settings.mode,
                baseColor: settings.color,
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
