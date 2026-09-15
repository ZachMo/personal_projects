import UIKit

/// Taps you can feel: a light tick when the building turns, a thud when it lands, a lift when it earns a trophy.
enum Haptics {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let notice = UINotificationFeedbackGenerator()

    static func tick() { light.impactOccurred() }
    static func thud() { medium.impactOccurred() }
    static func celebrate() { notice.notificationOccurred(.success) }
}
