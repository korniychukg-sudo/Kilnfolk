import SwiftUI

// MARK: - Icon kinds

enum FolkIconKind {
    case wheel, kiln, shelf, book, dots
    case hand, sponge, rib, pull
    case undo, reset, star, starFill, trash, close, check, plus, chevronRight, chevronLeft
    case drop, flame, clock, sparkle, info, shield, flag
}

/// All in-app iconography is drawn by hand — no system symbols anywhere.
struct FolkIcon: View {
    let kind: FolkIconKind
    var size: CGFloat = 22
    var color: Color = Studio.ink
    var lineWidth: CGFloat? = nil

    var body: some View {
        Canvas { ctx, canvasSize in
            let rect = CGRect(origin: .zero, size: canvasSize).insetBy(dx: canvasSize.width * 0.06, dy: canvasSize.height * 0.06)
            let lw = lineWidth ?? max(1.6, size * 0.085)
            draw(&ctx, rect: rect, lw: lw)
        }
        .frame(width: size, height: size)
    }

    private func stroke(_ ctx: inout GraphicsContext, _ p: Path, _ lw: CGFloat) {
        ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round))
    }

    private func fill(_ ctx: inout GraphicsContext, _ p: Path) {
        ctx.fill(p, with: .color(color))
    }

    private func draw(_ ctx: inout GraphicsContext, rect: CGRect, lw: CGFloat) {
        let w = rect.width, h = rect.height
        let cx = rect.midX, cy = rect.midY

        switch kind {
        case .wheel:
            var disc = Path()
            disc.addEllipse(in: CGRect(x: rect.minX, y: cy - h * 0.18, width: w, height: h * 0.42))
            stroke(&ctx, disc, lw)
            var pot = Path()
            pot.move(to: CGPoint(x: cx - w * 0.18, y: cy - h * 0.02))
            pot.addQuadCurve(to: CGPoint(x: cx - w * 0.13, y: rect.minY + h * 0.10),
                             control: CGPoint(x: cx - w * 0.30, y: rect.minY + h * 0.22))
            pot.addLine(to: CGPoint(x: cx + w * 0.13, y: rect.minY + h * 0.10))
            pot.addQuadCurve(to: CGPoint(x: cx + w * 0.18, y: cy - h * 0.02),
                             control: CGPoint(x: cx + w * 0.30, y: rect.minY + h * 0.22))
            stroke(&ctx, pot, lw)
            var base = Path()
            base.move(to: CGPoint(x: rect.minX + w * 0.28, y: rect.maxY - h * 0.12))
            base.addLine(to: CGPoint(x: rect.maxX - w * 0.28, y: rect.maxY - h * 0.12))
            stroke(&ctx, base, lw)

        case .kiln:
            var arch = Path()
            arch.move(to: CGPoint(x: rect.minX + w * 0.08, y: rect.maxY))
            arch.addLine(to: CGPoint(x: rect.minX + w * 0.08, y: cy - h * 0.05))
            arch.addQuadCurve(to: CGPoint(x: rect.maxX - w * 0.08, y: cy - h * 0.05),
                              control: CGPoint(x: cx, y: rect.minY - h * 0.15))
            arch.addLine(to: CGPoint(x: rect.maxX - w * 0.08, y: rect.maxY))
            arch.closeSubpath()
            stroke(&ctx, arch, lw)
            var mouth = Path()
            mouth.move(to: CGPoint(x: cx - w * 0.16, y: rect.maxY))
            mouth.addLine(to: CGPoint(x: cx - w * 0.16, y: cy + h * 0.18))
            mouth.addQuadCurve(to: CGPoint(x: cx + w * 0.16, y: cy + h * 0.18),
                               control: CGPoint(x: cx, y: cy - h * 0.02))
            mouth.addLine(to: CGPoint(x: cx + w * 0.16, y: rect.maxY))
            stroke(&ctx, mouth, lw * 0.85)

        case .shelf:
            var board = Path()
            board.move(to: CGPoint(x: rect.minX, y: rect.maxY - h * 0.16))
            board.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - h * 0.16))
            stroke(&ctx, board, lw)
            var vase1 = Path()
            vase1.move(to: CGPoint(x: rect.minX + w * 0.14, y: rect.maxY - h * 0.16))
            vase1.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.22, y: rect.minY + h * 0.18),
                               control: CGPoint(x: rect.minX + w * 0.00, y: rect.midY - h * 0.08))
            vase1.addLine(to: CGPoint(x: rect.minX + w * 0.34, y: rect.minY + h * 0.18))
            vase1.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.42, y: rect.maxY - h * 0.16),
                               control: CGPoint(x: rect.minX + w * 0.56, y: rect.midY - h * 0.08))
            stroke(&ctx, vase1, lw * 0.9)
            var vase2 = Path()
            vase2.addEllipse(in: CGRect(x: rect.maxX - w * 0.38, y: rect.midY - h * 0.10,
                                        width: w * 0.30, height: h * 0.42).offsetBy(dx: 0, dy: -h * 0.06))
            stroke(&ctx, vase2, lw * 0.9)

        case .book:
            var cover = Path()
            cover.move(to: CGPoint(x: cx, y: rect.minY + h * 0.10))
            cover.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.14),
                               control: CGPoint(x: cx - w * 0.28, y: rect.minY - h * 0.02))
            cover.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - h * 0.08))
            cover.addQuadCurve(to: CGPoint(x: cx, y: rect.maxY - h * 0.02),
                               control: CGPoint(x: cx - w * 0.28, y: rect.maxY - h * 0.16))
            cover.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY - h * 0.08),
                               control: CGPoint(x: cx + w * 0.28, y: rect.maxY - h * 0.16))
            cover.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.14))
            cover.addQuadCurve(to: CGPoint(x: cx, y: rect.minY + h * 0.10),
                               control: CGPoint(x: cx + w * 0.28, y: rect.minY - h * 0.02))
            stroke(&ctx, cover, lw)
            var spine = Path()
            spine.move(to: CGPoint(x: cx, y: rect.minY + h * 0.12))
            spine.addLine(to: CGPoint(x: cx, y: rect.maxY - h * 0.04))
            stroke(&ctx, spine, lw * 0.8)

        case .dots:
            for i in 0..<3 {
                let x = rect.minX + w * (0.18 + 0.32 * CGFloat(i))
                var dot = Path()
                dot.addEllipse(in: CGRect(x: x - w * 0.07, y: cy - w * 0.07, width: w * 0.14, height: w * 0.14))
                fill(&ctx, dot)
            }

        case .hand:
            var palm = Path()
            palm.move(to: CGPoint(x: rect.minX + w * 0.22, y: rect.maxY))
            palm.addLine(to: CGPoint(x: rect.minX + w * 0.22, y: rect.minY + h * 0.34))
            stroke(&ctx, palm, lw)
            for i in 0..<3 {
                let x = rect.minX + w * (0.40 + 0.19 * CGFloat(i))
                let top = rect.minY + h * (i == 1 ? 0.10 : 0.20)
                var f = Path()
                f.move(to: CGPoint(x: x, y: rect.maxY - h * 0.10))
                f.addLine(to: CGPoint(x: x, y: top))
                stroke(&ctx, f, lw)
            }
            var base = Path()
            base.move(to: CGPoint(x: rect.minX + w * 0.22, y: rect.maxY))
            base.addQuadCurve(to: CGPoint(x: rect.maxX - w * 0.22, y: rect.maxY - h * 0.10),
                              control: CGPoint(x: cx, y: rect.maxY + h * 0.06))
            stroke(&ctx, base, lw)

        case .sponge:
            var body = Path()
            body.addRoundedRect(in: CGRect(x: rect.minX + w * 0.08, y: cy - h * 0.22,
                                           width: w * 0.84, height: h * 0.48), cornerSize: CGSize(width: 8, height: 8))
            stroke(&ctx, body, lw)
            for (dx, dy) in [(0.30, 0.0), (0.52, -0.08), (0.68, 0.06)] {
                var pore = Path()
                pore.addEllipse(in: CGRect(x: rect.minX + w * dx, y: cy + h * dy - 1.5, width: 3, height: 3))
                fill(&ctx, pore)
            }

        case .rib:
            var blade = Path()
            blade.move(to: CGPoint(x: rect.minX + w * 0.14, y: rect.maxY - h * 0.12))
            blade.addLine(to: CGPoint(x: rect.minX + w * 0.30, y: rect.minY + h * 0.12))
            blade.addLine(to: CGPoint(x: rect.maxX - w * 0.14, y: rect.minY + h * 0.22))
            blade.addQuadCurve(to: CGPoint(x: rect.maxX - w * 0.30, y: rect.maxY - h * 0.12),
                               control: CGPoint(x: rect.maxX - w * 0.10, y: cy + h * 0.16))
            blade.closeSubpath()
            stroke(&ctx, blade, lw)

        case .pull:
            var stem = Path()
            stem.move(to: CGPoint(x: cx, y: rect.maxY - h * 0.06))
            stem.addLine(to: CGPoint(x: cx, y: rect.minY + h * 0.06))
            stroke(&ctx, stem, lw)
            var up = Path()
            up.move(to: CGPoint(x: cx - w * 0.20, y: rect.minY + h * 0.26))
            up.addLine(to: CGPoint(x: cx, y: rect.minY + h * 0.06))
            up.addLine(to: CGPoint(x: cx + w * 0.20, y: rect.minY + h * 0.26))
            stroke(&ctx, up, lw)
            var down = Path()
            down.move(to: CGPoint(x: cx - w * 0.20, y: rect.maxY - h * 0.26))
            down.addLine(to: CGPoint(x: cx, y: rect.maxY - h * 0.06))
            down.addLine(to: CGPoint(x: cx + w * 0.20, y: rect.maxY - h * 0.26))
            stroke(&ctx, down, lw)

        case .undo:
            var arc = Path()
            arc.addArc(center: CGPoint(x: cx, y: cy), radius: w * 0.34,
                       startAngle: .degrees(40), endAngle: .degrees(280), clockwise: false)
            stroke(&ctx, arc, lw)
            var head = Path()
            let tip = CGPoint(x: cx + cos(CGFloat.pi * 40 / 180) * w * 0.34,
                              y: cy + sin(CGFloat.pi * 40 / 180) * w * 0.34)
            head.move(to: CGPoint(x: tip.x - w * 0.16, y: tip.y - h * 0.02))
            head.addLine(to: tip)
            head.addLine(to: CGPoint(x: tip.x + w * 0.02, y: tip.y - h * 0.18))
            stroke(&ctx, head, lw)

        case .reset:
            var lumpPath = Path()
            lumpPath.move(to: CGPoint(x: rect.minX + w * 0.14, y: rect.maxY - h * 0.14))
            lumpPath.addQuadCurve(to: CGPoint(x: rect.maxX - w * 0.14, y: rect.maxY - h * 0.14),
                                  control: CGPoint(x: cx, y: rect.minY + h * 0.06))
            lumpPath.closeSubpath()
            stroke(&ctx, lumpPath, lw)
            var line = Path()
            line.move(to: CGPoint(x: rect.minX + w * 0.06, y: rect.maxY - h * 0.14))
            line.addLine(to: CGPoint(x: rect.maxX - w * 0.06, y: rect.maxY - h * 0.14))
            stroke(&ctx, line, lw)

        case .star, .starFill:
            var p = Path()
            let outer = min(w, h) * 0.5
            let inner = outer * 0.42
            for i in 0..<10 {
                let r = i % 2 == 0 ? outer : inner
                let a = CGFloat(i) / 10 * .pi * 2 - .pi / 2
                let pt = CGPoint(x: cx + cos(a) * r, y: cy + sin(a) * r)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
            if kind == .starFill { fill(&ctx, p) } else { stroke(&ctx, p, lw) }

        case .trash:
            var can = Path()
            can.move(to: CGPoint(x: rect.minX + w * 0.20, y: rect.minY + h * 0.24))
            can.addLine(to: CGPoint(x: rect.minX + w * 0.28, y: rect.maxY - h * 0.04))
            can.addLine(to: CGPoint(x: rect.maxX - w * 0.28, y: rect.maxY - h * 0.04))
            can.addLine(to: CGPoint(x: rect.maxX - w * 0.20, y: rect.minY + h * 0.24))
            stroke(&ctx, can, lw)
            var lid = Path()
            lid.move(to: CGPoint(x: rect.minX + w * 0.12, y: rect.minY + h * 0.24))
            lid.addLine(to: CGPoint(x: rect.maxX - w * 0.12, y: rect.minY + h * 0.24))
            lid.move(to: CGPoint(x: cx - w * 0.12, y: rect.minY + h * 0.24))
            lid.addLine(to: CGPoint(x: cx - w * 0.08, y: rect.minY + h * 0.10))
            lid.addLine(to: CGPoint(x: cx + w * 0.08, y: rect.minY + h * 0.10))
            lid.addLine(to: CGPoint(x: cx + w * 0.12, y: rect.minY + h * 0.24))
            stroke(&ctx, lid, lw)

        case .close:
            var p = Path()
            p.move(to: CGPoint(x: rect.minX + w * 0.2, y: rect.minY + h * 0.2))
            p.addLine(to: CGPoint(x: rect.maxX - w * 0.2, y: rect.maxY - h * 0.2))
            p.move(to: CGPoint(x: rect.maxX - w * 0.2, y: rect.minY + h * 0.2))
            p.addLine(to: CGPoint(x: rect.minX + w * 0.2, y: rect.maxY - h * 0.2))
            stroke(&ctx, p, lw)

        case .check:
            var p = Path()
            p.move(to: CGPoint(x: rect.minX + w * 0.14, y: cy + h * 0.05))
            p.addLine(to: CGPoint(x: cx - w * 0.08, y: rect.maxY - h * 0.22))
            p.addLine(to: CGPoint(x: rect.maxX - w * 0.12, y: rect.minY + h * 0.22))
            stroke(&ctx, p, lw)

        case .plus:
            var p = Path()
            p.move(to: CGPoint(x: cx, y: rect.minY + h * 0.14))
            p.addLine(to: CGPoint(x: cx, y: rect.maxY - h * 0.14))
            p.move(to: CGPoint(x: rect.minX + w * 0.14, y: cy))
            p.addLine(to: CGPoint(x: rect.maxX - w * 0.14, y: cy))
            stroke(&ctx, p, lw)

        case .chevronRight:
            var p = Path()
            p.move(to: CGPoint(x: cx - w * 0.12, y: rect.minY + h * 0.2))
            p.addLine(to: CGPoint(x: cx + w * 0.16, y: cy))
            p.addLine(to: CGPoint(x: cx - w * 0.12, y: rect.maxY - h * 0.2))
            stroke(&ctx, p, lw)

        case .chevronLeft:
            var p = Path()
            p.move(to: CGPoint(x: cx + w * 0.12, y: rect.minY + h * 0.2))
            p.addLine(to: CGPoint(x: cx - w * 0.16, y: cy))
            p.addLine(to: CGPoint(x: cx + w * 0.12, y: rect.maxY - h * 0.2))
            stroke(&ctx, p, lw)

        case .drop:
            var p = Path()
            p.move(to: CGPoint(x: cx, y: rect.minY + h * 0.04))
            p.addQuadCurve(to: CGPoint(x: cx + w * 0.30, y: cy + h * 0.16),
                           control: CGPoint(x: cx + w * 0.34, y: cy - h * 0.18))
            p.addArc(center: CGPoint(x: cx, y: cy + h * 0.16), radius: w * 0.30,
                     startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
            p.addQuadCurve(to: CGPoint(x: cx, y: rect.minY + h * 0.04),
                           control: CGPoint(x: cx - w * 0.34, y: cy - h * 0.18))
            stroke(&ctx, p, lw)

        case .flame:
            var p = Path()
            p.move(to: CGPoint(x: cx, y: rect.minY + h * 0.04))
            p.addQuadCurve(to: CGPoint(x: cx + w * 0.28, y: cy + h * 0.18),
                           control: CGPoint(x: cx + w * 0.38, y: cy - h * 0.24))
            p.addQuadCurve(to: CGPoint(x: cx, y: rect.maxY - h * 0.04),
                           control: CGPoint(x: cx + w * 0.30, y: rect.maxY - h * 0.06))
            p.addQuadCurve(to: CGPoint(x: cx - w * 0.28, y: cy + h * 0.18),
                           control: CGPoint(x: cx - w * 0.30, y: rect.maxY - h * 0.06))
            p.addQuadCurve(to: CGPoint(x: cx, y: rect.minY + h * 0.04),
                           control: CGPoint(x: cx - w * 0.38, y: cy - h * 0.24))
            stroke(&ctx, p, lw)
            var inner = Path()
            inner.move(to: CGPoint(x: cx, y: cy + h * 0.02))
            inner.addQuadCurve(to: CGPoint(x: cx, y: rect.maxY - h * 0.10),
                               control: CGPoint(x: cx + w * 0.14, y: rect.maxY - h * 0.16))
            stroke(&ctx, inner, lw * 0.8)

        case .clock:
            var face = Path()
            face.addEllipse(in: rect.insetBy(dx: w * 0.08, dy: h * 0.08))
            stroke(&ctx, face, lw)
            var hands = Path()
            hands.move(to: CGPoint(x: cx, y: cy))
            hands.addLine(to: CGPoint(x: cx, y: cy - h * 0.24))
            hands.move(to: CGPoint(x: cx, y: cy))
            hands.addLine(to: CGPoint(x: cx + w * 0.18, y: cy + h * 0.08))
            stroke(&ctx, hands, lw * 0.9)

        case .sparkle:
            var p = Path()
            p.move(to: CGPoint(x: cx, y: rect.minY))
            p.addQuadCurve(to: CGPoint(x: rect.maxX, y: cy), control: CGPoint(x: cx + w * 0.10, y: cy - h * 0.10))
            p.addQuadCurve(to: CGPoint(x: cx, y: rect.maxY), control: CGPoint(x: cx + w * 0.10, y: cy + h * 0.10))
            p.addQuadCurve(to: CGPoint(x: rect.minX, y: cy), control: CGPoint(x: cx - w * 0.10, y: cy + h * 0.10))
            p.addQuadCurve(to: CGPoint(x: cx, y: rect.minY), control: CGPoint(x: cx - w * 0.10, y: cy - h * 0.10))
            fill(&ctx, p)

        case .info:
            var circle = Path()
            circle.addEllipse(in: rect.insetBy(dx: w * 0.08, dy: h * 0.08))
            stroke(&ctx, circle, lw)
            var mark = Path()
            mark.move(to: CGPoint(x: cx, y: cy - h * 0.02))
            mark.addLine(to: CGPoint(x: cx, y: cy + h * 0.20))
            stroke(&ctx, mark, lw)
            var dot = Path()
            dot.addEllipse(in: CGRect(x: cx - lw * 0.55, y: cy - h * 0.20, width: lw * 1.1, height: lw * 1.1))
            fill(&ctx, dot)

        case .flag:
            var pole = Path()
            pole.move(to: CGPoint(x: rect.minX + w * 0.22, y: rect.maxY))
            pole.addLine(to: CGPoint(x: rect.minX + w * 0.22, y: rect.minY + h * 0.04))
            stroke(&ctx, pole, lw)
            var pennant = Path()
            pennant.move(to: CGPoint(x: rect.minX + w * 0.22, y: rect.minY + h * 0.08))
            pennant.addQuadCurve(to: CGPoint(x: rect.maxX - w * 0.08, y: rect.minY + h * 0.24),
                                 control: CGPoint(x: cx, y: rect.minY + h * 0.02))
            pennant.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.22, y: rect.minY + h * 0.46),
                                 control: CGPoint(x: cx, y: rect.minY + h * 0.40))
            pennant.closeSubpath()
            stroke(&ctx, pennant, lw * 0.9)
            var dot = Path()
            dot.addEllipse(in: CGRect(x: cx - w * 0.06, y: rect.minY + h * 0.16, width: w * 0.12, height: w * 0.12))
            fill(&ctx, dot)

        case .shield:
            var p = Path()
            p.move(to: CGPoint(x: cx, y: rect.minY + h * 0.04))
            p.addLine(to: CGPoint(x: rect.maxX - w * 0.14, y: rect.minY + h * 0.18))
            p.addQuadCurve(to: CGPoint(x: cx, y: rect.maxY - h * 0.04),
                           control: CGPoint(x: rect.maxX - w * 0.14, y: cy + h * 0.28))
            p.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.14, y: rect.minY + h * 0.18),
                           control: CGPoint(x: rect.minX + w * 0.14, y: cy + h * 0.28))
            p.closeSubpath()
            stroke(&ctx, p, lw)
        }
    }
}
