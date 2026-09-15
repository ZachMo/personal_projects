import UIKit
import FirstTownCore

/// Buildings: a raised tile, the ground on each square, roofs, chimneys and signs.
enum BuildingArt {
    static let tile: [FirstTownCore.Category: [String]] = [
        .home: ["#f6e9dc", "#d9bfa9"],
        .agri: ["#f4ecd3", "#d7c69c"],
        .industry: ["#e9e9e5", "#c3c4be"],
        .shop: ["#e3f0eb", "#b5d0c6"],
        .civic: ["#e7edf6", "#bccadf"],
        .leisure: ["#f3e6ee", "#d4b9c9"],
    ]

    static let ground: [String: String] = [
        "garden": "#b3d494", "tree": "#b3d494", "flag": "#b3d494", "well": "#b3d494", "field": "#e6c463", "pasture": "#bddb95",
        "yard": "#e5d6b7", "crates": "#e5d6b7", "logs": "#e5d6b7", "produce": "#e5d6b7", "rocks": "#d2c9ba", "shaft": "#cfc4b1",
        "plank": "#bb8c5f", "porch": "#c29568", "rail": "#cdc2ad", "play": "#ebdaa9",
        "orchard": "#b8d98f", "vines": "#cbdc9e", "wheel": "#cfc4b1", "windmill": "#b3d494", "kiln": "#d2c9ba", "sluice": "#cbbfa9",
        "deck": "#c69a6b", "hay": "#e5d6b7", "plaza": "#e3dac7", "graves": "#b3d494", "pool": "#e3dac7", "track": "#bddb95", "tent": "#eadcb5",
    ]

    static let roofs: Set<String> = ["house", "rowA", "rowB", "hall", "shop", "barn", "forge", "shed", "nave", "steeple", "big"]

    /// A raised tile with a building on it. `lift` raises the whole tile off the board.
    static func piece(_ g: CGContext, _ type: String, _ cells: [Int], lift: CGFloat, _ L: BoardLayout, _ smoke: SmokeSink? = nil) {
        let d = Library[type], S = L.S, ins = S * 0.075, r = S * 0.16, th = S * 0.085
        let t = d.tile ?? tile[d.category]!
        g.saveGState()
        g.setShadow(offset: CGSize(width: 0, height: S * 0.05 + lift * 0.5), blur: S * 0.14 + lift * 0.5, color: rgba(18, 28, 24, 0.4))
        g.beginPath(); g.addUnion(cells, L, inset: ins, radius: r); g.fillCurrent(hex(t[1]))
        g.restoreGState()
        if lift > 0 { g.beginPath(); g.addUnion(cells, L, inset: ins, radius: r, dy: -lift); g.fillCurrent(hex(t[1])) }
        g.beginPath(); g.addUnion(cells, L, inset: ins, radius: r, dy: -lift - th - 1); g.fillCurrent(rgba(255, 255, 255, 0.7))
        g.beginPath(); g.addUnion(cells, L, inset: ins, radius: r, dy: -lift - th); g.fillCurrent(hex(t[0]))
        art(g, type, cells, dy: -lift - th, L, smoke)
    }

