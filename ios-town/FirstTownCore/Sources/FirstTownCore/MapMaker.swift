/// Builds the land for a seed: water first, then patches of woods, ore, wild wheat and herds.
public enum MapMaker {
    public static func make(seed: Int32) -> [Terrain] {
        var r = Mulberry32(seed: seed)
        var t = [Terrain](repeating: .grass, count: Board.count)
        let cols = Board.cols, rows = Board.rows

        let style = r.next()
        if style < 0.5 {
            // A river from the top edge to the bottom edge that wanders as it goes.
            var x = r.int(2, cols - 3)
            for y in 0..<rows {
                t[Board.index(x, y)] = .water
                if y > 0 && y < rows - 1 && r.next() < 0.3 {
                    x = clamp(x + (r.next() < 0.5 ? -1 : 1), 1, cols - 2)
                    t[Board.index(x, y)] = .water
                }
            }
        } else if style < 0.8 {
            // A lake on one side, with a creek that runs out across the map.
            let left = r.next() < 0.5
            let ly = r.int(3, rows - 4)
            let size = r.int(6, 8)
            grow(&t, &r, Board.index(left ? 0 : cols - 1, ly), size, .water)
            var y = ly + (r.next() < 0.5 ? -2 : 2)
            for s in 0..<cols {
                let x = left ? s : cols - 1 - s
                t[Board.index(x, y)] = .water
                if s > 1 && s < cols - 1 && r.next() < 0.3 {
                    y = clamp(y + (r.next() < 0.5 ? -1 : 1), 1, rows - 2)
                    t[Board.index(x, y)] = .water
                }
            }
        } else {
            // Two ponds.
            let ax = r.int(1, 3), ay = r.int(1, 4), asize = r.int(4, 6)
            grow(&t, &r, Board.index(ax, ay), asize, .water)
            let bx = r.int(5, 7), by = r.int(7, 10), bsize = r.int(4, 6)
            grow(&t, &r, Board.index(bx, by), bsize, .water)
        }

        // Each patch picks its start, then its size, then grows: the order the web version draws in.
        func patch(_ kind: Terrain, nearWater: Bool = false, _ size: (inout Mulberry32) -> Int) {
            let start = spot(t, &r, nearWater: nearWater)
            let n = size(&r)
            grow(&t, &r, start, n, kind)
        }
        patch(.forest) { $0.int(5, 7) }
        patch(.forest) { $0.int(3, 5) }
        patch(.ore) { _ in 3 }
        patch(.ore) { _ in 2 }
        patch(.wheat, nearWater: true) { $0.int(4, 5) }
        patch(.wheat) { $0.int(3, 4) }
        patch(.herd) { $0.int(3, 4) }
        if r.next() < 0.6 { patch(.herd) { $0.int(2, 3) } }
        return t
    }

    /// A random open square, preferring one beside water when asked. -1 when none turns up.
    static func spot(_ t: [Terrain], _ r: inout Mulberry32, nearWater: Bool) -> Int {
        for tries in 0..<50 {
            let i = Int((r.next() * Double(Board.count)).rounded(.down))
            if t[i] != .grass { continue }
            if nearWater && tries < 35 && !Board.around(i).contains(where: { t[$0] == .water }) { continue }
            return i
        }
        return -1
    }

    /// A blob that prefers to grow into squares that already touch it, so patches come out chunky.
    @discardableResult
    static func grow(_ t: inout [Terrain], _ r: inout Mulberry32, _ start: Int, _ size: Int, _ kind: Terrain) -> Int {
        guard start >= 0, t[start] == .grass else { return 0 }
        var got = [start]
        t[start] = kind
        for _ in 0..<60 {
            guard got.count < size else { break }
            var candidates: [(square: Int, weight: Int)] = []
            for c in got {
                for j in Board.around(c) where t[j] == .grass {
                    let touching = Board.around(j).filter { t[$0] == kind }.count
                    candidates.append((j, 1 + touching * touching))
                }
            }
            if candidates.isEmpty { break }
            var s = r.next() * Double(candidates.reduce(0) { $0 + $1.weight })
            for (j, w) in candidates {
                s -= Double(w)
                if s <= 0 {
                    t[j] = kind
                    got.append(j)
                    break
                }
            }
        }
        return got.count
    }
}
