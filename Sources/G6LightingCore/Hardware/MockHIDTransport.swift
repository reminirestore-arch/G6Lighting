import Foundation
import os

/// In-memory transport for tests and previews. Records every report it receives,
/// optionally fails on demand, and offers helpers to inspect what was sent.
public final class MockHIDTransport: HIDTransport, @unchecked Sendable {
    public enum FailureMode: Sendable {
        case never
        case once
        case always
    }

    public init() {}

    private struct State {
        var sentReports: [[UInt8]] = []
        var failureMode: FailureMode = .never
        var failureError: HIDTransportError = .deviceNotFound
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    public var sentReports: [[UInt8]] {
        state.withLock { $0.sentReports }
    }

    public func setFailureMode(_ mode: FailureMode, error: HIDTransportError = .deviceNotFound) {
        state.withLock {
            $0.failureMode = mode
            $0.failureError = error
        }
    }

    public func reset() {
        state.withLock {
            $0.sentReports.removeAll()
            $0.failureMode = .never
        }
    }

    public func send(reports: [[UInt8]]) async throws {
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
