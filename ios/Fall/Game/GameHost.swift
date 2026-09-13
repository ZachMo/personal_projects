import Foundation
import Observation

/// What the running game wants to show outside the scene: the HUD readout and
/// the overlay panel. The web version wrote straight into the DOM; here the
/// SwiftUI shell watches this instead.
@Observable
final class GameHost {
    static let shared = GameHost()

    var hudBig = "0"
    var hudSub = ""
    var overlay: Overlay?

    /// Set by the play screen, so a game can send the player back to the list.
    @ObservationIgnored var goHome: () -> Void = {}

    private init() {}

    func hud(_ big: String, _ sub: String = "") {
        hudBig = big
        hudSub = sub
    }

    func show(_ overlay: Overlay) { self.overlay = overlay }
    func hideOverlay() { overlay = nil }
    var overlayShowing: Bool { overlay != nil }
}

struct Overlay: Identifiable {
    let id = UUID()
    var title: String
    var why: String?
    var score: String?
    var best: String?
    var actions: [OverlayAction]
}

struct OverlayAction: Identifiable {
    enum Kind { case primary, ghost }

    let id = UUID()
    var label: String
    var kind: Kind
    var run: () -> Void

    static func primary(_ label: String, _ run: @escaping () -> Void) -> OverlayAction {
        OverlayAction(label: label, kind: .primary, run: run)
    }

    static func ghost(_ label: String, _ run: @escaping () -> Void) -> OverlayAction {
        OverlayAction(label: label, kind: .ghost, run: run)
    }
}
