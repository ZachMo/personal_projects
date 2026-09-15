import UIKit
import FirstTownCore

/// The board and the land on it: grass, wheat, herd land, ore, woods and water, with a faint outline on every open lot.
enum LandArt {
    static let grass = ["#a5c884", "#a0c47f", "#9cc17b", "#a9cb88"]
    static let trees = ["#4f8d52", "#5b9a58", "#468449", "#62a05c"]

    static func tree(_ g: CGContext, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ seed: CGFloat) {
        g.oval(x + r * 0.32, y + r * 0.42, r * 1.02, r * 0.82, rgba(28, 58, 34, 0.26))
        g.dot(x, y, r, hex(trees[min(trees.count - 1, Int(seed * CGFloat(trees.count)))]))
        g.dot(x - r * 0.28, y - r * 0.3, r * 0.52, rgba(255, 255, 255, 0.14))
    }

    static func draw(_ g: CGContext, _ L: BoardLayout, _ game: Game) {
        let S = L.S, W = L.W, H = L.H, m = S * 0.24, map = game.map
        func of(_ t: Terrain) -> [Int] { (0..<Board.count).filter { map[$0] == t } }

        // The frame the map sits in.
        g.saveGState()
        g.setShadow(offset: CGSize(width: 0, height: S * 0.22), blur: S * 0.7, color: rgba(0, 0, 0, 0.45))
        g.beginPath(); g.rounded(L.BX - m, L.BY - m, W + m * 2, H + m * 2, S * 0.55); g.fillCurrent(hex("#3a4843"))
        g.restoreGState()
        g.beginPath(); g.rounded(L.BX - m, L.BY - m, W + m * 2, H + m * 2, S * 0.55); g.strokeCurrent(rgba(255, 255, 255, 0.07), 1)
        g.beginPath(); g.rounded(L.BX - 3, L.BY - 3, W + 6, H + 6, S * 0.3); g.fillCurrent(hex("#26302d"))

        g.saveGState()
        g.beginPath(); g.rounded(L.BX, L.BY, W, H, S * 0.26); g.clip()

        for i in 0..<Board.count {
            g.box(L.cellX(i), L.cellY(i), S + 0.5, S + 0.5, hex(grass[min(3, Int(artHash(Double(i), 1) * 4))]))
        }
        // Tufts on the open grass.
        g.beginPath()
        for i in 0..<Board.count where map[i] == .grass {
            for k in 0..<3 {
                let x = L.cellX(i) + S * (0.14 + 0.72 * artHash(Double(i), Double(k * 3 + 2)))
                let y = L.cellY(i) + S * (0.18 + 0.7 * artHash(Double(i), Double(k * 5 + 7)))
                let s = S * 0.05
                g.move(to: P(x - s, y - s)); g.addLine(to: P(x, y)); g.addLine(to: P(x + s * 0.8, y - s * 1.1))
            }
        }
        g.setLineCap(.round); g.setLineJoin(.round)
        g.strokeCurrent(rgba(70, 110, 50, 0.35), max(1, S * 0.025))

        // Wild wheat: rows of little stalks.
        g.beginPath(); g.addUnion(of(.wheat), L, inset: S * 0.03, radius: S * 0.28); g.fillCurrent(hex("#e5c66b"))
        for i in of(.wheat) {
            let x = L.cellX(i), y = L.cellY(i)
            for row in 0..<4 {
                for col in 0..<4 {
                    let px = x + S * (0.16 + CGFloat(col) * 0.22 + CGFloat(row % 2) * 0.1), py = y + S * (0.22 + CGFloat(row) * 0.21)
                    if px > x + S * 0.92 { continue }
                    g.beginPath(); g.line(px, py + S * 0.05, px + S * 0.03, py - S * 0.06)
                    g.strokeCurrent(hex("#c9a445"), max(1, S * 0.035))
                    g.dot(px + S * 0.035, py - S * 0.07, S * 0.028, hex("#f3dc92"))
                }
            }
        }

        // Grazing herds: lush grass. The animals move, so they are drawn every frame.
        g.beginPath(); g.addUnion(of(.herd), L, inset: S * 0.03, radius: S * 0.3); g.fillCurrent(hex("#c9de8f"))
        g.beginPath(); g.addUnion(of(.herd), L, inset: S * 0.1, radius: S * 0.24); g.fillCurrent(hex("#d2e39a"))

        // Ore: grey rock with bright flecks.
        g.beginPath(); g.addUnion(of(.ore), L, inset: S * 0.04, radius: S * 0.3); g.fillCurrent(hex("#c3baa8"))
        for i in of(.ore) {
            let x = L.cellX(i), y = L.cellY(i)
            for (rx, ry, rs) in [(0.34, 0.38, 0.2), (0.68, 0.6, 0.16), (0.36, 0.74, 0.11)] as [(CGFloat, CGFloat, CGFloat)] {
                let px = x + S * (rx + (artHash(Double(i), Double(rx * 10)) - 0.5) * 0.08), py = y + S * ry, s = S * rs
                g.oval(px + s * 0.2, py + s * 0.3, s * 1.05, s * 0.75, rgba(60, 50, 40, 0.22))
                g.oval(px, py, s, s * 0.78, hex("#8f887d"))
                g.oval(px - s * 0.18, py - s * 0.2, s * 0.62, s * 0.42, hex("#aaa396"))
            }
            for k in 0..<4 {
                let px = x + S * (0.2 + 0.6 * artHash(Double(i), Double(k + 40)))
                let py = y + S * (0.2 + 0.6 * artHash(Double(i), Double(k + 50)))
                g.saveGState(); g.translateBy(x: px, y: py); g.rotate(by: .pi / 4)
                g.box(-S * 0.025, -S * 0.025, S * 0.05, S * 0.05, hex(k % 2 == 1 ? "#f2cf63" : "#e8eef2"))
                g.restoreGState()
            }
        }

        // Woods ground.
        g.beginPath(); g.addUnion(of(.forest), L, inset: S * 0.02, radius: S * 0.32); g.fillCurrent(hex("#86b16b"))

        // Water: a pale bank, then deeper water in the middle.
        let water = of(.water)
        g.beginPath(); g.addUnion(water, L, inset: 0, radius: S * 0.32); g.fillCurrent(hex("#cfe8e6"))
        g.beginPath(); g.addUnion(water, L, inset: S * 0.07, radius: S * 0.26); g.fillCurrent(hex("#62abc9"))
        g.beginPath(); g.addUnion(water, L, inset: S * 0.2, radius: S * 0.2); g.fillCurrent(hex("#559fc0"))

        // Empty lots: a faint outline where a building could go.
        g.beginPath()
        for i in 0..<Board.count where map[i] != .water && game.owner[i] < 0 {
            g.rounded(L.cellX(i) + S * 0.08 + 0.5, L.cellY(i) + S * 0.08 + 0.5, S * 0.84, S * 0.84, S * 0.14)
        }
        g.strokeCurrent(rgba(255, 255, 255, 0.2), 1)

        // Trees, top row first so lower trees overlap the ones behind.
        for i in of(.forest) {
            let x = L.cellX(i), y = L.cellY(i)
            for (k, spot) in ([(0.3, 0.3, 0.21), (0.72, 0.38, 0.19), (0.44, 0.72, 0.22), (0.84, 0.82, 0.13)] as [(CGFloat, CGFloat, CGFloat)]).enumerated() {
                if k == 3 && artHash(Double(i), 9) < 0.5 { continue }
                tree(g, x + S * (spot.0 + (artHash(Double(i), Double(k)) - 0.5) * 0.1),
                     y + S * (spot.1 + (artHash(Double(i), Double(k + 20)) - 0.5) * 0.1),
                     S * spot.2, artHash(Double(i), Double(k + 30)))
            }
        }
        g.restoreGState()
    }
}
