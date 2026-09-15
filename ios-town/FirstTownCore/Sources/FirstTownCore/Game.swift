/// A building on the map.
public struct Piece: Codable, Hashable, Sendable {
    public let type: String
    public let cells: [Int]
    /// The open land beside it when it was built. Land bonuses read this, so covering that land later takes nothing away.
    public let land: [Terrain: Int]
}

/// One line of a score. `rule` is an index into the building's rules, or -1 for its base points.
public struct ScorePart: Hashable, Sendable {
    public let rule: Int
    public let n: Int
    public let v: Int
}

public extension Array where Element == ScorePart {
    var sum: Int { reduce(0) { $0 + $1.v } }
}

/// A building next door whose score moved when something was built.
public struct Change: Hashable, Sendable {
    public let index: Int
    public let delta: Int
}

public enum GameEvent: Hashable, Sendable {
    /// A building fit nowhere, so it was turned away.
    case away(String)
    /// The deck ran out.
    case end
}

public struct BuildResult: Sendable {
    public let type: String
    public let index: Int
    /// The new building's own score.
    public let points: Int
    public let parts: [ScorePart]
    /// Everything the move earned: the new building's score plus every change next door.
    public let gain: Int
    public let changed: [Change]
    public let trophies: [Trophy]
    public let events: [GameEvent]
}

/// What a footprint sits on and touches.
struct Surroundings {
    var on: [Terrain: Int]
    var by: [Terrain: Int]
    /// Indices of the buildings next to it.
    var near: [Int]
    var edge: Bool
    /// Its own index, or -1 for a building not yet built.
    var me: Int
}

public struct Game: Sendable {
    /// Points lost for each building that fits nowhere.
    public static let awayPenalty = 5
    /// Points won when every building finds a place.
    public static let allFitBonus = 10

    public let seed: Int32
    public var player: String
    /// Which of the town names built from the player's name this game uses.
    public var namePick: Int
    public internal(set) var deck: [String]
    public private(set) var at = 0
    public private(set) var away: [String] = []
    public private(set) var pieces: [Piece] = []
    public internal(set) var over = false
    public private(set) var trophies: [Trophy: Int] = [:]
    public private(set) var streak = 0
    /// Set when this is a daily map, to the day it belongs to, like "2026-09-14".
    public var day: String?

    /// Rebuilt from the seed, never saved.
    public let map: [Terrain]
    /// For each square, the index of the building on it, or -1.
    public private(set) var owner: [Int]

    public init(seed: Int32, player: String = "", namePick: Int = 0, day: String? = nil) {
        self.seed = seed
        self.player = player
        self.namePick = namePick
        self.day = day
        map = MapMaker.make(seed: seed)
        owner = Array(repeating: -1, count: Board.count)
        deck = DeckMaker.make(seed: seed, map: map)
        _ = settle()
    }

    // MARK: - The building in hand

    public var current: String? { over ? nil : deck[at] }
    public var upcoming: String? { over || at + 1 >= deck.count ? nil : deck[at + 1] }
    public var remaining: ArraySlice<String> { over ? [] : deck[at...] }

    public func cells(_ type: String, _ p: Placement) -> [Int]? { Placements.cells(type, p) }
    public func canPlace(_ cells: [Int]?, _ type: String) -> Bool { Placements.canPlace(cells, type, map: map, owner: owner) }
    public func placements(_ type: String) -> [Option] { Placements.all(type, map: map, owner: owner) }
    public func fits(_ type: String) -> Bool { Placements.first(type, map: map, owner: owner) != nil }

    /// Moves past buildings that fit nowhere, and ends the game when the deck runs out.
    mutating func settle() -> [GameEvent] {
        var events: [GameEvent] = []
        while !over {
            if at >= deck.count {
                over = true
                if away.isEmpty { trophies[.allfit] = 1 }
                events.append(.end)
                break
            }
            if fits(deck[at]) { break }
            away.append(deck[at])
            events.append(.away(deck[at]))
            at += 1
        }
        return events
    }

