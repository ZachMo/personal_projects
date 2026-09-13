import SpriteKit

/// The sky drops blocks. You are a small dinosaur with nowhere to hide.
/// Four things fall that are not blocks. Score is time on your feet.
///
/// The simulation below is the web version's `update` with Swift spelling. Only
/// the drawing changed: instead of clearing a canvas every frame, each moving
/// thing owns a node and the frame ends by pushing positions into it.
final class DinoFall: FallGame {

    static let id = "dino"
    static let title = "Dino Fall"

    // Tuning, unchanged.
    private static let pickupOdds: CGFloat = 0.13
    private static let slowSeconds: CGFloat = 5.5
    private static let miniSeconds: CGFloat = 8
    private static let miniScale: CGFloat = 0.55

    private enum State { case ready, run, held, over }

    // MARK: - Simulation state

    private var state: State = .ready
    private var blocks: [Block] = []
    private var dust: [Mote] = []

    private var elapsed: CGFloat = 0
    private var scroll: CGFloat = 0
    private var nextSpawn: CGFloat = 0.7

    private var shield = false
    private var shieldFlash: CGFloat = 0
    private var flash: CGFloat = 0
    private var slowT: CGFloat = 0
    private var miniT: CGFloat = 0
    private var mini: CGFloat = 1

    private var x: CGFloat = 0
    private var w: CGFloat = 0
    private var h: CGFloat = 0
    private var unit: CGFloat = 40
    private var ground: CGFloat = 0

    // MARK: - Scene graph

    private unowned var scene: GameScene!
    private let world = SKNode()
    private let dustLayer = SKNode()
    private let blockLayer = SKNode()
    private let dinoLayer = SKNode()

    private var sky = CanvasSprite(color: .black, size: .zero)
    private var sun = CanvasSprite(texture: Textures.disc, tint: UIColor(red: 1, green: 0.886, blue: 0.659, alpha: 0.75), size: .zero)
    private let dunesFar = SKShapeNode()
    private let dunesNear = SKShapeNode()
    private var groundNode = CanvasSprite(color: UIColor(hex: 0x3A2430), size: .zero)
    private var ticks: [CanvasSprite] = []

    private let dino = Dino()
    private var wash = CanvasSprite(color: UIColor(hex: 0x5AA9D6), size: .zero)
    private var flashNode = CanvasSprite(color: UIColor(hex: 0xFFF5E0), size: .zero)
    private let timers = TimerBars()

    private var motePool: [CanvasSprite] = []

    // MARK: - Lifecycle

    func attach(to scene: GameScene) {
        self.scene = scene

        world.zPosition = 0
        dustLayer.zPosition = 10
        blockLayer.zPosition = 20
        dinoLayer.zPosition = 30
        wash.zPosition = 40

        dunesFar.lineWidth = 0
        dunesNear.lineWidth = 0
        dunesFar.fillColor = UIColor(hex: 0x8D5A54)
        dunesNear.fillColor = UIColor(hex: 0x6B3F45)

        world.addChild(sky)
        world.addChild(sun)
        world.addChild(dunesFar)
        world.addChild(dunesNear)
        world.addChild(groundNode)

        dino.build(into: dinoLayer)
        wash.alpha = 0

        scene.canvas.addChild(world)
        scene.canvas.addChild(dustLayer)
        scene.canvas.addChild(blockLayer)
        scene.canvas.addChild(dinoLayer)
        scene.canvas.addChild(wash)

        flashNode.alpha = 0
        flashNode.zPosition = 10
        scene.overlayLayer.addChild(flashNode)
        timers.build(into: scene.overlayLayer)

        state = .ready
        GameHost.shared.hud("0.0", "seconds")
        intro()
    }

    func resize(_ w: CGFloat, _ h: CGFloat) {
        self.w = w
        self.h = h
        unit = clamp(min(w, h) * 0.115, 30, 78)          // dino height
        ground = h - max(h * 0.06, 26) - unit
        x = clamp(x == 0 ? w / 2 : x, 0, w - unit * 0.92)

        sky.texture = Textures.verticalGradient([
            (0.00, UIColor(hex: 0x5B4478)),
            (0.45, UIColor(hex: 0x8F5560)),
            (0.78, UIColor(hex: 0xD98A5F)),
            (1.00, UIColor(hex: 0xF0B57C)),
        ])
        sky.colorBlendFactor = 0
        sky.place(x: -10, y: -10, w: w + 20, h: h + 20)

        let sunR = unit * 1.5
        sun.centre(x: w * 0.72, y: h * 0.52, w: sunR * 2, h: sunR * 2)

        let gy = ground + unit
        groundNode.place(x: 0, y: gy, w: w, h: max(0, h - gy))

        wash.place(x: 0, y: 0, w: w, h: h)
        flashNode.place(x: 0, y: 0, w: w, h: h)
        timers.layout(w: w, top: 74 + (scene?.view?.safeAreaInsets.top ?? 0))

        rebuildTicks()
        PickupArt.clearCache()
    }

