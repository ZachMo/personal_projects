import Foundation
import XCTest
@testable import FirstTownCore

/// The port against the web version: same maps, same decks, and the same games when a bot plays them.
/// See Tools/make-web-fixtures.js.
final class WebParityTests: XCTestCase {
    struct Fixture: Decodable {
        let seed: Int32
        let map: String
        let deck: [String]
        let moves: [Move]
        let total: Int
        let away: [String]
        let scores: [Int]
    }

    struct Move: Decodable {
        let t: String
        let c: [Int]
        let p: Int
        let g: Int
        let tr: [String]
    }

    static let fixtures: [Fixture] = try! JSONDecoder().decode([Fixture].self, from: Data(WebFixtures.json.utf8))
    static let letter: [Terrain: Character] = [.grass: "g", .forest: "f", .ore: "o", .wheat: "w", .herd: "h", .water: "~"]

    func testMapsMatch() {
        for f in Self.fixtures {
            let map = String(MapMaker.make(seed: f.seed).map { Self.letter[$0]! })
            XCTAssertEqual(map, f.map, "map for seed \(f.seed)")
        }
    }

    func testDecksMatch() {
        for f in Self.fixtures {
            XCTAssertEqual(Game(seed: f.seed).deck, f.deck, "deck for seed \(f.seed)")
        }
    }

    func testBotGamesMatch() {
        for f in Self.fixtures {
            var game = Game(seed: f.seed, player: "bot")
            for (n, move) in f.moves.enumerated() {
                guard let type = game.current else { return XCTFail("seed \(f.seed): game ended early at move \(n)") }
                var best: Option?, bestScore = Int.min
                for o in game.placements(type) {
                    let v = game.scoreParts(type, o.cells).sum
                    if v > bestScore { bestScore = v; best = o }
                }
                let r = game.build(best!.cells)
                XCTAssertEqual(r.type, move.t, "seed \(f.seed) move \(n) type")
                XCTAssertEqual(best!.cells, move.c, "seed \(f.seed) move \(n) cells")
                XCTAssertEqual(r.points, move.p, "seed \(f.seed) move \(n) points")
                XCTAssertEqual(r.gain, move.g, "seed \(f.seed) move \(n) gain")
                XCTAssertEqual(r.trophies.map(\.rawValue), move.tr, "seed \(f.seed) move \(n) trophies")
            }
            XCTAssertTrue(game.over, "seed \(f.seed) should be over")
            XCTAssertEqual(game.total, f.total, "seed \(f.seed) total")
            XCTAssertEqual(game.away, f.away, "seed \(f.seed) away")
            XCTAssertEqual(game.pieces.indices.map(game.pieceScore), f.scores, "seed \(f.seed) final scores")
        }
    }
}
