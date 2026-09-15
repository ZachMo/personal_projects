import SwiftUI
import FirstTownCore

enum LandColour {
    static func of(_ t: Terrain) -> Color {
        switch t {
        case .grass: Color(hex: 0xa5c884)
        case .forest: Color(hex: 0x5b9a58)
        case .ore: Color(hex: 0x9a9285)
        case .wheat: Color(hex: 0xe2bf5c)
        case .herd: Color(hex: 0xc4a37c)
        case .water: Color(hex: 0x62abc9)
        }
    }
}

/// A small picture of what a rule counts: land under a building, land around it, or a building beside it.
struct RuleIcon: View {
    let rule: Rule

    var body: some View {
        Canvas { ctx, size in
            let k = size.width / 20
            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> Path {
                Path(roundedRect: CGRect(x: x * k, y: y * k, width: w * k, height: h * k), cornerRadius: r * k)
            }
            let white = Color.white, edge = Color(hex: 0xc9c2b4)
            let cat = rule.cats.first.map(Palette.category) ?? Color(hex: 0x9aa19c)
            switch rule.kind {
            case .on:
                ctx.fill(rect(1, 1, 18, 18, 4), with: .color(LandColour.of(rule.terrain!)))
                var house = Path()
                house.move(to: CGPoint(x: 5.5 * k, y: 15.5 * k)); house.addLine(to: CGPoint(x: 5.5 * k, y: 9.8 * k))
                house.addLine(to: CGPoint(x: 10 * k, y: 5.8 * k)); house.addLine(to: CGPoint(x: 14.5 * k, y: 9.8 * k))
                house.addLine(to: CGPoint(x: 14.5 * k, y: 15.5 * k)); house.closeSubpath()
                ctx.fill(house, with: .color(white))
            case .by:
                ctx.fill(rect(1, 1, 18, 18, 4), with: .color(LandColour.of(rule.terrain!)))
                ctx.fill(rect(6, 6, 8, 8, 2), with: .color(white))
            case .near:
                ctx.fill(rect(1.5, 5.5, 8, 9, 2.5), with: .color(white))
                ctx.stroke(rect(1.5, 5.5, 8, 9, 2.5), with: .color(edge), lineWidth: k)
                ctx.fill(rect(10.5, 5, 8.5, 10, 2.5), with: .color(cat))
            case .edge:
                ctx.fill(rect(5, 3, 13, 14, 3), with: .color(white))
                ctx.stroke(rect(5, 3, 13, 14, 3), with: .color(edge), lineWidth: k)
                ctx.fill(rect(1, 1, 3, 18, 1.5), with: .color(Palette.ink2))
            case .town:
                for a in 0..<3 { for b in 0..<3 { ctx.fill(rect(1 + CGFloat(a) * 6.3, 1 + CGFloat(b) * 6.3, 5, 5, 1.2), with: .color(Color(hex: 0xd8d2c5))) } }
                ctx.fill(rect(13.6, 1, 5, 5, 1.2), with: .color(cat))
                ctx.fill(rect(1, 13.6, 5, 5, 1.2), with: .color(cat))
            case .without:
                ctx.fill(rect(3, 3, 14, 14, 3.5), with: .color(cat.opacity(0.45)))
                var slash = Path()
                slash.move(to: CGPoint(x: 3 * k, y: 17 * k)); slash.addLine(to: CGPoint(x: 17 * k, y: 3 * k))
                ctx.stroke(slash, with: .color(Palette.bad), style: StrokeStyle(lineWidth: 2.6 * k, lineCap: .round))
            case .variety:
                for (i, c) in [FirstTownCore.Category.home, .shop, .civic].enumerated() {
                    ctx.fill(rect(1 + CGFloat(i) * 6.25, 6, 5.5, 8, 1.5), with: .color(Palette.category(c)))
                }
            }
        }
        .frame(width: 18, height: 18)
    }
}

struct CategoryChip: View {
    let category: FirstTownCore.Category

    var body: some View {
        Text(category.name.uppercased())
            .font(.system(size: 9.5, weight: .heavy)).kerning(0.9)
            .foregroundStyle(.white)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Palette.category(category), in: Capsule())
    }
}

/// One line of scoring: the points in a badge, a small picture, and the words.
struct RuleRow: View {
    enum Tone { case good, bad, base, zero }

    let points: Int
    let text: String
    var tone: Tone
    var rule: Rule?
    var compact = false

    static func tone(_ v: Int) -> Tone { v < 0 ? .bad : .good }

