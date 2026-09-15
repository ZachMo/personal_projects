import Foundation
import Observation
import FirstTownCore

/// A build the board still has to show: the building dropping in, numbers over its neighbours, confetti.
struct BuildEffect {
    let result: BuildResult
    let cells: [Int]
}

/// The game in play, plus what the screen needs around it: the building in hand, the open card, the drag, the sheets.
@Observable
final class Town {
    enum Sheet: String, Identifiable {
        case score, deck, menu
        var id: String { rawValue }
    }

    private(set) var game: Game
    /// Where the building in hand sits.
    private(set) var ghost: Placement?
    /// The square whose info card is open, or -1.
    private(set) var selection = -1
    /// The scoring card for the building in hand is open.
    private(set) var rulesOpen = false
    var dragging = false
    var sheet: Sheet?
    /// The name form for a new town is showing, with its map behind.
    private(set) var introOpen = false
    var summaryOpen = false
    /// The last build, and a count that changes with every build, so the score pop-up shows each one.
    private(set) var lastBuild: BuildResult?
    private(set) var builds = 0
    /// The best score before this game ended.
    private(set) var bestBefore = 0

    /// Builds the board has not shown yet. The renderer takes them.
    @ObservationIgnored var effects: [BuildEffect] = []
    /// Set when a new game starts, so the board clears its walkers and effects.
    @ObservationIgnored var resetScene = false

    init(game: Game, intro: Bool = false) {
        self.game = game
        introOpen = intro
        bestBefore = Self.best
        freshGhost()
    }

    var name: String { Words.townName(game.player, game.namePick) }

    // MARK: - Starting and saving

    private static let saveKey = "firsttown.game.v1"
    private static let bestKey = "firsttown.best"

    static var best: Int { UserDefaults.standard.integer(forKey: bestKey) }

    static func launch() -> Town {
        #if DEBUG
        // -seed 424242 -autoplay 12 starts a known map with a few moves made, for simulator screenshots.
        let args = ProcessInfo.processInfo.arguments
        func number(_ flag: String) -> Int? {
            guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
            return Int(args[i + 1])
        }
        if args.contains("-intro") { return Town(game: newGame(), intro: true) }
        if let seed = number("-seed") {
            let town = Town(game: Game(seed: Int32(truncatingIfNeeded: seed), player: "Zach", namePick: 4))
            for _ in 0..<(number("-autoplay") ?? 0) { town.autoplay() }
            town.effects.removeAll()
            if args.contains("-rules") { town.toggleRules() }
            if let square = number("-select") { town.select(square) }
            if args.contains("-pop"), let last = town.lastBuild { town.lastBuild = last; town.builds += 1 }
            if args.contains("-summary") { while !town.game.over { town.autoplay() }; town.effects.removeAll(); town.summaryOpen = true }
            if let sheet = args.firstIndex(of: "-sheet").flatMap({ $0 + 1 < args.count ? Sheet(rawValue: args[$0 + 1]) : nil }) { town.sheet = sheet }
            return town
        }
        #endif
        if let data = UserDefaults.standard.data(forKey: saveKey), let game = try? JSONDecoder().decode(Game.self, from: data), !game.player.isEmpty {
            return Town(game: game)
        }
        return Town(game: newGame(), intro: true)
    }

    private static func newGame() -> Game {
        Game(seed: Int32.random(in: 0...Int32.max))
    }

    func save() {
        guard !game.player.isEmpty, let data = try? JSONEncoder().encode(game) else { return }
        UserDefaults.standard.set(data, forKey: Self.saveKey)
    }

    /// A fresh map behind the name form. The old town stays saved until the new one starts.
    func openIntro() {
        summaryOpen = false
        sheet = nil
        start(Self.newGame())
        introOpen = true
    }

    /// Names the town on the map behind the form, and starts playing.
    func found(player: String) {
        game.player = player
        game.namePick = Int.random(in: 0..<Words.townNameCount)
        introOpen = false
        save()
    }

    private func start(_ game: Game) {
        self.game = game
        selection = -1
        rulesOpen = false
        summaryOpen = false
        lastBuild = nil
        effects.removeAll()
        resetScene = true
        bestBefore = Self.best
        freshGhost()
    }

