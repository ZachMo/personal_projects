import SwiftUI
import FirstTownCore

/// The game screen: the town bar, the map, and the slim panel with the building in hand.
struct PlayView: View {
    let town: Town
    @Environment(\.scenePhase) private var phase

    var body: some View {
        VStack(spacing: 0) {
            hud
            BoardView(town: town)
            panel
        }
        .background {
            RadialGradient(colors: [Palette.tableGlow, Palette.table], center: UnitPoint(x: 0.5, y: 0.42), startRadius: 0, endRadius: 620)
                .ignoresSafeArea()
        }
        .onChange(of: phase) { _, now in if now != .active { town.save() } }
    }

    // MARK: - Town bar

    private var subtitle: String {
        let g = town.game
        if g.over { return "The town is done" }
        return "\(g.pieces.count) built" + (g.away.isEmpty ? "" : " · \(g.away.count) turned away")
    }

    private var hud: some View {
        HStack(spacing: 8) {
            Button {} label: {
                Image(systemName: "line.3.horizontal").font(.system(size: 17, weight: .semibold)).frame(width: 44, height: 44)
            }
            .background(Palette.glass, in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 1) {
                Text(Words.townName(town.game.player, town.game.namePick)).font(.system(size: 16, weight: .bold)).lineLimit(1)
                Text(subtitle).font(.system(size: 11.5)).foregroundStyle(Palette.hudSub).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)

            stat(town.game.total, "Points")
            stat(town.game.remaining.count, "To come")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 2)
    }

    private func stat(_ value: Int, _ label: String) -> some View {
        VStack(spacing: 0) {
            Text("\(value)").font(.system(size: 17, weight: .heavy)).monospacedDigit().contentTransition(.numericText())
            Text(label.uppercased()).font(.system(size: 9, weight: .bold)).kerning(0.9).foregroundStyle(Palette.hudSub)
        }
        .frame(minWidth: 62, minHeight: 44)
        .padding(.horizontal, 8)
        .background(Palette.glass, in: RoundedRectangle(cornerRadius: 14))
        .animation(.snappy, value: value)
    }

    // MARK: - Panel

    private var panel: some View {
        HStack(spacing: 8) {
            if let type = town.game.current {
                Button { town.toggleRules() } label: { inHand(type) }
                    .buttonStyle(.plain)
                ToolButton(symbol: "arrow.clockwise", label: "Turn") { town.turn() }
                ToolButton(symbol: "arrow.left.and.right.righttriangle.left.righttriangle.right", label: "Flip") { town.flip() }
                Button("Build") { town.build() }
                    .buttonStyle(BuildButtonStyle())
                    .disabled(!town.canBuild)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(town.game.total)").font(.system(size: 27, weight: .heavy)).foregroundStyle(Palette.ink)
                    Text("points").font(.system(size: 13)).foregroundStyle(Palette.ink2)
                }
                .padding(.leading, 6)
                Spacer()
            }
        }
        .padding(8)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.34), radius: 17, y: 12)
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    private func inHand(_ type: String) -> some View {
        HStack(spacing: 10) {
            ShapeIcon(type: type, rot: town.ghost?.rot ?? 0, flip: town.ghost?.flip ?? false, box: 34)
                .frame(width: 44, height: 44)
                .background(Palette.card2, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(Library[type].name).font(.system(size: 15.5, weight: .bold)).foregroundStyle(Palette.ink).lineLimit(1)
                HStack(spacing: 10) {
                    Text(town.rulesOpen ? "Scoring ▴" : "Scoring ▾")
                    if let next = town.game.upcoming {
                        HStack(spacing: 4) { Text("Next"); ShapeIcon(type: next, box: 15) }
                    }
                }
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(Palette.muted)
                .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }
}

private struct ToolButton: View {
    let symbol: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .frame(width: 44, height: 44)
                .background(Palette.card2, in: RoundedRectangle(cornerRadius: 14))
        }
        .accessibilityLabel(label)
    }
}

private struct BuildButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(enabled ? Color.white : Color(hex: 0x8e897e))
            .frame(height: 44)
            .padding(.horizontal, 22)
            .background {
                RoundedRectangle(cornerRadius: 14).fill(enabled ? Palette.accentDeep : Color(hex: 0xdcd6ca))
                    .overlay { RoundedRectangle(cornerRadius: 14).fill(enabled ? Palette.accent : Color(hex: 0xdcd6ca)).padding(.bottom, enabled ? 3 : 0) }
            }
            .offset(y: configuration.isPressed ? 1 : 0)
    }
}
