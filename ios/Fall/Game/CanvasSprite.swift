import SpriteKit

/// A sprite that lives in the flipped canvas layer. The `yScale = -1` cancels
/// the layer's flip so textures arrive the right way up; see `GameScene`.
///
/// Positioning follows canvas habits: `place(x:y:w:h:)` takes a top-left corner
/// and a size, the way `fillRect` does.
final class CanvasSprite: SKSpriteNode {

    convenience init(color: SKColor, size: CGSize) {
        self.init(texture: nil, color: color, size: size)
        unflip()
    }

    convenience init(texture: SKTexture?, size: CGSize) {
        self.init(texture: texture, color: .white, size: size)
        unflip()
    }

    /// A tinted copy of a greyscale texture, used for dust and round blocks.
    convenience init(texture: SKTexture?, tint: SKColor, size: CGSize) {
        self.init(texture: texture, color: tint, size: size)
        colorBlendFactor = 1
        unflip()
    }

    private func unflip() { yScale = -1 }

    /// Top-left placement, matching `ctx.fillRect(x, y, w, h)`.
    func place(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
        size = CGSize(width: w, height: h)
        position = CGPoint(x: x + w / 2, y: y + h / 2)
    }

    /// Centre placement, for things the original drew around a midpoint.
    func centre(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
        size = CGSize(width: w, height: h)
        position = CGPoint(x: x, y: y)
    }
}

/// Textures built once and shared. Nothing here is loaded from disk — the whole
/// point of the original was that it shipped as one file with no assets.
enum Textures {
    /// A soft-edged white disc, tinted at the call site.
    static let disc: SKTexture = {
        let side = 64
        let image = UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { ctx in
            ctx.cgContext.setFillColor(UIColor.white.cgColor)
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: side, height: side))
        }
        let t = SKTexture(image: image)
        t.filteringMode = .linear
        return t
    }()

    /// A vertical gradient, stretched to fill a background.
    /// `stops` are `(position 0...1, colour)` in the order the CSS listed them.
    static func verticalGradient(_ stops: [(CGFloat, UIColor)], height: Int = 256) -> SKTexture {
        let size = CGSize(width: 1, height: height)
        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            let colours = stops.map { $0.1.cgColor } as CFArray
            let locations = stops.map { $0.0 }
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colours,
                locations: locations
            ) else { return }
            // UIKit's image context already runs y-down, so stop 0 lands at the top.
            ctx.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: size.height),
                options: []
            )
        }
        let t = SKTexture(image: image)
        t.filteringMode = .linear
        return t
    }

    /// Rasterises a small piece of canvas drawing into a texture, for art that
    /// is fixed once the size is known. `draw` runs in a y-down context whose
    /// origin sits at the centre, matching a `translate` then draw in the web code.
    static func centred(side: CGFloat, _ draw: (CGContext, CGFloat) -> Void) -> SKTexture {
        let px = max(8, side)
        let image = UIGraphicsImageRenderer(size: CGSize(width: px, height: px)).image { ctx in
            let g = ctx.cgContext
            g.translateBy(x: px / 2, y: px / 2)
            draw(g, px / 2)
        }
        let t = SKTexture(image: image)
        t.filteringMode = .linear
        return t
    }
}

extension CGContext {
    /// `ctx.fillStyle = c; ctx.fillRect(...)` in one call.
    func fill(_ rect: CGRect, _ colour: UIColor) {
        setFillColor(colour.cgColor)
        fill(rect)
    }

    /// `ctx.beginPath(); ctx.arc(...); ctx.fill()`.
    func fillCircle(x: CGFloat, y: CGFloat, r: CGFloat, _ colour: UIColor) {
        setFillColor(colour.cgColor)
        fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
    }

    /// A closed polygon through the given points.
    func fillPolygon(_ points: [CGPoint], _ colour: UIColor) {
        guard let first = points.first else { return }
        setFillColor(colour.cgColor)
        beginPath()
        move(to: first)
        points.dropFirst().forEach { addLine(to: $0) }
        closePath()
        fillPath()
    }
}