    /// A building's art on top of its tile. `dy` is how far the top of the tile is raised.
    static func art(_ g: CGContext, _ type: String, _ cells: [Int], dy: CGFloat, _ L: BoardLayout, _ smoke: SmokeSink?) {
        let d = Library[type], S = L.S, ins = S * 0.075
        var roleOf: [Int: String] = [:]
        for (k, c) in cells.enumerated() { roleOf[c] = d.roles[k] }
        let xs = cells.map(Board.col), ys = cells.map(Board.row)
        let horiz = xs.max()! - xs.min()! >= ys.max()! - ys.min()!

        var seen = Set<String>()
        for role in d.roles where seen.insert(role).inserted && !roofs.contains(role) {
            let group = cells.filter { roleOf[$0] == role }
            g.beginPath(); g.addUnion(group, L, inset: ins + S * 0.045, radius: S * 0.1, dy: dy); g.fillCurrent(hex(ground[role]!))

            if role == "field" || role == "plank" {
                g.saveGState()
                g.beginPath(); g.addUnion(group, L, inset: ins + S * 0.045, radius: S * 0.1, dy: dy); g.clip()
                g.beginPath()
                let step = S * (role == "field" ? 0.16 : 0.12), flat = role == "field" ? horiz : !horiz
                for c in group {
                    let x = L.cellX(c), y = L.cellY(c) + dy
                    var t = (flat ? y : x) + step / 2
                    while t < (flat ? y : x) + S {
                        if flat { g.line(x, t, x + S, t) } else { g.line(t, y, t, y + S) }
                        t += step
                    }
                }
                g.strokeCurrent(hex(role == "field" ? "#cfa546" : "#9c704a"), max(1, S * (role == "field" ? 0.05 : 0.025)))
                g.restoreGState()
            }

            func bounds() -> (x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
                let gx = group.map(Board.col), gy = group.map(Board.row), x0 = gx.min()!, y0 = gy.min()!
                let w = CGFloat(gx.max()! - x0 + 1) * S, h = CGFloat(gy.max()! - y0 + 1) * S
                return (L.BX + CGFloat(x0) * S + w / 2, L.BY + CGFloat(y0) * S + dy + h / 2, w, h)
            }
            if role == "plaza" {
                g.saveGState()
                g.beginPath(); g.addUnion(group, L, inset: ins + S * 0.045, radius: S * 0.1, dy: dy); g.clip()
                g.beginPath()
                for c in group {
                    for k in 1..<3 {
                        let x = L.cellX(c), y = L.cellY(c) + dy, o = S * CGFloat(k) / 3
                        g.line(x + o, y, x + o, y + S); g.line(x, y + o, x + S, y + o)
                    }
                }
                g.strokeCurrent(rgba(120, 100, 70, 0.18), 1)
                g.restoreGState()
                let b = bounds()
                g.dot(b.x + S * 0.03, b.y + S * 0.05, S * 0.36, rgba(40, 30, 20, 0.18))
                g.dot(b.x, b.y, S * 0.36, hex("#cfc5b0")); g.dot(b.x, b.y, S * 0.28, hex("#7cc3d8"))
                g.dot(b.x, b.y, S * 0.1, hex("#e9e2d0")); g.dot(b.x - S * 0.08, b.y - S * 0.09, S * 0.05, rgba(255, 255, 255, 0.6))
            }
            if role == "track" {
                let b = bounds(), rx = b.w / 2 - S * 0.32, ry = b.h / 2 - S * 0.32
                g.beginPath(); g.addEllipse(in: CGRect(x: b.x - rx, y: b.y - ry, width: rx * 2, height: ry * 2))
                g.strokeCurrent(hex("#caa46c"), S * 0.3)
                let ox = b.w / 2 - S * 0.16, oy = b.h / 2 - S * 0.16
                g.beginPath(); g.addEllipse(in: CGRect(x: b.x - ox, y: b.y - oy, width: ox * 2, height: oy * 2))
                g.strokeCurrent(hex("#f7f2e6"), max(1, S * 0.025))
                g.dot(b.x + b.w / 2 - S * 0.32, b.y, S * 0.07, hex("#7a5236"))
                g.dot(b.x - b.w / 2 + S * 0.32, b.y - S * 0.3, S * 0.07, hex("#3d2b1f"))
            }
            if role == "pasture" {
                // A fence: a darker ring, then the grass again just inside it.
                g.beginPath(); g.addUnion(group, L, inset: ins + S * 0.075, radius: S * 0.08, dy: dy); g.fillCurrent(hex("#9d7b56"))
                g.beginPath(); g.addUnion(group, L, inset: ins + S * 0.1, radius: S * 0.07, dy: dy); g.fillCurrent(hex(ground["pasture"]!))
            }
            for c in group { groundDetail(g, role, c, L.cellX(c), L.cellY(c) + dy, S, horiz, smoke) }
        }

        // Roofs: squares with the same role that make a rectangle share one roof.
        var done = Set<Int>()
        let pad = ins + S * 0.06
        var sign: (n: Int, x: CGFloat, y: CGFloat)?
        for c in cells {
            let role = roleOf[c]!
            guard roofs.contains(role), !done.contains(c) else { continue }
            var group = [c], queue = [c]
            done.insert(c)
            while let q = queue.popLast() {
                for j in Board.around(q) where !done.contains(j) && roleOf[j] == role {
                    done.insert(j); group.append(j); queue.append(j)
                }
            }
            let gx = group.map(Board.col), gy = group.map(Board.row)
            let x0 = gx.min()!, y0 = gy.min()!, gw = gx.max()! - x0 + 1, gh = gy.max()! - y0 + 1
            if gw * gh == group.count {
                roof(g, role, d, L.BX + CGFloat(x0) * S + pad, L.BY + CGFloat(y0) * S + dy + pad,
                     CGFloat(gw) * S - pad * 2, CGFloat(gh) * S - pad * 2, S, smoke)
            } else {
                for q in group { roof(g, role, d, L.cellX(q) + pad, L.cellY(q) + dy + pad, S - pad * 2, S - pad * 2, S, smoke) }
            }
            if sign == nil || group.count > sign!.n {
                sign = (group.count, L.BX + (CGFloat(x0) + CGFloat(gw) / 2) * S, L.BY + (CGFloat(y0) + CGFloat(gh) / 2) * S + dy)
            }
        }
        if let kind = d.emblem, let sign { emblem(g, kind, sign.x, sign.y, S) }
    }

