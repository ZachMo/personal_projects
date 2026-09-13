import SwiftUI

/// The three screens of the web version, swapped the same way: one at a time,
/// no navigation chrome.
struct RootView: View {
    enum Screen: Equatable {
        case home
        case settings
        case play(GameID)
    }

    @State private var screen: Screen = Self.launchScreen

    /// `-autostart dino` drops straight into a game, so a build can be checked
    /// on a simulator without anyone tapping through the menu.
    private static var launchScreen: Screen {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-autostart"), i + 1 < args.count,
           let id = GameID(rawValue: args[i + 1]) {
            return .play(id)
        }
        #endif
        return .home
    }

    var body: some View {
        ZStack {
            Palette.bg.ignoresSafeArea()

            switch screen {
            case .home:
                HomeView(
                    openSettings: { screen = .settings },
                    play: { screen = .play($0) }
                )
                .transition(.opacity)

            case .settings:
                SettingsView(back: { screen = .home })
                    .transition(.opacity)

            case .play(let id):
                PlayView(id: id, quit: { screen = .home })
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.18), value: screen)
    }
}
