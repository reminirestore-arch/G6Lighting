import Foundation
import Combine

@MainActor
public final class LightingViewModel: ObservableObject {
    @Published public private(set) var lastError: String?
    @Published public private(set) var isConnected: Bool = false

    public let settings: SettingsStore
    public let player: EffectPlayer
    private let device: G6Device
    private var cancellables: Set<AnyCancellable> = []
    private var deviceMonitor: DeviceMonitor?
    private var wakeMonitor: WakeMonitor?

    public init(
        settings: SettingsStore,
        device: G6Device,
        player: EffectPlayer? = nil,
        installSystemMonitors: Bool = true
    ) {
        self.settings = settings
        self.device = device
        self.player = player ?? EffectPlayer()

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

    public func restart() {
        Task { [weak self] in
            await self?.run()
        }
    }

    private func run() async {
        do {
            try await device.setRingLed(enabled: settings.ringLedOn)

            if !settings.isOn {
                player.stop(showing: .off)
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
            // Single source of truth: EffectPlayer ticks frames; we forward each
            // to the device. The same player publishes currentFrame to the UI.
            player.play(effect) { [weak self] frame in
                guard let self else { return }
                do {
                    try await self.device.setColor(frame)
                    self.isConnected = true
                    self.lastError = nil
                } catch is CancellationError {
                    // restart triggered
                } catch {
                    self.isConnected = false
                    self.lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
        } catch is CancellationError {
            // restart triggered
        } catch {
            isConnected = false
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