    // MARK: - Roofs

    static func roof(_ g: CGContext, _ role: String, _ d: Building, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
                     _ S: CGFloat, _ smoke: SmokeSink?) {
        if role == "big" || role == "steeple" {
            hip(g, x, y, w, h, d.roof!, S)
            if role == "steeple" {
                g.beginPath()
                g.line(x + w / 2 - S * 0.08, y + h / 2, x + w / 2 + S * 0.08, y + h / 2)
                g.line(x + w / 2, y + h / 2 - S * 0.12, x + w / 2, y + h / 2 + S * 0.08)
                g.strokeCurrent(hex("#f5efe2"), max(1.5, S * 0.04))
            }
            return
        }
        gable(g, x, y, w, h, (role == "rowB" ? d.roof2 : d.roof)!, S)
        if role == "house" || role == "rowA" { chimney(g, x + w * 0.7, y + h * 0.12, dark: false, S, smoke) }
        if role == "forge" { chimney(g, x + w * 0.62, y + h * 0.18, dark: true, S, smoke) }
        if role == "shop" {
            // A striped awning along the front.
            let ah = S * 0.13, ay = y + h - ah * 0.6
            g.box(x, ay + S * 0.05, w, ah, rgba(40, 30, 20, 0.2))
            let n = max(3, Int((w / (S * 0.12)).rounded()))
            for k in 0..<n { g.box(x + w / CGFloat(n) * CGFloat(k), ay, w / CGFloat(n) + 0.5, ah, k % 2 == 1 ? hex("#f7f2e6") : hex(d.roof![0])) }
        }
        if role == "barn" {
            g.beginPath(); g.rounded(x + w / 2 - S * 0.08, y + h / 2 - S * 0.08, S * 0.16, S * 0.16, S * 0.02)
            g.strokeCurrent(rgba(255, 255, 255, 0.55), max(1, S * 0.025))
        }
        if role == "hall" && d.id == "townhall" {
            hip(g, x + w / 2 - S * 0.16, y + h / 2 - S * 0.16, S * 0.32, S * 0.32, ["#e9e2d0", "#c9bfaa"], S)
            g.dot(x + w / 2, y + h / 2, S * 0.05, hex("#e3a92f"))
        }
        if role == "hall" && d.id == "station" {
            for k in 1..<4 { g.box(x + w / 4 * CGFloat(k) - S * 0.02, y + h / 2 - S * 0.1, S * 0.04, S * 0.2, rgba(255, 255, 255, 0.5)) }
        }
    }

    /// A roof with a ridge down its long side, lit from the top left.
    static func gable(_ g: CGContext, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: [String], _ S: CGFloat) {
        let r = S * 0.05, along = w >= h
        g.beginPath(); g.rounded(x + S * 0.03, y + S * 0.06, w, h, r); g.fillCurrent(rgba(40, 30, 20, 0.2))
        g.saveGState()
        g.beginPath(); g.rounded(x, y, w, h, r); g.clip()
        g.box(x, y, w, h, hex(c[0]))
        if along { g.box(x, y + h / 2, w, h / 2, hex(c[1])) } else { g.box(x + w / 2, y, w / 2, h, hex(c[1])) }
        g.beginPath()
        let step = S * 0.085
        if along {
            var t = y + step
            while t < y + h { g.line(x, t, x + w, t); t += step }
        } else {
            var t = x + step
            while t < x + w { g.line(t, y, t, y + h); t += step }
        }
        g.strokeCurrent(rgba(0, 0, 0, 0.08), max(1, S * 0.018))
        g.restoreGState()
        g.beginPath()
        if along { g.line(x + S * 0.05, y + h / 2, x + w - S * 0.05, y + h / 2) } else { g.line(x + w / 2, y + S * 0.05, x + w / 2, y + h - S * 0.05) }
        g.setLineCap(.round)
        g.strokeCurrent(rgba(255, 255, 255, 0.4), max(1, S * 0.028))
    }