    var body: some View {
        HStack(spacing: 9) {
            Text(Words.signed(points))
                .font(.system(size: compact ? 11.5 : 13, weight: .heavy)).monospacedDigit()
                .foregroundStyle(foreground)
                .frame(minWidth: compact ? 30 : 36)
                .padding(.vertical, 2).padding(.horizontal, 5)
                .background(background, in: RoundedRectangle(cornerRadius: 8))
            Group {
                if let rule { RuleIcon(rule: rule) } else { Color.clear.frame(width: 18, height: 18) }
            }
            Text(text)
                .font(.system(size: compact ? 12.5 : 14))
                .foregroundStyle(tone == .zero ? Palette.muted : Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var foreground: Color {
        switch tone {
        case .good: Palette.good
        case .bad: Palette.bad
        case .base: .white
        case .zero: Palette.muted
        }
    }

    private var background: Color {
        switch tone {
        case .good: Palette.goodBg
        case .bad: Palette.badBg
        case .base: Palette.ink
        case .zero: Palette.card2
        }
    }
}

/// A building's base points and rules, as its scoring card shows them.
struct RulesList: View {
    let type: String
    var compact = false

    var body: some View {
        let d = Library[type]
        VStack(alignment: .leading, spacing: compact ? 3 : 5) {
            RuleRow(points: d.base, text: "base points", tone: .base, compact: compact)
            ForEach(Array(d.rules.enumerated()), id: \.offset) { _, r in
                RuleRow(points: r.points, text: Words.rule(r), tone: RuleRow.tone(r.points), rule: r, compact: compact)
            }
        }
    }
}

/// The card over the map: the scoring for the building in hand, a building's score, or what a square of land is good for.
struct InfoCard: View {
    let town: Town

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            content
        }
        .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 12)
        .frame(maxWidth: 420, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 20).fill(Palette.card).shadow(color: .black.opacity(0.34), radius: 17, y: 12)
        }
        .overlay(alignment: .topTrailing) {
            Button { town.closeInfo() } label: {
                Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundStyle(Palette.ink2).frame(width: 34, height: 34)
            }
            .padding(6)
        }
    }

    @ViewBuilder private var content: some View {
        let g = town.game
        if town.rulesOpen, let type = g.current {
            kind("Scoring", Library[type].category)
            title(Library[type].name)
            Text(Library[type].blurb).font(.system(size: 13.5)).foregroundStyle(Palette.ink2).padding(.bottom, 4)
            RulesList(type: type)
        } else if town.selection >= 0 {
            let i = town.selection
            if g.owner[i] >= 0 { building(g, g.owner[i]) } else { land(g.map[i]) }
        }
    }

    private func kind(_ word: String, _ category: FirstTownCore.Category? = nil) -> some View {
        HStack(spacing: 6) {
            Text(word.uppercased()).font(.system(size: 10.5, weight: .heavy)).kerning(1).foregroundStyle(Palette.muted)
            if let category { CategoryChip(category: category) }
        }
        .padding(.trailing, 36)
    }

    private func title(_ s: String, score: Int? = nil) -> some View {
        HStack(spacing: 8) {
            Text(s).font(.system(size: 18, weight: .bold)).foregroundStyle(Palette.ink)
            if let score {
                Text(Words.signed(score)).font(.system(size: 13, weight: .heavy)).foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 2).background(Palette.ink, in: Capsule())
            }
        }
    }

    @ViewBuilder private func building(_ g: Game, _ k: Int) -> some View {
        let p = g.pieces[k], d = Library[p.type], parts = g.pieceParts(k)
        kind("Built", d.category)
        title(d.name, score: parts.sum).padding(.bottom, 4)
        VStack(alignment: .leading, spacing: 5) {
            ForEach(Array(parts.enumerated()), id: \.offset) { _, q in
                let r: Rule? = q.rule >= 0 ? d.rules[q.rule] : nil
                let each = r.map { !$0.once && $0.kind != .edge ? " × \(Words.signed($0.points))" : "" } ?? ""
                let tone: RuleRow.Tone = r == nil ? .base : q.v < 0 ? .bad : q.v == 0 ? .zero : .good
                RuleRow(points: q.v, text: Words.part(p.type, q) + each, tone: tone, rule: r)
            }
        }
    }

    @ViewBuilder private func land(_ t: Terrain) -> some View {
        let cares = Words.caresAbout(t)
        kind(t == .water ? "Bridges only" : "Open land")
        title(t.name)
        if !cares.on.isEmpty {
            label("Build on it")
            ForEach(Array(cares.on.enumerated()), id: \.offset) { _, x in
                RuleRow(points: x.1.points, text: "\(x.0.name), each square", tone: RuleRow.tone(x.1.points), rule: x.1)
            }
        }
        if !cares.by.isEmpty {
            label("Build beside it")
            ForEach(Array(cares.by.enumerated()), id: \.offset) { _, x in
                RuleRow(points: x.1.points, text: "\(x.0.name), \(x.1.once ? "once" : "each square")", tone: RuleRow.tone(x.1.points), rule: x.1)
            }
            if t != .water {
                Text("Buildings beside it keep their points even if it is covered later.")
                    .font(.system(size: 13)).foregroundStyle(Palette.ink2).padding(.top, 6)
            }
        }
        if cares.on.isEmpty && cares.by.isEmpty {
            Text("No building scores for this land. Use it to fill gaps.").font(.system(size: 13.5)).foregroundStyle(Palette.ink2)
        }
    }

    private func label(_ s: String) -> some View {
        Text(s.uppercased()).font(.system(size: 10.5, weight: .heavy)).kerning(1).foregroundStyle(Palette.muted).padding(.top, 8).padding(.bottom, 2)
    }
}
