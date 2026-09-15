import UIKit
import FirstTownCore

/// A colour from "#rrggbb".
func hex(_ s: String, _ alpha: CGFloat = 1) -> CGColor {
    let v = UInt32(s.dropFirst(), radix: 16) ?? 0
    return CGColor(srgbRed: CGFloat(v >> 16 & 255) / 255, green: CGFloat(v >> 8 & 255) / 255, blue: CGFloat(v & 255) / 255, alpha: alpha)
}

/// A colour from 0...255 channels, the way the web version wrote `rgba(...)`.
func rgba(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat) -> CGColor {
    CGColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: a)
}

/// Towards white for `f` above 0, towards black below.
func shade(_ s: String, _ f: CGFloat) -> CGColor {
    let v = UInt32(s.dropFirst(), radix: 16) ?? 0
    func ch(_ c: UInt32) -> CGFloat {
        let c = CGFloat(c)
        return (f < 0 ? c * (1 + f) : c + (255 - c) * f).rounded() / 255
    }
    return CGColor(srgbRed: ch(v >> 16 & 255), green: ch(v >> 8 & 255), blue: ch(v & 255), alpha: 1)
}

/// A fixed hash for art, so a square draws the same way every frame.
func artHash(_ a: Double, _ b: Double) -> CGFloat {
    let s = sin(a * 127.1 + b * 311.7) * 43758.5453
    return CGFloat(s - floor(s))
}

func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

/// Chimneys report where they are while the board is drawn, so smoke can rise from them.
typealias SmokeSink = (CGPoint, Bool) -> Void

/// Where the board sits in its view, and how big a square is. The same sums as the web version's `layout`.
struct BoardLayout: Equatable {
    let size: CGSize
    let S: CGFloat
    let BX: CGFloat
    let BY: CGFloat

    init(size: CGSize) {
        let pad: CGFloat = 6, frame: CGFloat = 0.24
        self.size = size
        S = max(16, floor(min((size.width - pad * 2) / (CGFloat(Board.cols) + frame * 2),
                              (size.height - pad * 2) / (CGFloat(Board.rows) + frame * 2))))
        BX = ((size.width - CGFloat(Board.cols) * S) / 2).rounded()
        BY = ((size.height - CGFloat(Board.rows) * S) / 2).rounded()
    }

    var W: CGFloat { CGFloat(Board.cols) * S }
    var H: CGFloat { CGFloat(Board.rows) * S }
    func cellX(_ i: Int) -> CGFloat { BX + CGFloat(Board.col(i)) * S }
    func cellY(_ i: Int) -> CGFloat { BY + CGFloat(Board.row(i)) * S }

    /// A point in squares, with fractions.
    func squares(_ p: CGPoint) -> (x: CGFloat, y: CGFloat) { ((p.x - BX) / S, (p.y - BY) / S) }

    /// The square under a point in squares, or -1 off the map.
    func square(_ fx: CGFloat, _ fy: CGFloat) -> Int {
        let x = Int(floor(fx)), y = Int(floor(fy))
        return Board.inside(x, y) ? Board.index(x, y) : -1
    }

    /// The middle of a group of squares.
    func centre(of cells: [Int]) -> CGPoint {
        let n = CGFloat(max(1, cells.count))
        return P(cells.reduce(0) { $0 + cellX($1) } / n + S / 2, cells.reduce(0) { $0 + cellY($1) } / n + S / 2)
    }
}

extension CGContext {
    /// Adds a rounded rectangle, drawn in the same direction as `addRect`, so the two fill together as one shape.
    func rounded(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ radius: CGFloat) {
        let r = max(0, min(radius, w / 2, h / 2))
        move(to: P(x + r, y))
        addArc(tangent1End: P(x + w, y), tangent2End: P(x + w, y + h), radius: r)
        addArc(tangent1End: P(x + w, y + h), tangent2End: P(x, y + h), radius: r)
        addArc(tangent1End: P(x, y + h), tangent2End: P(x, y), radius: r)
        addArc(tangent1End: P(x, y), tangent2End: P(x + w, y), radius: r)
        closePath()
    }

    func dot(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ c: CGColor) {
        setFillColor(c)
        fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
    }

    func oval(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ c: CGColor) {
        setFillColor(c)
        fillEllipse(in: CGRect(x: x - rx, y: y - ry, width: rx * 2, height: ry * 2))
    }

    func box(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: CGColor) {
        setFillColor(c)
        fill(CGRect(x: x, y: y, width: w, height: h))
    }

    func line(_ x0: CGFloat, _ y0: CGFloat, _ x1: CGFloat, _ y1: CGFloat) {
        move(to: P(x0, y0))
        addLine(to: P(x1, y1))
    }

    func fillCurrent(_ c: CGColor) {
        setFillColor(c)
        fillPath()
    }

    func strokeCurrent(_ c: CGColor, _ width: CGFloat) {
        setStrokeColor(c)
        setLineWidth(width)
        strokePath()
    }

    /// Points along an arc, with angles growing clockwise on screen, the way canvas draws them.
    /// Starts a new subpath unless `join` is set, in which case it runs on from the current point.
    func arcPoints(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ a0: CGFloat, _ a1: CGFloat, join: Bool = false) {
        let steps = 18
        for k in 0...steps {
            let a = a0 + (a1 - a0) * CGFloat(k) / CGFloat(steps)
            let p = P(cx + cos(a) * rx, cy + sin(a) * ry)
            if k == 0 && !join { move(to: p) } else { addLine(to: p) }
        }
    }

    /// One path for a group of squares, as if cut from one sheet: rounded outside corners,
    /// with bridges across the gaps between squares that belong together.
    func addUnion(_ cells: [Int], _ L: BoardLayout, inset: CGFloat, radius r: CGFloat, dy: CGFloat = 0) {
        let set = Set(cells), S = L.S, span = inset * 2 + r * 2
        for i in cells {
            let x = L.cellX(i), y = L.cellY(i) + dy
            let right = Board.col(i) < Board.cols - 1 && set.contains(i + 1), down = set.contains(i + Board.cols)
            rounded(x + inset, y + inset, S - inset * 2, S - inset * 2, r)
            if right { addRect(CGRect(x: x + S - inset - r, y: y + inset, width: span, height: S - inset * 2)) }
            if down { addRect(CGRect(x: x + inset, y: y + S - inset - r, width: S - inset * 2, height: span)) }
            if right && down && set.contains(i + Board.cols + 1) {
                addRect(CGRect(x: x + S - inset - r, y: y + S - inset - r, width: span, height: span))
            }
        }
    }

    /// Text centred on a point.
    func centredText(_ s: String, _ x: CGFloat, _ y: CGFloat, size: CGFloat, color: CGColor) {
        UIGraphicsPushContext(self)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: size, weight: .heavy),
            .foregroundColor: UIColor(cgColor: color),
        ]
        let text = s as NSString, measure = text.size(withAttributes: attrs)
        text.draw(at: P(x - measure.width / 2, y - measure.height / 2), withAttributes: attrs)
        UIGraphicsPopContext()
    }
}
