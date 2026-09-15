public enum Terrain: String, Codable, CaseIterable, Sendable, CodingKeyRepresentable {
    case grass, forest, ore, wheat, herd, water
}

public enum Category: String, Codable, CaseIterable, Sendable {
    case home, agri, industry, shop, civic, leisure
}

/*
  A building scores its base points plus its rules. On means the land under it. Beside means open land that
  shares a side with it. Next to means a building that shares a side with it. Corners don't count.
  Land bonuses are set when you build: covering that land later takes nothing away, and water under a bridge
  still counts as water. Bonuses for buildings stay live, so a building gains whenever a neighbour it likes arrives.
*/
public struct Rule: Hashable, Sendable {
    public enum Kind: String, Sendable {
        /// Points for each of its squares on a terrain.
        case on
        /// Points for each open square of a terrain beside it. `once` counts one at most.
        case by
        /// Points for each building of a category next to it.
        case near
        /// Points if it touches the edge of the map.
        case edge
        /// Points for each kind of building next to it.
        case variety
        /// Points for each building of a category anywhere in town.
        case town
        /// Points if no building of a category is next to it.
        case without
    }

    public let kind: Kind
    public let terrain: Terrain?
    public let cats: [Category]
    /// For `near`: every building counts, whatever its category.
    public let any: Bool
    public let points: Int
    public let once: Bool

    public static func on(_ t: Terrain, _ p: Int) -> Rule { Rule(kind: .on, terrain: t, cats: [], any: false, points: p, once: false) }
    public static func by(_ t: Terrain, _ p: Int, once: Bool = false) -> Rule { Rule(kind: .by, terrain: t, cats: [], any: false, points: p, once: once) }
    public static func near(_ cats: [Category], _ p: Int) -> Rule { Rule(kind: .near, terrain: nil, cats: cats, any: false, points: p, once: false) }
    public static func nearAny(_ p: Int) -> Rule { Rule(kind: .near, terrain: nil, cats: [], any: true, points: p, once: false) }
    public static func edge(_ p: Int) -> Rule { Rule(kind: .edge, terrain: nil, cats: [], any: false, points: p, once: false) }
    public static func variety(_ p: Int) -> Rule { Rule(kind: .variety, terrain: nil, cats: [], any: false, points: p, once: false) }
    public static func town(_ cats: [Category], _ p: Int) -> Rule { Rule(kind: .town, terrain: nil, cats: cats, any: false, points: p, once: false) }
    public static func without(_ cats: [Category], _ p: Int) -> Rule { Rule(kind: .without, terrain: nil, cats: cats, any: false, points: p, once: false) }

    public func matches(_ type: String) -> Bool { any || cats.contains(Library[type].category) }

    /// Land rules score for what a building claims when it goes up. The rest score for the town around it.
    public var isLand: Bool { kind == .on || kind == .by || kind == .edge }
}

public struct Building: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let plural: String
    public let category: Category
    public let shape: String
    /// How many a deck starts with, before it is padded or trimmed.
    public let count: Int
    /// 1 comes early, 3 comes late.
    public let era: Int
    public let base: Int
    /// What is drawn on each square, in footprint order.
    public let roles: [String]
    /// Roof colours, light side then dark side.
    public let roof: [String]?
    public let roof2: [String]?
    /// A small sign drawn on the roof.
    public let emblem: String?
    /// Its own tile colours, instead of its category's.
    public let tile: [String]?
    /// It may sit on water, with both ends on land.
    public let bridge: Bool
    public let blurb: String
    public let rules: [Rule]
}

private func b(_ id: String, _ name: String, _ category: Category, _ shape: String, n: Int, era: Int, base: Int,
               roles: [String], _ blurb: String, _ rules: [Rule], plural: String? = nil,
               roof: [String]? = nil, roof2: [String]? = nil, emblem: String? = nil,
               tile: [String]? = nil, bridge: Bool = false) -> Building {
    Building(id: id, name: name, plural: plural ?? name + "s", category: category, shape: shape, count: n, era: era,
             base: base, roles: roles, roof: roof, roof2: roof2, emblem: emblem, tile: tile, bridge: bridge,
             blurb: blurb, rules: rules)
}

