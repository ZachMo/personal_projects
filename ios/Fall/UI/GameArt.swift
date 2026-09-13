import SwiftUI

/// The four card tiles. They were inline SVG on a 40 x 40 box; this draws the
/// same shapes on the same box and scales it to whatever the card asks for.
struct GameArt: View {
    let id: GameID
    var side: CGFloat = 66

    var body: some View {
        Canvas { ctx, size in
            let k = size.width / 40                     // the SVG viewBox
            ctx.scaleBy(x: k, y: k)
            switch id {
            case .dino: Self.dino(&ctx)
            case .fish: Self.fish(&ctx)
            case .ski:  Self.ski(&ctx)
            case .golf: Self.golf(&ctx)
            }
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: side * 14 / 40, style: .continuous))
    }

    // MARK: - Tiles

    private static func dino(_ ctx: inout GraphicsContext) {
        fillAll(&ctx, 0x7A4A55)
        rect(&ctx, 8, 6, 6, 6, 0x15151A)
        rect(&ctx, 24, 4, 5, 10, 0x15151A)
        // The falling shield, tipped on its corner.
        var diamond = Path(CGRect(x: 17, y: 12, width: 4, height: 4))
        diamond = diamond.applying(
            CGAffineTransform(translationX: 19, y: 14)
                .rotated(by: .pi / 4)
                .translatedBy(x: -19, y: -14)
        )
        ctx.fill(diamond, with: .color(Color(hex: 0xD76B5B)))
        path(&ctx, 0x15151A) { p in
            p.move(to: CGPoint(x: 20, y: 33))
            p.addLine(to: CGPoint(x: 29, y: 33))
            p.addLine(to: CGPoint(x: 29, y: 27))
            p.addLine(to: CGPoint(x: 25, y: 27))
            p.addLine(to: CGPoint(x: 25, y: 23))
            p.addLine(to: CGPoint(x: 22, y: 23))
            p.addLine(to: CGPoint(x: 22, y: 27))
            p.addLine(to: CGPoint(x: 18, y: 27))
            p.addLine(to: CGPoint(x: 18, y: 30))
            p.addLine(to: CGPoint(x: 20, y: 30))
            p.closeSubpath()
        }
        rect(&ctx, 4, 33, 32, 3, 0x3A2430)
    }

    private static func fish(_ ctx: inout GraphicsContext) {
        fillAll(&ctx, 0x0D4A75)
        rect(&ctx, 0, 0, 40, 11, 0x2FA3D8)
        path(&ctx, 0x0D1219) { p in
            p.move(to: CGPoint(x: 17, y: 4))
            p.addLine(to: CGPoint(x: 25, y: 4))
            p.addLine(to: CGPoint(x: 23, y: 8))
            p.addLine(to: CGPoint(x: 17, y: 8))
            p.closeSubpath()
        }
        var line = Path()
        line.move(to: CGPoint(x: 21, y: 8))
        line.addLine(to: CGPoint(x: 21, y: 21))
        ctx.stroke(line, with: .color(Color(hex: 0xDBE9F6)), lineWidth: 1.1)
        ctx.fill(
            Path(ellipseIn: CGRect(x: 10, y: 24.6, width: 14, height: 6.8)),
            with: .color(Color(hex: 0x0D1219))
        )
        path(&ctx, 0x1B2532) { p in
            p.move(to: CGPoint(x: 10, y: 28))
            p.addLine(to: CGPoint(x: 6, y: 24.6))
            p.addLine(to: CGPoint(x: 6, y: 31.4))
            p.closeSubpath()
        }
        circle(&ctx, 21, 27, 1.2, 0xDBE9F6)
    }

    private static func ski(_ ctx: inout GraphicsContext) {
        fillAll(&ctx, 0xDCE9F5)
        rect(&ctx, 0, 0, 40, 13, 0xA7C6DE)
        path(&ctx, 0xC3D8EA) { p in                 // the ridge line
            p.move(to: CGPoint(x: 0, y: 13))
            p.addLine(to: CGPoint(x: 9, y: 6))
            p.addLine(to: CGPoint(x: 16, y: 11))
            p.addLine(to: CGPoint(x: 24, y: 5))
            p.addLine(to: CGPoint(x: 33, y: 13))
            p.closeSubpath()
        }
        triangle(&ctx, 6, 34, 11, 21, 16, 34, 0x1D3524)
        triangle(&ctx, 29, 33, 33, 22, 37, 33, 0x1D3524)
        path(&ctx, 0x16232E) { p in
            p.move(to: CGPoint(x: 20, y: 22))
            p.addLine(to: CGPoint(x: 23, y: 22))
            p.addLine(to: CGPoint(x: 24, y: 30))
            p.addLine(to: CGPoint(x: 19, y: 30))
            p.closeSubpath()
        }
        circle(&ctx, 21.5, 19, 2.4, 0xE8452F)
        var skis = Path()
        skis.move(to: CGPoint(x: 18, y: 30)); skis.addLine(to: CGPoint(x: 17, y: 37))
        skis.move(to: CGPoint(x: 25, y: 30)); skis.addLine(to: CGPoint(x: 26, y: 37))
        ctx.stroke(skis, with: .color(Color(hex: 0x16232E)), lineWidth: 1.6)
    }

    private static func golf(_ ctx: inout GraphicsContext) {
        fillAll(&ctx, 0x8FC3E8)
        path(&ctx, 0x6DA851) { p in                 // the green, in plan
            p.move(to: CGPoint(x: 20, y: 15))
            p.addLine(to: CGPoint(x: 34, y: 22))
            p.addLine(to: CGPoint(x: 20, y: 29))
            p.addLine(to: CGPoint(x: 6, y: 22))
            p.closeSubpath()
        }
        path(&ctx, 0x4A7D3C) { p in
            p.move(to: CGPoint(x: 6, y: 22))
            p.addLine(to: CGPoint(x: 6, y: 26))
            p.addLine(to: CGPoint(x: 20, y: 33))
            p.addLine(to: CGPoint(x: 20, y: 29))
            p.closeSubpath()
        }
        path(&ctx, 0x3D6B32) { p in
            p.move(to: CGPoint(x: 34, y: 22))
            p.addLine(to: CGPoint(x: 34, y: 26))
            p.addLine(to: CGPoint(x: 20, y: 33))
            p.addLine(to: CGPoint(x: 20, y: 29))
            p.closeSubpath()
        }
        var pin = Path()
        pin.move(to: CGPoint(x: 24, y: 12))
        pin.addLine(to: CGPoint(x: 24, y: 21))
        ctx.stroke(pin, with: .color(Color(hex: 0xF3F3EF)), lineWidth: 1.4)
        triangle(&ctx, 24, 12, 29, 13.6, 24, 15.4, 0xE8452F)
        circle(&ctx, 15, 23, 2.1, 0xFDFDF8)
    }

    // MARK: - Small drawing helpers

    private static func fillAll(_ ctx: inout GraphicsContext, _ hex: UInt32) {
        ctx.fill(Path(CGRect(x: 0, y: 0, width: 40, height: 40)), with: .color(Color(hex: hex)))
    }

    private static func rect(_ ctx: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat,
                             _ w: CGFloat, _ h: CGFloat, _ hex: UInt32) {
        ctx.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(Color(hex: hex)))
    }

    private static func circle(_ ctx: inout GraphicsContext, _ cx: CGFloat, _ cy: CGFloat,
                               _ r: CGFloat, _ hex: UInt32) {
        ctx.fill(
            Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)),
            with: .color(Color(hex: hex))
        )
    }

    private static func triangle(_ ctx: inout GraphicsContext,
                                 _ x1: CGFloat, _ y1: CGFloat,
                                 _ x2: CGFloat, _ y2: CGFloat,
                                 _ x3: CGFloat, _ y3: CGFloat, _ hex: UInt32) {
        path(&ctx, hex) { p in
            p.move(to: CGPoint(x: x1, y: y1))
            p.addLine(to: CGPoint(x: x2, y: y2))
            p.addLine(to: CGPoint(x: x3, y: y3))
            p.closeSubpath()
        }
    }

    private static func path(_ ctx: inout GraphicsContext, _ hex: UInt32,
                             _ build: (inout Path) -> Void) {
        var p = Path()
        build(&p)
        ctx.fill(p, with: .color(Color(hex: hex)))
    }
}