    /// A roof that slopes on all four sides.
    static func hip(_ g: CGContext, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: [String], _ S: CGFloat) {
        g.beginPath(); g.rounded(x + S * 0.03, y + S * 0.06, w, h, S * 0.05); g.fillCurrent(rgba(40, 30, 20, 0.2))
        let cx = x + w / 2, cy = y + h / 2, k = min(w, h) / 2
        let r1 = w >= h ? P(x + k, cy) : P(cx, y + k), r2 = w >= h ? P(x + w - k, cy) : P(cx, y + h - k)
        let TL = P(x, y), TR = P(x + w, y), BR = P(x + w, y + h), BL = P(x, y + h)
        func face(_ pts: [CGPoint], _ col: CGColor) {
            g.beginPath(); g.move(to: pts[0]); pts.dropFirst().forEach { g.addLine(to: $0) }; g.closePath(); g.fillCurrent(col)
        }
        if w >= h {
            face([TL, TR, r2, r1], shade(c[0], 0.12)); face([TL, r1, BL], hex(c[0]))
            face([TR, BR, r2], hex(c[1])); face([BL, BR, r2, r1], shade(c[1], -0.1))
        } else {
            face([TL, TR, r1], shade(c[0], 0.12)); face([TL, r1, r2, BL], hex(c[0]))
            face([TR, BR, r2, r1], hex(c[1])); face([BL, BR, r2], shade(c[1], -0.1))
        }
        g.beginPath()
        g.move(to: TL); g.addLine(to: r1); g.addLine(to: BL)
        g.move(to: TR); g.addLine(to: r2); g.addLine(to: BR)
        g.move(to: r1); g.addLine(to: r2)
        g.strokeCurrent(rgba(255, 255, 255, 0.3), max(1, S * 0.022))
    }

    static func chimney(_ g: CGContext, _ x: CGFloat, _ y: CGFloat, dark: Bool, _ S: CGFloat, _ smoke: SmokeSink?) {
        let s = S * 0.11
        g.box(x + s * 0.3, y + s * 0.4, s, s, rgba(40, 30, 20, 0.25))
        g.box(x, y, s, s, hex("#8d827a"))
        g.box(x + s * 0.22, y + s * 0.22, s * 0.56, s * 0.56, hex(dark ? "#e0743a" : "#4d4642"))
        smoke?(P(x + s / 2, y), dark)
    }

    /// A small sign on a roof: a star for the sheriff, a dollar for the bank.
    static func emblem(_ g: CGContext, _ kind: String, _ x: CGFloat, _ y: CGFloat, _ S: CGFloat) {
        let s = S * 0.15
        g.saveGState()
        g.translateBy(x: x, y: y)
        g.dot(S * 0.02, S * 0.03, s * 1.25, rgba(30, 20, 10, 0.25))
        if kind == "star" {
            g.beginPath()
            for k in 0..<10 {
                let a = -CGFloat.pi / 2 + CGFloat(k) * .pi / 5, rad = k % 2 == 1 ? s * 0.5 : s * 1.2
                let p = P(cos(a) * rad, sin(a) * rad)
                if k == 0 { g.move(to: p) } else { g.addLine(to: p) }
            }
            g.closePath()
            g.setFillColor(hex("#f2c94c")); g.setStrokeColor(hex("#8a6414")); g.setLineWidth(max(1, S * 0.02))
            g.drawPath(using: .fillStroke)
        } else {
            g.dot(0, 0, s * 1.15, hex(kind == "dollar" ? "#f2c94c" : "#f7f2e6"))
            g.setLineCap(.round)
            let ink = hex("#3d4148"), width = max(1.2, S * 0.03)
            switch kind {
            case "bars":
                g.beginPath(); for bx: CGFloat in [-0.45, 0, 0.45] { g.line(bx * s, -0.7 * s, bx * s, 0.7 * s) }
                g.strokeCurrent(ink, width)
            case "clock":
                g.beginPath(); g.line(0, 0, 0, -0.7 * s); g.line(0, 0, 0.5 * s, 0.2 * s)
                g.strokeCurrent(ink, width)
            case "cross":
                g.box(-0.22 * s, -0.7 * s, 0.44 * s, 1.4 * s, hex("#d65a45")); g.box(-0.7 * s, -0.22 * s, 1.4 * s, 0.44 * s, hex("#d65a45"))
            case "book":
                g.box(-0.75 * s, -0.5 * s, 0.68 * s, s, hex("#6d8f7a")); g.box(0.07 * s, -0.5 * s, 0.68 * s, s, hex("#6d8f7a"))
            case "dollar":
                g.centredText("$", 0, s * 0.08, size: (s * 1.5).rounded(), color: hex("#6b4a08"))
            case "mask":
                g.dot(-0.4 * s, -0.2 * s, 0.17 * s, ink); g.dot(0.4 * s, -0.2 * s, 0.17 * s, ink)
                g.beginPath(); g.arcPoints(0, 0.05 * s, 0.5 * s, 0.5 * s, 0.15 * .pi, 0.85 * .pi)
                g.strokeCurrent(ink, width)
            case "diamond":
                g.beginPath(); g.move(to: P(0, -0.8 * s)); g.addLine(to: P(0.6 * s, 0)); g.addLine(to: P(0, 0.8 * s)); g.addLine(to: P(-0.6 * s, 0)); g.closePath()
                g.fillCurrent(hex("#d9434f"))
            default:
                break
            }
        }
        g.restoreGState()
    }