    func destroy() {
        world.removeFromParent()
        dustLayer.removeFromParent()
        blockLayer.removeFromParent()
        dinoLayer.removeFromParent()
        wash.removeFromParent()
        flashNode.removeFromParent()
        timers.teardown()
    }

    // MARK: - Overlays

    private func intro() {
        GameHost.shared.show(Overlay(
            title: Self.title,
            why: "The sky is falling.",
            actions: [
                .primary("Start") { [weak self] in self?.begin() },
                .ghost("Back") { GameHost.shared.goHome() },
            ]
        ))
    }

    private func begin() {
        GameHost.shared.hideOverlay()
        scene.resumeRun()
        state = .run
        clearBlocks()
        clearDust()
        elapsed = 0
        shield = false
        slowT = 0
        miniT = 0
        mini = 1
        flash = 0
        scene.shake = 0
        nextSpawn = 0.7
        x = w / 2 - unit * 0.46
        _ = Input.shared.dragDelta()
    }

    func onPause() {
        guard state == .run else { return }
        state = .held
        GameHost.shared.show(Overlay(
            title: "Paused",
            actions: [
                .primary("Keep going") { [weak self] in
                    guard let self else { return }
                    GameHost.shared.hideOverlay()
                    self.state = .run
                    _ = Input.shared.dragDelta()
                    self.scene.resumeRun()
                },
                .ghost("Give up") { GameHost.shared.goHome() },
            ]
        ))
    }

    // MARK: - Spawning

    private func spawn() {
        let u = unit
        if CGFloat.random(in: 0..<1) < Self.pickupOdds {
            let kind = Pickup.weighted()
            let side = kind.size * u
            let block = Block(
                pickup: kind, shape: nil,
                w: side, h: side,
                x: rand(0, max(1, w - side)),
                y: -side - rand(0, u),
                spin: rand(-1.6, 1.6),
                jitter: rand(0.8, 1.0)
            )
            attachNodes(to: block)
            blocks.append(block)
        } else {
            let s = pick(BlockShape.all)
            let bw = s.w * u, bh = s.h * u
            let block = Block(
                pickup: nil, shape: s,
                w: bw, h: bh,
                x: rand(0, max(1, w - bw)),
                y: -bh - rand(0, u),
                spin: 0,
                jitter: rand(0.86, 1.18)
            )
            attachNodes(to: block)
            blocks.append(block)
        }
    }

    // MARK: - Frame

