import SwiftUI

/// The warm orange button: Build, Start, New town.
struct PrimaryButtonStyle: ButtonStyle {
    var wide = false
    @Environment(\.isEnabled) private var enabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(enabled ? Color.white : Color(hex: 0x8e897e))
            .frame(maxWidth: wide ? .infinity : nil)
            .frame(height: 46)
            .padding(.horizontal, 22)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(enabled ? Palette.accentDeep : Color(hex: 0xdcd6ca))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(enabled ? Palette.accent : Color(hex: 0xdcd6ca))
                            .padding(.bottom, enabled ? 3 : 0)
                    }
            }
            .offset(y: configuration.isPressed ? 1 : 0)
    }
}

/// The quiet button on a light card: Close, Summary, Look at the town.
struct SecondaryButtonStyle: ButtonStyle {
    var wide = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: wide ? .infinity : nil)
            .frame(height: 46)
            .padding(.horizontal, 16)
            .background(Palette.card2, in: RoundedRectangle(cornerRadius: 14))
            .offset(y: configuration.isPressed ? 1 : 0)
    }
}

/// Lays its children out in rows, wrapping to a new row when one is full. For trophy chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews)
        let height = rows.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(0, rows.count - 1))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews) {
            var x = bounds.minX
            for i in row.items {
                let size = subviews[i].sizeThatFits(.unspecified)
                subviews[i].place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private func arrange(width: CGFloat, _ subviews: Subviews) -> [(items: [Int], width: CGFloat, height: CGFloat)] {
        var rows: [(items: [Int], width: CGFloat, height: CGFloat)] = []
        var current: (items: [Int], width: CGFloat, height: CGFloat) = ([], 0, 0)
        for i in subviews.indices {
            let size = subviews[i].sizeThatFits(.unspecified)
            let needed = current.items.isEmpty ? size.width : current.width + spacing + size.width
            if needed > width && !current.items.isEmpty {
                rows.append(current)
                current = ([i], size.width, size.height)
            } else {
                current = (current.items + [i], needed, max(current.height, size.height))
            }
        }
        if !current.items.isEmpty { rows.append(current) }
        return rows
    }
}
