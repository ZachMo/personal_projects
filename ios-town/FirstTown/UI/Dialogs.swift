import SwiftUI
import FirstTownCore

/// The first thing a new town shows: a name, and the map it will be built on, behind.
struct IntroView: View {
    let town: Town
    @State private var name = ""
    @State private var rules = false
    @FocusState private var focused: Bool

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    Text("First Town").font(.system(size: 36, weight: .heavy)).kerning(-1.2).foregroundStyle(Palette.ink)
                    Text("Fit odd-shaped buildings onto the map. Good spots score more.")
                        .font(.system(size: 15)).foregroundStyle(Palette.ink2).multilineTextAlignment(.center)
                    TextField("", text: $name, prompt: Text("Your name").foregroundStyle(Palette.muted))
                        .font(.system(size: 17))
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.go)
                        .focused($focused)
                        .onSubmit(start)
                        .padding(14)
                        .background(Palette.card2, in: RoundedRectangle(cornerRadius: 14))
                        .overlay { RoundedRectangle(cornerRadius: 14).stroke(focused ? Palette.accent : .clear, lineWidth: 2) }
                        .foregroundStyle(Palette.ink)
                    Button("Start", action: start)
                        .buttonStyle(PrimaryButtonStyle(wide: true))
                        .disabled(trimmed.isEmpty)
                    Button(rules ? "Hide how to play" : "How to play") { withAnimation(.snappy) { rules.toggle() } }
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(Palette.ink2).padding(.top, 2)
                    if rules { HowToPlay().transition(.opacity) }
                }
                .padding(24)
                .frame(maxWidth: 380)
                .background {
                    RoundedRectangle(cornerRadius: 24).fill(Palette.card).shadow(color: .black.opacity(0.35), radius: 20, y: 12)
                }
                .padding(20)
                .frame(maxWidth: .infinity, minHeight: 700)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private func start() {
        guard !trimmed.isEmpty else { return }
        focused = false
        town.found(player: String(trimmed.prefix(14)))
    }
}

/// The end of a game: the score, the best so far, trophies and the best buildings.
struct SummaryView: View {
    let town: Town

    var body: some View {
        let g = town.game, me = g.total, best = town.bestBefore
        let top = g.pieces.indices.map { (k: $0, v: g.pieceScore($0)) }.sorted { $0.v > $1.v }.prefix(3)
        let won = Trophy.allCases.filter { (g.trophies[$0] ?? 0) > 0 }
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(spacing: 4) {
                        Text("\(Words.townName(g.player, g.namePick)) is done").font(.system(size: 21, weight: .bold))
                        Text("\(me)").font(.system(size: 58, weight: .heavy, design: .rounded)).monospacedDigit()
                        Text(me >= best ? "Your best town yet" : "Your best is \(best)")
                            .font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.muted)
                    }
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 12)

                    row("Buildings", "\(g.boardScore)")
                    if g.away.isEmpty { row("Every building fit", "+\(Game.allFitBonus)") }
                    else { row("\(g.away.count) turned away", "−\(g.away.count * Game.awayPenalty)") }

                    if !won.isEmpty {
                        label("Trophies")
                        FlowLayout {
                            ForEach(won, id: \.self) { t in
                                let n = g.trophies[t] ?? 0
                                Text(t.title.replacingOccurrences(of: "!", with: "") + (n > 1 ? " ×\(n)" : ""))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(t.good ? Color(hex: 0x7a5608) : Palette.bad)
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(t.good ? Color(hex: 0xf6e7b4) : Palette.badBg, in: Capsule())
                            }
                        }
                    }

                    label("Best buildings")
                    ForEach(Array(top), id: \.k) { x in row(Library[g.pieces[x.k].type].name, Words.signed(x.v)) }

                    HStack(spacing: 8) {
                        Button("Look at the town") { town.summaryOpen = false }.buttonStyle(SecondaryButtonStyle(wide: true))
                        Button("New town") { town.openIntro() }.buttonStyle(PrimaryButtonStyle(wide: true))
                    }
                    .padding(.top, 16)
                }
                .padding(22)
                .frame(maxWidth: 380)
                .background {
                    RoundedRectangle(cornerRadius: 24).fill(Palette.card).shadow(color: .black.opacity(0.35), radius: 20, y: 12)
                }
                .padding(20)
                .frame(maxWidth: .infinity, minHeight: 700)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private func row(_ what: String, _ value: String) -> some View {
        HStack {
            Text(what).foregroundStyle(Palette.ink2)
            Spacer()
            Text(value).bold().monospacedDigit().foregroundStyle(Palette.ink)
        }
        .font(.system(size: 15))
        .padding(.vertical, 8)
        .overlay(alignment: .top) { Rectangle().fill(Palette.line).frame(height: 1) }
    }

    private func label(_ s: String) -> some View {
        Text(s.uppercased()).font(.system(size: 11, weight: .heavy)).kerning(1).foregroundStyle(Palette.muted)
            .padding(.top, 14).padding(.bottom, 6)
    }
}