    func update(_ dt: CGFloat) {
        // These keep running past the end of the run so a death still lands.
        scene.shake = max(0, scene.shake - dt * 2.2)
        flash = max(0, flash - dt * 3)
        flashNode.alpha = flash * 0.75

        guard state == .run else {
            syncDust(dt)
            return
        }

        elapsed += dt
        scroll += dt * (140 + elapsed * 5)
        shieldFlash = max(0, shieldFlash - dt * 2)

        // Timed pickups. Only the sky slows down — you still move at full speed.
        slowT = max(0, slowT - dt)
        miniT = max(0, miniT - dt)
        let wantMini = miniT > 0 ? Self.miniScale : 1
        mini.ease(to: wantMini, dt * 9)
        let slow: CGFloat = slowT > 0 ? 0.42 : 1

        GameHost.shared.hud(String(format: "%.1f", elapsed), "seconds")

        // Steering. A small dino is a nimble dino.
        let dw = unit * 0.92 * mini
        let dh = unit * mini
        x = Input.shared.steer(x, dt: dt, speed: w * (1.25 + (1 - mini) * 0.5), lo: 0, hi: w - dw)

        // Difficulty ramp: quicker falls, tighter gaps.
        let fall = min(h * (0.30 + elapsed * 0.011), h * 0.95) * slow
        let gap = max(0.13, 0.60 - elapsed * 0.016) / slow

        nextSpawn -= dt
        if nextSpawn <= 0 {
            spawn()
            if elapsed > 18, CGFloat.random(in: 0..<1) < 0.3 { spawn() }
            nextSpawn = gap * rand(0.75, 1.3)
        }

        // Dino hitbox, a little kinder than the drawing.
        let hx = x + dw * 0.18, hw = dw * 0.64
        let hy = ground + unit - dh + dh * 0.14, hh = dh * 0.8

        for i in stride(from: blocks.count - 1, through: 0, by: -1) {
            let b = blocks[i]
            b.y += fall * b.jitter * dt
            b.rot += b.spin * dt

            if b.y + b.h >= ground + unit {
                retire(at: i)
                if b.pickup == nil {
                    for _ in 0..<5 {
                        addMote(x: b.x + rand(0, b.w), y: ground + unit,
                                r: rand(1.5, 3.5), life: 0.8, vx: rand(-60, 60))
                    }
                }
                continue
            }

            let hit = b.x < hx + hw && b.x + b.w > hx && b.y < hy + hh && b.y + b.h > hy
            guard hit else { continue }

            retire(at: i)
            if let pickup = b.pickup {
                take(pickup, at: CGPoint(x: b.x + b.w / 2, y: b.y + b.h / 2))
            } else if shield {
                shield = false
                scene.shake = 1
                burst(b.x + b.w / 2, b.y + b.h / 2, UIColor(hex: 0xD76B5B))
                Sound.shared.noise(0.2, 0.18)
                Sound.shared.slide(from: 420, to: 120, 0.2, .square)
                Haptics.buzz(34)
            } else {
                die()
                return
            }
        }

        // Foot dust.
        if CGFloat.random(in: 0..<1) < 0.5 {
            addMote(x: x + unit * rand(0.15, 0.7), y: ground + unit,
                    r: rand(1.5, 3.5), life: 1, vx: rand(-26, -70))
        }

        syncDust(dt)
        syncBlocks()
        syncScenery()
        dino.sync(game: self, x: x, base: ground + unit, u: unit * mini)
        wash.alpha = slowT > 0 ? min(1, slowT) * 0.13 : 0
        timers.sync(slow: slowT / Self.slowSeconds, mini: miniT / Self.miniSeconds, shield: shield)
    }

    // MARK: - Pickups

    private func take(_ pickup: Pickup, at p: CGPoint) {
        burst(p.x, p.y, pickup.colour)
        Haptics.buzz(14)
        switch pickup.kind {
        case .shield:
            shield = true
            shieldFlash = 1
            Sound.shared.blip(880, 0.14, .triangle, 0.13)
            Sound.shared.blip(1320, 0.18, .triangle, 0.09)
        case .mini:
            miniT = Self.miniSeconds
            Sound.shared.slide(from: 300, to: 900, 0.22, .triangle)
        case .slow:
            slowT = Self.slowSeconds
            Sound.shared.slide(from: 900, to: 260, 0.4, .sine)
        case .bomb:
            bomb(p.x, p.y)
        }
    }

    /// Clears the sky. Pickups already falling survive it.
    private func bomb(_ cx: CGFloat, _ cy: CGFloat) {
        for i in stride(from: blocks.count - 1, through: 0, by: -1) {
            let b = blocks[i]
            guard b.pickup == nil else { continue }
            burst(b.x + b.w / 2, b.y + b.h / 2, UIColor(hex: 0xE8B33C))
            retire(at: i)
        }
        flash = 1
        scene.shake = 1.3
        for _ in 0..<26 {
            addMote(x: cx, y: cy, r: rand(2, 6), life: 1,
                    vx: rand(-260, 260), colour: UIColor(hex: 0xE8B33C))
        }
        Sound.shared.noise(0.4, 0.3)
        Sound.shared.slide(from: 220, to: 40, 0.5, .sawtooth)
        Haptics.buzz([40, 30, 60])
    }

    private func burst(_ bx: CGFloat, _ by: CGFloat, _ colour: UIColor) {
        for _ in 0..<12 {
            addMote(x: bx, y: by, r: rand(2, 4.5), life: 1, vx: rand(-90, 90), colour: colour)
        }
    }

    private func die() {
        state = .over
        scene.shake = 1.6
        burst(x + unit * 0.46, ground + unit * 0.5, UIColor(hex: 0x15151B))
        let secs = (elapsed * 10).rounded() / 10
        let fresh = Best.set(Self.id, Double(secs))
        Sound.shared.slide(from: 300, to: 60, 0.45, .sawtooth)
        Haptics.buzz([30, 50, 60])
        GameHost.shared.show(Overlay(
            title: fresh ? "New best" : "Flattened",
            score: String(format: "%.1fs", secs),
            best: String(format: "Best %.1fs", Best.get(Self.id)),
            actions: [
                .primary("Again") { [weak self] in self?.begin() },
                .ghost("Back") { GameHost.shared.goHome() },
            ]
        ))
    }