    /// Builds the building in hand. Neighbour bonuses are live, so the buildings next to it can go up or down too.
    public mutating func build(_ cells: [Int]) -> BuildResult {
        let type = current!
        let before = pieces.indices.map { pieceScore($0) }
        pieces.append(Piece(type: type, cells: cells, land: look(cells).by))
        let k = pieces.count - 1
        for c in cells { owner[c] = k }
        at += 1
        let parts = pieceParts(k), points = parts.sum
        let changed = before.enumerated().compactMap { j, b -> Change? in
            let d = pieceScore(j) - b
            return d == 0 ? nil : Change(index: j, delta: d)
        }
        let gain = points + changed.reduce(0) { $0 + $1.delta }
        let won = judge(type, cells, parts, points, gain, changed)
        for t in won { trophies[t, default: 0] += 1 }
        let events = settle()
        return BuildResult(type: type, index: k, points: points, parts: parts, gain: gain,
                           changed: changed, trophies: won, events: events)
    }

    // MARK: - Scoring

    func look(_ cells: [Int], me: Int = -1) -> Surroundings {
        let own = Set(cells)
        var on: [Terrain: Int] = [:], byCells: [Int: Terrain] = [:], near: [Int] = [], seen = Set<Int>(), edge = false
        for c in cells {
            on[map[c], default: 0] += 1
            let x = Board.col(c), y = Board.row(c)
            for step in Board.steps {
                guard Board.inside(x + step.dx, y + step.dy) else { edge = true; continue }
                let j = Board.index(x + step.dx, y + step.dy)
                if own.contains(j) { continue }
                if owner[j] >= 0 && owner[j] != me && seen.insert(owner[j]).inserted { near.append(owner[j]) }
                // Water never runs out: a bridge over it doesn't stop it counting.
                if owner[j] < 0 || map[j] == .water { byCells[j] = map[j] }
            }
        }
        var by: [Terrain: Int] = [:]
        for t in byCells.values { by[t, default: 0] += 1 }
        // A placed building keeps the land it had beside it when it was built.
        if me >= 0 { by = pieces[me].land }
        return Surroundings(on: on, by: by, near: near, edge: edge, me: me)
    }

    func evaluate(_ rule: Rule, _ s: Surroundings) -> (n: Int, v: Int) {
        let n: Int
        switch rule.kind {
        case .on: n = s.on[rule.terrain!] ?? 0
        case .by:
            let count = s.by[rule.terrain!] ?? 0
            return (count, (rule.once ? min(count, 1) : count) * rule.points)
        case .near: n = s.near.filter { rule.matches(pieces[$0].type) }.count
        case .edge: n = s.edge ? 1 : 0
        case .variety: n = Set(s.near.map { Library[pieces[$0].type].category }).count
        case .town: n = pieces.indices.filter { $0 != s.me && rule.matches(pieces[$0].type) }.count
        case .without: n = s.near.contains { rule.matches(pieces[$0].type) } ? 0 : 1
        }
        return (n, n * rule.points)
    }

    /// A score, part by part. With `me` left at -1 it reads the board as it is now, for a building not yet built.
    public func scoreParts(_ type: String, _ cells: [Int], me: Int = -1) -> [ScorePart] {
        let d = Library[type], s = look(cells, me: me)
        return [ScorePart(rule: -1, n: 1, v: d.base)] + d.rules.enumerated().map { i, rule in
            let e = evaluate(rule, s)
            return ScorePart(rule: i, n: e.n, v: e.v)
        }
    }

    public func pieceParts(_ k: Int) -> [ScorePart] { scoreParts(pieces[k].type, pieces[k].cells, me: k) }
    public func pieceScore(_ k: Int) -> Int { pieceParts(k).sum }
    public var boardScore: Int { pieces.indices.reduce(0) { $0 + pieceScore($1) } }
    public var total: Int {
        boardScore - Game.awayPenalty * away.count + (over && away.isEmpty ? Game.allFitBonus : 0)
    }

