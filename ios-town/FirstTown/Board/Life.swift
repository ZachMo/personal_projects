import SwiftUI
import FirstTownCore

/// Everything on the board that moves: people on the lanes, smoke, herds, water, glints, dust, confetti and score numbers.
final class Life {
    struct Walker {
        var ax: Int, ay: Int, bx: Int, by: Int
        var px = -1, py = -1
        var t = 1.0
        var speed: Double
        var wait: Double
        var phase: Double
        var fade = 0.0
        var shirt: CGColor
        var skin: CGColor
    }

    struct Puff { var x: CGFloat; var y: CGFloat; var t: Double; var dark: Bool; var drift: CGFloat }
    struct Dust { var x: CGFloat; var y: CGFloat; var a: CGFloat; var t: Double }
    struct Floater { var x: CGFloat; var y: CGFloat; var t: Double; var text: String; var good: Bool; var big: Bool }
    struct Bit { var x: CGFloat; var y: CGFloat; var vx: CGFloat; var vy: CGFloat; var r: CGFloat; var vr: CGFloat; var s: CGFloat; var t: Double; var c: CGColor }

    static let shirts = ["#d65a45", "#3f79b5", "#4f9a5f", "#e3a92f", "#8a5fb0", "#f4efe4", "#2f6b73", "#c2703f"].map { hex($0) }
    static let skins = ["#f1cfae", "#d9a77f", "#a8744f", "#7a5236"].map { hex($0) }
    static let confettiColours = ["#ffd45c", "#e0703f", "#5ab4d6", "#6cc07a", "#b673c9", "#ffffff"].map { hex($0) }

    private var walkers: [Walker] = []
    private var puffs: [Puff] = []
    private var dust: [Dust] = []
    private var bits: [Bit] = []
    var floaters: [Floater] = []
    private var smokeClock = 0.0

    func reset() {
        walkers.removeAll(); puffs.removeAll(); dust.removeAll(); bits.removeAll(); floaters.removeAll()
    }

    // MARK: - People

    /// A lane runs along a grid line that has a building on at least one side, and isn't inside one building.
    private func lane(_ owner: [Int], _ ax: Int, _ ay: Int, _ bx: Int, _ by: Int) -> Bool {
        func at(_ x: Int, _ y: Int) -> Int { Board.inside(x, y) ? owner[Board.index(x, y)] : -2 }
        let a: Int, b: Int
        if ay == by { let x = min(ax, bx); a = at(x, ay - 1); b = at(x, ay) }
        else { let y = min(ay, by); a = at(ax - 1, y); b = at(ax, y) }
        return (a >= 0 || b >= 0) && !(a >= 0 && a == b)
    }

    private func exits(_ owner: [Int], _ x: Int, _ y: Int) -> [(x: Int, y: Int)] {
        Board.steps.map { (x + $0.dx, y + $0.dy) }.filter { nx, ny in
            nx >= 0 && ny >= 0 && nx <= Board.cols && ny <= Board.rows && lane(owner, x, y, nx, ny)
        }
    }

    private func spawn(_ owner: [Int]) -> Walker? {
        var spots: [(Int, Int)] = []
        for y in 0...Board.rows { for x in 0...Board.cols where !exits(owner, x, y).isEmpty { spots.append((x, y)) } }
        guard let spot = spots.randomElement() else { return nil }
        return Walker(ax: spot.0, ay: spot.1, bx: spot.0, by: spot.1, speed: 0.55 + .random(in: 0..<0.45), wait: .random(in: 0..<2),
                      phase: .random(in: 0..<6), shirt: Self.shirts.randomElement()!, skin: Self.skins.randomElement()!)
    }

    func update(_ dt: Double, _ game: Game, smoke: [(CGPoint, Bool)]) {
        let owner = game.owner
        let homes = game.pieces.filter { Library[$0.type].category == .home }.count
        let want = min(34, Int((Double(game.pieces.count) * 1.1 + Double(homes) * 1.4).rounded()))
        if walkers.count < want && Double.random(in: 0..<1) < dt * 2, let w = spawn(owner) { walkers.append(w) }
        if walkers.count > want { walkers.removeLast(walkers.count - want) }

        var n = walkers.count - 1
        while n >= 0 {
            defer { n -= 1 }
            var w = walkers[n]
            w.fade = min(1, w.fade + dt * 2)
            if w.wait > 0 { w.wait -= dt; walkers[n] = w; continue }
            w.t += dt * w.speed
            if w.t < 1 { walkers[n] = w; continue }
            w.ax = w.bx; w.ay = w.by; w.t = 0
            var next = exits(owner, w.ax, w.ay)
            if next.isEmpty { walkers.remove(at: n); continue }
            if next.count > 1 { next = next.filter { $0.x != w.px || $0.y != w.py } }
            let choice = (next.isEmpty ? exits(owner, w.ax, w.ay) : next).randomElement()!
            w.px = w.ax; w.py = w.ay; w.bx = choice.x; w.by = choice.y
            if Double.random(in: 0..<1) < 0.12 { w.wait = 0.6 + .random(in: 0..<1.6) }
            walkers[n] = w
        }

        smokeClock -= dt
        if smokeClock <= 0, let source = smoke.randomElement() {
            smokeClock = 1.6 / max(1, Double(smoke.count) * 0.6)
            puffs.append(Puff(x: source.0.x, y: source.0.y, t: 0, dark: source.1, drift: 0.5 + .random(in: 0..<0.5)))
        }
        for i in puffs.indices { puffs[i].t += dt }
        puffs.removeAll { $0.t >= 2.4 }
    }