    // MARK: - Node bookkeeping

    private func attachNodes(to b: Block) {
        if let pickup = b.pickup {
            let side = PickupArt.boxSide(for: b.w)
            let node = CanvasSprite(texture: PickupArt.texture(pickup, size: b.w),
                                    size: CGSize(width: side, height: side))
            b.body = node
            blockLayer.addChild(node)
        } else {
            let shadow = CanvasSprite(color: UIColor(white: 0, alpha: 0.18), size: .zero)
            let body: CanvasSprite
            if b.shape?.kind == "dot" {
                shadow.texture = Textures.disc
                shadow.colorBlendFactor = 1
                shadow.color = UIColor(white: 0, alpha: 1)
                shadow.alpha = 0.18
                body = CanvasSprite(texture: Textures.disc, tint: DinoArt.ink, size: .zero)
            } else {
                body = CanvasSprite(color: UIColor(hex: 0x15151B), size: .zero)
            }
            b.shadow = shadow
            b.body = body
            blockLayer.addChild(shadow)
            blockLayer.addChild(body)
        }
    }

    private func retire(at i: Int) {
        let b = blocks.remove(at: i)
        b.body?.removeFromParent()
        b.shadow?.removeFromParent()
    }

    private func clearBlocks() {
        blocks.forEach { $0.body?.removeFromParent(); $0.shadow?.removeFromParent() }
        blocks.removeAll()
    }

    private func syncBlocks() {
        for b in blocks {
            if b.pickup != nil {
                b.body?.position = CGPoint(x: b.x + b.w / 2, y: b.y + b.h / 2)
                b.body?.zRotation = b.rot
            } else {
                b.shadow?.place(x: b.x + 2, y: b.y + 3, w: b.w, h: b.h)
                b.body?.place(x: b.x, y: b.y, w: b.w, h: b.h)
            }
        }
    }

    // MARK: - Dust

    private func addMote(x mx: CGFloat, y my: CGFloat, r: CGFloat, life: CGFloat,
                         vx: CGFloat, colour: UIColor? = nil) {
        let node = motePool.popLast() ?? CanvasSprite(texture: Textures.disc, tint: .white, size: .zero)
        node.color = colour ?? UIColor(hex: 0xE8C8A8)
        node.colorBlendFactor = 1
        if node.parent == nil { dustLayer.addChild(node) }
        node.isHidden = false
        // Placed now, not on the next sync: `die()` bursts and then returns, so a
        // mote left unpositioned would show at the origin for a frame.
        node.centre(x: mx, y: my, w: r * 2, h: r * 2)
        node.alpha = life * 0.6
        dust.append(Mote(x: mx, y: my, r: r, life: life, vx: vx, node: node))
    }

    private func syncDust(_ dt: CGFloat) {
        for i in stride(from: dust.count - 1, through: 0, by: -1) {
            let d = dust[i]
            d.life -= dt * 1.9
            d.x += d.vx * dt
            d.y -= dt * 8
            if d.life <= 0 {
                d.node.isHidden = true
                motePool.append(d.node)
                dust.remove(at: i)
                continue
            }
            d.node.centre(x: d.x, y: d.y, w: d.r * 2, h: d.r * 2)
            d.node.alpha = max(0, d.life) * 0.6
        }
    }

    private func clearDust() {
        dust.forEach { $0.node.isHidden = true; motePool.append($0.node) }
        dust.removeAll()
    }

    // MARK: - Scenery

    /// The dunes are one periodic path slid sideways, and the ground ticks are a
    /// fixed pool of nodes moved along, so neither allocates per frame.
    private func syncScenery() {
        dunesFar.path = dunePath(base: h * 0.66, off: scroll * 0.06)
        dunesNear.path = dunePath(base: h * 0.76, off: scroll * 0.13)

        let gy = ground + unit
        let period = w + 60
        for (i, tick) in ticks.enumerated() {
            let n = CGFloat(i - 1)
            var tx = (n * 60 - scroll * 0.5).truncatingRemainder(dividingBy: period)
            if tx < 0 { tx += period }
            tick.place(x: tx - 60, y: gy + 6 + CGFloat((i - 1) % 2) * 9, w: 22, h: 2)
        }
    }

