import SwiftUI
import FirstTownCore

/// The map. Drag to move the building in hand, tap it to see its scoring, tap any square to learn about it.
struct BoardView: View {
    let town: Town
    @State private var renderer = BoardRenderer()
    @State private var press: Press?
    @Environment(\.displayScale) private var scale

    private struct Press {
        var here: Int
        var onGhost: Bool
        /// Where the finger sits on the building, in squares from its top-left corner.
        var gx: CGFloat
        var gy: CGFloat
        var moved = false
    }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 60)) { timeline in
                Canvas { ctx, size in
                    renderer.draw(&ctx, size: size, now: timeline.date.timeIntervalSinceReferenceDate, town: town, scale: scale)
                }
            }
            .contentShape(Rectangle())
            .gesture(drag(BoardLayout(size: geo.size)))
        }
    }

    private func drag(_ L: BoardLayout) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                if press == nil {
                    let f = L.squares(v.startLocation)
                    let here = L.square(f.x, f.y)
                    // The building floats a little above its squares, so a press just below it still grabs it.
                    let lifted = L.square(f.x, f.y + 0.25)
                    let cells = town.ghostCells ?? []
                    press = Press(here: here, onGhost: cells.contains(here) || cells.contains(lifted),
                                  gx: f.x - CGFloat(town.ghost?.ax ?? 0), gy: f.y - CGFloat(town.ghost?.ay ?? 0))
                }
                guard var p = press, let g = town.ghost, let type = town.game.current else { return }
                if !p.moved && hypot(v.translation.width, v.translation.height) < 7 { return }
                p.moved = true
                press = p
                if !town.dragging { town.dragging = true }
                let f = L.squares(v.location)
                let (w, h) = Shapes.extent(Shapes.orient(Library[type].shape, rot: g.rot, flip: g.flip))
                let ax: Int, ay: Int
                if p.onGhost {
                    ax = Int((f.x - p.gx).rounded()); ay = Int((f.y - p.gy).rounded())
                } else {
                    // A finger hides what is under it, so a drag from elsewhere holds the building above the finger.
                    ax = Int((f.x - CGFloat(w) / 2).rounded()); ay = Int((f.y - 1.3 - CGFloat(h) / 2).rounded())
                }
                town.place(Placement(rot: g.rot, flip: g.flip, ax: ax, ay: ay))
            }
            .onEnded { _ in
                defer { press = nil; if town.dragging { town.dragging = false } }
                guard let p = press, !p.moved else { return }
                if p.onGhost && !town.game.over { town.toggleRules() }
                else if p.here < 0 || p.here == town.selection { town.closeInfo() }
                else { town.select(p.here) }
            }
    }
}