    // MARK: - The ground on each square

    static func groundDetail(_ g: CGContext, _ role: String, _ i: Int, _ x: CGFloat, _ y: CGFloat, _ S: CGFloat, _ horiz: Bool, _ smoke: SmokeSink?) {
        let cx = x + S / 2, cy = y + S / 2, hi = Double(i)
        func h(_ k: Double) -> CGFloat { artHash(hi, k) }
        let shadow = rgba(40, 30, 20, 0.2)

        switch role {
        case "garden":
            g.dot(x + S * 0.34, y + S * 0.38, S * 0.13, hex("#86bd6d"))
            g.dot(x + S * 0.64, y + S * 0.62, S * 0.11, hex("#79b262"))
            for (k, f) in ["#f2a4b3", "#fff1a8", "#ffffff", "#f7b27a"].enumerated() {
                g.dot(x + S * (0.25 + 0.5 * h(Double(k + 60))), y + S * (0.25 + 0.5 * h(Double(k + 70))), S * 0.03, hex(f))
            }
        case "tree":
            LandArt.tree(g, cx, cy, S * 0.25, h(3))
        case "flag":
            g.dot(cx, cy, S * 0.22, hex("#9fcd84"))
            for k in 0..<6 { g.dot(cx + cos(CGFloat(k)) * S * 0.15, cy + sin(CGFloat(k)) * S * 0.15, S * 0.03, hex(k % 2 == 1 ? "#f2a4b3" : "#fff1a8")) }
            g.box(cx + S * 0.02, cy - S * 0.1, S * 0.22, S * 0.03, rgba(0, 0, 0, 0.2))
            g.dot(cx, cy, S * 0.035, hex("#6d645c"))
            g.box(cx, cy - S * 0.14, S * 0.2, S * 0.1, hex("#d65a45"))
            g.box(cx, cy - S * 0.14, S * 0.07, S * 0.05, hex("#f7f2e6"))
        case "well":
            g.dot(cx + S * 0.03, cy + S * 0.05, S * 0.26, shadow)
            g.dot(cx, cy, S * 0.26, hex("#b9afa1")); g.dot(cx, cy, S * 0.19, hex("#8f867a")); g.dot(cx, cy, S * 0.15, hex("#5aa4c4"))
            g.dot(cx - S * 0.05, cy - S * 0.05, S * 0.05, rgba(255, 255, 255, 0.45))
            g.box(cx - S * 0.3, cy - S * 0.025, S * 0.6, S * 0.05, hex("#8a6444"))
        case "yard", "crates":
            func crate(_ bx: CGFloat, _ by: CGFloat, _ s: CGFloat) {
                g.box(bx + s * 0.15, by + s * 0.2, s, s, shadow)
                g.box(bx, by, s, s, hex("#bb8f5c"))
                g.beginPath(); g.addRect(CGRect(x: bx + 0.5, y: by + 0.5, width: s - 1, height: s - 1)); g.line(bx, by, bx + s, by + s)
                g.strokeCurrent(hex("#946b40"), max(1, S * 0.02))
            }
            crate(x + S * 0.22, y + S * 0.24, S * 0.2)
            crate(x + S * 0.5, y + S * 0.3, S * 0.16)
            g.dot(x + S * 0.38, y + S * 0.66, S * 0.1, hex("#8d6545")); g.dot(x + S * 0.38, y + S * 0.66, S * 0.06, hex("#a77c58"))
        case "logs":
            for k in 0..<3 {
                let ly = y + S * (0.28 + CGFloat(k) * 0.17), lx = x + S * 0.16 + CGFloat(k % 2) * S * 0.06, lw = S * 0.6
                g.box(lx + S * 0.03, ly + S * 0.05, lw, S * 0.12, shadow)
                g.beginPath(); g.rounded(lx, ly, lw, S * 0.12, S * 0.06); g.fillCurrent(hex("#a47650"))
                g.dot(lx + lw - S * 0.05, ly + S * 0.06, S * 0.055, hex("#dcb98c"))
            }
        case "produce":
            let fruit = ["#d9483b", "#f09b30", "#7fb24a", "#e8c43c"]
            for k in 0..<4 {
                let bx = x + S * (0.16 + CGFloat(k % 2) * 0.36), by = y + S * (0.18 + CGFloat(k / 2) * 0.36), s = S * 0.3
                g.box(bx + S * 0.03, by + S * 0.04, s, s, rgba(40, 30, 20, 0.18))
                g.box(bx, by, s, s, hex("#b98d5c"))
                for f in 0..<4 { g.dot(bx + s * (0.3 + CGFloat(f % 2) * 0.4), by + s * (0.3 + CGFloat(f / 2) * 0.4), s * 0.17, hex(fruit[k])) }
            }
        case "rocks":
            for (rx, ry, rs) in [(0.35, 0.4, 0.15), (0.64, 0.58, 0.12), (0.4, 0.7, 0.09)] as [(CGFloat, CGFloat, CGFloat)] {
                g.oval(x + S * rx + S * 0.02, y + S * ry + S * 0.04, S * rs, S * rs * 0.75, shadow)
                g.oval(x + S * rx, y + S * ry, S * rs, S * rs * 0.75, hex("#958d82"))
                g.oval(x + S * rx - S * rs * 0.2, y + S * ry - S * rs * 0.2, S * rs * 0.55, S * rs * 0.38, hex("#b0a89b"))
            }
            g.dot(x + S * 0.7, y + S * 0.3, S * 0.035, hex("#f2cf63"))
        case "shaft":
            g.oval(cx + S * 0.03, cy + S * 0.06, S * 0.32, S * 0.27, rgba(40, 30, 20, 0.22))
            g.oval(cx, cy, S * 0.32, S * 0.27, hex("#8b8378"))
            g.oval(cx - S * 0.06, cy - S * 0.06, S * 0.2, S * 0.15, hex("#a39b8f"))
            g.beginPath(); g.arcPoints(cx, cy + S * 0.06, S * 0.13, S * 0.1, .pi, .pi * 2); g.closePath(); g.fillCurrent(hex("#2f2a26"))
            g.box(cx - S * 0.15, cy + S * 0.05, S * 0.3, S * 0.04, hex("#7a5a3c"))
            g.beginPath(); g.line(cx - S * 0.06, cy + S * 0.1, cx - S * 0.08, y + S); g.line(cx + S * 0.06, cy + S * 0.1, cx + S * 0.08, y + S)
            g.strokeCurrent(hex("#6c5b4a"), max(1, S * 0.025))
        case "play":
            g.dot(cx, cy, S * 0.26, hex("#e2c98e"))
            g.beginPath(); g.line(cx - S * 0.2, cy - S * 0.08, cx + S * 0.2, cy - S * 0.08); g.strokeCurrent(hex("#8a6444"), max(1.5, S * 0.04))
            g.box(cx - S * 0.12, cy - S * 0.02, S * 0.08, S * 0.04, hex("#d65a45")); g.box(cx + S * 0.04, cy - S * 0.02, S * 0.08, S * 0.04, hex("#d65a45"))
        case "rail":
            g.beginPath()
            for k in 0..<4 {
                let t = 0.16 + CGFloat(k) * 0.23
                if horiz { g.line(x + S * t, y + S * 0.22, x + S * t, y + S * 0.78) } else { g.line(x + S * 0.22, y + S * t, x + S * 0.78, y + S * t) }
            }
            g.strokeCurrent(hex("#8c6c4d"), max(1.5, S * 0.045))
            g.beginPath()
            if horiz { g.line(x, y + S * 0.35, x + S, y + S * 0.35); g.line(x, y + S * 0.65, x + S, y + S * 0.65) }
            else { g.line(x + S * 0.35, y, x + S * 0.35, y + S); g.line(x + S * 0.65, y, x + S * 0.65, y + S) }
            g.strokeCurrent(hex("#6f777e"), max(1, S * 0.035))
        case "porch":
            g.dot(x + S * 0.7, y + S * 0.36, S * 0.09, hex("#7f5a3d")); g.dot(x + S * 0.7, y + S * 0.36, S * 0.055, hex("#9c7452"))
            g.dot(x + S * 0.32, y + S * 0.62, S * 0.08, hex("#7f5a3d"))
        case "orchard":
            for (tx, ty) in [(0.3, 0.32), (0.7, 0.32), (0.3, 0.72), (0.7, 0.72)] as [(CGFloat, CGFloat)] {
                LandArt.tree(g, x + S * tx, y + S * ty, S * 0.15, h(Double(tx * 10 + ty)))
            }
        case "vines":
            for k in 0..<3 {
                let t = 0.22 + CGFloat(k) * 0.28
                g.beginPath()
                if horiz { g.rounded(x + S * 0.06, y + S * (t - 0.06), S * 0.88, S * 0.12, S * 0.06) } else { g.rounded(x + S * (t - 0.06), y + S * 0.06, S * 0.12, S * 0.88, S * 0.06) }
                g.fillCurrent(hex("#6e9b4c"))
                for q in 0..<3 {
                    let u = 0.2 + CGFloat(q) * 0.3
                    g.dot(horiz ? x + S * u : x + S * t, horiz ? y + S * t : y + S * u, S * 0.035, hex("#7b4a8c"))
                }
            }
        case "wheel":
            g.beginPath(); g.rounded(x + S * 0.1, y + S * 0.64, S * 0.8, S * 0.2, S * 0.08); g.fillCurrent(hex("#62abc9"))
            g.beginPath(); g.addEllipse(in: CGRect(x: cx - S * 0.26, y: cy - S * 0.05 - S * 0.26, width: S * 0.52, height: S * 0.52))
            g.strokeCurrent(hex("#7a5634"), max(1.5, S * 0.05))
            g.beginPath()
            for k in 0..<4 {
                let a = CGFloat(k) * .pi / 4
                g.line(cx - cos(a) * S * 0.26, cy - S * 0.05 - sin(a) * S * 0.26, cx + cos(a) * S * 0.26, cy - S * 0.05 + sin(a) * S * 0.26)
            }
            g.strokeCurrent(hex("#7a5634"), max(1, S * 0.03))
        case "windmill":
            g.dot(cx + S * 0.03, cy + S * 0.05, S * 0.2, shadow)
            g.dot(cx, cy, S * 0.19, hex("#ece5d4")); g.dot(cx, cy, S * 0.12, hex("#b9ab94"))
            g.saveGState(); g.translateBy(x: cx, y: cy); g.rotate(by: .pi / 5)
            for _ in 0..<4 {
                g.rotate(by: .pi / 2)
                g.box(-S * 0.02, 0, S * 0.04, S * 0.4, hex("#8a6444"))
                g.box(S * 0.02, S * 0.12, S * 0.08, S * 0.26, hex("#f7f2e6"))
            }
            g.restoreGState()
            g.dot(cx, cy, S * 0.045, hex("#5b4a3c"))
        case "kiln":
            g.oval(cx + S * 0.03, cy + S * 0.06, S * 0.3, S * 0.26, rgba(40, 30, 20, 0.22))
            g.dot(cx, cy, S * 0.29, hex("#9c7f66")); g.dot(cx - S * 0.06, cy - S * 0.07, S * 0.17, hex("#b39479"))
            g.beginPath(); g.arcPoints(cx, cy + S * 0.13, S * 0.1, S * 0.07, .pi, .pi * 2); g.closePath(); g.fillCurrent(hex("#2f2622"))
            g.dot(cx, cy + S * 0.1, S * 0.03, hex("#e0743a"))
            smoke?(P(cx, cy - S * 0.22), true)
        case "sluice":
            let w = S * 0.3
            g.beginPath()
            if horiz { g.rounded(x, cy - w / 2, S, w, S * 0.04) } else { g.rounded(cx - w / 2, y, w, S, S * 0.04) }
            g.fillCurrent(hex("#9a7350"))
            if horiz { g.box(x, cy - w * 0.28, S, w * 0.56, hex("#6fb4cf")) } else { g.box(cx - w * 0.28, y, w * 0.56, S, hex("#6fb4cf")) }
            for k in 0..<3 {
                let t = 0.2 + CGFloat(k) * 0.3
                if horiz { g.box(x + S * t, cy - w * 0.28, S * 0.03, w * 0.56, rgba(60, 40, 25, 0.55)) } else { g.box(cx - w * 0.28, y + S * t, w * 0.56, S * 0.03, rgba(60, 40, 25, 0.55)) }
            }
            g.dot(horiz ? x + S * 0.3 : x + S * 0.8, horiz ? y + S * 0.8 : y + S * 0.3, S * 0.07, hex("#958d82"))
            g.dot(horiz ? x + S * 0.66 : x + S * 0.2, horiz ? y + S * 0.2 : y + S * 0.68, S * 0.035, hex("#f2cf63"))
        case "deck":
            g.beginPath()
            for k in 1..<6 {
                let t = CGFloat(k) / 6
                if horiz { g.line(x + S * t, y + S * 0.14, x + S * t, y + S * 0.86) } else { g.line(x + S * 0.14, y + S * t, x + S * 0.86, y + S * t) }
            }
            g.strokeCurrent(hex("#a57b52"), max(1, S * 0.025))
            g.beginPath()
            if horiz { g.line(x, y + S * 0.16, x + S, y + S * 0.16); g.line(x, y + S * 0.84, x + S, y + S * 0.84) }
            else { g.line(x + S * 0.16, y, x + S * 0.16, y + S); g.line(x + S * 0.84, y, x + S * 0.84, y + S) }
            g.strokeCurrent(hex("#6e4c2e"), max(1.5, S * 0.05))
        case "hay":
            for (hx, hy) in [(0.32, 0.36), (0.66, 0.44), (0.42, 0.7)] as [(CGFloat, CGFloat)] {
                g.dot(x + S * hx + S * 0.02, y + S * hy + S * 0.04, S * 0.12, shadow)
                g.dot(x + S * hx, y + S * hy, S * 0.12, hex("#e2c15c"))
                g.beginPath(); g.arcPoints(x + S * hx, y + S * hy, S * 0.06, S * 0.06, 0, .pi * 1.5)
                g.strokeCurrent(hex("#c29d3f"), max(1, S * 0.02))
            }
        case "graves":
            for (gx, gy) in [(0.3, 0.32), (0.66, 0.3), (0.34, 0.68), (0.7, 0.66)] as [(CGFloat, CGFloat)] {
                let px = x + S * gx, py = y + S * gy
                g.box(px - S * 0.04, py - S * 0.04, S * 0.12, S * 0.15, shadow)
                g.beginPath(); g.rounded(px - S * 0.06, py - S * 0.08, S * 0.12, S * 0.15, S * 0.05); g.fillCurrent(hex("#cfcac1"))
            }
            g.dot(x + S * 0.5, y + S * 0.5, S * 0.03, hex("#f2a4b3"))
        case "pool":
            g.beginPath(); g.rounded(x + S * 0.16, y + S * 0.16, S * 0.68, S * 0.68, S * 0.14); g.fillCurrent(hex("#7cc3d8"))
            g.beginPath(); g.line(x + S * 0.3, y + S * 0.42, x + S * 0.5, y + S * 0.42); g.line(x + S * 0.45, y + S * 0.6, x + S * 0.68, y + S * 0.6)
            g.strokeCurrent(rgba(255, 255, 255, 0.6), max(1, S * 0.025))
        case "tent":
            g.dot(cx + S * 0.03, cy + S * 0.05, S * 0.3, shadow)
            let stripe = hex(h(4) > 0.5 ? "#d65a45" : "#3f79b5")
            for k in 0..<8 {
                g.beginPath(); g.move(to: P(cx, cy))
                g.arcPoints(cx, cy, S * 0.3, S * 0.3, CGFloat(k) * .pi / 4, CGFloat(k + 1) * .pi / 4, join: true)
                g.closePath(); g.fillCurrent(k % 2 == 1 ? hex("#f7f2e6") : stripe)
            }
            g.dot(cx, cy, S * 0.05, hex("#e3a92f"))
        case "pasture" where h(11) > 0.35:
            let px = x + S * (0.3 + 0.35 * h(12)), py = y + S * (0.35 + 0.3 * h(13))
            g.oval(px + S * 0.03, py + S * 0.05, S * 0.14, S * 0.08, rgba(40, 50, 30, 0.2))
            g.oval(px, py, S * 0.14, S * 0.08, hex("#f7f3ea"))
            g.dot(px + S * 0.15, py, S * 0.05, hex("#5a4a3e"))
            g.dot(px - S * 0.03, py - S * 0.02, S * 0.035, hex("#5a4a3e"))
        default:
            break
        }
    }
}