/// Every building in the game. The order matters: the deck draws from it in this order.
public enum Library {
    public static let all: [Building] = [
        b("well", "Town Well", .civic, "I1", n: 2, era: 1, base: 1, roles: ["well"],
          "Water for the families and the herds.", [.near([.home], 1), .by(.herd, 1)], plural: "Town Wells"),
        b("cabin", "Cabin", .home, "I2", n: 3, era: 1, base: 2, roles: ["house", "garden"],
          "A porch by the woods, close to the food.", [.by(.forest, 1), .near([.agri], 2), .near([.industry], -2)],
          roof: ["#dc7b50", "#b75d3a"]),
        b("homestead", "Homestead", .home, "V3", n: 2, era: 1, base: 3, roles: ["garden", "house", "house"],
          "A family that wants food and grain close by.", [.near([.agri], 2), .by(.wheat, 1), .near([.industry], -2)],
          roof: ["#c86a4b", "#a45237"]),
        b("rowhouses", "Row Houses", .home, "I4", n: 2, era: 2, base: 3, roles: ["rowA", "rowB", "rowA", "rowB"],
          "Town folk who want the shops close and a river view.", [.near([.shop], 2), .by(.water, 2, once: true), .near([.industry], -2)],
          plural: "Row Houses", roof: ["#d98c5b", "#b76d43"], roof2: ["#bb6f5b", "#955240"]),
        b("farm", "Farm", .agri, "O4", n: 2, era: 1, base: 2, roles: ["barn", "field", "field", "field"],
          "Grain for the families next door.", [.on(.wheat, 3), .by(.water, 2, once: true), .near([.home], 1)],
          roof: ["#cc5443", "#a43f31"]),
        b("ranch", "Ranch", .agri, "V5", n: 1, era: 2, base: 2, roles: ["pasture", "pasture", "barn", "pasture", "pasture"],
          "Round up a herd, or graze open grass. Sells to the shops.", [.on(.herd, 2), .on(.grass, 1), .near([.shop], 1)],
          plural: "Ranches", roof: ["#b85a40", "#93432f"]),
        b("lumber", "Lumber Mill", .industry, "S4", n: 2, era: 1, base: 2, roles: ["hall", "logs", "logs", "hall"],
          "Saws timber from the woods around it.", [.by(.forest, 2), .near([.industry], 1)],
          roof: ["#8e6c4f", "#6e523b"]),
        b("mine", "Mine", .industry, "V3", n: 2, era: 1, base: 1, roles: ["shaft", "rocks", "yard"],
          "Only worth digging where the ore is.", [.on(.ore, 4), .near([.industry], 1)]),
        b("smithy", "Blacksmith", .industry, "I2", n: 1, era: 2, base: 2, roles: ["forge", "yard"],
          "Tools for the mills, shoes for the herds.", [.near([.industry], 2), .by(.herd, 1)],
          roof: ["#6f7985", "#535c67"]),
        b("dock", "Fishing Dock", .agri, "I3", n: 1, era: 2, base: 1, roles: ["shed", "plank", "plank"],
          "Nets and boats along the bank.", [.by(.water, 2), .near([.shop], 1)],
          roof: ["#927c64", "#73614d"]),
        b("store", "General Store", .shop, "T4", n: 1, era: 2, base: 3, roles: ["shop", "shop", "shop", "crates"],
          "A little of everything, brought up the river.", [.near([.home], 2), .by(.water, 2, once: true)],
          roof: ["#40a092", "#2f7e72"]),
        b("grocer", "Grocer", .shop, "L4", n: 1, era: 2, base: 2, roles: ["shop", "shop", "produce", "produce"],
          "Fresh food, straight from the source.", [.near([.agri], 2), .near([.home], 1), .by(.herd, 1)],
          roof: ["#5ea56b", "#468753"]),
        b("saloon", "Saloon", .leisure, "S4", n: 1, era: 2, base: 3, roles: ["hall", "hall", "porch", "porch"],
          "Where the miners and the cowhands go after a shift.", [.near([.industry], 2), .near([.leisure], 1), .by(.herd, 1)],
          roof: ["#a95a90", "#864571"]),
        b("church", "Church", .civic, "X5", n: 1, era: 3, base: 3, roles: ["steeple", "tree", "nave", "tree", "nave"],
          "The heart of a quiet town.", [.near([.home], 2), .by(.water, 1, once: true), .near([.leisure], -3)],
          plural: "Churches", roof: ["#8195b8", "#63779d"]),
        b("school", "Schoolhouse", .civic, "T5", n: 1, era: 3, base: 3, roles: ["hall", "hall", "hall", "yard", "play"],
          "Lessons for the children next door.", [.near([.home], 2), .by(.forest, 1), .near([.industry], -2)],
          roof: ["#cc5e4c", "#a84737"]),
        b("hotel", "Hotel", .leisure, "P5", n: 1, era: 3, base: 3, roles: ["big", "big", "big", "big", "porch"],
          "Travellers want a drink, a view and a store.", [.near([.leisure], 2), .by(.water, 2, once: true), .near([.shop], 1)],
          roof: ["#9160aa", "#724489"]),
        b("station", "Train Station", .civic, "I5", n: 1, era: 3, base: 3, roles: ["rail", "hall", "hall", "hall", "rail"],
          "The line comes in from the edge of the map.", [.edge(3), .near([.industry, .shop], 2)],
          roof: ["#5d7189", "#46586c"]),
        b("townhall", "Town Hall", .civic, "U5", n: 1, era: 3, base: 3, roles: ["tree", "flag", "hall", "hall", "hall"],
          "Wants every part of town at its door.", [.variety(2), .by(.water, 2, once: true)],
          roof: ["#5580c8", "#4065a8"]),

        // Homes
        b("manor", "Manor", .home, "O4", n: 1, era: 2, base: 4, roles: ["big", "big", "garden", "tree"],
          "Old money wants a view and fine neighbours.", [.by(.water, 3, once: true), .near([.civic], 2), .near([.industry], -3)],
          roof: ["#7e8a9e", "#616c80"]),
        b("loghouse", "Log House", .home, "I3", n: 2, era: 1, base: 2, roles: ["house", "house", "garden"],
          "Built from the trees, a walk from the store.", [.by(.forest, 1), .near([.shop], 2)],
          roof: ["#9b6a45", "#7a5234"]),
        b("boarding", "Boarding House", .home, "L4", n: 1, era: 2, base: 2, roles: ["hall", "hall", "hall", "yard"],
          "Cheap beds for working men.", [.near([.industry], 2), .near([.shop], 1), .by(.ore, 1)],
          roof: ["#b07a52", "#8e5f3d"]),
        b("farmhouse", "Farmhouse", .home, "V3", n: 2, era: 1, base: 2, roles: ["house", "house", "garden"],
          "Wants the fields and the herds close by.", [.near([.agri], 2), .by(.wheat, 1), .by(.herd, 1)],
          roof: ["#d0885a", "#ad6a40"]),
        b("miners", "Miners' Shacks", .home, "S4", n: 1, era: 2, base: 1, roles: ["rowA", "yard", "rowB", "rowA"],
          "Close to the dig, far from comfort.", [.near([.industry], 2), .by(.ore, 1), .near([.shop], 1)],
          plural: "Miners' Shacks", roof: ["#8c7f73", "#6d6259"], roof2: ["#a08f7c", "#7f7162"]),

        // Food
        b("orchard", "Orchard", .agri, "L4", n: 1, era: 1, base: 2, roles: ["orchard", "orchard", "orchard", "orchard"],
          "Apple trees in neat rows.", [.on(.grass, 1), .by(.water, 2, once: true), .near([.home], 1)]),
        b("vineyard", "Vineyard", .agri, "W5", n: 1, era: 2, base: 1, roles: ["vines", "vines", "vines", "vines", "vines"],
          "Grapes for the saloons and hotels.", [.on(.grass, 1), .near([.leisure], 2)]),
        b("gristmill", "Gristmill", .agri, "I2", n: 1, era: 2, base: 2, roles: ["hall", "wheel"],
          "A water wheel grinding the harvest.", [.by(.water, 3, once: true), .near([.agri], 2), .by(.wheat, 1)],
          roof: ["#a7836a", "#86684f"]),
        b("stables", "Stables", .agri, "T4", n: 1, era: 2, base: 2, roles: ["hall", "hall", "hall", "hay"],
          "Horses for hire, broken from the herds.", [.by(.herd, 2), .near([.leisure, .civic], 1)],
          plural: "Stables", roof: ["#a2603c", "#7f492c"]),
        b("granary", "Granary", .agri, "I2", n: 1, era: 3, base: 1, roles: ["hall", "hall"],
          "Stores grain where it grows, and the harvest of every food building.", [.on(.wheat, 2), .town([.agri], 1)],
          plural: "Granaries", roof: ["#caa24e", "#a8843a"]),
        b("windmill", "Windmill", .agri, "I1", n: 2, era: 1, base: 1, roles: ["windmill"],
          "Turns wherever the grain grows.", [.near([.agri], 2), .on(.wheat, 2)]),

        // Industry
        b("sluice", "Gold Sluice", .industry, "I3", n: 1, era: 1, base: 2, roles: ["sluice", "sluice", "sluice"],
          "Washes gold out of the rock.", [.on(.ore, 3), .by(.water, 3, once: true), .near([.industry], 1)],
          plural: "Gold Sluices"),
        b("stampmill", "Stamp Mill", .industry, "O4", n: 1, era: 2, base: 2, roles: ["big", "big", "rocks", "yard"],
          "Crushes ore beside the diggings.", [.by(.ore, 2), .near([.industry], 2), .by(.water, 2, once: true)],
          roof: ["#6c7480", "#525964"]),
        b("brickworks", "Brickworks", .industry, "T4", n: 1, era: 2, base: 2, roles: ["forge", "forge", "forge", "crates"],
          "Bricks for every home in town.", [.by(.water, 3, once: true), .town([.home], 1)],
          plural: "Brickworks", roof: ["#b4533d", "#903f2e"]),
        b("tannery", "Tannery", .industry, "I2", n: 1, era: 2, base: 2, roles: ["hall", "yard"],
          "Hides from the herds. It smells.", [.by(.herd, 2), .near([.agri], 2), .near([.home], -2)],
          plural: "Tanneries", roof: ["#8a6f4e", "#6b553b"]),
        b("kiln", "Charcoal Kiln", .industry, "I1", n: 1, era: 1, base: 1, roles: ["kiln"],
          "Burns wood into fuel.", [.by(.forest, 2), .near([.industry], 1)]),
        b("freight", "Freight Yard", .industry, "L5", n: 1, era: 3, base: 2, roles: ["rail", "rail", "rail", "rail", "shed"],
          "Loads goods at the edge of town.", [.edge(3), .near([.industry], 2)],
          roof: ["#7d6a56", "#615243"]),

        // Shops
        b("bakery", "Bakery", .shop, "I2", n: 1, era: 2, base: 2, roles: ["house", "crates"],
          "Flour from the farms, bread for the homes.", [.by(.wheat, 1), .near([.agri], 2), .near([.home], 1)],
          plural: "Bakeries", roof: ["#d69a52", "#b47c3c"]),
        b("fishmarket", "Fish Market", .shop, "I3", n: 1, era: 2, base: 2, roles: ["shop", "shop", "crates"],
          "The day's catch, from the river to the homes.", [.by(.water, 1), .near([.home], 2)],
          roof: ["#4f93b0", "#3d7690"]),
        b("bank", "Bank", .shop, "O4", n: 1, era: 3, base: 3, roles: ["big", "big", "big", "big"],
          "Holds the town's gold. Wants shops and the law close by.", [.near([.shop], 2), .near([.civic], 1), .by(.ore, 1)],
          roof: ["#b9a26a", "#968250"], emblem: "dollar"),
        b("tradingpost", "Trading Post", .shop, "V3", n: 1, era: 1, base: 2, roles: ["hall", "hall", "crates"],
          "Trade with whoever comes in from outside.", [.edge(3), .by(.water, 2, once: true), .near([.home], 1)],
          roof: ["#9a7b55", "#7a603f"]),
        b("assay", "Assay Office", .shop, "I2", n: 1, era: 2, base: 2, roles: ["shop", "shop"],
          "Weighs what the diggings bring in.", [.near([.industry], 2), .by(.ore, 1)],
          roof: ["#8b8f96", "#6e7278"]),

        // Civic
        b("bridge", "Bridge", .civic, "I3", n: 1, era: 1, base: 2, roles: ["deck", "deck", "deck"],
          "Crosses the water. Both ends must sit on land.", [.on(.water, 3), .nearAny(1)],
          tile: ["#c9a06f", "#8f6a45"], bridge: true),
        b("coveredbridge", "Covered Bridge", .civic, "I4", n: 1, era: 1, base: 3, roles: ["deck", "hall", "hall", "deck"],
          "A long, roofed crossing. Both ends must sit on land.", [.on(.water, 3), .nearAny(1)],
          roof: ["#b0503c", "#8c3d2d"], tile: ["#c9a06f", "#8f6a45"], bridge: true),
        b("library", "Library", .civic, "F5", n: 1, era: 3, base: 3, roles: ["hall", "tree", "garden", "hall", "hall"],
          "Needs quiet, trees and civic neighbours.", [.without([.industry, .leisure], 4), .near([.civic], 2), .by(.forest, 1)],
          plural: "Libraries", roof: ["#6d8f7a", "#557260"], emblem: "book"),
        b("sheriff", "Sheriff's Office", .civic, "V3", n: 1, era: 2, base: 3, roles: ["hall", "hall", "yard"],
          "Watches the saloons, the shops and the road into town.", [.near([.leisure], 2), .near([.shop], 1), .edge(2)],
          roof: ["#8a6a4a", "#6c5238"], emblem: "star"),
        b("jail", "Jail", .civic, "I2", n: 1, era: 2, base: 2, roles: ["hall", "yard"],
          "Belongs with the law, at the edge of town.", [.near([.civic], 3), .edge(2), .near([.home], -2)],
          roof: ["#7b7f86", "#5f636a"], emblem: "bars"),
        b("plaza", "Plaza", .civic, "O4", n: 1, era: 2, base: 1, roles: ["plaza", "plaza", "plaza", "plaza"],
          "An open square among shops and homes.", [.near([.shop, .leisure], 2), .near([.home], 1), .by(.water, 2, once: true)]),
        b("cemetery", "Cemetery", .civic, "T4", n: 1, era: 2, base: 2, roles: ["graves", "graves", "graves", "graves"],
          "Quiet ground by the church and the trees.", [.near([.civic], 2), .by(.forest, 1), .near([.home], -1)],
          plural: "Cemeteries"),
        b("doctor", "Doctor", .civic, "I2", n: 1, era: 2, base: 3, roles: ["house", "garden"],
          "Close to families, far from the smoke.", [.near([.home], 2), .by(.water, 1, once: true), .near([.industry], -2)],
          roof: ["#e9e3d6", "#c9c1b0"], emblem: "cross"),
        b("courthouse", "Courthouse", .civic, "T5", n: 1, era: 3, base: 3, roles: ["hall", "hall", "hall", "yard", "flag"],
          "Law and order, on the main street.", [.near([.civic], 2), .near([.shop], 1), .on(.grass, 1)],
          roof: ["#9aa3ad", "#7c858f"], emblem: "clock"),

        // Leisure
        b("theater", "Theater", .leisure, "Y5", n: 1, era: 3, base: 3, roles: ["hall", "hall", "hall", "hall", "porch"],
          "A show for the town and its visitors.", [.near([.home], 2), .near([.leisure], 1), .by(.water, 2, once: true)],
          roof: ["#b0445a", "#8c3447"], emblem: "mask"),
        b("bathhouse", "Bathhouse", .leisure, "L4", n: 1, era: 2, base: 2, roles: ["hall", "hall", "pool", "pool"],
          "Hot water for tired travellers.", [.by(.water, 3, once: true), .by(.forest, 1), .near([.leisure], 1)],
          roof: ["#6aa3b5", "#528596"]),
        b("casino", "Gambling Hall", .leisure, "P5", n: 1, era: 3, base: 4, roles: ["big", "big", "big", "big", "porch"],
          "A riverboat gamble. The law and the church hate it.", [.near([.leisure, .shop], 2), .by(.water, 2, once: true), .near([.civic], -3)],
          roof: ["#2f6b4f", "#22523c"], emblem: "diamond"),
        b("racetrack", "Racetrack", .leisure, "R6", n: 1, era: 3, base: 2, roles: ["track", "track", "track", "track", "track", "track"],
          "Needs open grass and horses from the herds.", [.on(.grass, 1), .by(.herd, 2), .near([.leisure], 2)]),
        b("fairground", "Fairground", .leisure, "N5", n: 1, era: 2, base: 2, roles: ["tent", "tent", "tent", "tent", "tent"],
          "Tents at the edge of town, near the farms.", [.edge(3), .near([.agri], 2), .by(.herd, 1)]),
        b("park", "Park", .leisure, "Z5", n: 1, era: 2, base: 1, roles: ["tree", "garden", "tree", "garden", "tree"],
          "Green space for the families.", [.near([.home], 2), .by(.forest, 1), .by(.water, 1, once: true)]),
    ]

    public static let byID: [String: Building] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    public static subscript(_ id: String) -> Building { byID[id]! }
}
