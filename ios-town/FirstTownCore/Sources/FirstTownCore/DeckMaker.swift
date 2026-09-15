/// Each game draws a few kinds of building from every category, and any map with water to cross gets a bridge.
/// Then the counts go up or down until the deck covers a bit less than the land can take.
public enum DeckMaker {
    /// The deck covers this share of the land you can build on.
    public static let fill = 0.87
    static let quota: [(Category, Int)] = [(.home, 4), (.agri, 3), (.industry, 3), (.shop, 3), (.civic, 3), (.leisure, 2)]

    public static func make(seed: Int32, map: [Terrain]) -> [String] {
        var r = Mulberry32(seed: seed ^ 0x5bd1e995)

        var chosen: [String] = []
        func add(_ id: String) { if !chosen.contains(id) { chosen.append(id) } }

        for (category, n) in quota {
            var ids = Library.all.filter { $0.category == category && !$0.bridge }.map(\.id)
            r.shuffle(&ids)
            ids.prefix(n).forEach(add)
        }
        var bridges = Library.all.filter(\.bridge).map(\.id)
        r.shuffle(&bridges)
        let empty = [Int](repeating: -1, count: Board.count)
        if let bridge = bridges.first(where: { Placements.first($0, map: map, owner: empty) != nil }) { add(bridge) }

        var count: [String: Int] = [:]
        for id in chosen { count[id] = Library[id].count }
        func size(_ id: String) -> Int { Shapes.table[Library[id].shape]!.count }
        func total() -> Int { chosen.reduce(0) { $0 + count[$1]! * size($1) } }
        let land = Double(map.filter { $0 != .water }.count)
        let target = Int((land * fill + 0.5).rounded(.down))

        while total() > target {
            let id = r.pick(chosen.filter { count[$0]! > 1 })
                ?? r.pick(chosen.filter { count[$0]! == 1 && !Library[$0].bridge })
            guard let id else { break }
            count[id]! -= 1
        }
        let padding = chosen.filter { Library[$0].category == .home || size($0) <= 2 }
        while total() < target - 1 {
            let id = r.pick(padding.filter { count[$0]! < 4 }) ?? r.pick(chosen)!
            count[id]! += 1
        }

        // Early buildings first, with a little overlap between eras. Ties keep the order they were added in.
        var keyed: [(id: String, key: Double, order: Int)] = []
        for id in chosen {
            for _ in 0..<count[id]! {
                keyed.append((id, Double(Library[id].era) + r.next() * 1.6, keyed.count))
            }
        }
        return keyed.sorted { $0.key != $1.key ? $0.key < $1.key : $0.order < $1.order }.map(\.id)
    }
}
