import Foundation

/// Persistence backend abstraction so tests can run against an in-memory store
/// instead of UserDefaults.
protocol KeyValueStore: AnyObject, Sendable {
    func bool(forKey: String, default: Bool) -> Bool
    func integer(forKey: String, default: Int) -> Int
    func double(forKey: String, default: Double) -> Double
    func string(forKey: String) -> String?

    func setBool(_ value: Bool, forKey: String)
    func setInteger(_ value: Int, forKey: String)
    func setDouble(_ value: Double, forKey: String)
    func setString(_ value: String?, forKey: String)
}

extension UserDefaults: @retroactive @unchecked Sendable {}

extension UserDefaults: KeyValueStore {
    func bool(forKey key: String, default defaultValue: Bool) -> Bool {
        object(forKey: key) as? Bool ?? defaultValue
    }
    func integer(forKey key: String, default defaultValue: Int) -> Int {
        object(forKey: key) as? Int ?? defaultValue
    }
    func double(forKey key: String, default defaultValue: Double) -> Double {
        object(forKey: key) as? Double ?? defaultValue
    }
    func string(forKey key: String) -> String? {
        object(forKey: key) as? String
    }

    func setBool(_ value: Bool, forKey key: String) { set(value, forKey: key) }
    func setInteger(_ value: Int, forKey key: String) { set(value, forKey: key) }
    func setDouble(_ value: Double, forKey key: String) { set(value, forKey: key) }
    func setString(_ value: String?, forKey key: String) { set(value, forKey: key) }
}

final class InMemoryKeyValueStore: KeyValueStore, @unchecked Sendable {
    private var values: [String: Any] = [:]
    private let queue = DispatchQueue(label: "kv.store")

    func bool(forKey key: String, default defaultValue: Bool) -> Bool {
        queue.sync { (values[key] as? Bool) ?? defaultValue }
    }
    func integer(forKey key: String, default defaultValue: Int) -> Int {
        queue.sync { (values[key] as? Int) ?? defaultValue }
    }
    func double(forKey key: String, default defaultValue: Double) -> Double {
        queue.sync { (values[key] as? Double) ?? defaultValue }
    }
    func string(forKey key: String) -> String? {
        queue.sync { values[key] as? String }
    }

    func setBool(_ value: Bool, forKey key: String) { queue.sync { values[key] = value } }
    func setInteger(_ value: Int, forKey key: String) { queue.sync { values[key] = value } }
    func setDouble(_ value: Double, forKey key: String) { queue.sync { values[key] = value } }
    func setString(_ value: String?, forKey key: String) {
        queue.sync {
            if let value { values[key] = value } else { values.removeValue(forKey: key) }
        }
    }
}