    // MARK: - The building in hand

    var ghostCells: [Int]? {
        guard let ghost, let type = game.current else { return nil }
        return game.cells(type, ghost)
    }

    var canBuild: Bool {
        guard let type = game.current else { return false }
        return game.canPlace(ghostCells, type)
    }

    var showsGhost: Bool { !game.over && !introOpen }

    /// Moves the building in hand, kept on the map.
    func place(_ p: Placement) {
        guard let type = game.current else { return }
        let (w, h) = Shapes.extent(Shapes.orient(Library[type].shape, rot: p.rot, flip: p.flip))
        let kept = Placement(rot: p.rot, flip: p.flip, ax: min(max(p.ax, 0), Board.cols - w), ay: min(max(p.ay, 0), Board.rows - h))
        if kept != ghost { ghost = kept }
    }

    /// Starts a new building in hand at the open spot nearest the middle of the map.
    func freshGhost() {
        guard let type = game.current else { ghost = nil; return }
        var best: (p: Placement, d: Double)?
        for o in game.placements(type) {
            let p = o.placement
            let (w, h) = Shapes.extent(Shapes.orient(Library[type].shape, rot: p.rot, flip: p.flip))
            let dx = Double(p.ax) + Double(w) / 2 - Double(Board.cols) / 2
            let dy = Double(p.ay) + Double(h) / 2 - Double(Board.rows) / 2
            let d = dx * dx + dy * dy + (p.rot != 0 || p.flip ? 1.5 : 0)
            if best == nil || d < best!.d { best = (p, d) }
        }
        ghost = best?.p
    }

    /// Turns or flips the building in hand about its middle.
    private func reorient(turn: Int, flip: Bool) {
        guard let g = ghost, let type = game.current else { return }
        let shape = Library[type].shape
        let (w, h) = Shapes.extent(Shapes.orient(shape, rot: g.rot, flip: g.flip))
        let rot = (g.rot + turn + 4) % 4, flipped = flip ? !g.flip : g.flip
        let (w2, h2) = Shapes.extent(Shapes.orient(shape, rot: rot, flip: flipped))
        place(Placement(rot: rot, flip: flipped,
                        ax: Int((Double(g.ax) + Double(w) / 2 - Double(w2) / 2).rounded()),
                        ay: Int((Double(g.ay) + Double(h) / 2 - Double(h2) / 2).rounded())))
        Haptics.tick()
    }

    func turn() { reorient(turn: 1, flip: false) }
    func flip() { reorient(turn: 0, flip: true) }

    func build() {
        guard let type = game.current, let cells = ghostCells, game.canPlace(cells, type) else { return }
        let result = game.build(cells)
        effects.append(BuildEffect(result: result, cells: cells))
        lastBuild = result
        builds += 1
        if game.over {
            rulesOpen = false
            bestBefore = Self.best
            if game.total > bestBefore { UserDefaults.standard.set(game.total, forKey: Self.bestKey) }
        }
        freshGhost()
        save()
        if result.trophies.contains(where: \.good) { Haptics.celebrate() } else { Haptics.thud() }
    }

    #if DEBUG
    /// Builds where the building in hand scores most on its own.
    private func autoplay() {
        guard let type = game.current else { return }
        let best = game.placements(type).max { game.scoreParts(type, $0.cells).sum < game.scoreParts(type, $1.cells).sum }
        if let best { ghost = best.placement; build() }
    }
    #endif

    // MARK: - Cards

    func toggleRules() {
        if rulesOpen { closeInfo(); return }
        selection = -1
        rulesOpen = game.current != nil
    }

    func select(_ square: Int) {
        rulesOpen = false
        selection = square
    }

    func closeInfo() {
        selection = -1
        rulesOpen = false
    }

    /// The row the open card is about, so it can sit on the other half of the map.
    var cardRow: Double? {
        if rulesOpen, let cells = ghostCells { return Double(cells.reduce(0) { $0 + Board.row($1) }) / Double(cells.count) }
        if selection >= 0 { return Double(Board.row(selection)) }
        return nil
    }
}
