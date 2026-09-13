import Foundation

/// Stands in for the `Store` object built on localStorage. Same `fall_` key
/// prefix, so a future import from the web version has somewhere to land.
enum Store {
    private static let prefix = "fall_"
    private static let defaults = UserDefaults.standard

    static func read<T>(_ key: String, _ fallback: T) -> T {
        defaults.object(forKey: prefix + key) as? T ?? fallback
    }

    static func write<T>(_ key: String, _ value: T) {
        defaults.set(value, forKey: prefix + key)
    }

    static func drop(_ key: String) {
        defaults.removeObject(forKey: prefix + key)
    }

    /// Clears every key this app owns and leaves the rest of UserDefaults alone.
    static func dropAll() {
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            defaults.removeObject(forKey: key)
        }
    }
}
