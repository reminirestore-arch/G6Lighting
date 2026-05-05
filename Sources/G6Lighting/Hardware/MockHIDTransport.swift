import Foundation

/// In-memory transport for tests and previews. Records every report it receives,
/// optionally fails on demand, and offers helpers to inspect what was sent.
final class MockHIDTransport: HIDTransport, @unchecked Sendable {
    enum FailureMode: Sendable {
        case never
        case once
        case always
    }

    private let lock = NSLock()
    private var _sentReports: [[UInt8]] = []
    private var _failureMode: FailureMode = .never
    private var _failureError: HIDTransportError = .deviceNotFound

    var sentReports: [[UInt8]] {
        lock.lock(); defer { lock.unlock() }
        return _sentReports
    }

    func setFailureMode(_ mode: FailureMode, error: HIDTransportError = .deviceNotFound) {
        lock.lock(); defer { lock.unlock() }
        _failureMode = mode
        _failureError = error
    }

    func reset() {
        lock.lock(); defer { lock.unlock() }
        _sentReports.removeAll()
        _failureMode = .never
    }

    func send(reports: [[UInt8]]) async throws {
        lock.lock()
        let mode = _failureMode
        let error = _failureError
        if mode == .once { _failureMode = .never }
        lock.unlock()

        if mode != .never {
            throw error
        }

        lock.lock()
        _sentReports.append(contentsOf: reports)
        lock.unlock()
    }
}
