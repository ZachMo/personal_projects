import Foundation
import XCTest
@testable import FirstTownCore

final class RuleTests: XCTestCase {
    func testLibraryIsWellFormed() {
        XCTAssertEqual(Library.all.count, 55)
        XCTAssertEqual(Set(Library.all.map(\.id)).count, 55, "ids are unique")
        for d in Library.all {
            XCTAssertEqual(d.roles.count, Shapes.table[d.shape]?.count, "\(d.id): one role per square")
            let bonuses = d.rules.filter { $0.points > 0 }
            XCTAssertTrue(bonuses.contains(where: \.isLand), "\(d.id) has a land bonus")
            XCTAssertTrue(bonuses.contains(where: { !$0.isLand }), "\(d.id) has a neighbour bonus")
            XCTAssertFalse(Words.rule(d.rules[0]).isEmpty)
        }
    }

    /// A game with an empty deck, so a test can build exactly what it wants.
    private func blank(_ seed: Int32) -> Game { Game(seed: seed) }

    private func put(_ game: inout Game, _ type: String, _ cells: [Int]) -> BuildResult {
        game.forceNext(type)
        return game.build(cells)
    }

    func testCoveringLandKeepsTheBonus() throws {
        for seed in Int32(1)..<400 {
            var game = blank(seed)
            for o in game.placements("lumber") {
                let woods = Set(o.cells.flatMap(Board.around)).filter { !o.cells.contains($0) && game.map[$0] == .forest }
                guard woods.count >= 2 else { continue }
                _ = put(&game, "lumber", o.cells)
                let before = game.pieceScore(0)
                guard let cover = game.placements("well").first(where: { woods.contains($0.cells[0]) }) else { break }
                _ = put(&game, "well", cover.cells)
                XCTAssertEqual(game.pieceScore(0), before, "covering the woods takes nothing from the mill")
                return
            }
        }
        XCTFail("no map with a lumber mill beside two woods squares")
    }

    func testWaterUnderABridgeStillCounts() {
        for seed in Int32(1)..<400 {
            var game = blank(seed)
            for bridge in game.placements("bridge") {
                var trial = game
                _ = put(&trial, "bridge", bridge.cells)
                let wet = bridge.cells.filter { trial.map[$0] == .water }
                let dock = trial.placements("dock").first { option in
                    option.cells.contains { cell in Board.around(cell).contains(where: wet.contains) }
                }
                guard let dock else { continue }
                let water = Set(dock.cells.flatMap(Board.around)).filter { !dock.cells.contains($0) && trial.map[$0] == .water }
                XCTAssertEqual(trial.look(dock.cells).by[.water] ?? 0, water.count)
                game = trial
                return
            }
        }
        XCTFail("no map with a bridge and a dock beside it")
    }

    func testNeighbourBonusesGrow() {
        var game = Game(seed: 99)
        var raised = 0
        while let type = game.current {
            let best = game.placements(type).max { game.scoreParts(type, $0.cells).sum < game.scoreParts(type, $1.cells).sum }!
            raised += game.build(best.cells).changed.filter { $0.delta > 0 }.count
        }
        XCTAssertGreaterThan(raised, 0, "later buildings raise earlier ones")
    }

    func testSaveRoundTrip() throws {
        var game = Game(seed: 777, player: "Sam", namePick: 3, day: "2026-09-14")
        for _ in 0..<12 { guard let type = game.current else { break }; _ = game.build(game.placements(type)[0].cells) }
        let data = try JSONEncoder().encode(game)
        let back = try JSONDecoder().decode(Game.self, from: data)
        XCTAssertEqual(back.pieces, game.pieces)
        XCTAssertEqual(back.owner, game.owner)
        XCTAssertEqual(back.total, game.total)
        XCTAssertEqual(back.current, game.current)
        XCTAssertEqual(back.trophies, game.trophies)
        XCTAssertEqual(back.day, "2026-09-14")
    }

    func testTownNames() {
        XCTAssertEqual(Words.townName("zach", 0), "Fort Zach")
        XCTAssertEqual(Words.townName("Zach Mo", 4), "Zachville")
        XCTAssertEqual(Words.signed(-3), "−3")
    }
}

extension Game {
    /// Puts `type` in hand next, for tests that build a board by hand.
    mutating func forceNext(_ type: String) {
        over = false
        deck.insert(type, at: at)
    }
}
