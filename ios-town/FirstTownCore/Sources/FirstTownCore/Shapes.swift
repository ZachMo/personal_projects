public struct Offset: Hashable, Sendable {
    public let x: Int
    public let y: Int
    public init(_ x: Int, _ y: Int) { self.x = x; self.y = y }
}

/// Footprints. The order of the squares matters: each building's roles line up with it,
/// and a bridge's first and last squares are its two ends.
public enum Shapes {
    public static let table: [String: [Offset]] = {
        let raw: [String: [(Int, Int)]] = [
            "I1": [(0, 0)],
            "I2": [(0, 0), (1, 0)],
            "I3": [(0, 0), (1, 0), (2, 0)],
            "V3": [(0, 0), (0, 1), (1, 1)],
            "I4": [(0, 0), (1, 0), (2, 0), (3, 0)],
            "O4": [(0, 0), (1, 0), (0, 1), (1, 1)],
            "T4": [(0, 0), (1, 0), (2, 0), (1, 1)],
            "S4": [(1, 0), (2, 0), (0, 1), (1, 1)],
            "L4": [(0, 0), (0, 1), (0, 2), (1, 2)],
            "I5": [(0, 0), (1, 0), (2, 0), (3, 0), (4, 0)],
            "V5": [(0, 0), (0, 1), (0, 2), (1, 2), (2, 2)],
            "X5": [(1, 0), (0, 1), (1, 1), (2, 1), (1, 2)],
            "T5": [(0, 0), (1, 0), (2, 0), (1, 1), (1, 2)],
            "P5": [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)],
            "U5": [(0, 0), (2, 0), (0, 1), (1, 1), (2, 1)],
            "L5": [(0, 0), (0, 1), (0, 2), (0, 3), (1, 3)],
            "N5": [(0, 0), (1, 0), (2, 0), (2, 1), (3, 1)],
            "Y5": [(0, 0), (1, 0), (2, 0), (3, 0), (1, 1)],
            "W5": [(0, 0), (0, 1), (1, 1), (1, 2), (2, 2)],
            "Z5": [(0, 0), (1, 0), (1, 1), (1, 2), (2, 2)],
            "F5": [(1, 0), (2, 0), (0, 1), (1, 1), (1, 2)],
            "R6": [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2), (1, 2)],
        ]
        return raw.mapValues { $0.map { Offset($0.0, $0.1) } }
    }()

    /// A shape flipped, then turned a quarter at a time, then moved so its top-left is at 0,0.
    public static func orient(_ shape: String, rot: Int, flip: Bool) -> [Offset] {
        var s = table[shape]!
        if flip { s = s.map { Offset(-$0.x, $0.y) } }
        for _ in 0..<(((rot % 4) + 4) % 4) { s = s.map { Offset(-$0.y, $0.x) } }
        let mx = s.map(\.x).min()!, my = s.map(\.y).min()!
        return s.map { Offset($0.x - mx, $0.y - my) }
    }

    /// Width and height in squares.
    public static func extent(_ offsets: [Offset]) -> (w: Int, h: Int) {
        (offsets.map(\.x).max()! + 1, offsets.map(\.y).max()! + 1)
    }
}

/// Where a building sits: how it is turned and flipped, and the square its top-left corner is on.
public struct Placement: Hashable, Sendable, Codable {
    public var rot: Int
    public var flip: Bool
    public var ax: Int
    public var ay: Int

    public init(rot: Int, flip: Bool, ax: Int, ay: Int) {
        self.rot = rot; self.flip = flip; self.ax = ax; self.ay = ay
    }
}

/// A placement and the squares it covers.
public struct Option: Hashable, Sendable {
    public let placement: Placement
    public let cells: [Int]
}

public enum Placements {
    /// Every distinct way to turn and flip a building: unflipped turns first, then flipped ones.
    public static func orientations(_ type: String) -> [(rot: Int, flip: Bool)] {
        var seen = Set<String>(), out: [(rot: Int, flip: Bool)] = []
        for flip in [false, true] {
            for rot in 0..<4 {
                let key = Shapes.orient(Library[type].shape, rot: rot, flip: flip)
                    .map { "\($0.x),\($0.y)" }.sorted().joined(separator: ";")
                if seen.insert(key).inserted { out.append((rot, flip)) }
            }
        }
        return out
    }

    /// The squares a placement covers, or nil if any of them falls off the map.
    public static func cells(_ type: String, _ p: Placement) -> [Int]? {
        var out: [Int] = []
        for o in Shapes.orient(Library[type].shape, rot: p.rot, flip: p.flip) {
            guard Board.inside(p.ax + o.x, p.ay + o.y) else { return nil }
            out.append(Board.index(p.ax + o.x, p.ay + o.y))
        }
        return out
    }

    /// A building can't overlap another or sit on water. A bridge must sit on water, with both ends on land.
    public static func canPlace(_ cells: [Int]?, _ type: String, map: [Terrain], owner: [Int]) -> Bool {
        guard let cells, !cells.contains(where: { owner[$0] >= 0 }) else { return false }
        guard Library[type].bridge else { return !cells.contains { map[$0] == .water } }
        return map[cells.first!] != .water && map[cells.last!] != .water && cells.contains { map[$0] == .water }
    }

    /// Every legal spot, in the web version's order: orientation, then row, then column.
    public static func all(_ type: String, map: [Terrain], owner: [Int]) -> [Option] {
        var out: [Option] = []
        visit(type, map: map, owner: owner) { out.append($0); return true }
        return out
    }

    public static func first(_ type: String, map: [Terrain], owner: [Int]) -> Option? {
        var found: Option?
        visit(type, map: map, owner: owner) { found = $0; return false }
        return found
    }

    /// Walks the legal spots until `keepGoing` says stop.
    private static func visit(_ type: String, map: [Terrain], owner: [Int], _ keepGoing: (Option) -> Bool) {
        for o in orientations(type) {
            let (w, h) = Shapes.extent(Shapes.orient(Library[type].shape, rot: o.rot, flip: o.flip))
            guard w <= Board.cols, h <= Board.rows else { continue }
            for ay in 0...(Board.rows - h) {
                for ax in 0...(Board.cols - w) {
                    let p = Placement(rot: o.rot, flip: o.flip, ax: ax, ay: ay)
                    let cells = self.cells(type, p)
                    if canPlace(cells, type, map: map, owner: owner), !keepGoing(Option(placement: p, cells: cells!)) { return }
                }
            }
        }
    }
}