    func drawWalkers(_ g: CGContext, _ L: BoardLayout, _ now: Double) {
        let S = L.S
        for w in walkers {
            let t = w.wait > 0 ? 0 : w.t
            let x = L.BX + (CGFloat(w.ax) + CGFloat(w.bx - w.ax) * t) * S, y = L.BY + (CGFloat(w.ay) + CGFloat(w.by - w.ay) * t) * S
            let bob = w.wait > 0 ? 0 : abs(sin(now * 9 + w.phase)) * S * 0.02
            g.setAlpha(w.fade)
            g.oval(x + S * 0.02, y + S * 0.045, S * 0.065, S * 0.035, rgba(20, 20, 15, 0.22))
            g.dot(x, y - bob, S * 0.06, w.shirt)
            g.dot(x, y - bob - S * 0.02, S * 0.036, w.skin)
            g.setAlpha(1)
        }
    }

    func drawSmoke(_ g: CGContext, _ L: BoardLayout) {
        let S = L.S
        for p in puffs {
            let k = p.t / 2.4, a = (1 - k) * min(1, p.t * 4) * 0.5
            g.dot(p.x + k * S * 0.35 * p.drift, p.y - k * S * 0.5, S * (0.04 + k * 0.1), p.dark ? rgba(90, 90, 95, a) : rgba(255, 255, 255, a))
        }
    }

    // MARK: - The land

    func drawWater(_ g: CGContext, _ L: BoardLayout, _ game: Game, _ now: Double) {
        let S = L.S
        g.beginPath()
        for i in 0..<Board.count where game.map[i] == .water && game.owner[i] < 0 {
            for k in 0..<2 {
                let ph = (now * 0.07 + Double(artHash(Double(i), Double(k + 80)))).truncatingRemainder(dividingBy: 1)
                let x = L.cellX(i) + S * (0.25 + 0.5 * ph), y = L.cellY(i) + S * (0.3 + 0.4 * artHash(Double(i), Double(k + 90)))
                let len = S * 0.1 * sin(ph * .pi)
                g.line(x - len, y, x + len, y)
            }
        }
        g.setLineCap(.round)
        g.strokeCurrent(rgba(255, 255, 255, 0.5), max(1, S * 0.03))
    }

    /// Cattle and sheep that drift around their patch until something is built on it.
    func drawHerds(_ g: CGContext, _ L: BoardLayout, _ game: Game, _ now: Double) {
        let S = L.S
        for i in 0..<Board.count where game.map[i] == .herd && game.owner[i] < 0 {
            for k in 0..<2 {
                let ph = Double(artHash(Double(i), Double(k + 120))) * 6, t = now * 0.25 + ph
                let x = L.cellX(i) + S * (0.3 + 0.4 * artHash(Double(i), Double(k + 130))) + sin(t) * S * 0.06
                let y = L.cellY(i) + S * (0.28 + 0.44 * artHash(Double(i), Double(k + 140))) + cos(t * 0.8) * S * 0.03
                let face: CGFloat = cos(t) >= 0 ? 1 : -1, z = S * 1.35
                g.oval(x + z * 0.02, y + z * 0.07, z * 0.13, z * 0.05, rgba(30, 50, 20, 0.25))
                if artHash(Double(i), Double(k + 150)) < 0.45 {
                    for (dx, dy) in [(-0.05, 0), (0.04, -0.02), (0.03, 0.03), (-0.02, -0.03), (0, 0)] as [(CGFloat, CGFloat)] {
                        g.dot(x + z * dx, y + z * dy, z * 0.055, hex("#fbf8f0"))
                    }
                    g.dot(x + face * z * 0.1, y - z * 0.01, z * 0.038, hex("#3f3a36"))
                } else {
                    g.oval(x, y, z * 0.11, z * 0.065, hex("#f7f3ea"))
                    g.dot(x - face * z * 0.03, y - z * 0.02, z * 0.032, hex("#4a382d"))
                    g.dot(x + face * z * 0.045, y + z * 0.02, z * 0.026, hex("#4a382d"))
                    g.dot(x + face * z * 0.12, y - z * 0.005, z * 0.042, hex("#6e5140"))
                }
            }
        }
    }

