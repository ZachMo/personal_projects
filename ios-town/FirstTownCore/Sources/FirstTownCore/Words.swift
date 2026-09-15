/// Special builds, in the order they are announced.
public enum Trophy: String, CaseIterable, Codable, Sendable, CodingKeyRepresentable {
    case jackpot, combo, quadruple, triple, perfect, boost, snug, roll, allfit
    case ouch, neighbours, spoiler, wasted

    /// Points a move must earn to count as great, and as a jackpot.
    public static let greatPoints = 8
    public static let jackpotPoints = 13

    public var title: String {
        switch self {
        case .jackpot: "Jackpot!"
        case .combo: "Combo!"
        case .quadruple: "Quadruple!"
        case .triple: "Triple!"
        case .perfect: "Perfect ground"
        case .boost: "Good neighbour"
        case .snug: "Snug fit"
        case .roll: "On a roll"
        case .allfit: "Every building fit"
        case .ouch: "Ouch"
        case .neighbours: "Bad neighbours"
        case .spoiler: "Spoiler"
        case .wasted: "Wasted land"
        }
    }

    public var good: Bool {
        switch self {
        case .ouch, .neighbours, .spoiler, .wasted: false
        default: true
        }
    }
}

public extension Terrain {
    var name: String {
        switch self {
        case .grass: "Open grass"
        case .forest: "Woods"
        case .ore: "Ore vein"
        case .wheat: "Wild wheat"
        case .herd: "Grazing herd"
        case .water: "Water"
        }
    }

    /// The word in "each woods square beside it".
    var short: String {
        switch self {
        case .grass: "open grass"
        case .forest: "woods"
        case .ore: "ore"
        case .wheat: "wild wheat"
        case .herd: "herd"
        case .water: "water"
        }
    }

    /// The words in "each square on herd land".
    var onWord: String { self == .herd ? "herd land" : short }

    var blurb: String {
        switch self {
        case .grass: "Flat, easy land."
        case .forest: "Tall trees. A building put here clears them."
        case .ore: "Rock with a seam of silver in it."
        case .wheat: "Rich soil where grain grows on its own."
        case .herd: "Cattle and sheep on open range. A building here drives them off."
        case .water: "Only a bridge can be built on water."
        }
    }
}

public extension Category {
    var name: String {
        switch self {
        case .home: "Home"
        case .agri: "Food"
        case .industry: "Industry"
        case .shop: "Shop"
        case .civic: "Civic"
        case .leisure: "Leisure"
        }
    }

    var one: String {
        switch self {
        case .home: "home"
        case .shop: "shop"
        case .agri: "food building"
        default: "\(rawValue) building"
        }
    }

    var many: String { one + "s" }
}

public enum Words {
    /// "+2" or "−1", with a true minus sign.
    public static func signed(_ v: Int) -> String { (v < 0 ? "−" : "+") + String(abs(v)) }

    static func joinOr(_ items: [String]) -> String {
        items.count < 2 ? items.joined() : items.dropLast().joined(separator: ", ") + " or " + items.last!
    }

    static func nearNoun(_ r: Rule, _ n: Int) -> String {
        if r.any { return n == 1 ? "building" : "buildings" }
        return joinOr(r.cats.map { n == 1 ? $0.one : $0.many })
    }

    /// A rule as the card shows it, after its points: "each woods square beside it".
    public static func rule(_ r: Rule) -> String {
        switch r.kind {
        case .on: "each square on \(r.terrain!.onWord)"
        case .by: r.once ? "if beside \(r.terrain!.short)" : "each \(r.terrain!.short) square beside it"
        case .near: "each \(nearNoun(r, 1)) next to it"
        case .edge: "if at the edge of the map"
        case .variety: "each kind of building next to it"
        case .town: "each \(nearNoun(r, 1)) in town"
        case .without: "if no \(nearNoun(r, 2)) next to it"
        }
    }

    /// One part of a score as it stands: "3 woods beside", "4 on wild wheat".
    public static func part(_ type: String, _ q: ScorePart) -> String {
        guard q.rule >= 0 else { return "Base" }
        let r = Library[type].rules[q.rule]
        switch r.kind {
        case .on: return "\(q.n) on \(r.terrain!.onWord)"
        case .by:
            if r.once { return q.n > 0 ? "Beside \(r.terrain!.short)" : "Not beside \(r.terrain!.short)" }
            return "\(q.n) \(r.terrain!.short) beside"
        case .near: return "\(q.n) \(nearNoun(r, q.n)) next to it"
        case .edge: return q.n > 0 ? "At the map edge" : "Not at the map edge"
        case .variety: return "\(q.n) \(q.n == 1 ? "kind" : "kinds") next to it"
        case .town: return "\(q.n) \(nearNoun(r, q.n)) in town"
        case .without: return q.n > 0 ? "No \(nearNoun(r, 2)) next to it" : "Has \(nearNoun(r, 2)) next to it"
        }
    }

    /// Which buildings score for a kind of land, split into building on it and building beside it.
    public static func caresAbout(_ t: Terrain) -> (on: [(Building, Rule)], by: [(Building, Rule)]) {
        var on: [(Building, Rule)] = [], by: [(Building, Rule)] = []
        for d in Library.all {
            for r in d.rules where r.terrain == t {
                if r.kind == .on { on.append((d, r)) } else { by.append((d, r)) }
            }
        }
        return (on, by)
    }

    static let prefixes = ["Fort", "St.", "New", "Port"]
    static let suffixes = ["ville", "burg", "ton", "field"]
    public static let townNameCount = prefixes.count + suffixes.count

    /// Fort Zach, Zachville and so on.
    public static func townName(_ player: String, _ pick: Int) -> String {
        let first = player.split(separator: " ").first.map(String.init) ?? "Pioneer"
        let name = first.prefix(1).uppercased() + first.dropFirst()
        let all = prefixes.map { "\($0) \(name)" } + suffixes.map { name + $0 }
        return all[((pick % all.count) + all.count) % all.count]
    }
}
