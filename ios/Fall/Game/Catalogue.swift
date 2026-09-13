import Foundation

enum GameID: String, CaseIterable, Identifiable, Equatable {
    case dino, fish, golf, ski
    var id: String { rawValue }
}

/// The `GAMES` list from the bottom of fall.html: what to show on a card, how to
/// word a best score, and whether the game is playable yet.
struct GameEntry: Identifiable {
    let id: GameID
    let title: String
    let soon: Bool
    let best: (Double) -> String
    let make: (() -> FallGame)?

    static let all: [GameEntry] = [
        GameEntry(
            id: .dino, title: DinoFall.title, soon: false,
            best: { $0 > 0 ? String(format: "Best %.1fs", $0) : "Never played" },
            make: { DinoFall() }
        ),
        GameEntry(
            id: .fish, title: "Fish Fall", soon: true,
            best: { $0 > 0 ? "Best \(Int($0)) points" : "Never played" },
            make: nil
        ),
        GameEntry(
            id: .golf, title: "Golf Fall", soon: true,
            best: { $0 > 0 ? "Best \(Int($0)) shots" : "Never played" },
            make: nil
        ),
        GameEntry(
            id: .ski, title: "Ski Fall", soon: true,
            best: { $0 > 0 ? "Best \(Int($0)) metres" : "Never played" },
            make: nil
        ),
    ]

    static func entry(_ id: GameID) -> GameEntry {
        all.first { $0.id == id } ?? all[0]
    }
}
