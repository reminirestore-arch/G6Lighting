import Foundation
import SwiftUI

/// Drives a `LightingEffect` and publishes the current frame so views can mirror
/// what the device displays. Device output and UI preview both consume frames
/// from this single source of truth.
@MainActor
public final class EffectPlayer: ObservableObject {
     public private(set) var currentFrame: LightingFrame = .off

    private var task: Task<Void, Never>?

    /// Start playing a new effect. Cancels any previous one.
    /// `onFrame` is called for every frame while playing — the LightingViewModel
    /// uses it to push to the device.
    public func play(_ effect: LightingEffect, onFrame: @MainActor @escaping (LightingFrame) async -> Void) {
        task?.cancel()
        task = Task { @MainActor [weak self] in
            guard let self else { return }
            let started = Date()
            while !Task.isCancelled {
                let now = Date().timeIntervalSince(started)
                let (frame, nextDelay) = effect.frame(at: now)
                self.currentFrame = frame
                await onFrame(frame)
                guard let delay = nextDelay else { return }
                let nanos = UInt64(max(0, delay) * 1_000_000_000)
                do {
                    try await Task.sleep(nanoseconds: nanos)
                } catch {
                    return
                }
            }
        }
    }

    public func stop(showing frame: LightingFrame = .off) {
        task?.cancel()
        currentFrame = frame
    }
}
