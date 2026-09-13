import SpriteKit
import SwiftUI

/// The CSS custom properties from the top of fall.html, kept in one place so the
/// SwiftUI shell and the SpriteKit scenes agree on a colour.
enum Palette {
    // Shell
    static let bg      = Color(hex: 0x0E1118)
    static let panel   = Color(hex: 0x171C27)
    static let panel2  = Color(hex: 0x1E2431)
    static let line    = Color(hex: 0x29303F)
    static let ink     = Color(hex: 0xF2F4F8)
    static let ink2    = Color(hex: 0x98A2B6)
    static let muted   = Color(hex: 0x6D7688)
    static let accent  = Color(hex: 0xFFB703)
    static let accent2 = Color(hex: 0x4CC9F0)
    static let good    = Color(hex: 0x6EE7A8)
    static let bad     = Color(hex: 0xFF6B6B)

    /// Text on top of the amber accent.
    static let onAccent = Color(hex: 0x17130A)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8)  & 0xFF) / 255,
            blue:  Double(hex         & 0xFF) / 255,
            opacity: alpha
        )
    }
}

extension UIColor {
    /// `UIColor(hex: 0x15151A)` reads closer to the `#15151b` in the original
    /// than three divided components do. `SKColor` is the same type on iOS.
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red:   CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8)  & 0xFF) / 255,
            blue:  CGFloat(hex         & 0xFF) / 255,
            alpha: alpha
        )
    }
}
