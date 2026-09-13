import SpriteKit

/// The contract every game keeps, matching the object shape the web engine ran:
/// `init / resize / update / draw`, with drawing folded into the scene graph.
protocol FallGame: AnyObject {
    static var id: String { get }
    static var title: String { get }

    /// Golf and Ski are played over sky and snow, where white HUD text vanishes.
    var light: Bool { get }
    /// Golf steers with a club bar instead of the pads.
    var usesPads: Bool { get }

    /// Build the scene graph. Called once, on a sized scene.
    func attach(to scene: GameScene)
    func resize(_ w: CGFloat, _ h: CGFloat)
    func update(_ dt: CGFloat)
    /// The screen went away mid-run.
    func onPause()
    func destroy()
}

extension FallGame {
    var light: Bool { false }
    var usesPads: Bool { true }
    func onPause() {}
    func destroy() {}
}