    private func rebuildTicks() {
        ticks.forEach { $0.removeFromParent() }
        ticks.removeAll()
        let count = Int(w / 60) + 3
        for _ in 0..<count {
            let node = CanvasSprite(color: UIColor(white: 1, alpha: 0.09), size: .zero)
            world.addChild(node)
            ticks.append(node)
        }
    }

    private func dunePath(base: CGFloat, off: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let span = w / 3
        let shift = off.truncatingRemainder(dividingBy: span)
        path.move(to: CGPoint(x: 0, y: h))
        for i in -1...4 {
            let dx = CGFloat(i) * span - shift
            path.addQuadCurve(
                to: CGPoint(x: dx + span, y: base),
                control: CGPoint(x: dx + span * 0.5, y: base - span * 0.28)
            )
        }
        path.addLine(to: CGPoint(x: w, y: h))
        path.closeSubpath()
        return path
    }

    // MARK: - Read by the dino

    fileprivate var runningStep: CGFloat { state == .run ? sin(elapsed * 15) : 0 }
    fileprivate var shieldOn: Bool { shield }
    fileprivate var shieldPulse: CGFloat {
        clamp(0.55 + sin(elapsed * 6) * 0.2 + shieldFlash * 0.4, 0, 1)
    }
}

// MARK: - Moving things

private final class Block {
    let pickup: Pickup?
    let shape: BlockShape?
    let w: CGFloat
    let h: CGFloat
    var x: CGFloat
    var y: CGFloat
    var rot: CGFloat = 0
    let spin: CGFloat
    let jitter: CGFloat

    var body: CanvasSprite?
    var shadow: CanvasSprite?

    init(pickup: Pickup?, shape: BlockShape?, w: CGFloat, h: CGFloat,
         x: CGFloat, y: CGFloat, spin: CGFloat, jitter: CGFloat) {
        self.pickup = pickup; self.shape = shape
        self.w = w; self.h = h; self.x = x; self.y = y
        self.spin = spin; self.jitter = jitter
    }
}

private final class Mote {
    var x: CGFloat
    var y: CGFloat
    let r: CGFloat
    var life: CGFloat
    let vx: CGFloat
    let node: CanvasSprite

    init(x: CGFloat, y: CGFloat, r: CGFloat, life: CGFloat, vx: CGFloat, node: CanvasSprite) {
        self.x = x; self.y = y; self.r = r; self.life = life; self.vx = vx; self.node = node
    }
}

// MARK: - The dinosaur

/// Rectangles on a 24 x 26 grid, held in a container that is scaled to whatever
/// height the dino currently is. The legs swap places as it runs.
private final class Dino {
    private let shadow = CanvasSprite(texture: Textures.disc, tint: UIColor(white: 0, alpha: 1), size: .zero)
    private let ring = SKShapeNode()
    private let body = SKNode()
    private var legsA: [SKSpriteNode] = []
    private var legsB: [SKSpriteNode] = []
    private var ringRadius: CGFloat = -1

    func build(into parent: SKNode) {
        shadow.alpha = 0.22
        parent.addChild(shadow)

        ring.fillColor = .clear
        ring.strokeColor = UIColor(hex: 0xD76B5B)
        ring.isHidden = true
        parent.addChild(ring)

        for r in DinoArt.body { body.addChild(rect(r, DinoArt.ink)) }
        for r in DinoArt.legsA { let n = rect(r, DinoArt.ink); legsA.append(n); body.addChild(n) }
        for r in DinoArt.legsB { let n = rect(r, DinoArt.ink); legsB.append(n); body.addChild(n) }
        body.addChild(rect([14.5, 2, 2, 2], DinoArt.eye))
        parent.addChild(body)
    }

    /// `base` is the ground line. The dino stands on it whatever size it is.
    func sync(game: DinoFall, x: CGFloat, base: CGFloat, u: CGFloat) {
        let s = u / DinoArt.gridHeight
        let step = game.runningStep

        shadow.centre(x: x + u * 0.46, y: base + 3, w: u * 0.84, h: u * 0.18)

        ring.isHidden = !game.shieldOn
        if game.shieldOn {
            let r = u * 0.72
            if abs(r - ringRadius) > 0.5 {
                ring.path = CGPath(ellipseIn: CGRect(x: -r, y: -r, width: r * 2, height: r * 2),
                                   transform: nil)
                ringRadius = r
            }
            ring.lineWidth = max(2, u * 0.07)
            ring.position = CGPoint(x: x + u * 0.46, y: base - u + u * 0.5)
            ring.strokeColor = UIColor(hex: 0xD76B5B, alpha: game.shieldPulse)
        }

        body.position = CGPoint(x: x, y: base - u)
        body.setScale(s)
        for (i, n) in legsA.enumerated() { place(n, DinoArt.legsA[i], yOffset: step * 1.4) }
        for (i, n) in legsB.enumerated() { place(n, DinoArt.legsB[i], yOffset: -step * 1.4) }
    }

