import Foundation
import os

/// In-memory transport for tests and previews. Records every report it receives,
/// optionally fails on demand, and offers helpers to inspect what was sent.
final class MockHIDTransport: HIDTransport, @unchecked Sendable {
    enum FailureMode: Sendable {
        case never
        case once
        case always
    }

    private struct State {
        var sentReports: [[UInt8]] = []
        var failureMode: FailureMode = .never
        var failureError: HIDTransportError = .deviceNotFound
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    var sentReports: [[UInt8]] {
        state.withLock { $0.sentReports }
    }

    func setFailureMode(_ mode: FailureMode, error: HIDTransportError = .deviceNotFound) {
        state.withLock {
            $0.failureMode = mode
            $0.failureError = error
        }
    }

    func reset() {
        state.withLock {
            $0.sentReports.removeAll()
            $0.failureMode = .never
        }
    }

    func send(reports: [[UInt8]]) async throws {
        let result: HIDTransportError? = state.withLock {
            let mode = $0.failureMode
            let err = $0.failureError
            if mode == .once { $0.failureMode = .never }
            if mode != .never {
                return err
            }
            $0.sentReports.append(contentsOf: reports)
            return nil
        }
        if let result {
            throw result
        }
    }
}
