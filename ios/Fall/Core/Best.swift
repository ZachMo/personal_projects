import Foundation

/// Best scores. Most games want the highest number; golf wants the lowest.
enum Best {
    static func get(_ game: String) -> Double {
        Store.read("best_" + game, 0.0)
    }

    /// Returns true when this run beat the stored best.
    @discardableResult
    static func set(_ game: String, _ value: Double) -> Bool {
        guard value > get(game) else { return false }
        Store.write("best_" + game, value)
        return true
    }

    /// Golf is won by the smallest number.
    @discardableResult
    static func setLow(_ game: String, _ value: Double) -> Bool {
        let current = get(game)
        guard current == 0 || value < current else { return false }
        Store.write("best_" + game, value)
        return true
    }

    static func wipe() { Store.dropAll() }
}