    private func rect(_ r: [CGFloat], _ colour: SKColor) -> SKSpriteNode {
        let n = SKSpriteNode(color: colour, size: CGSize(width: r[2], height: r[3]))
        n.position = CGPoint(x: r[0] + r[2] / 2, y: r[1] + r[3] / 2)
        return n
    }

    private func place(_ n: SKSpriteNode, _ r: [CGFloat], yOffset: CGFloat) {
        n.position = CGPoint(x: r[0] + r[2] / 2, y: r[1] + yOffset + r[3] / 2)
    }
}

// MARK: - Countdown bars

/// The two timed pickups get a bar. The shield runs until something hits you, so
/// a draining bar would be a lie — it gets a diamond instead.
private final class TimerBars {
    private let slowTrack = CanvasSprite(color: UIColor(white: 0, alpha: 0.28), size: .zero)
    private let slowFill  = CanvasSprite(color: UIColor(hex: 0x5AA9D6), size: .zero)
    private let miniTrack = CanvasSprite(color: UIColor(white: 0, alpha: 0.28), size: .zero)
    private let miniFill  = CanvasSprite(color: UIColor(hex: 0x6FBF73), size: .zero)
    private let pip = SKShapeNode()

    private var w: CGFloat = 0
    private var top: CGFloat = 74

    private static let barW: CGFloat = 52
    private static let barH: CGFloat = 5
    private static let gap: CGFloat = 8
    private static let pipW: CGFloat = 20

    func build(into parent: SKNode) {
        [slowTrack, slowFill, miniTrack, miniFill].forEach {
            $0.zPosition = 5
            parent.addChild($0)
        }
        pip.path = CGMutablePath.diamond(halfWidth: 7, halfHeight: 8)
        pip.fillColor = UIColor(hex: 0xD76B5B)
        pip.lineWidth = 0
        pip.zPosition = 5
        parent.addChild(pip)
    }

    func layout(w: CGFloat, top: CGFloat) {
        self.w = w
        self.top = top
    }

    func teardown() {
        [slowTrack, slowFill, miniTrack, miniFill].forEach { $0.removeFromParent() }
        pip.removeFromParent()
    }

    func sync(slow: CGFloat, mini: CGFloat, shield: Bool) {
        let showSlow = slow > 0, showMini = mini > 0
        let bars = (showSlow ? 1 : 0) + (showMini ? 1 : 0)
        let pipWidth: CGFloat = shield ? Self.pipW : 0
        let total = CGFloat(bars) * Self.barW
            + CGFloat(max(0, bars - 1)) * Self.gap
            + ((pipWidth > 0 && bars > 0) ? Self.gap : 0)
            + pipWidth

        slowTrack.isHidden = !showSlow; slowFill.isHidden = !showSlow
        miniTrack.isHidden = !showMini; miniFill.isHidden = !showMini
        pip.isHidden = !shield
        guard total > 0 else { return }

        var x = (w - total) / 2
        if showSlow {
            slowTrack.place(x: x, y: top, w: Self.barW, h: Self.barH)
            slowFill.place(x: x, y: top, w: Self.barW * clamp(slow, 0, 1), h: Self.barH)
            x += Self.barW + Self.gap
        }
        if showMini {
            miniTrack.place(x: x, y: top, w: Self.barW, h: Self.barH)
            miniFill.place(x: x, y: top, w: Self.barW * clamp(mini, 0, 1), h: Self.barH)
            x += Self.barW + Self.gap
        }
        if shield {
            pip.position = CGPoint(x: x + pipWidth / 2, y: top + 2.5)
        }
    }
}

private extension CGMutablePath {
    static func diamond(halfWidth: CGFloat, halfHeight: CGFloat) -> CGPath {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: 0, y: -halfHeight))
        p.addLine(to: CGPoint(x: halfWidth, y: 0))
        p.addLine(to: CGPoint(x: 0, y: halfHeight))
        p.addLine(to: CGPoint(x: -halfWidth, y: 0))
        p.closeSubpath()
        return p
    }
}
