import UIKit

/// Replaces `buzz(ms)`. The web version passed milliseconds, or an array for a
/// pattern; iOS has no duration control, so length becomes weight instead.
enum Haptics {
    private static let light  = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let heavy  = UIImpactFeedbackGenerator(style: .heavy)

    /// Warms the Taptic Engine so the first hit of a run is not late.
    static func prepare() {
        light.prepare(); medium.prepare(); heavy.prepare()
    }

    static func buzz(_ ms: Int) {
        guard Settings.shared.haptics else { return }
        generator(for: ms).impactOccurred()
    }

    /// A pattern, played back with the gaps the numbers imply.
    static func buzz(_ pattern: [Int]) {
        guard Settings.shared.haptics, !pattern.isEmpty else { return }
        var delay = 0.0
        for ms in pattern {
            let g = generator(for: ms)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { g.impactOccurred() }
            delay += Double(ms) / 1000 + 0.045
        }
    }

    private static func generator(for ms: Int) -> UIImpactFeedbackGenerator {
        switch ms {
        case ..<20:  return light
        case ..<45:  return medium
        default:     return heavy
        }
    }
}
