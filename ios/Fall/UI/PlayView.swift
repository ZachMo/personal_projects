import SpriteKit
import SwiftUI

struct PlayView: View {
    let id: GameID
    let quit: () -> Void

    @State private var scene = GameScene()
    @State private var game: FallGame?
    @State private var host = GameHost.shared
    @State private var settings = Settings.shared
    @Environment(\.scenePhase) private var phase

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            SpriteView(scene: scene, preferredFramesPerSecond: 60)
                .ignoresSafeArea()

            hud
            if showPads { PadBar(lefty: settings.lefty) }
            if let overlay = host.overlay { VeilView(overlay: overlay) }
        }
        .statusBarHidden()
        .onAppear(perform: start)
        .onDisappear(perform: stop)
        .onChange(of: phase) { _, new in
            if new != .active { scene.pauseRun() }
        }
        .onChange(of: settings.controls) { _, new in
            new == .tilt ? Input.shared.startMotion() : Input.shared.stopMotion()
        }
    }

    private var light: Bool { game?.light ?? false }
    private var showPads: Bool {
        settings.controls == .buttons && (game?.usesPads ?? true) && !host.overlayShowing
    }

    // MARK: - Wiring

    private func start() {
        host.goHome = quit
        let entry = GameEntry.entry(id)
        guard let made = entry.make?() else { quit(); return }
        game = made
        scene.scaleMode = .resizeFill
        scene.run(made)
        if settings.controls == .tilt { Input.shared.startMotion() }
    }

    private func stop() {
        Input.shared.stopMotion()
        Input.shared.reset()
        scene.stop()
        host.hideOverlay()
        host.goHome = {}
    }

    // MARK: - HUD

    private var hud: some View {
        VStack {
            HStack(alignment: .top, spacing: 10) {
                Button(action: quit) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Palette.ink2)
                        .frame(width: 42, height: 42)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.14))
                        )
                }
                .accessibilityLabel("Back")

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(host.hudBig)
                        .font(.system(size: 24, weight: .heavy))
                        .kerning(-0.48)
                        .monospacedDigit()
                    Text(host.hudSub)
                        .font(.system(size: 11, weight: .semibold))
                        .kerning(0.9)
                        .textCase(.uppercase)
                        .monospacedDigit()
                        .opacity(light ? 0.62 : 0.7)
                }
                // Golf and Ski are played over sky and snow, where white is nothing.
                .foregroundStyle(light ? Color(hex: 0x16232E) : .white)
                .shadow(
                    color: light ? .white.opacity(0.9) : .black.opacity(0.6),
                    radius: 3, y: 1
                )
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            Spacer()
        }
        .allowsHitTesting(!host.overlayShowing)
    }
}

// MARK: - Pads

/// Two pads at the bottom, which swap sides for left-handers.
private struct PadBar: View {
    let lefty: Bool

    var body: some View {
        VStack {
            Spacer()
            HStack {
                pad(dir: -1, symbol: "arrowtriangle.left.fill", label: "Left")
                Spacer()
                pad(dir: 1, symbol: "arrowtriangle.right.fill", label: "Right")
            }
            .environment(\.layoutDirection, lefty ? .rightToLeft : .leftToRight)
            .padding(.horizontal, 14)
            .padding(.bottom, 18)
        }
    }

    private func pad(dir: CGFloat, symbol: String, label: String) -> some View {
        PadButton(dir: dir, symbol: symbol)
            .accessibilityLabel(label)
    }
}

private struct PadButton: View {
    let dir: CGFloat
    let symbol: String
    @State private var down = false

    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(down ? Palette.accent.opacity(0.3) : Color.white.opacity(0.09))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.16))
            )
            .overlay(
                Image(systemName: symbol)
                    .font(.system(size: 22))
                    .foregroundStyle(Color.white.opacity(0.85))
            )
            .frame(width: 120, height: 74)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !down else { return }
                        down = true
                        Input.shared.padAxis = dir
                    }
                    .onEnded { _ in
                        down = false
                        if Input.shared.padAxis == dir { Input.shared.padAxis = 0 }
                    }
            )
    }
}
