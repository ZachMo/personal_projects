import CoreGraphics
import Foundation

/// The handful of helpers the web version kept at the top of the file.
let TAU = CGFloat.pi * 2

@inlinable func clamp(_ v: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
    v < lo ? lo : (v > hi ? hi : v)
}

@inlinable func clamp(_ v: Int, _ lo: Int, _ hi: Int) -> Int {
    v < lo ? lo : (v > hi ? hi : v)
}

@inlinable func rand(_ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
    lo + CGFloat.random(in: 0..<1) * (hi - lo)
}

@inlinable func pick<T>(_ a: [T]) -> T {
    a[Int.random(in: 0..<a.count)]
}

extension CGFloat {
    /// Moves toward a target by a proportion of the remaining distance, the
    /// `x += (want - x) * k` idiom the games lean on.
    @inlinable mutating func ease(to target: CGFloat, _ k: CGFloat) {
        self += (target - self) * Swift.min(1, k)
    }
}
