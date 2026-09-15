import SwiftUI
import FirstTownCore

/// A building's footprint as small rounded squares in its category's colour.
struct ShapeIcon: View {
    let type: String
    var rot = 0
    var flip = false
    var box: CGFloat = 34

    var body: some View {
        let offsets = Shapes.orient(Library[type].shape, rot: rot, flip: flip)
        let (w, h) = Shapes.extent(offsets)
        let s = floor(box / CGFloat(max(w, h, 3))), gap = max(1, s * 0.12)
        let colour = Palette.category(Library[type].category)
        Canvas { ctx, _ in
            for o in offsets {
                let rect = CGRect(x: CGFloat(o.x) * s + gap / 2, y: CGFloat(o.y) * s + gap / 2, width: s - gap, height: s - gap)
                ctx.fill(Path(roundedRect: rect, cornerRadius: s * 0.22), with: .color(colour))
            }
        }
        .frame(width: CGFloat(w) * s, height: CGFloat(h) * s)
    }
}