    // MARK: - Trophies

    mutating func judge(_ type: String, _ cells: [Int], _ parts: [ScorePart], _ points: Int, _ gain: Int, _ changed: [Change]) -> [Trophy] {
        let d = Library[type]
        func rule(_ q: ScorePart) -> Rule? { q.rule < 0 ? nil : d.rules[q.rule] }
        var out = Set<Trophy>()
        if gain >= Trophy.jackpotPoints { out.insert(.jackpot) }

        // The biggest stack of one bonus: 3 of a kind is a triple, 4 a quadruple, 5 or more a combo.
        var top = 0
        for q in parts {
            if let r = rule(q), r.points > 0, !r.once, r.kind != .edge, r.kind != .without { top = max(top, q.n) }
        }
        if top >= 3 { out.insert(top >= 5 ? .combo : top == 4 ? .quadruple : .triple) }

        let fullyOn = parts.contains { q in
            guard let r = rule(q) else { return false }
            return r.kind == .on && r.points > 0 && q.n == cells.count
        }
        if cells.count >= 2 && fullyOn { out.insert(.perfect) }
        if changed.filter({ $0.delta > 0 }).count >= 2 { out.insert(.boost) }
        let own = Set(cells)
        if !cells.contains(where: { c in Board.around(c).contains { !own.contains($0) && owner[$0] < 0 && map[$0] != .water } }) {
            out.insert(.snug)
        }

        streak = gain >= Trophy.greatPoints ? streak + 1 : 0
        if streak >= 3 && streak % 3 == 0 { out.insert(.roll) }

        if points <= 0 { out.insert(.ouch) }
        if parts.contains(where: { (rule($0)?.points ?? 0) < 0 && $0.n >= 2 }) { out.insert(.neighbours) }
        if changed.reduce(0, { $0 + min(0, $1.delta) }) <= -3 { out.insert(.spoiler) }
        let uses = Set(d.rules.filter { $0.kind == .on }.compactMap(\.terrain))
        if cells.filter({ [.ore, .wheat, .herd].contains(map[$0]) && !uses.contains(map[$0]) }).count >= 2 { out.insert(.wasted) }
        return Trophy.allCases.filter(out.contains)
    }
}

// MARK: - Saving

extension Game: Codable {
    enum CodingKeys: String, CodingKey {
        case seed, player, namePick, deck, at, away, pieces, over, trophies, streak, day
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        seed = try c.decode(Int32.self, forKey: .seed)
        player = try c.decode(String.self, forKey: .player)
        namePick = try c.decode(Int.self, forKey: .namePick)
        deck = try c.decode([String].self, forKey: .deck)
        at = try c.decode(Int.self, forKey: .at)
        away = try c.decode([String].self, forKey: .away)
        pieces = try c.decode([Piece].self, forKey: .pieces)
        over = try c.decode(Bool.self, forKey: .over)
        trophies = try c.decode([Trophy: Int].self, forKey: .trophies)
        streak = try c.decode(Int.self, forKey: .streak)
        day = try c.decodeIfPresent(String.self, forKey: .day)
        map = MapMaker.make(seed: seed)
        owner = Array(repeating: -1, count: Board.count)
        for (k, p) in pieces.enumerated() { for cell in p.cells { owner[cell] = k } }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(seed, forKey: .seed)
        try c.encode(player, forKey: .player)
        try c.encode(namePick, forKey: .namePick)
        try c.encode(deck, forKey: .deck)
        try c.encode(at, forKey: .at)
        try c.encode(away, forKey: .away)
        try c.encode(pieces, forKey: .pieces)
        try c.encode(over, forKey: .over)
        try c.encode(trophies, forKey: .trophies)
        try c.encode(streak, forKey: .streak)
        try c.encodeIfPresent(day, forKey: .day)
    }
}
