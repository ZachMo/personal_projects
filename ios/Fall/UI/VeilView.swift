import SwiftUI

/// The `.veil` overlay: a blurred sheet with a small panel on it. Every game
/// uses this for its intro, its pause and its ending.
///
/// The panel sits in the middle of the screen and only scrolls when it cannot
/// fit, which is what `margin: auto 0` inside a scrolling flex box did.
struct VeilView: View {
    let overlay: Overlay

    #if DEBUG
    /// `-autoplay` presses the first Start for you, once, so a simulator run can
    /// be photographed mid-game. It fires a single time, leaving the ending
    /// overlay alone.
    private static var autoplayed = false
    private var shouldAutoplay: Bool {
        !Self.autoplayed && ProcessInfo.processInfo.arguments.contains("-autoplay")
    }
    #endif

    var body: some View {
        ZStack {
            Color(hex: 0x090B10, alpha: 0.78)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            GeometryReader { proxy in
                ScrollView {
                    box
                        .frame(maxWidth: 340)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 16)
                        .frame(minHeight: proxy.size.height)
                }
            }
        }
        #if DEBUG
        .onAppear {
            guard shouldAutoplay,
                  let start = overlay.actions.first(where: { $0.kind == .primary })
            else { return }
            Self.autoplayed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: start.run)
        }
        #endif
    }

    private var box: some View {
        VStack(spacing: 0) {
            Text(overlay.title)
                .font(.system(size: 22, weight: .semibold))
                .kerning(-0.44)
                .padding(.bottom, 6)

            if let why = overlay.why {
                Text(why)
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.ink2)
                    .padding(.bottom, 18)
            }

            if let score = overlay.score {
                Text(score)
                    .font(.system(size: 48, weight: .heavy))
                    .kerning(-1.44)
                    .foregroundStyle(Palette.accent)
                    .monospacedDigit()
                    .padding(.top, 4)
                    .padding(.bottom, 2)
            }

            if let best = overlay.best {
                Text(best)
                    .font(.system(size: 12, weight: .semibold))
                    .kerning(0.7)
                    .textCase(.uppercase)
                    .foregroundStyle(Palette.muted)
                    .monospacedDigit()
                    .padding(.bottom, 20)
            }

            VStack(spacing: 8) {
                ForEach(overlay.actions) { action in
                    Button(action.label, action: action.run)
                        .buttonStyle(PanelButton(kind: action.kind == .primary ? .primary : .ghost))
                }
            }
        }
        .multilineTextAlignment(.center)
        .padding(.vertical, 24)
        .padding(.horizontal, 22)
        .background(Palette.panel, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Palette.line)
        )
    }
}
