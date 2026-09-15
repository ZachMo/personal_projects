import SwiftUI
import FirstTownCore

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB, red: Double(hex >> 16 & 255) / 255, green: Double(hex >> 8 & 255) / 255, blue: Double(hex & 255) / 255, opacity: opacity)
    }
}

/// The web version's colours: a dark table, light cards, one warm accent.
enum Palette {
    static let table = Color(hex: 0x1b2422)
    static let tableGlow = Color(hex: 0x2d3a36)
    static let glass = Color.white.opacity(0.07)
    static let hudSub = Color(hex: 0x9fb0a9)

    static let card = Color(hex: 0xfbf9f4)
    static let card2 = Color(hex: 0xf0ece3)
    static let line = Color(hex: 0xe6e1d6)
    static let ink = Color(hex: 0x1f2624)
    static let ink2 = Color(hex: 0x5b645f)
    static let muted = Color(hex: 0x8c938e)

    static let accent = Color(hex: 0xe0703f)
    static let accentDeep = Color(hex: 0xc05a2e)
    static let good = Color(hex: 0x2f8a55)
    static let goodBg = Color(hex: 0xe4f2e8)
    static let bad = Color(hex: 0xb8412f)
    static let badBg = Color(hex: 0xf9e5e0)

    static func category(_ c: FirstTownCore.Category) -> Color {
        switch c {
        case .home: Color(hex: 0xd8734a)
        case .agri: Color(hex: 0xc9952a)
        case .industry: Color(hex: 0x6f7d8b)
        case .shop: Color(hex: 0x33968a)
        case .civic: Color(hex: 0x5a7fc4)
        case .leisure: Color(hex: 0xa8588f)
        }
    }
}
