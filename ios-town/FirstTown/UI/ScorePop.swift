import SwiftUI
import FirstTownCore

/// The new building's score, big, over its roof, with any trophies under it. It fades away on its own.
struct ScorePop: View {
    let result: BuildResult
    /// The top middle of the new building, in the board's space.
    let anchor: CGPoint
    let boardWidth: CGFloat

    @State private var shown = 0
    @State private var appeared = false
    @State private var leaving = false

    private var pills: [Trophy] {
        Array(result.trophies.filter(\.good).prefix(2)) + Array(result.trophies.filter { !$0.good }.prefix(1))
    }

    private var colour: Color {
        if result.gain >= Trophy.jackpotPoints { return Color(hex: 0xffd45c) }
        if result.gain >= Trophy.greatPoints { return Color(hex: 0xa9f2b8) }
        if result.points <= 0 { return Color(hex: 0xffa38f) }
        return .white
    }

    var body: some View {
        let gold = result.gain >= Trophy.jackpotPoints
        let height = CGFloat(gold ? 56 : 46) + CGFloat(pills.count) * 36
        let bottom = max(60 + CGFloat(pills.count) * 34, anchor.y)
        VStack(spacing: 6) {
            Text(Words.signed(shown))
                .font(.system(size: gold ? 54 : 43, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(colour)
                .contentTransition(.numericText(value: Double(shown)))
                .shadow(color: Palette.table, radius: 0, x: 2, y: 0)
                .shadow(color: Palette.table, radius: 0, x: -2, y: 0)
                .shadow(color: Palette.table, radius: 0, x: 0, y: 2)
                .shadow(color: Palette.table, radius: 0, x: 0, y: -2)
                .shadow(color: .black.opacity(0.45), radius: 11, y: 8)
                .scaleEffect(appeared ? 1 : 0.4)
            ForEach(Array(pills.enumerated()), id: \.offset) { n, trophy in
                TrophyPill(trophy: trophy)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.spring(response: 0.45, dampingFraction: 0.6).delay(0.25 + Double(n) * 0.15), value: appeared)
            }
        }
        .fixedSize()
        .opacity(leaving ? 0 : 1)
        .offset(y: leaving ? -26 : 0)
        .position(x: min(max(anchor.x, 100), boardWidth - 100), y: bottom - height / 2)
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { appeared = true }
            withAnimation(.easeOut(duration: 0.5)) { shown = result.points }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.3 + 0.6 * Double(pills.count)))
            withAnimation(.easeIn(duration: 0.4)) { leaving = true }
        }
    }
}

struct TrophyPill: View {
    let trophy: Trophy

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: trophy.good ? "trophy.fill" : "arrow.down.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(trophy.good ? Color(hex: 0xffd45c) : Color(hex: 0xff9f8a))
            Text(trophy.title).font(.system(size: 14, weight: .heavy))
        }
        .foregroundStyle(trophy.good ? Color(hex: 0xfff2c2) : Color(hex: 0xffddd4))
        .padding(.leading, 9).padding(.trailing, 13).padding(.vertical, 6)
        .background {
            Capsule().fill(LinearGradient(colors: trophy.good ? [Color(hex: 0x3a2d08), Color(hex: 0x735610)] : [Color(hex: 0x3b1812), Color(hex: 0x72291d)],
                                          startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .shadow(color: .black.opacity(0.35), radius: 10, y: 8)
    }
}
