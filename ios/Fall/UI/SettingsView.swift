import SwiftUI

struct SettingsView: View {
    let back: () -> Void

    @State private var settings = Settings.shared
    @State private var confirmWipe = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                bar

                Group {
                    label("Steering")
                    Segmented(
                        options: ControlScheme.allCases.map { ($0, $0.label) },
                        selection: $settings.controls
                    )
                    Text(settings.controls.hint)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.muted)
                        .padding(.top, 10)
                }
                .padding(.bottom, 26)

                Group {
                    label("Tilt sensitivity")
                    Segmented(
                        options: TiltSensitivity.allCases.map { ($0, $0.label) },
                        selection: $settings.tilt
                    )
                    Button("Recentre tilt") { Input.shared.recentre() }
                        .buttonStyle(PanelButton())
                        .padding(.top, 10)
                }
                .padding(.bottom, 26)

                Group {
                    label("Feel")
                    Toggle_("Sound", $settings.sound)
                    Toggle_("Vibration", $settings.haptics)
                    Toggle_("Left-handed", $settings.lefty)
                }
                .padding(.bottom, 26)

                Group {
                    label("Scores")
                    Button("Erase every best score") { confirmWipe = true }
                        .buttonStyle(PanelButton(ghost: true))
                }
            }
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.top, 28)
            .padding(.bottom, 40)
        }
        .background(Palette.bg)
        .confirmationDialog("Erase every best score?", isPresented: $confirmWipe, titleVisibility: .visible) {
            Button("Erase", role: .destructive) { Best.wipe() }
            Button("Keep them", role: .cancel) {}
        }
    }

    private var bar: some View {
        HStack(spacing: 12) {
            Button(action: back) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.ink2)
                    .frame(width: 42, height: 42)
                    .background(Palette.panel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Palette.line)
                    )
            }
            .accessibilityLabel("Back")

            Text("Settings")
                .font(.system(size: 21, weight: .semibold))
                .kerning(-0.42)
            Spacer()
        }
        .padding(.bottom, 24)
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .kerning(1.2)
            .textCase(.uppercase)
            .foregroundStyle(Palette.muted)
            .padding(.bottom, 10)
    }

    @ViewBuilder
    private func Toggle_(_ title: String, _ value: Binding<Bool>) -> some View {
        HStack {
            Text(title).font(.system(size: 15))
            Spacer()
            Switch(isOn: value)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Palette.panel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Palette.line)
        )
        .padding(.bottom, 8)
    }
}

/// The `.seg` control: a row of buttons where one is pressed.
private struct Segmented<T: Hashable>: View {
    let options: [(T, String)]
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.0) { value, title in
                Button { selection = value } label: {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .foregroundStyle(selection == value ? Palette.onAccent : Palette.ink2)
                        .background(
                            selection == value ? Palette.accent : Color.clear,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                }
            }
        }
        .padding(5)
        .background(Palette.panel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Palette.line)
        )
    }
}

/// The pill switch from the CSS, rather than the stock iOS one, so the settings
/// screen still looks like the page it came from.
private struct Switch: View {
    @Binding var isOn: Bool

    var body: some View {
        Button { isOn.toggle() } label: {
            Capsule()
                .fill(isOn ? Palette.accent.opacity(0.25) : Palette.panel2)
                .overlay(Capsule().strokeBorder(isOn ? Palette.accent : Palette.line))
                .frame(width: 50, height: 30)
                .overlay(alignment: .leading) {
                    Circle()
                        .fill(isOn ? Palette.accent : Palette.muted)
                        .frame(width: 22, height: 22)
                        .offset(x: isOn ? 23 : 3)
                }
        }
        .animation(.easeOut(duration: 0.16), value: isOn)
    }
}

struct PanelButton: ButtonStyle {
    enum Kind { case panel, primary, ghost }

    var kind: Kind = .panel

    /// `PanelButton(ghost: true)` reads better at the call sites that want it.
    init(kind: Kind = .panel) { self.kind = kind }
    init(ghost: Bool) { self.kind = ghost ? .ghost : .panel }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                background(pressed: configuration.isPressed),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(border)
            )
    }

    private var foreground: Color {
        switch kind {
        case .panel:   return Palette.ink
        case .primary: return Palette.onAccent
        case .ghost:   return Palette.ink2
        }
    }

    private func background(pressed: Bool) -> Color {
        switch kind {
        case .panel:   return pressed ? Palette.panel2 : Palette.panel
        case .primary: return pressed ? Palette.accent.opacity(0.85) : Palette.accent
        case .ghost:   return .clear
        }
    }

    private var border: Color {
        switch kind {
        case .panel:   return Palette.line
        case .primary: return Palette.accent
        case .ghost:   return .clear
        }
    }
}
