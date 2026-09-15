import SwiftUI
import FirstTownCore

/// The rules, in five lines.
struct HowToPlay: View {
    private let lines: [(String, String)] = [
        ("Build:", "drag a building onto open land and press Build. Tap it to see how it scores."),
        ("On", "is the land under a building. Beside is open land that shares a side with it. Next to is a building that shares a side with it."),
        ("Land bonuses are kept.", "Covering land later doesn't take away points a building already earned from it."),
        ("Neighbour bonuses grow.", "A building gains whenever you add a neighbour it likes."),
        ("No room", "for a building: −\(Game.awayPenalty). Fit them all: +\(Game.allFitBonus)."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    RoundedRectangle(cornerRadius: 3).fill(Palette.accent).frame(width: 8, height: 8)
                    (Text(line.0).bold().foregroundColor(Palette.ink) + Text(" " + line.1).foregroundColor(Palette.ink2))
                        .font(.system(size: 14))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 8)
                .overlay(alignment: .top) { Rectangle().fill(Palette.line).frame(height: 1) }
            }
        }
    }
}

/// Every building's score as it stands, part by part. Tap one to find it on the map.
struct ScoreSheet: View {
    let town: Town
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let g = town.game
        let rows = g.pieces.indices.map { (k: $0, parts: g.pieceParts($0)) }.sorted { $0.parts.sum > $1.parts.sum }
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Score \(g.total)").font(.system(size: 21, weight: .bold)).foregroundStyle(Palette.ink).padding(.bottom, 10)
                if rows.isEmpty { Text("Nothing built yet.").foregroundStyle(Palette.ink2) }
                ForEach(rows, id: \.k) { row in
                    let type = g.pieces[row.k].type
                    Button {
                        dismiss()
                        town.select(g.pieces[row.k].cells[0])
                    } label: {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(Library[type].name).font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.ink)
                                Text(row.parts.filter { $0.v != 0 }.map { "\(Words.part(type, $0)) \(Words.signed($0.v))" }.joined(separator: " · "))
                                    .font(.system(size: 12)).foregroundStyle(Palette.muted).multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Text(Words.signed(row.parts.sum)).font(.system(size: 15, weight: .bold)).monospacedDigit().foregroundStyle(Palette.ink)
                        }
                        .padding(.vertical, 9)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider().overlay(Palette.line)
                }
                if !g.away.isEmpty { tally("\(g.away.count) turned away", "−\(g.away.count * Game.awayPenalty)") }
                if g.over && g.away.isEmpty { tally("Every building fit", "+\(Game.allFitBonus)") }
            }
            .padding(20)
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Palette.card)
    }

    private func tally(_ what: String, _ value: String) -> some View {
        HStack {
            Text(what).foregroundStyle(Palette.ink2)
            Spacer()
            Text(value).bold().foregroundStyle(Palette.ink)
        }
        .font(.system(size: 15))
        .padding(.vertical, 9)
    }
}

/// What is left in the deck: how many of each, and how each one scores.
struct DeckSheet: View {
    let town: Town

    var body: some View {
        let g = town.game, left = Array(g.remaining)
        let count = Dictionary(left.map { ($0, 1) }, uniquingKeysWith: +)
        let kinds = Library.all.filter { count[$0.id] != nil }
        let squares = left.reduce(0) { $0 + Shapes.table[Library[$1].shape]!.count }
        let open = (0..<Board.count).filter { g.map[$0] != .water && g.owner[$0] < 0 }.count
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Still to come").font(.system(size: 21, weight: .bold)).foregroundStyle(Palette.ink)
                Text(left.isEmpty ? "Nothing left to place." : "\(left.count) buildings need \(squares) squares. You have \(open) open squares left.")
                    .font(.system(size: 14)).foregroundStyle(Palette.ink2)
                ForEach(kinds) { d in
                    HStack(alignment: .top, spacing: 12) {
                        ShapeIcon(type: d.id, box: 36)
                            .frame(width: 48, height: 48)
                            .background(Palette.card, in: RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Text(d.name).font(.system(size: 15, weight: .bold)).foregroundStyle(Palette.ink)
                                Text("×\(count[d.id]!)").font(.system(size: 12, weight: .heavy)).foregroundStyle(Palette.ink2)
                                    .padding(.horizontal, 7).padding(.vertical, 1).background(Palette.card, in: Capsule())
                                CategoryChip(category: d.category)
                            }
                            RulesList(type: d.id, compact: true)
                        }
                    }
                    .padding(10)
                    .background(Palette.card2, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(20)
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Palette.card)
    }
}

/// How to play, and a way to start again.
struct MenuSheet: View {
    let town: Town
    @Environment(\.dismiss) private var dismiss
    @State private var confirming = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("How to play").font(.system(size: 21, weight: .bold)).foregroundStyle(Palette.ink)
                HowToPlay()
                HStack(spacing: 8) {
                    Button("Close") { dismiss() }.buttonStyle(SecondaryButtonStyle(wide: true))
                    Button(confirming ? "Yes, start over" : "New town") {
                        if !town.game.over && !town.game.pieces.isEmpty && !confirming { confirming = true; return }
                        dismiss()
                        town.openIntro()
                    }
                    .buttonStyle(PrimaryButtonStyle(wide: true))
                }
                .padding(.top, 6)
                if confirming {
                    Text("This town will be lost.").font(.system(size: 13)).foregroundStyle(Palette.bad)
                }
            }
            .padding(20)
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Palette.card)
    }
}