    func drawGlints(_ g: CGContext, _ L: BoardLayout, _ game: Game, _ now: Double) {
        let S = L.S
        for i in 0..<Board.count where game.map[i] == .ore && game.owner[i] < 0 {
            let a = max(0, sin(now * 1.7 + Double(artHash(Double(i), 5)) * 20) - 0.82) / 0.18
            guard a > 0 else { continue }
            let x = L.cellX(i) + S * (0.25 + 0.5 * artHash(Double(i), 6)), y = L.cellY(i) + S * (0.25 + 0.5 * artHash(Double(i), 7)), s = S * 0.09 * a
            g.beginPath()
            g.move(to: P(x, y - s)); g.addLine(to: P(x + s * 0.25, y)); g.addLine(to: P(x, y + s)); g.addLine(to: P(x - s * 0.25, y)); g.closePath()
            g.move(to: P(x - s, y)); g.addLine(to: P(x, y + s * 0.25)); g.addLine(to: P(x + s, y)); g.addLine(to: P(x, y - s * 0.25)); g.closePath()
            g.fillCurrent(rgba(255, 248, 215, a))
        }
    }

    // MARK: - Celebration

    /// A ring of dust where a building lands.
    func landed(at p: CGPoint) {
        for n in 0..<12 { dust.append(Dust(x: p.x, y: p.y, a: CGFloat(n) / 12 * .pi * 2, t: 0)) }
    }

    func drawDust(_ g: CGContext, _ L: BoardLayout, _ dt: Double) {
        let S = L.S
        for i in dust.indices {
            dust[i].t += dt
            let p = dust[i], k = p.t / 0.6
            g.dot(p.x + cos(p.a) * S * 0.5 * k, p.y + sin(p.a) * S * 0.25 * k, S * (0.05 + k * 0.06), rgba(245, 236, 215, (1 - k) * 0.8))
        }
        dust.removeAll { $0.t >= 0.6 }
    }

    func burst(at p: CGPoint, count: Int, _ S: CGFloat) {
        for _ in 0..<count {
            let a = -CGFloat.pi / 2 + (.random(in: 0..<1) - 0.5) * 2.4, sp = S * (3 + .random(in: 0..<6))
            bits.append(Bit(x: p.x, y: p.y, vx: cos(a) * sp, vy: sin(a) * sp, r: .random(in: 0..<6), vr: (.random(in: 0..<1) - 0.5) * 14,
                            s: S * (0.07 + .random(in: 0..<0.07)), t: 0, c: Self.confettiColours.randomElement()!))
        }
    }

    func drawConfetti(_ g: CGContext, _ L: BoardLayout, _ dt: Double) {
        let S = L.S
        for i in bits.indices {
            bits[i].t += dt
            bits[i].vy += S * 10 * dt
            bits[i].vx *= 1 - dt * 1.4
            bits[i].x += bits[i].vx * dt; bits[i].y += bits[i].vy * dt; bits[i].r += bits[i].vr * dt
            let p = bits[i]
            g.saveGState()
            g.translateBy(x: p.x, y: p.y); g.rotate(by: p.r); g.setAlpha(max(0, 1 - p.t / 1.8))
            g.box(-p.s / 2, -p.s * 0.3, p.s, p.s * 0.6, p.c)
            g.restoreGState()
        }
        bits.removeAll { $0.t >= 1.8 }
    }

    /// Score numbers that rise from buildings whose score changed.
    func drawFloaters(_ ctx: inout GraphicsContext, _ L: BoardLayout, _ dt: Double) {
        let S = L.S
        for i in floaters.indices { floaters[i].t += dt }
        for f in floaters {
            let k = f.t / 1.4, a = min(1, (1 - k) * 3)
            let y = f.y - CGFloat(k) * S * 0.8
            let font = Font.system(size: S * (f.big ? 0.78 : 0.5), weight: .heavy, design: .rounded)
            let outline = ctx.resolve(Text(f.text).font(font).foregroundColor(Color(red: 0.08, green: 0.11, blue: 0.1).opacity(a * 0.8)))
            for (ox, oy) in [(-1.5, 0), (1.5, 0), (0, -1.5), (0, 1.5)] as [(CGFloat, CGFloat)] {
                ctx.draw(outline, at: P(f.x + ox, y + oy))
            }
            let colour = f.good ? Color(red: 160 / 255, green: 236 / 255, blue: 170 / 255) : Color(red: 1, green: 170 / 255, blue: 150 / 255)
            ctx.draw(ctx.resolve(Text(f.text).font(font).foregroundColor(colour.opacity(a))), at: P(f.x, y))
        }
        floaters.removeAll { $0.t >= 1.4 }
    }
}
