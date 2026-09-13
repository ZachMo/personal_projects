import SpriteKit

/// Hosts one game. Sizing, the frame loop and the touch feed, which is all the
/// web `Engine` did once drawing moved into the scene graph.
///
/// ## Coordinates
/// SpriteKit puts the origin at the bottom left with y running up. Canvas puts
/// it at the top left with y running down, and every line of game logic in
/// fall.html was written that way. Rather than rewrite all of it, `canvas` sits
/// at the top of the scene with `yScale = -1`, so anything added to it uses
/// canvas coordinates unchanged.
///
/// Two rules follow from that flip:
/// * A node carrying a **texture** must cancel it with its own `yScale = -1`,
///   or the picture arrives upside down. `CanvasSprite` does this for you.
/// * `zRotation` still turns clockwise, the same direction `ctx.rotate()` does
///   under a y-down axis, so rotation values copy across as they are.
final class GameScene: SKScene {

    /// Everything the game draws. Shake is applied here.
    private(set) var canvas = SKNode()
    /// Sits outside the shake, for the bomb's full-frame white-out.
    private(set) var overlayLayer = SKNode()

    private var game: FallGame?
    private var last: TimeInterval = 0
    private(set) var paused_ = false

    /// Canvas-space size, which is just the scene size named the way games read it.
    var w: CGFloat { size.width }
    var h: CGFloat { size.height }

    // MARK: - Setup

    override func didMove(to view: SKView) {
        backgroundColor = .black
        scaleMode = .resizeFill
        isUserInteractionEnabled = true
        layoutLayers()
    }

    private func layoutLayers() {
        if canvas.parent == nil { addChild(canvas) }
        if overlayLayer.parent == nil { addChild(overlayLayer) }
        // Top-left origin, y down.
        canvas.position = CGPoint(x: 0, y: size.height)
        canvas.yScale = -1
        overlayLayer.position = CGPoint(x: 0, y: size.height)
        overlayLayer.yScale = -1
        overlayLayer.zPosition = 900
    }

    func run(_ game: FallGame) {
        stop()
        Input.shared.reset()
        Sound.shared.wake()
        Haptics.prepare()
        self.game = game
        layoutLayers()
        game.attach(to: self)
        game.resize(w, h)
        paused_ = false
        last = 0
    }

    func stop() {
        game?.destroy()
        game = nil
        canvas.removeAllChildren()
        overlayLayer.removeAllChildren()
        shake = 0
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size.width > 1, size.height > 1 else { return }
        layoutLayers()
        game?.resize(w, h)
    }

    // MARK: - Loop

    override func update(_ currentTime: TimeInterval) {
        guard let game else { return }
        if last == 0 { last = currentTime }
        // The same 50 ms ceiling the web loop used, so a stall does not teleport
        // anything through a wall.
        let dt = CGFloat(min(currentTime - last, 0.05))
        last = currentTime
        guard !paused_ else { return }
        Input.shared.step()
        game.update(dt)
        applyShake()
    }

    func pauseRun() {
        guard game != nil, !paused_ else { return }
        paused_ = true
        game?.onPause()
    }

    func resumeRun() {
        paused_ = false
        last = 0
    }

    // MARK: - Shake

    /// Games set this and it decays on its own, the way the web version wrote
    /// `this.shake` and translated the context by it each frame.
    var shake: CGFloat = 0

    private func applyShake() {
        guard shake > 0 else {
            if canvas.position.x != 0 || canvas.zRotation != 0 {
                canvas.position = CGPoint(x: 0, y: size.height)
                canvas.zRotation = 0
            }
            return
        }
        let k = shake * shake * 16
        canvas.position = CGPoint(x: rand(-1, 1) * k, y: size.height + rand(-1, 1) * k)
        canvas.zRotation = rand(-1, 1) * shake * 0.012
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        Input.shared.pressed(at: canvasPoint(t))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        Input.shared.moved(to: canvasPoint(t))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        Input.shared.released(at: canvasPoint(t))
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        Input.shared.released(at: canvasPoint(t))
    }

    /// Scene point to canvas point: same x, y measured from the top.
    private func canvasPoint(_ t: UITouch) -> CGPoint {
        let p = t.location(in: self)
        return CGPoint(x: p.x, y: size.height - p.y)
    }
}
