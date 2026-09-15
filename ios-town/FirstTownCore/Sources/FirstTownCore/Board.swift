/// The grid, 9 squares by 12, addressed by one index: `y * cols + x`.
public enum Board {
    public static let cols = 9
    public static let rows = 12
    public static let count = cols * rows

    /// Right, left, down, up: the order the web version checks neighbours in.
    /// Placement order and tie-breaks depend on it.
    public static let steps: [(dx: Int, dy: Int)] = [(1, 0), (-1, 0), (0, 1), (0, -1)]

    public static func index(_ x: Int, _ y: Int) -> Int { y * cols + x }
    public static func col(_ i: Int) -> Int { i % cols }
    public static func row(_ i: Int) -> Int { i / cols }
    public static func inside(_ x: Int, _ y: Int) -> Bool { x >= 0 && y >= 0 && x < cols && y < rows }

    /// The squares that share a side with `i`.
    public static func around(_ i: Int) -> [Int] {
        let x = col(i), y = row(i)
        return steps.compactMap { inside(x + $0.dx, y + $0.dy) ? index(x + $0.dx, y + $0.dy) : nil }
    }
}

func clamp(_ v: Int, _ lo: Int, _ hi: Int) -> Int { max(lo, min(hi, v)) }

/// Mulberry32, the generator the web version uses. Every draw matches it bit for bit,
/// so a seed builds the same map and deck here as it does in the browser.
public struct Mulberry32: Sendable {
    private var state: Int32

    public init(seed: Int32) { state = seed }

    public mutating func next() -> Double {
        state = state &+ 0x6D2B79F5
        let s = state
        var t = (s ^ Int32(bitPattern: UInt32(bitPattern: s) >> 15)) &* (1 | s)
        t = (t &+ ((t ^ Int32(bitPattern: UInt32(bitPattern: t) >> 7)) &* (61 | t))) ^ t
        let out = UInt32(bitPattern: t ^ Int32(bitPattern: UInt32(bitPattern: t) >> 14))
        return Double(out) / 4_294_967_296
    }

    /// A whole number from `a` to `b`, both included.
    mutating func int(_ a: Int, _ b: Int) -> Int {
        a + Int((next() * Double(b - a + 1)).rounded(.down))
    }

    /// One item from the list. It spends a draw even when the list is empty, as the web version does,
    /// so the draws that follow stay in step.
    mutating func pick<T>(_ items: [T]) -> T? {
        let r = next()
        return items.isEmpty ? nil : items[Int((r * Double(items.count)).rounded(.down))]
    }

    mutating func shuffle<T>(_ items: inout [T]) {
        var i = items.count - 1
        while i > 0 {
            let j = Int((next() * Double(i + 1)).rounded(.down))
            items.swapAt(i, j)
            i -= 1
        }
    }
}
