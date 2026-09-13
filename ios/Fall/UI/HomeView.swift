import SwiftUI

struct HomeView: View {
    let openSettings: () -> Void
    let play: (GameID) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                Text("Four small games for a phone, played with one thumb.")
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.ink2)
                    .frame(maxWidth: 300, alignment: .leading)
                    .padding(.top, 10)
                    .padding(.bottom, 26)

                VStack(spacing: 14) {
                    ForEach(GameEntry.all) { entry in
                        GameCard(entry: entry) { play(entry.id) }
                    }
                }
            }
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.top, 28)
            .padding(.bottom, 40)
        }
        .background(Palette.bg)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            HStack(spacing: 0) {
                Text("Fall")
                Text(".").foregroundStyle(Palette.accent)
            }
            .font(.system(size: 52, weight: .heavy))
            .kerning(-2.2)

            Spacer()

            Button(action: openSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(Palette.ink2)
                    .frame(width: 42, height: 42)
                    .background(Palette.panel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Palette.line)
                    )
            }
            .accessibilityLabel("Settings")
        }
    }
}

private struct GameCard: View {
    let entry: GameEntry
    let tap: () -> Void

    var body: some View {
        Button(action: tap) {
            HStack(spacing: 16) {
                GameArt(id: entry.id)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(entry.title)
                            .font(.system(size: 18, weight: .bold))
                            .kerning(-0.36)
                        Tag(text: entry.soon ? "Soon" : "Beta", dim: entry.soon)
                    }
                    Text(entry.best(Best.get(entry.id.rawValue)))
                        .font(.system(size: 12, weight: .semibold))
                        .kerning(0.7)
                        .textCase(.uppercase)
                        .foregroundStyle(Palette.muted)
                        .monospacedDigit()
                        .padding(.top, 4)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(Palette.panel, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Palette.line)
            )
            .opacity(entry.soon ? 0.55 : 1)
        }
        .buttonStyle(PressStyle(enabled: !entry.soon))
        .disabled(entry.soon)
    }
}

private struct Tag: View {
    let text: String
    let dim: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 9.5, weight: .bold))
            .kerning(1)
            .textCase(.uppercase)
            .foregroundStyle(dim ? Palette.ink2 : Palette.accent)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(
                (dim ? Palette.ink2 : Palette.accent).opacity(0.14),
                in: Capsule()
            )
    }
}

/// The `.card:active { transform: scale(.985) }` rule, kept.
struct PressStyle: ButtonStyle {
    var enabled = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(enabled && configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
