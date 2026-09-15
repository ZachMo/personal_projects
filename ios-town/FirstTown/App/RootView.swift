import SwiftUI
import FirstTownCore

/// A placeholder until the board and the panels land: it proves the app links the rules.
struct RootView: View {
    @State private var game = Game(seed: 424242, player: "Zach")

    var body: some View {
        VStack(spacing: 8) {
            Text("First Town").font(.largeTitle.bold())
            Text("\(game.deck.count) buildings to place on \(Words.townName(game.player, game.namePick))")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.106, green: 0.141, blue: 0.133))
    }
}
