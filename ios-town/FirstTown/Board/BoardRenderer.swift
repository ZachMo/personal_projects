import SwiftUI
import FirstTownCore

/// Draws the board each frame. The land, the streets and settled buildings are drawn once into an image,
/// the way the web version bakes them, and only the things that move are drawn every frame.
final class BoardRenderer {
    let life = Life()
    private var baked: CGImage?
    private var bakedKey = ""
    private var smoke: [(CGPoint, Bool)] = []
    private var last: Double?
    /// A building still falling onto the board: its index and when it was built.
    private var drop: (index: Int, start: Double)?

    func draw(_ ctx: inout GraphicsContext, size: CGSize, now: Double, town: Town, scale: CGFloat) {
        guard size.width > 1, size.height > 1 else { return }
        let L = BoardLayout(size: size), S = L.S
        let dt = min(0.1, last.map { now - $0 } ?? 0)
        last = now

        if town.resetScene { life.reset(); drop = nil; town.resetScene = false }
        let game = town.game
        for effect in town.effects {
            drop = (effect.result.index, now)
            for c in effect.result.changed {
                let m = L.centre(of: game.pieces[c.index].cells)
                life.floaters.append(.init(x: m.x, y: m.y - S * 0.2, t: -0.35, text: Words.signed(c.delta), good: c.delta > 0, big: false))
            }
            if effect.result.trophies.contains(where: \.good) {
                life.burst(at: L.centre(of: effect.cells), count: effect.result.gain >= Trophy.jackpotPoints ? 90 : 45, S)
            }
        }
        town.effects.removeAll()

        let key = "\(size.width)x\(size.height)@\(scale):\(game.seed):\(game.pieces.count):\(drop?.index ?? -1)"
        if key != bakedKey || baked == nil {
            bake(L, game, hide: drop?.index, scale: scale)
            bakedKey = key
        }
        if let baked { ctx.draw(Image(decorative: baked, scale: scale), in: CGRect(origin: .zero, size: size)) }

        ctx.withCGContext { g in
            life.drawWater(g, L, game, now)
            life.drawGlints(g, L, game, now)
            life.drawHerds(g, L, game, now)
            if let d = drop, d.index < game.pieces.count {
                let k = min(1, (now - d.start) / 0.32), p = game.pieces[d.index]
                BuildingArt.piece(g, p.type, p.cells, lift: S * 0.5 * CGFloat((1 - k) * (1 - k)), L)
                if k >= 1 {
                    let m = L.centre(of: p.cells)
                    life.landed(at: P(m.x, m.y + S * 0.3))
                    drop = nil
                }
            }
            life.update(dt, game, smoke: smoke)
            life.drawWalkers(g, L, now)
            life.drawSmoke(g, L)
            life.drawDust(g, L, dt)
            if town.showsGhost, let cells = town.ghostCells { drawGhost(g, L, town, cells, now) }
            drawSelection(g, L, town, now)
            life.drawConfetti(g, L, dt)
        }
        life.drawFloaters(&ctx, L, dt)
    }

