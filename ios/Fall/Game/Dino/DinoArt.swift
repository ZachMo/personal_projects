import SpriteKit

/// The dinosaur is a list of rectangles on a 24 x 26 grid, as it was in the
/// margin of the page it started in.
enum DinoArt {
    /// x, y, w, h
    static let body: [[CGFloat]] = [
        [12, 0, 11, 8], [12, 8, 8, 9], [8, 9, 4, 7], [4, 8, 4, 5], [0, 6, 4, 4], [20, 10, 3, 2],
    ]
    static let legsA: [[CGFloat]] = [[10, 16, 3, 8], [10, 23, 5, 3]]
    static let legsB: [[CGFloat]] = [[15, 16, 3, 8], [15, 23, 5, 3]]

    static let ink = SKColor(hex: 0x15151A)
    static let eye = SKColor.white

    /// The grid the rectangles are measured against.
    static let gridHeight: CGFloat = 26
}

/// The four shapes that fall and are only blocks.
struct BlockShape {
    let kind: String
    let w: CGFloat
    let h: CGFloat

    static let all: [BlockShape] = [
        BlockShape(kind: "sq",   w: 0.58, h: 0.58),
        BlockShape(kind: "tall", w: 0.34, h: 1.00),
        BlockShape(kind: "wide", w: 1.00, h: 0.34),
        BlockShape(kind: "dot",  w: 0.52, h: 0.52),
    ]
}

/// The four things that fall and are not blocks — the only colour in the game
/// apart from the sky.
struct Pickup {
    enum Kind: String { case shield, mini, slow, bomb }

    let kind: Kind
    let colour: UIColor
    let weight: CGFloat
    let size: CGFloat

    static let all: [Pickup] = [
        Pickup(kind: .shield, colour: UIColor(hex: 0xD76B5B), weight: 34, size: 0.56),
        Pickup(kind: .mini,   colour: UIColor(hex: 0x6FBF73), weight: 26, size: 0.60),
        Pickup(kind: .slow,   colour: UIColor(hex: 0x5AA9D6), weight: 24, size: 0.56),
        Pickup(kind: .bomb,   colour: UIColor(hex: 0xE8B33C), weight: 16, size: 0.52),
    ]

    static func weighted() -> Pickup {
        let total = all.reduce(0) { $0 + $1.weight }
        var r = CGFloat.random(in: 0..<1) * total
        for p in all {
            r -= p.weight
            if r <= 0 { return p }
        }
        return all[0]
    }
}

// MARK: - Pickup textures

/// Each pickup is drawn once into a texture at the size the current screen wants,
/// then spun as a sprite. The drawing is a straight transcription of
/// `drawPickup`, in a y-down context centred on the middle of the image.
enum PickupArt {
    private static var cache: [String: SKTexture] = [:]

    /// The bomb's fuse reaches well above the body, so the image is given room.
    private static let boxScale: CGFloat = 2.2

    static func texture(_ pickup: Pickup, size: CGFloat) -> SKTexture {
        let key = "\(pickup.kind.rawValue)-\(Int(size.rounded()))"
        if let hit = cache[key] { return hit }
        let t = Textures.centred(side: size * boxScale) { g, _ in
            draw(pickup, size: size, into: g)
        }
        cache[key] = t
        return t
    }

    /// The size the sprite must be for the art inside to come out at `size`.
    static func boxSide(for size: CGFloat) -> CGFloat { size * boxScale }

    static func clearCache() { cache.removeAll() }

    private static func draw(_ pickup: Pickup, size: CGFloat, into g: CGContext) {
        let r = size / 2
        let col = pickup.colour

        switch pickup.kind {
        case .shield:
            g.fillPolygon([
                CGPoint(x: 0, y: -r), CGPoint(x: r, y: 0),
                CGPoint(x: 0, y: r),  CGPoint(x: -r, y: 0),
            ], col)
            g.fillPolygon([
                CGPoint(x: 0, y: -r), CGPoint(x: r / 2, y: -r / 3),
                CGPoint(x: 0, y: 0),  CGPoint(x: -r / 2, y: -r / 3),
            ], UIColor(white: 1, alpha: 0.5))

        case .slow:                                     // hourglass
            g.fillPolygon([
                CGPoint(x: -r * 0.7, y: -r), CGPoint(x: r * 0.7, y: -r),
                CGPoint(x: -r * 0.7, y: r),  CGPoint(x: r * 0.7, y: r),
            ], col)
            g.fill(CGRect(x: -r * 0.85, y: -r - r * 0.22, width: r * 1.7, height: r * 0.22), col)
            g.fill(CGRect(x: -r * 0.85, y: r, width: r * 1.7, height: r * 0.22), col)
            g.fillCircle(x: 0, y: r * 0.55, r: r * 0.14, UIColor(white: 1, alpha: 0.7))

        case .bomb:                                     // bomb and fuse
            g.fillCircle(x: 0, y: r * 0.18, r: r * 0.78, col)
            g.setStrokeColor(col.cgColor)
            g.setLineWidth(max(2, r * 0.24))
            g.setLineCap(.round)
            g.beginPath()
            g.move(to: CGPoint(x: r * 0.3, y: -r * 0.5))
            g.addQuadCurve(
                to: CGPoint(x: r * 0.6, y: -r * 1.25),
                control: CGPoint(x: r * 0.9, y: -r * 0.9)
            )
            g.strokePath()
            g.fillCircle(x: r * 0.6, y: -r * 1.3, r: r * 0.22, UIColor(hex: 0xFFF5E0))

        case .mini:                                     // a very small dinosaur
            let sc = size / DinoArt.gridHeight
            g.saveGState()
            g.translateBy(x: -12 * sc, y: -13 * sc)
            for q in DinoArt.body + DinoArt.legsA + DinoArt.legsB {
                g.fill(CGRect(x: q[0] * sc, y: q[1] * sc, width: q[2] * sc, height: q[3] * sc), col)
            }
            g.restoreGState()
        }
    }
}