    private func bake(_ L: BoardLayout, _ game: Game, hide: Int?, scale: CGFloat) {
        var chimneys: [(CGPoint, Bool)] = []
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: L.size, format: format).image { rc in
            let g = rc.cgContext
            LandArt.draw(g, L, game)
            // Streets under the town, so gaps between buildings read as lanes.
            let built = (0..<Board.count).filter { game.owner[$0] >= 0 && game.map[$0] != .water }
            g.saveGState()
            g.beginPath(); g.rounded(L.BX, L.BY, L.W, L.H, L.S * 0.26); g.clip()
            g.beginPath(); g.addUnion(built, L, inset: L.S * 0.01, radius: L.S * 0.2); g.fillCurrent(hex("#e6dcc6"))
            g.beginPath(); g.addUnion(built, L, inset: L.S * 0.045, radius: L.S * 0.18); g.fillCurrent(hex("#ddd1b8"))
            g.restoreGState()
            let order = game.pieces.indices.sorted { game.pieces[$0].cells.min()! < game.pieces[$1].cells.min()! }
            for k in order where k != hide {
                BuildingArt.piece(g, game.pieces[k].type, game.pieces[k].cells, lift: 0, L) { chimneys.append(($0, $1)) }
            }
        }
        smoke = chimneys
        baked = image.cgImage
    }

    // MARK: - The building in hand

    private func drawGhost(_ g: CGContext, _ L: BoardLayout, _ town: Town, _ cells: [Int], _ now: Double) {
        guard let type = town.game.current else { return }
        let S = L.S, game = town.game, ok = game.canPlace(cells, type), lift = S * 0.16
        let dy = -lift - S * 0.085, pulse = 0.8 + 0.2 * sin(now * 5)

        // The squares it would land on, marked on the board below it.
        g.beginPath()
        for c in cells { g.rounded(L.cellX(c) + S * 0.1, L.cellY(c) + S * 0.1, S * 0.8, S * 0.8, S * 0.16) }
        g.fillCurrent(ok ? rgba(255, 255, 255, 0.38) : rgba(214, 72, 52, 0.4))

        // While you drag, or while its scoring is open, the squares that count as beside it.
        if town.dragging || town.rulesOpen {
            let own = Set(cells)
            var ring = Set<Int>()
            for c in cells { for j in Board.around(c) where !own.contains(j) { ring.insert(j) } }
            g.saveGState()
            g.setLineDash(phase: 0, lengths: [S * 0.09, S * 0.07])
            g.beginPath()
            for j in ring { g.rounded(L.cellX(j) + S * 0.14, L.cellY(j) + S * 0.14, S * 0.72, S * 0.72, S * 0.12) }
            g.strokeCurrent(rgba(255, 255, 255, 0.8), max(1.5, S * 0.035))
            g.restoreGState()
        }

        // A glowing rim: a slightly bigger shape underneath, so only its outside edge shows.
        g.beginPath(); g.addUnion(cells, L, inset: 0, radius: S * 0.22, dy: dy + S * 0.04)
        g.fillCurrent(ok ? rgba(255, 255, 255, pulse) : rgba(255, 105, 85, pulse))
        BuildingArt.piece(g, type, cells, lift: lift, L)

        guard !ok else { return }
        for c in cells {
            let end = c == cells.first || c == cells.last
            if game.owner[c] < 0 && (game.map[c] != .water || (Library[type].bridge && !end)) { continue }
            let x = L.cellX(c), y = L.cellY(c) + dy
            g.beginPath(); g.rounded(x + S * 0.12, y + S * 0.12, S * 0.76, S * 0.76, S * 0.14); g.fillCurrent(rgba(214, 72, 52, 0.55))
            g.beginPath(); g.line(x + S * 0.36, y + S * 0.36, x + S * 0.64, y + S * 0.64); g.line(x + S * 0.64, y + S * 0.36, x + S * 0.36, y + S * 0.64)
            g.setLineCap(.round)
            g.strokeCurrent(rgba(255, 255, 255, 1), max(2, S * 0.06))
        }
    }

    private func drawSelection(_ g: CGContext, _ L: BoardLayout, _ town: Town, _ now: Double) {
        let i = town.selection
        guard i >= 0 else { return }
        let S = L.S, a = 0.6 + 0.4 * sin(now * 4), k = town.game.owner[i]
        if k >= 0 {
            guard drop?.index != k else { return }
            let p = town.game.pieces[k]
            g.beginPath(); g.addUnion(p.cells, L, inset: S * 0.01, radius: S * 0.22, dy: -S * 0.04); g.fillCurrent(rgba(255, 214, 102, a))
            BuildingArt.piece(g, p.type, p.cells, lift: 0, L)
            return
        }
        g.beginPath(); g.rounded(L.cellX(i) + S * 0.05, L.cellY(i) + S * 0.05, S * 0.9, S * 0.9, S * 0.16)
        g.strokeCurrent(rgba(255, 214, 102, a), max(2, S * 0.055))
    }
}
